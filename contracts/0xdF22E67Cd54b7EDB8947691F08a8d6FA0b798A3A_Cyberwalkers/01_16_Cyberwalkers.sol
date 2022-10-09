// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


//  ____ _   _ ___  ____ ____ _ _ _ ____ _    _  _ ____ ____ ____
//  |     \_/  |__] |___ |__/ | | | |__| |    |_/  |___ |__/ [__
//  |___   |   |__] |___ |  \ |_|_| |  | |___ | \_ |___ |  \ ___]


/// @title The Cyberwalkers NFT Smart Contract.
/// @author The Cyberwalkers NFT project.
/// @notice This contract allows users to mint and transfer the Cyberwalkers NFTs.
/// @dev The contract inherits from the ERC721 contract.
contract Cyberwalkers is ERC721, Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeMath for uint8;

    /// @dev Maximum elite supply.
    uint256 public maxEliteSupply;

    /// @dev Maximum supply.
    uint256 public maxSaleSupply;

    /// @dev Maximum supply.
    uint256 public maxTotalSupply;

    /// @dev Sale configuration struct.
    struct SaleConfig {
        uint256 presaleMintPrice;
        uint256 publicSaleMintPrice;

        uint256 eliteSaleStartTime;
        uint256 presaleStartTime;
        uint256 publicSaleStartTime;
        uint256 freeMintStartTime;
    }

    /// @dev Sale configuration instance.
    SaleConfig public saleConfig;

    /// @dev Max mint per address per profile.
    uint8 public maxLegendaryPresaleMintPerWallet = 6;
    uint8 public maxVeteranPresaleMintPerWallet = 5;
    uint8 public maxRookiePresaleMintPerWallet = 4;
    uint8 public maxPresaleMintPerWallet = 4;
    uint8 public maxPublicMintPerWallet = 6;
    uint8 public maxLegendaryFreeMintPerWallet = 3;
    uint8 public maxVeteranFreeMintPerWallet = 2;
    uint8 public maxRookieFreeMintPerWallet = 1;

    /// @dev Token counter.
    Counters.Counter private _tokenIdCounter;

    /// @dev Sale State.
    bool private saleState;

    /// @dev Sale Revealed.
    bool private isRevealed;

    /// @dev Merke root that contains all the elite addresses.
    bytes32 private merkleRootElite;

    /// @dev Merke root that contains all the whitelisted addresses.
    bytes32 private merkleRootWhitelist;

    /// @dev Merke root that contains all the free mint addresses.
    bytes32 private merkleRootLegendary;

    /// @dev Merke root that contains all the free mint addresses.
    bytes32 private merkleRootVeteran;

    /// @dev Merke root that contains all the free mint addresses.
    bytes32 private merkleRootRookie;

    /// @dev Mapping of the amount of NFT minted during the elite sale.
    mapping(address => uint256) private amountMintedElite;

    /// @dev Mapping of the amount of NFT minted during the presale.
    mapping(address => uint256) private amountMintedPresale;

    /// @dev Mapping of the amount of NFT minted during the public sale.
    mapping(address => uint256) private amountMintedPublic;

    /// @dev Mapping of the amount of NFT minted during the free mint.
    mapping(address => uint256) private amountMintedFreeMint;

    /// @dev Base token URI used as a prefix by tokenURI().
    string private baseTokenURI;

    /// @dev Base token URI used as a suffix by tokenURI().
    string private extensionTokenURI;

    /// @dev Unrevealed toke URI.
    string private unrevealedTokenURI;

    constructor() ERC721("Cyberwalkers", "CW") {
        baseTokenURI = "";
        extensionTokenURI = ".json";
        unrevealedTokenURI = "";
        
        saleConfig.presaleMintPrice = 0.08 ether;
        saleConfig.publicSaleMintPrice = 0.1 ether;
        
        saleConfig.eliteSaleStartTime = 1665252000;
        saleConfig.presaleStartTime = 1665338370;
        saleConfig.publicSaleStartTime = 1665341970;
        saleConfig.freeMintStartTime = 1665424800;

        maxEliteSupply = 11;
        maxSaleSupply = 1601;
        maxTotalSupply = 2222;

        isRevealed = false;
        saleState = true;
    }

    /// @dev Modifier used in the mint functions in order to stop/unstop the mint.
    modifier whenNotLocked() {
        require(saleState, "Sale is locked.");
        _;
    }

    /// @dev Modifier used in the mint functions in order to avoid contract calls.
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    /// @dev Pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Making the token transfer pausable.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @dev Elite sale mint.
    function eliteMint(bytes32[] calldata _merkleProof) external payable whenNotLocked callerIsUser {
        SaleConfig memory config = saleConfig;
        require(block.timestamp > config.eliteSaleStartTime && block.timestamp < config.presaleStartTime, "Elite sale is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxEliteSupply, "Max Elite supply reached");
        require(msg.value >= config.publicSaleMintPrice, "Tr. value did not equal the mint price.");
        require(amountMintedElite[msg.sender] < 1, "You cannot mint that much.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootElite, leaf), "Invalid Elite Merkle Proof.");

        amountMintedElite[msg.sender] += 1;
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    /// @dev Presale mint for whitelisted addresses.
    function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable whenNotLocked callerIsUser {
        SaleConfig memory config = saleConfig;
        require(block.timestamp > config.presaleStartTime && block.timestamp < config.publicSaleStartTime, "Presale is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId.add(_mintAmount) < maxSaleSupply.add(1), "Max sale supply reached.");
        require(msg.value >= config.presaleMintPrice.mul(_mintAmount), "Tr. value did not equal the mint price.");
        require(amountMintedPresale[msg.sender].add(_mintAmount) < maxPresaleMintPerWallet.add(1), "You cannot mint that much.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootWhitelist, leaf), "Invalid Whitelist Merkle Proof.");

        amountMintedPresale[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newItemId);
        }
    }

    /// @dev Presale mint for legendary addresses.
    function allowlistMintLegendary(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable whenNotLocked callerIsUser {
        SaleConfig memory config = saleConfig;
        require(block.timestamp > config.presaleStartTime && block.timestamp < config.publicSaleStartTime, "Presale is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId.add(_mintAmount) < maxSaleSupply.add(1), "Max sale supply reached.");
        require(msg.value >= config.presaleMintPrice.mul(_mintAmount), "Tr. value did not equal the mint price.");
        require(amountMintedPresale[msg.sender].add(_mintAmount) < maxLegendaryPresaleMintPerWallet.add(1), "You cannot mint that much.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootLegendary, leaf), "Invalid Legendary Merkle Proof.");

        amountMintedPresale[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newItemId);
        }
    }

    /// @dev Presale mint for veteran addresses.
    function allowlistMintVeteran(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable whenNotLocked callerIsUser {
        SaleConfig memory config = saleConfig;
        require(block.timestamp > config.presaleStartTime && block.timestamp < config.publicSaleStartTime, "Presale is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId.add(_mintAmount) < maxSaleSupply.add(1), "Max sale supply reached.");
        require(msg.value >= config.presaleMintPrice.mul(_mintAmount), "Tr. value did not equal the mint price.");
        require(amountMintedPresale[msg.sender].add(_mintAmount) < maxVeteranPresaleMintPerWallet.add(1), "You cannot mint that much.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootVeteran, leaf), "Invalid Veteran Merkle Proof.");

        amountMintedPresale[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newItemId);
        }
    }

    /// @dev Presale mint for rookie addresses.
    function allowlistMintRookie(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable whenNotLocked callerIsUser {
        SaleConfig memory config = saleConfig;
        require(block.timestamp > config.presaleStartTime && block.timestamp < config.publicSaleStartTime, "Presale is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId.add(_mintAmount) < maxSaleSupply.add(1), "Max supply reached.");
        require(msg.value >= config.presaleMintPrice.mul(_mintAmount), "Tr. value did not equal the mint price.");
        require(amountMintedPresale[msg.sender].add(_mintAmount) < maxRookiePresaleMintPerWallet.add(1), "You cannot mint that much.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootRookie, leaf), "Invalid Rookie Merkle Proof.");

        amountMintedPresale[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newItemId);
        }
    }

    /// @dev Public sale mint.
    function publicSaleMint(uint256 _mintAmount) external payable whenNotLocked callerIsUser {
        SaleConfig memory config = saleConfig;
        require(block.timestamp > config.publicSaleStartTime && block.timestamp < config.freeMintStartTime, "Public sale is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId.add(_mintAmount) < maxSaleSupply.add(1), "Max supply reached.");
        require(msg.value >= config.publicSaleMintPrice.mul(_mintAmount), "Tr. value did not equal the mint price.");
        require(amountMintedPublic[msg.sender].add(_mintAmount) < maxPublicMintPerWallet.add(1), "You cannot mint that much.");

        amountMintedPublic[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newItemId);
        }
    }

    /// @dev Free mint for legendary addresses.
    function freeMintLegendary(uint256 _mintAmount, bytes32[] calldata _merkleProof) external whenNotLocked callerIsUser {
        SaleConfig memory config = saleConfig;
        require(block.timestamp > config.freeMintStartTime, "Free mint is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId.add(_mintAmount) < maxTotalSupply.add(1), "Max supply reached.");
        require(amountMintedFreeMint[msg.sender].add(_mintAmount) < maxLegendaryFreeMintPerWallet.add(1), "You cannot mint that much.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootLegendary, leaf), "Invalid Legendary Merkle Proof.");

        amountMintedFreeMint[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newItemId);
        }
    }

    /// @dev Free mint for veteran addresses.
    function freeMintVeteran(uint256 _mintAmount, bytes32[] calldata _merkleProof) external whenNotLocked callerIsUser {
        SaleConfig memory config = saleConfig;
        require(block.timestamp > config.freeMintStartTime, "Free mint is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId.add(_mintAmount) < maxTotalSupply.add(1), "Max supply reached.");
        require(amountMintedFreeMint[msg.sender].add(_mintAmount) < maxVeteranFreeMintPerWallet.add(1), "You cannot mint that much.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootVeteran, leaf), "Invalid Veteran Merkle Proof.");

        amountMintedFreeMint[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newItemId);
        }
    }

    /// @dev Free mint for rookies addresses.
    function freeMintRookie(uint256 _mintAmount, bytes32[] calldata _merkleProof) external whenNotLocked callerIsUser {
        SaleConfig memory config = saleConfig;
        require(block.timestamp > config.freeMintStartTime, "Free mint is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId.add(_mintAmount) < maxTotalSupply.add(1), "Max supply reached.");
        require(amountMintedFreeMint[msg.sender].add(_mintAmount) < maxRookieFreeMintPerWallet.add(1), "You cannot mint that much.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootRookie, leaf), "Invalid Rookie Merkle Proof.");

        amountMintedFreeMint[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newItemId);
        }
    }

    /// @dev Dev mint.
    function devMint(uint256 _mintAmount) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId.add(_mintAmount) < maxTotalSupply.add(1), "Max supply reached.");

        amountMintedPublic[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, newItemId);
        }
    }

    /// @dev Override the tokenURI to add our a custom base prefix and suffix.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        if (!isRevealed) {
            return unrevealedTokenURI;
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extensionTokenURI)) : "";
    }

    /// @dev Returns an URI for a given token ID.
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Sets the base token URI suffix.
    function setExtensionTokenURI(string memory _extensionTokenURI) external onlyOwner {
        extensionTokenURI = _extensionTokenURI;
    }

    /// @dev Sets the unrevealed token URI.
    function setUnrevealedTokenURI(string memory _unrevealedTokenURI) external onlyOwner {
        unrevealedTokenURI = _unrevealedTokenURI;
    }

    /// @dev Sets the isRevealed state.
    function setRevealed(bool _revealState) external onlyOwner {
        isRevealed = _revealState;
    }

    /// @dev Sets the public sale mint price.
    function setPublicSaleMintPrice(uint64 _publicSaleMintPrice) external onlyOwner {
        saleConfig.publicSaleMintPrice = _publicSaleMintPrice;
    }

    /// @dev Sets the presale mint price.
    function setPresaleMintPrice(uint64 _presaleMintPrice) external onlyOwner {
        saleConfig.presaleMintPrice = _presaleMintPrice;
    }

    /// @dev Sets the elite sale date.
    function setEliteSaleStartTime(uint256 _eliteSaleStartTime) external onlyOwner {
        saleConfig.eliteSaleStartTime = _eliteSaleStartTime;
    }

    /// @dev Sets the presale date.
    function setPresaleStartTime(uint256 _presaleStartTime) external onlyOwner {
        saleConfig.presaleStartTime = _presaleStartTime;
    }

    /// @dev Sets the public sale date.
    function setPublicSaleStartTime(uint256 _publicSaleStartTime) external onlyOwner {
        saleConfig.publicSaleStartTime = _publicSaleStartTime;
    }

    /// @dev Sets the free mint date.
    function setFreeMintStartTime(uint256 _freeMintStartTime) external onlyOwner {
        saleConfig.freeMintStartTime = _freeMintStartTime;
    }

    /// @dev Sets the max presale mint per legendary address allowed.
    function setMaxLegendaryPresaleMintPerWallet(uint8 _maxLegendaryPresaleMintPerWallet) external onlyOwner {
        maxLegendaryPresaleMintPerWallet = _maxLegendaryPresaleMintPerWallet;
    }

    /// @dev Sets the max presale mint per veteran address allowed.
    function setMaxVeteranPresaleMintPerWallet(uint8 _maxVeteranPresaleMintPerWallet) external onlyOwner {
        maxVeteranPresaleMintPerWallet = _maxVeteranPresaleMintPerWallet;
    }

    /// @dev Sets the max presale mint per rookie address allowed.
    function setMaxRookiePresaleMintPerWallet(uint8 _maxRookiePresaleMintPerWallet) external onlyOwner {
        maxRookiePresaleMintPerWallet = _maxRookiePresaleMintPerWallet;
    }

    /// @dev Sets the max presale mint per whitelisted address allowed.
    function setMaxPresaleMintPerWallet(uint8 _maxPresaleMintPerWallet) external onlyOwner {
        maxPresaleMintPerWallet = _maxPresaleMintPerWallet;
    }

    /// @dev Sets the max public mint per address allowed.
    function setMaxPublicMintPerWallet(uint8 _maxPublicMintPerWallet) external onlyOwner {
        maxPublicMintPerWallet = _maxPublicMintPerWallet;
    }

    /// @dev Sets the max free mint per legendary address allowed.
    function setMaxLegendaryFreeMintPerWallet(uint8 _maxLegendaryFreeMintPerWallet) external onlyOwner {
        maxLegendaryFreeMintPerWallet = _maxLegendaryFreeMintPerWallet;
    }

    /// @dev Sets the max free mint per veteran address allowed.
    function setMaxVeteranFreeMintPerWallet(uint8 _maxVeteranFreeMintPerWallet) external onlyOwner {
        maxVeteranFreeMintPerWallet = _maxVeteranFreeMintPerWallet;
    }

    /// @dev Sets the max free mint per rookie address allowed.
    function setMaxRookieFreeMintPerWallet(uint8 _maxRookieFreeMintPerWallet) external onlyOwner {
        maxRookieFreeMintPerWallet = _maxRookieFreeMintPerWallet;
    }

    /// @dev Set sale state.
    function setSaleState(bool _saleState) external onlyOwner {
        saleState = _saleState;
    }

    /// @dev Set the merkle root for elite addresses.
    function setMerkleRootElite(bytes32 _merkleRootElite) external onlyOwner {
        merkleRootElite = _merkleRootElite;
    }

    /// @dev Set the merkle root for whitelisted addresses.
    function setMerkleRootWhitelist(bytes32 _merkleRootWhitelist) external onlyOwner {
        merkleRootWhitelist = _merkleRootWhitelist;
    }

    /// @dev Set the merkle root for legendary addresses.
    function setMerkleRootLegendary(bytes32 _merkleRootLegendary) external onlyOwner {
        merkleRootLegendary = _merkleRootLegendary;
    }

    /// @dev Set the merkle root for veteran addresses.
    function setMerkleRootVeteran(bytes32 _merkleRootVeteran) external onlyOwner {
        merkleRootVeteran = _merkleRootVeteran;
    }

    /// @dev Set the merkle root for rookie addresses.
    function setMerkleRootRookie(bytes32 _merkleRootRookie) external onlyOwner {
        merkleRootRookie = _merkleRootRookie;
    }

    /// @dev Set the max elite supply.
    function setMaxEliteSupply(uint256 _maxEliteSupply) external onlyOwner {
        require(_maxEliteSupply <= maxSaleSupply, "Elite supply must be lower than the sale supply.");
        maxEliteSupply = _maxEliteSupply;
    }

    /// @dev Set the max sale supply (in case we need to cut the supply).
    function setMaxSaleSupply(uint256 _maxSaleSupply) external onlyOwner {
        require(_maxSaleSupply <= maxTotalSupply, "Sale supply must be lower than the total supply.");
        maxSaleSupply = _maxSaleSupply;
    }

    /// @dev Set the max supply (in case we need to cut the supply).
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    /// @dev Get the current total supply.
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @dev Withdraw the contract funds to the contract owner. The nonReentrant guard is useless but...safety first !
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
  }
}