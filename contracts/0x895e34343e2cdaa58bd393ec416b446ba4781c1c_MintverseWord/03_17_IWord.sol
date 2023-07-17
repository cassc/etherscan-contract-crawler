// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWord {
    struct TokenInfo {
        string definerPart;
        string relatedWordPart;
        string descriptionPart;

        uint16 wordPart;
        uint8 categoryPart; // 1: Genesis Card, 2: Special Card, 3. Censored Card
        uint8 partOfSpeechPart1;
        uint8 partOfSpeechPart2;

        uint48 mintTime;
        bool defined;
    }
}