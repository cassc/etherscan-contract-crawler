// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAsyncToSync {
    struct MusicParam {
        Rarity rarity;
        Rhythm rhythm;
        Lyric lyric;
        Oscillator oscillator;
        ADSR adsr;
    }

    enum Rarity {
        Common,
        Rare,
        SuperRare,
        UltraRare,
        OneOfOne
    }

    enum Rhythm {
        Thick,
        LoFi,
        HiFi,
        Glitch,
        Shuffle
    }

    enum Lyric {
        LittleGirl,
        OldMan,
        FussyMan,
        LittleBoy,
        Shuffle
    }

    enum Oscillator {
        Lyra,
        Freak,
        LFO,
        Glitch,
        Shuffle
    }

    enum ADSR {
        Piano,
        Pad,
        Pluck,
        Lead,
        Shuffle
    }
}