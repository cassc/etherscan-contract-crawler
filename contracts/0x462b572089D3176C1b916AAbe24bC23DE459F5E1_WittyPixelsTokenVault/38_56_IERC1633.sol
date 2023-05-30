// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title EIP-1633: Re-Fungible ERC721Token Standard (RFT)
/// @dev https://eips.ethereum.org/EIPS/eip-1633
interface IERC1633 /* is ERC20, ERC165 */ {
    /// @dev Note: the ERC-165 identifier for this interface is 0x5755c3f2.
    function parentToken() external view returns(address _parentToken);
    function parentTokenId() external view returns(uint256 _parentTokenId);
}