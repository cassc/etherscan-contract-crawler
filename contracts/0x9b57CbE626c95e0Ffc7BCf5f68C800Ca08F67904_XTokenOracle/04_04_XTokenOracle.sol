//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/INFTXInvetoryStaking.sol';
import './interfaces/IOracle.sol';

contract XTokenOracle {
    /// @notice address of NFTX vaultID
    uint256 public immutable nftxVaultID;

    /// @notice address of oracle contract
    IOracle public immutable oracle;

    /// @notice address of NFTX inventory staking
    INFTXInvetoryStaking public immutable nftxInventoryStaking;

    // /// @notice address of NFTX inventory staking
    // uint8 public constant decimals = 18;

    constructor(uint256 vaultId, IOracle oracleAddr, INFTXInvetoryStaking staking) {
        nftxVaultID = vaultId;
        oracle = oracleAddr;
        nftxInventoryStaking = staking;
    }

    function latestAnswer() external view returns (int256 answer) {
        uint256 shareVaule = nftxInventoryStaking.xTokenShareValue(nftxVaultID);
        answer = (int256(shareVaule) * oracle.latestAnswer()) / 1e18;
    }

    function decimals() external view returns (uint8) {
        return oracle.decimals();
    }
}