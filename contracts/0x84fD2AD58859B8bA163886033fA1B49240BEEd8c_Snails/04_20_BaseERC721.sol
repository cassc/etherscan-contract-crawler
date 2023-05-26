//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./ERC721EnumB.sol";

contract BaseERC721 is ERC721EnumB, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseUri;
    uint256 public supply;
    uint256 public max;
    string private extension = ".json";
    bool public isSaleActive;
    mapping(address => uint) public mintCount;
    event SaleActive(bool live);

    constructor(
        uint256 _supply,
        uint256 _max,
        string memory _baseUri,
        string memory name,
        string memory symbol
    ) ERC721B(name, symbol) {
        supply = _supply;
        max = _max;
        baseUri = _baseUri;
    }

    function setExtension(string memory _extension) external onlyOwner {
        extension = _extension;
    }

    function setUri(string memory _uri) external onlyOwner {
        baseUri = _uri;
    }

    function setMax(uint _max) external onlyOwner {
        max = _max;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        _burn(tokenId);
    }

    function setSupply(uint _supply) external onlyOwner {
        supply = _supply;
    }

    function mint(uint256 count) internal {
        require(isSaleActive, "Not Live");
        _callMint(count);
    }

   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	    string memory currentBaseURI = baseUri;
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), extension)) : "";
	}

    function _callMint(uint256 count) internal {
        uint256 total = totalSupply();
        require(count > 0, "Mint is 0");
        require(total + count <= supply, "Sold out");
		require(mintCount[msg.sender] + count <= max, "Max Mint Limit per Wallet reached");
        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, total + i);
            mintCount[msg.sender]++;
        }
        delete total;
    }

    function togglePublicSale() external onlyOwner {
        isSaleActive = !isSaleActive;
        emit SaleActive(isSaleActive);
    }
}