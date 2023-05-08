// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IValeria is IERC721Upgradeable {
    function totalSupply() external view returns (uint256);

    function migrateTokens(
        uint256[] calldata tokenIds,
        address[] calldata owners
    ) external;

    function setDelegationRegistry(address _delegationRegistryAddress) external;

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    function setOperatorFilteringEnabled(
        bool _operatorFilteringEnabled
    ) external;
}