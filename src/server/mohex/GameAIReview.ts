import Mohex from '../mohex-cli/Mohex';

const { MOHEX_BINARY } = process.env;

if (!MOHEX_BINARY) {
    throw new Error('Cannot use mohex module, please define a MOHEX_BINARY="..." in env');
}

const mohex = new Mohex(MOHEX_BINARY);

/*
boardsize 13 13
play-game k7 k6 i8 i7 d8 d9 f8 e10 g9 f11 j11 i13 k12 k11 j12 k10 i10 i9 h10 h9 g10 h8 f5 e6 g6 g7 f7 g5 f6 g1 g3 f4 g4 g8 f9 h1 i2 i11 j10 h2 h3 i1 j1 h11

[SERVER] review finished === AI REVIEW ===
[SERVER] best move: g7 (score: 0.58), played k7 (score (from op): 0.54)
[SERVER] best move: j6 (score: 0.55), played i8 (score (from op): 0.51)
[SERVER] best move: h7 (score: 0.54), played d8 (score (from op): 0.5)
[SERVER] best move: e8 (score: 0.55), played f8 (score (from op): 0.5)
[SERVER] best move: g9 (score: 0.5), played g9 (score (from op): 0.5)
[SERVER] best move: h8 (score: 0.52), played j11 (score (from op): 0.42000000000000004)
[SERVER] best move: g6 (score: 0.47), played k12 (score (from op): 0.4)
[SERVER] best move: g6 (score: 0.5), played j12 (score (from op): 0.43999999999999995)
[SERVER] best move: g6 (score: 0.53), played i10 (score (from op): 0.48)
[SERVER] best move: g10 (score: 0.55), played h10 (score (from op): 0.51)
[SERVER] best move: g10 (score: 0.56), played g10 (score (from op): 0.54)
[SERVER] best move: g6 (score: 0.69), played f5 (score (from op): 0.64)
[SERVER] best move: g6 (score: 0.78), played g6 (score (from op): 0.8200000000000001)
[SERVER] best move: f7 (score: 0.83), played f7 (score (from op): 0.87)
[SERVER] best move: h4 (score: null), played f6 (score (from op): null)
[SERVER] best move: h5 (score: null), played g3 (score (from op): null)
[SERVER] best move: g4 (score: null), played g4 (score (from op): null)
[SERVER] best move: f9 (score: null), played f9 (score (from op): null)
[SERVER] best move: i2 (score: null), played i2 (score (from op): null)
[SERVER] best move: j10 (score: null), played j10 (score (from op): null)
[SERVER] best move: h3 (score: null), played h3 (score (from op): null)

*/

const getLastScore = (mohex: Mohex): null | number => {
    const match = mohex.getLastStdErrChunks().join('\n').match(/Score *([\d.]+)/)?.pop();

    if (!match) {
        return null;
    }

    return parseFloat(match);
};

export const run = async () => {
    const moves = 'k7 k6 i8 i7 d8 d9 f8 e10 g9 f11 j11 i13 k12 k11 j12 k10 i10 i9 h10 h9 g10 h8 f5 e6 g6 g7 f7 g5 f6 g1 g3 f4 g4 g8 f9 h1 i2 i11 j10 h2 h3 i1 j1 h11'.split(' ');

    await mohex.setBoardSize(13);

    let i = 0;
    const review: string[] = ['=== AI REVIEW ==='];

    while (i < moves.length - 3) {
        const bestMove = await mohex.sendCommand('reg_genmove black');
        const bestMoveScore = getLastScore(mohex);

        await mohex.play('black', moves[i]);

        await mohex.sendCommand('reg_genmove white')
        const playedMoveScore = getLastScore(mohex);

        review.push(`best move: ${bestMove} (score: ${bestMoveScore}), played ${moves[i]} (score (from op): ${playedMoveScore ? 1 - playedMoveScore : null})`);

        await mohex.play('white', moves[i + 1]);

        console.log(review.join('\n'));

        i += 2;
    }

    console.log('review finished', review.join('\n'));
};
