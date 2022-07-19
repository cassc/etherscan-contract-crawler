// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IRegistry} from "./IRegistry.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

interface INFTStaker is IVotes {
    function registry() external view returns (IRegistry);

    function stake(uint256 _tokenId) external;

    function isStaked(uint256 _tokenId) external view returns (bool);

    function _stakeFromLock(uint256 _tokenId) external;

    function updateStake(uint256 _tokenId) external;

    function unstake(uint256 _tokenId) external;

    function getStakedBalance(address who) external view returns (uint256);

    event StakeNFT(
        address indexed who,
        address indexed owner,
        uint256 tokenId,
        uint256 amount
    );
    event RestakeNFT(
        address indexed who,
        address indexed owner,
        uint256 tokenId,
        uint256 oldAmount,
        uint256 newAmount
    );
    event UnstakeNFT(
        address indexed who,
        address indexed owner,
        uint256 tokenId,
        uint256 amount
    );
}