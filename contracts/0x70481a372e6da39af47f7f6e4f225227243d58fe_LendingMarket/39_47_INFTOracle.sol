//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {Trustus} from "../protocol/Trustus/Trustus.sol";

interface INFTOracle {
    function getTokensETHPrice(
        address collection,
        uint256[] memory tokenIds,
        bytes32 request,
        Trustus.TrustusPacket calldata packet
    ) external view returns (uint256);
}