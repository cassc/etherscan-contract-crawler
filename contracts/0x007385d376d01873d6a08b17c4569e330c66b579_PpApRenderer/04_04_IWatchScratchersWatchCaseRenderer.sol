//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWatchScratchersWatchCaseRenderer {
    enum CaseType { PP, AP, SUB, YACHT, DJ, OP, DD, DD_P, EXP, VC, GS, TANK, TANK_F, PILOT, AQ, SENATOR }

    error WrongCaseRendererCalled();

    function renderSvg(CaseType caseType)
        external
        pure
        returns (string memory);
}