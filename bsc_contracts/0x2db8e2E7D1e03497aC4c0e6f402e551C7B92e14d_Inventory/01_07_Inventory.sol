// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IERC721 {
    function balanceOf(address) external view returns(uint256);
    function tokenOfOwnerByIndex(address, uint) external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function currentTokenId() external view returns(uint256);
    function mint(address _to, uint256 _tokenId, string memory _hashs) external;
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint _tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Inventory is Ownable {

    constructor() {}

    function getInventory(address user, IERC721 _items721) external view returns(string[] memory tokenURI, uint[] memory tokenIds) {
        uint balanceOf = _items721.balanceOf(user);
        tokenURI = new string[](balanceOf);
        tokenIds = new uint[](balanceOf);
        for(uint i = 0; i < balanceOf; i++) {
            uint tokenId = _items721.tokenOfOwnerByIndex(user, i);
            tokenURI[i] = _items721.tokenURI(tokenId);
            tokenIds[i] = tokenId;
        }
    }

    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}