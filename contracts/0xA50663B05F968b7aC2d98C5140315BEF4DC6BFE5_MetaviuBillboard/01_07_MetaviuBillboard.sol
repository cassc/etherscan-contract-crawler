// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/// @title MetaviuBillboard
/// @notice https://metaviu.io/ https://twitter.com/meta_viu
contract MetaviuBillboard is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 7777;

    uint256 public constant price = 0.07 ether;
    uint256 public constant presalePrice = 0.05 ether;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    mapping(address => uint256) public whiteListWallets;
    uint256 public presaleMaxPerWallet = 50;
    string public baseURI = "";

    constructor() ERC721A("MetaViuBillboard", "MetaViuBillboard") {
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return super.tokenURI(tokenId);
    }


    /// Presale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the presale preconditions aren't satisfied
    function mintPresale(uint256 tokens) external payable {
        require(presaleStarted, "MetaviuBillboard: Presale has not started");
        uint256 qtyAllowed = whiteListWallets[msg.sender];
        require(tokens <= qtyAllowed && tokens >= 1, "MetaviuBillboard:  You can't mint on presale");

        require(totalSupply() + tokens <= MAX_TOKENS, "MetaviuBillboard: Minting would exceed max supply");

        require(presalePrice * tokens == msg.value, "MetaviuBillboard: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        whiteListWallets[msg.sender] = qtyAllowed - tokens;
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "MetaviuBillboard: Public sale has not started");
        require(totalSupply() + tokens <= MAX_TOKENS, "MetaviuBillboard: Minting would exceed max supply");
        require(tokens > 0, "MetaviuBillboard: Must mint at least one token");
        require(price * tokens == msg.value, "MetaviuBillboard: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    //set white list wallet addresses
    function setWhiteListWallets(address[] memory _address) public onlyOwner {
        for (uint256 i; i < _address.length; i++) {
            whiteListWallets[_address[i]] = presaleMaxPerWallet;
        }
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "MetaviuBillboard: Insufficent balance");
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "MetaviuBillboard: Failed to widthdraw Ether");
    }

}