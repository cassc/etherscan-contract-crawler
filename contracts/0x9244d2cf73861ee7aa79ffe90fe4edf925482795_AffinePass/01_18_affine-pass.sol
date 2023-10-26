// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract AffinePass is ERC721, ERC721Burnable, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant MAX_RESERVE_TOKENS = 988;
    uint256 public constant MAX_MINTABLE_SUPPLY = MAX_SUPPLY - MAX_RESERVE_TOKENS;
    uint256 public mintedReserveTokens = 0;
    uint256 public constant MAX_WHITELIST_MINT = 1; // Maximum number of NFTs that can be minted by a whitelisted wallet
    uint256 public constant MAX_PUBLIC_MINT = 1; // Maximum number of NFTs that can be minted by a wallet
    bool public saleIsActive;
    bool public whitelistSaleIsActive;
    string public baseURI;
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistedBridge;
    mapping(address => uint256) private _minted; // Total number of NFTs minted by each address
    mapping(address => uint256) private _whitelistMinted; // Number of NFTs minted by a whitelisted wallet

    Counters.Counter private _tokenIdCounter;
    
    event WhitelistMerkleRootUpdated(bytes32 indexed merkleRoot);

    modifier onlyBridge() {
        require(whitelistedBridge[msg.sender], "Only bridge can call");
        _;
    }

    constructor( bytes32 _merkleRoot) 
        ERC721("Affine Pass", "APASS")          
    {
        merkleRoot = _merkleRoot;
        _tokenIdCounter.increment();
        whitelistedBridge[msg.sender] = true;
        setBaseURI("https://affine-pass.s3.amazonaws.com/pass/");
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
        emit WhitelistMerkleRootUpdated(merkleRoot);
    }

    function stopMint() public onlyOwner {
        saleIsActive = false;
        whitelistSaleIsActive = false;
    }

    function hasMintedWhitelist(address _address) public view returns (bool) {
        return _whitelistMinted[_address] > 0;
    }

    function hasMinted(address _address) public view returns (bool) {
        return _minted[_address] > 0;
    }

    function isWhitelisted(
        address user,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, merkleRoot, node);
    }

    function toggleWhitelistSale() public onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
        saleIsActive = false;
    }

    function togglePublicSale() public onlyOwner {
        saleIsActive = !saleIsActive;
        whitelistSaleIsActive = false;
    }

    function mintReserve(uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        require(mintedReserveTokens + amount <= MAX_RESERVE_TOKENS, "Exceeds max reserve supply");
        mintedReserveTokens += amount;
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(owner(), tokenId);
        }
    }

    function hasRemainingSupply() public view returns (bool) {
        uint256 currentSupply = totalSupply() - mintedReserveTokens;
        return currentSupply < MAX_MINTABLE_SUPPLY;
    }

    function mintDrop(address[] memory recipients, uint256[] memory quantities) public onlyOwner {
        require(recipients.length == quantities.length, "Recipients and quantities length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            for (uint256 j = 0; j < quantities[i]; j++) {
                require(hasRemainingSupply(), "Exceeds max supply");
                uint256 tokenId = _tokenIdCounter.current();
                _tokenIdCounter.increment();
                _safeMint(recipients[i], tokenId);
            }
        }
    }
    
    function mintWhitelist(bytes32[] memory proof) public payable {
        require(
                (whitelistSaleIsActive && isWhitelisted(_msgSender(), proof)),
            "Sale paused or not whitelisted"
        );
        require(hasRemainingSupply(), "Exceeds max supply");
        require(
            _whitelistMinted[_msgSender()] + 1 <= MAX_WHITELIST_MINT,
            "Exceeds max WL mint"
        );

        _whitelistMinted[_msgSender()] += 1;

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function mint() public payable {
        require(saleIsActive, "Sale is not active");
        require(hasRemainingSupply(), "Exceeds max supply");
        require(
            _minted[_msgSender()] + 1 <= MAX_PUBLIC_MINT,
            "Exceeds max public mint"
        );

        _minted[_msgSender()] += 1;

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);

    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    // Overrides and Bridge

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function setIsWhitelistedBridge(address _bridge, bool _isWhitelisted) public onlyOwner {
        whitelistedBridge[_bridge] = _isWhitelisted;
    }

    function bridgeMint(address to, uint256 tokenId) external onlyBridge {
        _safeMint(to, tokenId);
    }

    function bridgeBurn(uint256 tokenId) external onlyBridge {
        _burn(tokenId);
    }

}