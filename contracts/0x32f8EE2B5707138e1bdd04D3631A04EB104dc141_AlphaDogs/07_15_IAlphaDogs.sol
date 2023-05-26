// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {IAlphaDogsEvents} from "./IAlphaDogsEvents.sol";
import {IAlphaDogsErrors} from "./IAlphaDogsErrors.sol";

interface IAlphaDogs is IAlphaDogsEvents, IAlphaDogsErrors {
    struct CustomMetadata {
        string name;
        string lore;
    }

    struct Stake {
        address owner;
        uint96 stakedAt;
    }

    // mapping(uint256 => CustomMetadata) getMetadata;
    function getMetadata(uint256 id)
        external
        view
        returns (CustomMetadata memory);

    function setName(uint256 id, string calldata newName) external;

    function setLore(uint256 id, string calldata newLore) external;

    function stake(uint256[] calldata tokenIds) external;

    function unstake(uint256[] calldata tokenIds) external;

    function claim(uint256[] calldata tokenIds) external;

    function premint(bytes32[] calldata proof) external;

    function mint() external;

    function breed(uint256 mom, uint256 dad) external;
}