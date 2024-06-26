<script setup lang="ts">
import { useOverlayMeta } from 'unoverlay-vue';
import { PropType, Ref, ref } from 'vue';
import { GameOptionsData, sanitizeGameOptions } from '@shared/app/GameOptions';
import { defaultGameOptions } from '@shared/app/GameOptions';
import { BIconCaretDownFill, BIconCaretRight, BIconExclamationTriangle } from 'bootstrap-icons-vue';
import AppBoardsize from './create-game/AppBoardsize.vue';
import AppPlayFirstOrSecond from './create-game/AppPlayFirstOrSecond.vue';
import AppSwapRule from './create-game/AppSwapRule.vue';
import AppTimeControl from './create-game/AppTimeControl.vue';
import useAiConfigsStore from '../../../stores/aiConfigsStore';
import { storeToRefs } from 'pinia';
import { AIConfigStatusData } from '@shared/app/Types';
import { apiGetAiConfigsStatus } from '../../../apiClient';
import AIConfig from '../../../../shared/app/models/AIConfig';

const { visible, confirm, cancel } = useOverlayMeta();

const props = defineProps({
    gameOptions: {
        type: Object as PropType<Partial<GameOptionsData>>,
        required: true,
    },
});

export type Create1vAIOverlayInput = typeof props;

const gameOptions = ref<GameOptionsData>({ ...defaultGameOptions, ...props.gameOptions });

const showSecondaryOptions = ref(false);
const timeControlComponent = ref();

const submitForm = (gameOptions: GameOptionsData): void => {
    timeControlComponent.value.compileOptions();

    confirm(sanitizeGameOptions(gameOptions));
};

/*
 * AI configs
 */
const { aiConfigs } = storeToRefs(useAiConfigsStore());
const selectedEngine = ref('katahex');
const selectedAiConfig = ref<AIConfig<'withPlayerId'> | null>(null);
const aiConfigsStatus: Ref<null | AIConfigStatusData> = ref(null);

(async () => {
    aiConfigsStatus.value = await apiGetAiConfigsStatus();
})();

const isAIConfigAvailable = (aiConfig: AIConfig<'withPlayerId'>): boolean => {
    if (!aiConfig.isRemote) {
        return true;
    }

    if (null === aiConfigsStatus.value) {
        return false;
    }

    if (aiConfig.isRemote && !aiConfigsStatus.value.aiApiAvailable) {
        return false;
    }

    if (aiConfig.requireMorePower && !aiConfigsStatus.value.powerfulPeerAvailable) {
        return false;
    }

    return true;
};

const capSelectedBoardsize = () => {
    if (null === selectedAiConfig.value) {
        return;
    }

    const { boardsizeMin, boardsizeMax } = selectedAiConfig.value;

    if (null !== boardsizeMin && gameOptions.value.boardsize < boardsizeMin) {
        gameOptions.value.boardsize = boardsizeMin;
    }

    if (null !== boardsizeMax && gameOptions.value.boardsize > boardsizeMax) {
        gameOptions.value.boardsize = boardsizeMax;
    }
};
</script>

<template>
    <div v-if="visible">
        <div class="modal d-block">
            <div class="modal-dialog">
                <form class="modal-content" @submit="e => { e.preventDefault(); submitForm(gameOptions); }">
                    <div class="modal-header">
                        <h5 class="modal-title">Game options</h5>
                        <button type="button" class="btn-close" @click="cancel()"></button>
                    </div>
                    <div class="modal-body">
                        <template v-if="null !== aiConfigsStatus">
                            <p v-if="!aiConfigsStatus.aiApiAvailable" class="text-danger"><b-icon-exclamation-triangle /> <small>No worker can compute moves right now. Only random bots are available.</small></p>
                            <p v-else-if="!aiConfigsStatus.powerfulPeerAvailable" class="text-warning"><b-icon-exclamation-triangle /> <small>No fast worker is online right now. Only limited AI are available.</small></p>
                        </template>

                        <ul class="nav nav-pills nav-justified ai-engine-choice">
                            <li v-for="(_, engine) in aiConfigs" class="nav-item">
                                <button type="button" class="nav-link" :class="{ active: engine === selectedEngine }" @click="selectedEngine = (engine as string)">{{ engine }}</button>
                            </li>
                        </ul>

                        <div class="engine-configs">
                            <div v-for="aiConfig in aiConfigs[selectedEngine]" :key="aiConfig.player.publicId" class="form-check">
                                <input
                                    v-model="gameOptions.opponent.publicId"
                                    @click="selectedAiConfig = aiConfig; capSelectedBoardsize()"
                                    required
                                    :disabled="!isAIConfigAvailable(aiConfig)"
                                    class="form-check-input"
                                    type="radio"
                                    name="flexRadioDefault"
                                    :id="aiConfig.player.publicId"
                                    :value="aiConfig.player.publicId"
                                >
                                <label class="form-check-label" :for="aiConfig.player.publicId">
                                    {{ aiConfig.label }} <small class="text-secondary">{{ aiConfig.description }}</small>
                                </label>
                            </div>
                        </div>

                        <div class="mb-3">
                            <app-boardsize
                                :game-options="gameOptions"
                                :boardsize-min="selectedAiConfig?.boardsizeMin ?? undefined"
                                :boardsize-max="selectedAiConfig?.boardsizeMax ?? undefined"
                            />
                        </div>

                        <div class="mb-3">
                            <app-time-control :game-options="gameOptions" ref="timeControlComponent" />
                        </div>

                        <button
                            v-if="showSecondaryOptions"
                            @click="showSecondaryOptions = false"
                            type="button"
                            class="btn btn-primary btn-sm mt-3"
                        ><b-icon-caret-down-fill /> Less options</button>
                        <button
                            v-else
                            @click="showSecondaryOptions = true"
                            type="button"
                            class="btn btn-outline-primary btn-sm mt-3"
                        ><b-icon-caret-right /> More options</button>
                    </div>
                    <div v-if="showSecondaryOptions" class="modal-body border-top">
                        <div class="mb-3">
                            <app-play-first-or-second :game-options="gameOptions" />
                        </div>

                        <div class="mb-3">
                            <app-swap-rule :game-options="gameOptions" />
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" @click="cancel()">Cancel</button>
                        <button type="submit" class="btn btn-success">Play vs AI</button>
                    </div>
                </form>
            </div>
        </div>
        <div class="modal-backdrop show d-fixed"></div>
    </div>
</template>

<style lang="stylus" scoped>
.ai-engine-choice
    .nav-link::first-letter
        text-transform capitalize

.engine-configs
    margin 1em 0 2em 1em
</style>
