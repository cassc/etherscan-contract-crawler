// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title CIMAdownOG
/// @author Burn0ut#8868 [email protected]
/// @notice https://CIMAdownNFT.com/ https://twitter.com/CIMAdownNFT
contract CIMAdownOG is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 65;
    uint256 public constant MAX_PER_MINT = 3;
    address public constant w1 = 0xFbEd81821FEFEbF3d8c90A2923A9038e1748b0Fb;
    address public constant w2 = 0x8deddE67889F0Bb474E094165A4BA37872A7c26B;

    uint256 public price = 1 ether;
    bool public publicSaleStarted = true;

    string public baseURI = "ipfs://QmY9ca3Vfbuwrzh6TdLmVkxKD3vSSV6mUnEWsxqTuLwD53/";

    constructor() ERC721A("CIMAdownOG", "CIMAdown OG Pass", 3) {
    }


    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "CIMAdown: Public sale has not started");
        require(tokens <= MAX_PER_MINT, "CIMAdown: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "CIMAdown: Minting would exceed max supply");
        require(tokens > 0, "CIMAdown: Must mint at least one token");
        require(price * tokens == msg.value, "CIMAdown: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "CIMAdown: Minting would exceed max supply");
        require(tokens > 0, "CIMAdown: Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "CIMAdown: Insufficent balance");
        _withdraw(w2, ((balance * 10) / 100));
        _withdraw(w1, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "CIMAdown: Failed to widthdraw Ether");
    }

}