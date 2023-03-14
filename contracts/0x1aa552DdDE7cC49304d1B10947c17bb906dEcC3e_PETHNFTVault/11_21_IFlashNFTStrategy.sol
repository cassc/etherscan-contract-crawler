// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./IGenericNFTStrategy.sol";

interface IFlashNFTStrategy is IGenericNFTStrategy {
    function afterDeposit(
        address _owner,
        address _returnAddress,
        uint256[] calldata _nftIndexes,
        bytes calldata _data
    ) external;
}