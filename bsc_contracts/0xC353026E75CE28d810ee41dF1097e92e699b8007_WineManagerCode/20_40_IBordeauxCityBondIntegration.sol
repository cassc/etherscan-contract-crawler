// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBordeauxCityBondIntegration {

    function BCBOutFee() external view returns (uint256);
    function BCBFixedFee() external view returns (uint256);
    function BCBFlexedFee() external view returns (uint256);

    function initialize(
        address manager_,
        uint256 BCBOutFee_,
        uint256 BCBFixedFee_,
        uint256 BCBFlexedFee_
    ) external;

//////////////////////////////////////// Settings
    function _editBCBOutFee(uint256 BCBOutFee_) external;

    function _editBCBFixedFee(uint256 BCBFixedFee_) external;

    function _editBCBFlexedFee(uint256 BCBFlexedFee_) external;

//////////////////////////////////////// Owner

    function getCurrency() external view returns (IERC20);

    function calculateStoragePrice(uint256 poolId, uint256 tokenId, bool withBCBOut) external view returns (uint256);

    function onMint(uint256 poolId, uint256 tokenId) external;

    function onOrderExecute(uint256 poolId, uint256 tokenId) external;

    function onRequestDelivery(uint256 poolId, uint256 tokenId) external;

//////////////////////////////////////// Owner

    function withdrawBCBFee(address to, uint256 amount) external;

}