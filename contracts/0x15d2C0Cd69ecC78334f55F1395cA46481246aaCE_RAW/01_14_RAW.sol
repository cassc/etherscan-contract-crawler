// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title The Red Astro Wars Contract
/// @notice https://redastrowars.io/ https://twitter.com/RedAstroWars
contract RAW is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 333;
    uint256 public constant MAX_TOKENS_STAGE1 = 203;
    uint256 public constant MAX_TOKENS_STAGE2 = 333;
    uint256 public constant MAX_PER_MINT = 1;
    address public constant w1 = 0xfA964c579eDd08438057600bba847d3A1caA14Bb;
    address public constant w2 = 0x61d5f2028597CFF4aDf0cFBb95341EFdAc117598;
    address public constant w3 = 0xd66c3152fD3030db77d6BE246c944dAe163Ed61b;


    uint256 public price = 0 ether;
    bool public isRevealed = false;
    bool public publicSaleStarted = false;
    bool public presaleStage1Started = false;
    bool public presaleStage2Started = false;
    mapping(address => uint256) private _mintMapping;
    uint256 public MaxPerWallet = 1;

    string public baseURI = "https://coffee-objective-antlion-23.mypinata.cloud/ipfs/QmRu7FtZcCehsLppibd2fqF4nV9aGMCkDQ3ppdSkysrEN7";
    bytes32 public merkleRootStage1 = 0xe9e691e707ca3a11d3b3256861ba5ed4bd743707b1f33cf4cee626ec17f18395;
    bytes32 public merkleRootStage2 = 0xccb260e72e9408595a50a9a88e5328dbdffdf861900904be07608599a6b5f9a0;

    constructor() ERC721A("Red Astro Wars", "RAW", 33) {
    }

    function togglePresaleStage1Started() external onlyOwner {
        presaleStage1Started = !presaleStage1Started;
    }

    function togglePresaleStage2Started() external onlyOwner {
        presaleStage2Started = !presaleStage2Started;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRootStage1(bytes32 _merkleRoot) external onlyOwner {
        merkleRootStage1 = _merkleRoot;
    }
    function setMerkleRootStage2(bytes32 _merkleRoot) external onlyOwner {
        merkleRootStage2 = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed) {
            // for this the metadata for the original image has to be 1.json and so on 
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) ;
        } else {
            // placeholder.json is the file used for placeholder
            return baseURI ;
        }
    }

    /// Set number of maximum presale mints a wallet can have
    /// @param _newPresaleMaxPerWallet value to set
    function setPresaleMaxPerWallet(uint256 _newPresaleMaxPerWallet) external onlyOwner {
        MaxPerWallet = _newPresaleMaxPerWallet;
    }

    /// PresaleStage1 mint function
    /// @param tokens number of tokens to mint
    /// @param merkleProof Merkle Tree proof
    /// @dev reverts if any of the presale preconditions aren't satisfied
    function mintPresaleStage1(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStage1Started, "RAW: Presale has not started");
        require(totalSupply() + tokens <= MAX_TOKENS_STAGE1, "RAW: Minting would exceed max supply");
        require(MerkleProof.verify(merkleProof, merkleRootStage1, keccak256(abi.encodePacked(msg.sender))), "RAW: You are not eligible for the presale");
        require(_mintMapping[_msgSender()] + tokens <= MaxPerWallet, "RAW: Presale limit for this wallet reached");
        require(tokens <= MAX_PER_MINT, "RAW: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "RAW: Minting would exceed max supply");
        require(tokens > 0, "RAW: Must mint at least one token");
        // require(price * tokens == msg.value, "RAW: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        _mintMapping[_msgSender()] += tokens;
    }

    /// PresaleStage2 mint function
    /// @param tokens number of tokens to mint
    /// @param merkleProof Merkle Tree proof
    /// @dev reverts if any of the presale preconditions aren't satisfied
    function mintPresaleStage2(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStage2Started, "RAW: Presale has not started");
        require(totalSupply() + tokens <= MAX_TOKENS_STAGE2, "RAW: Minting would exceed max supply");
        require(MerkleProof.verify(merkleProof, merkleRootStage2, keccak256(abi.encodePacked(msg.sender))), "RAW: You are not eligible for the presale");
        require(_mintMapping[_msgSender()] + tokens <= MaxPerWallet, "RAW: Presale limit for this wallet reached");
        require(tokens <= MAX_PER_MINT, "RAW: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "RAW: Minting would exceed max supply");
        require(tokens > 0, "RAW: Must mint at least one token");
        // require(price * tokens == msg.value, "RAW: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        _mintMapping[_msgSender()] += tokens;
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "RAW: Public sale has not started");
        require(tokens <= MAX_PER_MINT, "RAW: Cannot purchase this many tokens in a transaction");
        require(_mintMapping[_msgSender()] + tokens <= MaxPerWallet, "RAW: Public sale limit for this wallet reached");
        require(totalSupply() + tokens <= MAX_TOKENS, "RAW: Minting would exceed max supply");
        require(tokens > 0, "RAW: Must mint at least one token");
        // require(price * tokens == msg.value, "RAW: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        _mintMapping[_msgSender()] += tokens;
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "RAW: Minting would exceed max supply");
        require(tokens > 0, "RAW: Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// Distribute funds to wallets
    // function withdrawAll() public onlyOwner {
    //     uint256 balance = address(this).balance;
    //     require(balance > 0, "RAW: Insufficent balance");
    //     _widthdraw(w3, ((balance * 45) / 1000));
    //     _widthdraw(w2, ((balance * 45) / 1000));
    //     _widthdraw(w1, address(this).balance);
    // }

    // function _widthdraw(address _address, uint256 _amount) private {
    //     (bool success, ) = _address.call{value: _amount}("");
    //     require(success, "RAW: Failed to widthdraw Ether");
    // }

}