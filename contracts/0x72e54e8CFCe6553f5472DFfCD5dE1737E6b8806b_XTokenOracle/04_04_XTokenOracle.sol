//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/INFTXInvetoryStaking.sol';
import './interfaces/IOracle.sol';

contract XTokenOracle {
    // address of NFTX vaultID
    uint256 public immutable nftxVaultID;

    // address of oracle contract
    IOracle public immutable oracle;

    // address of NFTX inventory staking
    INFTXInvetoryStaking public immutable nftxInventoryStaking;

    constructor(uint256 vaultId, IOracle oracleAddr, INFTXInvetoryStaking staking) {
        nftxVaultID = vaultId;
        oracle = oracleAddr;
        nftxInventoryStaking = staking;
    }

    function latestAnswer() public view returns (int256 answer) {
        uint256 shareVaule = nftxInventoryStaking.xTokenShareValue(nftxVaultID);
        answer = (int256(shareVaule) * oracle.latestAnswer()) / 1e18;
    }
}