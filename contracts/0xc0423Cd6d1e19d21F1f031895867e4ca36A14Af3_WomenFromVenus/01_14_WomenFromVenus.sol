// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WomenFromVenus is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 5555;
    address public constant wg = 0xf79fC54DE98C69D58c2B5Dfa0568A1AE3231664F;
    address public constant wd = 0xDE1C19BAf0CcCc06a6843fcd778A08286BFFfEAD;
    address public constant wka = 0xdeA74c7a01aD23672A793190fA74e030cB472bcf;
    address public constant ws = 0xE1846416701a71aFaAaD6206c9011bCF4E40660f;
    address public constant wke = 0x1F3D3798f6881a7515422c039F1eA19e9Aad6AcC;
    address public constant wl = 0xcB90d86fA024A74A6d9CD28BA11194175e903FB1;

    uint256 public price = 0.0555 ether;
    uint256 public maxPerWallet = 3;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    bool public revealed = false;
    mapping(address => uint256) private _walletMints;
    mapping(address => uint256) private _stormyMints;

    string public baseURI = "";
    bytes32 public merkleRoot = 0xbe63bf88abc9f201bf20e0b9da02456f1e6f5904a7f9607ab09ea6013a3e54ae;
    bytes32 public stormyMerkleRoot = 0x02495ce5bd58f5df9382e21b5a2a99601521cf609e5225cea5bf08ec66ad432c;

    constructor() ERC721A("Women From Venus", "WFV") {
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

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setStormyMerkleRoot(bytes32 _stormyMerkleRoot) external onlyOwner {
        stormyMerkleRoot = _stormyMerkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if (!revealed) {
            return "https://mint.womenfromvenus.io/prereveal.json";
        }
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    /// Set number of maximum mints a wallet can have
    /// @param _newMaxPerWallet value to set
    function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }

    /// Presale mint function
    /// @param tokens number of tokens to mint
    /// @param merkleProof Merkle Tree proof
    /// @dev reverts if any of the presale preconditions aren't satisfied
    function mintPresale(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStarted, "Presale has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not eligible for the presale");
        require(tokens <= maxPerWallet, "Cannot purchase this many tokens in a transaction");
        require(_walletMints[_msgSender()] + tokens <= maxPerWallet, "Limit for this wallet reached");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(price * tokens <= msg.value, "ETH amount is incorrect");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    /// Stormy token mint function
    /// @param tokens number of tokens to mint
    /// @param merkleProof Merkle Tree proof
    /// @dev reverts if any of the presale preconditions aren't satisfied
    function mintStormy(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStarted, "Presale has not started");
        require(MerkleProof.verify(merkleProof, stormyMerkleRoot, keccak256(abi.encodePacked(msg.sender, tokens))), "You are not eligible for a free token");
        require(tokens <= maxPerWallet, "Cannot purchase this many tokens in a transaction");
        require(_stormyMints[_msgSender()] + tokens <= tokens, "Free tokens already claimed");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _stormyMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(tx.origin == msg.sender, "Humans only please");
        require(tokens <= maxPerWallet, "Cannot purchase this many tokens in a transaction");
        require(_walletMints[_msgSender()] + tokens <= maxPerWallet, "Limit for this wallet reached");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(price * tokens <= msg.value, "ETH amount is incorrect");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    /// Mints 50 WFVs to the vault for giveaways, collabs, etc.
    /// Does not require eth
    /// @dev reverts if any of the preconditions aren't satisfied
    function vaultMint() external onlyOwner {
        require(totalSupply() + 50 <= MAX_TOKENS, "Minting would exceed max supply");

        _safeMint(_msgSender(), 50);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(wg, ((balance * 8) / 100));
        _withdraw(wd, ((balance * 8) / 100));
        _withdraw(wka, ((balance * 22) / 100));
        _withdraw(ws, ((balance * 36) / 100));
        _withdraw(wke, ((balance * 15) / 100));
        _withdraw(wl, ((balance * 1) / 100));
        _withdraw(_msgSender(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}