// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IIdentityVerifier is IERC165 {

    /**
     *  @dev Verify that the buyer can purchase/bid
     */
    function verify(address identity, uint256 ethAmount) view external returns (bool);

    function verify(address identity, address erc20Address, uint256 erc20Amount) view external returns (bool);

}