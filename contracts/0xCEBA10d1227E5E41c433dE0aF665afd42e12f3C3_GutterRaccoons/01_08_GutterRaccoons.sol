// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GutterRaccoons is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 3000;
    uint256 public whitelistMints = 2500;
    uint256 public price = 0.015 ether;
    uint256 public presalePrice = 0.009 ether;
    uint256 public maxPerWLWallet = 1;
    uint256 public maxPerWallet = 2;

    address public constant w1 = 0x84E81746eb7b0e2a9280111138a2f941E65E7D72;
    address public constant w2 = 0x406B2cAA76cAE001E3aED35D47A7F2162ee26fA4;
    address public constant w3 = 0x0dF4BB7394f2f4863FacBfE359197b966E53b3e5;

    bool public publicSaleStarted = false;
    bool public presaleStarted = false;

    mapping(address => uint256) private _walletMints;
    mapping(address => uint256) private _WLWalletMints;

    string public baseURI = "https://www.gutterraccoons.com/placeholder.json";
    bytes32 public merkleRoot = 0x404c22106f808e03d68fd210f13409f3f702d4cf2589b8339d301ceb0ee44b62;

    constructor() ERC721A("Gutter Raccoons", "GR") {
        _safeMint(_msgSender(), 1);
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
        publicSaleStarted = !publicSaleStarted;
    }

    function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }

    function setMaxPerWLWallet(uint256 _newMaxPerWLWallet) external onlyOwner {
        maxPerWLWallet = _newMaxPerWLWallet;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setPresalePrice(uint256 _newPrice) external onlyOwner {
        presalePrice = _newPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    function mintWhitelist(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStarted, "Sale has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on the whitelist");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(totalSupply() + tokens <= whitelistMints, "Whitelist sold out");
        require(tokens > 0, "Must mint at least one Raccoon");
        require(_WLWalletMints[_msgSender()] + tokens <= maxPerWLWallet, "WL limit for this wallet reached");
        require(presalePrice * tokens <= msg.value, "Not enough ETH");

        _WLWalletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Sale has not started");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one Raccoon");
        require(_walletMints[_msgSender()] + tokens <= maxPerWallet, "Limit for this wallet reached");
        require(price * tokens <= msg.value, "Not enough ETH");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(w1, ((balance * 50) / 100));
        _withdraw(w2, ((balance * 40) / 100));
        _withdraw(w3, ((balance * 10) / 100));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}