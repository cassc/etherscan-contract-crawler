// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISpaceCows {
    function totalSupply() external view returns(uint256);
	function getMintingRate(address _address) external view returns(uint256);
    function cowMint(address _user, uint256[] memory _tokenId) external;
    function exists(uint256 _tokenId) external view returns(bool);
    function balanceOf(address owner) external returns(uint256);
}