// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// _________  ____  __.
// \_   ___ \|    |/ _|
// /    \  \/|      <  
// \     \___|    |  \ 
//  \______  /____|__ \
//         \/        \/
// @author stonkmaster69

struct PresaleConfig {
  uint32 startTime;
  uint32 endTime;
  uint256 whitelistMintPerWalletMax;
  uint256 whitelistPrice;
}

struct OGConfig {
  uint32 startTime;
  uint256 ogMintPerWalletMax;
  uint256 ogMaxSupply;
  uint256 ogPrice;
}

contract ComebacKids is ERC721A, Ownable, DefaultOperatorFilterer, ReentrancyGuard {

    /// ERRORS ///
    error ContractMint();
    error OutOfSupply();
    error ExceedsTxnLimit();
    error ExceedsWalletLimit();
    error InsufficientFunds();
    error InexistentToken();
    
    error MintPaused();
    error MintInactive();
    error InvalidProof();

    /// @dev For URI concatenation.
    using Strings for uint256;

    bytes32 public merkleRoot;
    bytes32 public ogRoot;

    mapping(address => uint256) public ogPublicMints;
    mapping(address => uint256) public wlPublicMints;

    string public baseURI = "ipfs://Qmcr1qEKyWAsonqb4U6jwnfxYn4X85yA4MNw5NHihsJgom/ck.json";
    
    uint32 publicSaleStartTime;

    uint256 public PRICE = 0.045 ether;
    uint256 public SUPPLY_MAX = 5555;
    uint256 public MAX_PER_WALLET = 2;
    uint256 public MAX_PER_TXN = 3;
    uint256 public whitelistSupply;
    uint256 public OGSupply;

    PresaleConfig public presaleConfig;
    OGConfig public ogConfig;

    bool public presalePaused;
    bool public publicSalePaused;
    bool public revealed;

    constructor() ERC721A("Comebackids", "CK") payable {
        presaleConfig = PresaleConfig({
            startTime: 1676674800,
            endTime: 1676682000,
            whitelistMintPerWalletMax: 2,
            whitelistPrice: 0.04 ether
        });
        ogConfig = OGConfig({
            startTime: 1676674800,
            ogMintPerWalletMax: 3,
            ogMaxSupply: 250,
            ogPrice: 0.035 ether
        });
        publicSaleStartTime = 1676682000;
        _safeMint(msg.sender, 1);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        if (msg.sender != tx.origin) revert ContractMint();
        if ((totalSupply() + _mintAmount) > SUPPLY_MAX) revert OutOfSupply();
        if (_mintAmount > MAX_PER_TXN) revert ExceedsTxnLimit();
        _;
    }

    function presaleMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount) 
    {
        PresaleConfig memory config_ = presaleConfig;
        
        if (presalePaused) revert MintPaused();
        if (block.timestamp < config_.startTime || block.timestamp > config_.endTime) revert MintInactive();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert InvalidProof();

        unchecked {
            if ((_numberMinted(msg.sender) + _mintAmount) > config_.whitelistMintPerWalletMax) revert ExceedsWalletLimit();
            if (msg.value < (config_.whitelistPrice * _mintAmount)) revert InsufficientFunds();
            whitelistSupply += _mintAmount;
        }

        _safeMint(msg.sender, _mintAmount);
    }

    function publicMint(uint256 _mintAmount)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount)
    {
        if (publicSalePaused) revert MintPaused();
        unchecked {
            if ((_numberMinted(msg.sender) + _mintAmount) > MAX_PER_WALLET) revert ExceedsWalletLimit(); 
            if (block.timestamp < publicSaleStartTime) revert MintInactive();
            if (msg.value < (PRICE * _mintAmount)) revert InsufficientFunds();
        }

        _safeMint(msg.sender, _mintAmount);
    }
    
    function ogMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount) 
    {
        OGConfig memory config_ = ogConfig;
        
        if (presalePaused) revert MintPaused();
        if (block.timestamp < config_.startTime) revert MintInactive();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, ogRoot, leaf)) revert InvalidProof();

        unchecked {
            if ((_numberMinted(msg.sender) + _mintAmount) > config_.ogMintPerWalletMax) revert ExceedsWalletLimit();
            if ((OGSupply + _mintAmount) > config_.ogMaxSupply) revert OutOfSupply();
            if (msg.value < (config_.ogPrice * _mintAmount)) revert InsufficientFunds();
            OGSupply += _mintAmount;
        }

        _safeMint(msg.sender, _mintAmount);
    }

    function ogPublicMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount)
    {
        if (publicSalePaused) revert MintPaused();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, ogRoot, leaf)) revert InvalidProof();

        unchecked {
            if ((ogPublicMints[msg.sender] + _mintAmount) > MAX_PER_WALLET) revert ExceedsWalletLimit();
            if (block.timestamp < publicSaleStartTime) revert MintInactive();
            if (msg.value < (PRICE * _mintAmount)) revert InsufficientFunds();
            ogPublicMints[msg.sender] += _mintAmount;
        }

        _safeMint(msg.sender, _mintAmount);
    }

    function wlPublicMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount)
    {
        if (publicSalePaused) revert MintPaused();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert InvalidProof();

        unchecked {
            if ((wlPublicMints[msg.sender] + _mintAmount) > MAX_PER_WALLET) revert ExceedsWalletLimit();
            if (block.timestamp < publicSaleStartTime) revert MintInactive();
            if (msg.value < (PRICE * _mintAmount)) revert InsufficientFunds();
            wlPublicMints[msg.sender] += _mintAmount;
        }

        _safeMint(msg.sender, _mintAmount);
    }

    /// @notice Airdrop for a single wallet.
    function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    /// @notice Airdrops to multiple wallets.
    function batchMintForAddress(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
        unchecked {
            uint32 i;
            for (i=0; i < addresses.length; ++i) {
                _safeMint(addresses[i], quantities[i]);
            }
        }
    }

    function _startTokenId()
        internal
        view
        virtual
        override returns (uint256) 
    {
        return 1;
    }

    function numberMinted(address userAddress) external view virtual returns (uint256) {
        return _numberMinted(userAddress);
    }

    /// SETTERS ///

    function setRevealed() external onlyOwner {
        revealed = true;
    }

    function pausePublicSale(bool _state) external onlyOwner {
        publicSalePaused = _state;
    }

    function pausePresale(bool _state) external onlyOwner {
        presalePaused = _state;
    }

    function setPublicSaleStartTime(uint32 startTime_) external onlyOwner {
        publicSaleStartTime = startTime_;
    }

    function setPresaleStartTime(uint32 startTime_, uint32 endTime_) external onlyOwner {
        presaleConfig.startTime = startTime_;
        presaleConfig.endTime = endTime_;
    }
    
    function setWlMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setOgMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        ogRoot = merkleRoot_;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setPublicMaxPerWallet(uint256 _max) external onlyOwner {
        MAX_PER_WALLET = _max;
    }

    function setWhitelistMaxPerWallet(uint256 _max) external onlyOwner {
        presaleConfig.whitelistMintPerWalletMax = _max;
    }

    function setWhitelistPrice(uint256 _price) external onlyOwner {
        presaleConfig.whitelistPrice = _price;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        SUPPLY_MAX = _supply;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x40dcBD5F84b597154B2BDb72acB9C960040B0CE9).transfer(balance * 58/100); // 58% Zack
        payable(0xBaABbD58fbD97F462f3731e6C8ccf9b82A856AE2).transfer(balance * 20/100); // 20% squirt
        payable(0x5b432E4346D7068B383fAe82652a19d721E503Cd).transfer(balance * 10/100); // 10% DAO
        payable(0xBD37aBE6E9191f908503349AD6304Cf64168573D).transfer(balance * 2/100); // 2% Drew
        payable(0xf17e7f8557C1102090d5D5B9a30D9D34A9A03485).transfer(balance * 5/100); // 5% Artist
        payable(0x446B7f1EC4749fddAfC50CcaA0c8f82d4665FB61).transfer(balance * 5/100); // 5% Stonk
    }
    
    /// METADATA URI ///

    function _baseURI()
        internal 
        view 
        virtual
        override returns (string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @dev Returning concatenated URI with .json as suffix on the tokenID when revealed.
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert InexistentToken();

        if (!revealed) return _baseURI();
        return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
    }

    /// @dev Operator filtering
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}