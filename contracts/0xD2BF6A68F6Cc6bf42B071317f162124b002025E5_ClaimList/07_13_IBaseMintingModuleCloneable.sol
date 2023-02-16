// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IBaseMintingModuleCloneable is IAccessControlUpgradeable {
    function setMaxClaim(uint256 _maxClaim) external;

    function setIsActive(bool _isActive) external;

    function setMintPrice(uint256 _mintPrice) external;

    function setMinterAddress(address _minterAddress) external;

    function initialize(
        address _admin,
        address _minter,
        bytes calldata data
    ) external;
}