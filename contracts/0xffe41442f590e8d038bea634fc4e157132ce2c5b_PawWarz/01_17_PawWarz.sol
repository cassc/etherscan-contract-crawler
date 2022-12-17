// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@imtbl/imx-contracts/contracts/Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PawWarz is ERC721, Mintable {
    using SafeERC20 for IERC20;

    string public baseURI;

    event PayedForImxMint();

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    function payForImxMint() external payable {
        emit PayedForImxMint();
    }

    // owner

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return baseURI;
    }

    function withdraw(uint256 _amount) external payable onlyOwner {
        require(address(this).balance >= _amount, "Not enough ETH");
        address payable to = payable(owner());
        (bool sent, ) = to.call{value: _amount}("");
        require(sent, "Failed to send ETH");
    }

    function withdrawERC20(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(owner(), _amount);
    }
}