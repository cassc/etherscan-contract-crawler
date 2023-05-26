pragma solidity ^0.8.2;

interface IERC1155Burnable {
	function burnFor(address _user, uint256 _tokenId, uint256 _amount) external;
}