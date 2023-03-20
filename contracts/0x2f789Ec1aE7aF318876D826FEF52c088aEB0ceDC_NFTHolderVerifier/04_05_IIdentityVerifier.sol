// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Identity Verifier interface made by Artiffine
 * @author https://artiffine.com/
 */
interface IIdentityVerifier is IERC165 {
    /**
     *  @dev Verify that the buyer can purchase/bid
     *
     *  @param identity       The identity to verify.
     *  @param tokenId        The token id associated with this verification.
     *  @param amount         Amount of tokens to buy.
     *  @param data           Additional data needed to verify.
     *
     */
    function verify(address identity, uint256 tokenId, uint256 amount, bytes calldata data) external returns (bool);

    /**
     *  @dev Preview {verify} function result.
     *
     *  @param identity       The identity to verify.
     *  @param tokenId        The token id associated with this verification.
     *  @param amount         Amount of tokens to buy.
     *  @param data           Additional data needed to verify.
     */
    function previewVerify(address identity, uint256 tokenId, uint256 amount, bytes calldata data) external view returns (bool);
}