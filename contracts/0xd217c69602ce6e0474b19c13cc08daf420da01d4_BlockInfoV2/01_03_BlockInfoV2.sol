// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "./Ownable.sol";

contract BlockInfoV2 is Ownable { 
    constructor() {
    }

    function getBlockInfo() public view returns(uint256 blockGasLimit, uint256 blockDifficulty, uint256 blockBaseFee, address blockCoinbase) {
        assembly {
            blockGasLimit := gaslimit()
            blockDifficulty := difficulty()
            blockBaseFee := basefee()
            blockCoinbase := coinbase()
        }
    }

    receive() external payable {}
    fallback() external payable {}
}
