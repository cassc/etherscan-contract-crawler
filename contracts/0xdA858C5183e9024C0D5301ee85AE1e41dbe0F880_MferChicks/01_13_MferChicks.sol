// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MferChicks is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_PER_MINT = 50;
    address public constant w1 = 0xf2F809faFCdF06b4C544714D9393d6e0740cb1F1;
    address public constant w2 = 0x0d12ce9633d1aE3198c4f44C6b36DEbCf65fE95C;
    address public constant w3 = 0x44BAd28cf991EdD62461aaf6c92e26d8D9B574D2;

    uint256 public price = 0.015 ether;
    uint256 public maxSupply = 5555;
    bool public publicSaleStarted = false;

    string public baseURI = "";

    constructor() ERC721A("mfer chicks", "MFCHICK", 50) {
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	    maxSupply = _newMaxSupply;
	}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(tokens <= MAX_PER_MINT, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= maxSupply, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(price * tokens <= msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= maxSupply, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(w1, ((balance * 20) / 100));
        _withdraw(w2, ((balance * 50) / 100));
        _withdraw(w3, ((balance * 20) / 100));
        _withdraw(w1, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}