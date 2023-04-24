// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {INFTManagerDefination} from "src/interfaces/nft/INFTManager.sol";
import {IDegenNFTDefination} from "src/interfaces/nft/IDegenNFT.sol";

import {DegenNFT} from "src/nft/DegenNFT.sol";

contract NFTManagerStorage is INFTManagerDefination {
    // degen nft address
    DegenNFT public degenNFT;

    // white list merkle tree root
    bytes32 public merkleRoot;

    mapping(address => bool) public signers;

    // record minted users to avoid whitelist users mint more than once
    // mapping(address => bool) public minted;
    BitMapsUpgradeable.BitMap internal hasMinted;

    // Mapping from mint type to mint start and end time
    mapping(StageType => StageTime) stageTime;

    // different config with different level, index as level
    mapping(uint256 => BurnRefundConfig) internal burnRefundConfigs;

    // public mint pay mint fee
    uint256 public mintFee;

    uint256[43] private _gap;
}