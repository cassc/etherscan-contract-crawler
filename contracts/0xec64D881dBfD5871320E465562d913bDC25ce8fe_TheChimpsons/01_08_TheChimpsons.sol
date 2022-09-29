// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TheChimpsons is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 7000;
    uint256 public allowlistMints = 4000;
    uint256 public price = 0.035 ether;
    uint256 public presalePrice = 0.025 ether;
    uint256 public maxPerALWallet = 3;
    uint256 public maxPerWallet = 7;

    address public constant w1 = 0xb557936a7543408842E7255d36958568AC684f05;
    address public constant w2 = 0xd8844d807c4e527bb247B2c61bE8ea78C0348Dee;
    address public constant w3 = 0x88375f4c4Dfe2f40154e76C3175DE7ceD551Dd33;
    address public constant w4 = 0xE561f74bE4A1F1E7F686D48980491B89295F9C9C;
    address public constant w5 = 0x6bA37Efa24472E27DD1513199b2A0e3ccE7A4f09;

    bool public publicSaleStarted = false;
    bool public presaleStarted = false;

    mapping(address => uint256) private _walletMints;
    mapping(address => uint256) private _ALWalletMints;

    string public baseURI = "";
    bytes32 public merkleRoot;

    constructor() ERC721A("The Chimpsons", "CHIMPSONS") {
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }

    function setMaxPerALWallet(uint256 _newMaxPerALWallet) external onlyOwner {
        maxPerALWallet = _newMaxPerALWallet;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
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

    function mintAllowlist(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStarted, "Sale has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on the allowlist");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(totalSupply() + tokens <= allowlistMints, "Allowlist sold out");
        require(tokens > 0, "Must mint at least one Chimpson");
        require(_ALWalletMints[_msgSender()] + tokens <= maxPerALWallet, "AL limit for this wallet reached");
        require(presalePrice * tokens <= msg.value, "Not enough ETH");

        _ALWalletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Sale has not started");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one Chimpson");
        require(_walletMints[_msgSender()] + tokens <= maxPerWallet, "Limit for this wallet reached");
        require(price * tokens <= msg.value, "Not enough ETH");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function reserve(uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one Chimpson");
        require(_walletMints[_msgSender()] + tokens <= 100, "Can only reserve 100 tokens");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(w1, ((balance * 58) / 100)); // 58%
        _withdraw(w2, ((balance * 5) / 100)); // 5%
        _withdraw(w3, ((balance * 25) / 200)); // 12.5%
        _withdraw(w4, ((balance * 25) / 200)); // 12.5%
        _withdraw(w5, ((balance * 12) / 100)); // 12%
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}