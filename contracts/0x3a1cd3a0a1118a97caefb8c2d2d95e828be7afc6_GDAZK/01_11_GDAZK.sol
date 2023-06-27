// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

/// @title GDAZK
/// @author Burn0ut#8868 https://twitter.com/0xh3x
/// @notice https://www.thedeadarmyskeletonklub.army/ https://twitter.com/The_DASK
contract GDAZK is ERC721A, Ownable {
    using Strings for uint;

    uint public constant MAX_TOKENS = 69;
    uint public constant MAX_PER_MINT = 20;

    uint public price = 0.02 ether;
    uint public goldenId = type(uint).max;

    string public baseURI = "ipfs://Qma2DoYBK1BqDg5FWuoJfBdP3mX5rjZPXX8KGUcj95KoMp/";
    string public goldenURI = "ipfs://QmcMtB9XtJjy6uaNHArUxXxtN1U5qZVCESZkgxRnG8aKNn/";

    constructor() ERC721A("Golden DAZK", "GDAZK") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        if (tokenId == goldenId) {
            return string(abi.encodePacked(goldenURI, tokenId.toString()));
        } else {
            return super.tokenURI(tokenId);
        }
    }
 
    function mint(uint tokens) external payable {
        require(tokens <= MAX_PER_MINT, "GDAZK: Cannot purchase this many tokens in a transaction");
        require(_totalMinted() + tokens <= MAX_TOKENS, "GDAZK: Minting would exceed max supply");
        require(tokens > 0, "GDAZK: Must mint at least one token");
        require(price * tokens == msg.value, "GDAZK: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }


    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function setGoldenURI(string memory _newGoldenURI) external onlyOwner {
        goldenURI = _newGoldenURI;
    }

    function setPrice(uint _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function setGoldenAndDistributeETH(uint tokenId) external onlyOwner {
        goldenId = tokenId;
        baseURI = "ipfs://QmQbP4xJnoNhiPNmbcbiyAfGbvKyNwvxUp3uBUx7MPmDdf/";
        _widthdraw(ownerOf(tokenId), address(this).balance);
    }

    function _widthdraw(address _address, uint _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "GDAZK: Failed to widthdraw Ether");
    }
}