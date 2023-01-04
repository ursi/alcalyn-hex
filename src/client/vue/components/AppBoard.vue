<script setup lang="ts">
/* eslint-env browser */
import GameView from '@client/GameView';
import Hex from '@client/Hex';
import { PlayerIndex } from '@shared/game-engine';
import { onMounted, onUnmounted, ref } from '@vue/runtime-core';
import { toRefs } from 'vue';

const colorA = '#' + Hex.COLOR_A.toString(16);
const colorB = '#' + Hex.COLOR_B.toString(16);
const pixiApp = ref<HTMLElement>();

const props = defineProps({
    gameView: {
        type: GameView,
        required: true,
    },
    onJoin: {
        type: Function,
        default: null,
        required: false,
    },
});

const { gameView, onJoin } = toRefs(props);
const game = gameView?.value?.getGame();

if (!gameView || !game) {
    throw new Error('gameView is required');
}

const displayJoin = (playerIndex: PlayerIndex): boolean => {
    return Boolean(onJoin);
}

const joinGame = (playerIndex: PlayerIndex) => {
    if (!onJoin.value) {
        return;
    }

    onJoin.value(playerIndex);
};

onMounted(() => {
    if (!pixiApp.value) {
        throw new Error('No element with ref="pixiApp"');
    }

    if (!gameView.value) {
        throw new Error('gameView has no value');
    }

    pixiApp.value.appendChild(gameView.value.getView() as unknown as Node);
});

onUnmounted(() => {
    gameView.value.destroy();
});
</script>

<template>
    <div class="container">
        <div class="board-container">
            <div ref="pixiApp"></div>
        </div>

        <div v-if="game" :class="['game-info-overlay', `orientation-${gameView.getOrientation()}`]">
            <div class="player player-a">
                <p :style="{ color: colorA }">{{ game.getPlayer(0).toData().id }}</p>
                <button v-if="displayJoin(0)" @click="joinGame(0)">Join</button>
            </div>
            <div class="player player-b">
                <p :style="{ color: colorB }">{{ game.getPlayer(1).toData().id }}</p>
                <button v-if="displayJoin(1)" @click="joinGame(1)">Join</button>
            </div>
        </div>
        <p v-else>Initialize game...</p>
    </div>
</template>

<style lang="stylus">
.container
    position relative

.board-container
    display flex
    justify-content center

.player
    position absolute
    height auto
    max-width 35%

    p
        margin-top 0

.orientation-vertical_bias_right_hand
    .player-a
        left 0
        top 0
    .player-b
        right 0
        bottom 0

.orientation-vertical_bias_left_hand
    .player-a
        right 0
        top 0
    .player-b
        left 0
        bottom 0

.orientation-horizontal
    .player-a
        left 0
        top 0
    .player-b
        right 0
        top 0

.orientation-horizontal_bias
    .player-a
        left 0
        bottom 0
    .player-b
        right 0
        top 0

.orientation-vertical
    .player-a
        left 0
        top 0
    .player-b
        right 0
        top 0
</style>