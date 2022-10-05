// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Interface for redemption
/// @author Martin Wawrusch
interface INFTRedeemable {
    function redeem(address sender, uint256 tokenId) external;
}