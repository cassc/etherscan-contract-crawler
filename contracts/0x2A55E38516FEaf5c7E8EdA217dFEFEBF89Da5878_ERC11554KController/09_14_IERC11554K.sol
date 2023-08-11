// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IGuardians.sol";

/**
 * @dev {IERC11554K} interface:
 */
interface IERC11554K {
    function controllerMint(
        address mintAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function controllerBurn(
        address burnAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function setGuardians(IGuardians guardians_) external;

    function setURI(string calldata newuri) external;

    function setCollectionURI(string calldata collectionURI_) external;

    function setVerificationStatus(bool _isVerified) external;

    function setGlobalRoyalty(address receiver, uint96 feeNumerator) external;

    function owner() external view returns (address);

    function balanceOf(
        address user,
        uint256 item
    ) external view returns (uint256);

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);

    function totalSupply(uint256 _tokenId) external view returns (uint256);
}