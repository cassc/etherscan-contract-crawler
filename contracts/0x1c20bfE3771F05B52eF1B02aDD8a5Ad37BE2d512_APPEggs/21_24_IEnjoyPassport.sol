// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IEnjoyPassport {
    function minterMint(address _address, uint256 _amount) external;
    function burnerBurn(address _address, uint256[] calldata tokenIds) external;
    function tokenOfOwner(address owner) external view returns (uint256);

    function refreshMetadata(uint256 _tokenId) external;
	function refreshMetadata(uint256 _fromTokenId, uint256 _toTokenId) external;
}