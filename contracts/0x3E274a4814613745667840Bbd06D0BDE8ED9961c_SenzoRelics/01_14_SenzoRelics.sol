// SPDX-License-Identifier: MIT
// pragma solidity >=0.8.9 <0.9.0;
pragma solidity ^0.8.17;

/**
 *   _____                                _____           _   _              
 *  / ____|                              |  __ \         | | (_)             
 * | (___     ___   _ __    ____   ___   | |__) |   ___  | |  _    ___   ___ 
 *  \___ \   / _ \ | '_ \  |_  /  / _ \  |  _  /   / _ \ | | | |  / __| / __|
 *  ____) | |  __/ | | | |  / /  | (_) | | | \ \  |  __/ | | | | | (__  \__ \
 * |_____/   \___| |_| |_| /___|  \___/  |_|  \_\  \___| |_| |_|  \___| |___/
 */
import "./ERC721AUpgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract SenzoRelics is ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;

    bytes32 public merkleRoot;
    
    // stage => (wallet => amount)
    mapping(uint256 => mapping(address => uint256)) public stageMintedAddress;
    // market blacklist
    mapping(address => bool) public approvedMarketplace;
    mapping(address => bool) public blacklistedMarketplace;

    string public baseUri;
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public stage;
    uint256 public stageRemainSupply;
    uint256 public maxMintAmountPerTx;

    bool public paused;
    bool public whitelistEnabled;
    bool public revealed;
    // market blacklist
    bool public marketplaceRestriction;

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _stageRemainSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) initializerERC721A initializer public {
        __ERC721A_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        __ReentrancyGuard_init();

        setStage(1);
        setCost(_cost);
        setBaseUri("");
        setPaused(true);
        setRevealed(false);
        setWhitelistEnabled(true);
        setStageRemainSupply(_stageRemainSupply);
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier amountCompliance(uint256 _mintAmount) {
        // mint amount > 0 and mint amount <= max per tx
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount");
        // mint amount no bigger than stageRemainSupply
        require(stageRemainSupply >= _mintAmount, "Max supply exceeded");
        // each wallet can mint only once
        require(stageMintedAddress[stage][_msgSender()] == 0, "Already minted");
        _;
    }

    modifier amountComplianceOwner(uint256 _mintAmount) {
        // owner can mint without limited
        require(_mintAmount > 0, "Invalid mint amount");
        //mint amount no bigger than stageRemainSupply
        require(stageRemainSupply >= _mintAmount, "Max supply exceeded");
        _;
    }

    modifier priceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds");
        _;
    }

    // Mint
    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable amountCompliance(_mintAmount) priceCompliance(_mintAmount) {
        require(!paused, "The contract is paused");
        require(checkWhitelistMint(_merkleProof), "Not eligible for mint");
        safeMint(_msgSender(), _mintAmount);
    }
    
    // Owner can mint for a specific address
    function mintForAddress(uint256 _mintAmount, address _receiver) public amountComplianceOwner(_mintAmount) onlyOwner {
        safeMint(_receiver, _mintAmount);
    }

    function safeMint(address _receiver, uint256 _mintAmount) private {
        _safeMint(_receiver, _mintAmount);
        stageRemainSupply -= _mintAmount;
        stageMintedAddress[stage][_receiver] += _mintAmount;
    }

    function _startTokenId() internal view virtual override(ERC721AUpgradeable) returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721AUpgradeable) returns (string memory) {
        require(tokenExist(_tokenId), "Token not exist");
        if (!revealed) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        if (bytes(currentBaseURI).length > 0) {
            return string(abi.encodePacked(currentBaseURI, _tokenId.toString()));
        }
        return "";
    }

    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId, true);
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistEnabled(bool _state) public onlyOwner {
        whitelistEnabled = _state;
    }

    function setStage(uint256 _stage) public onlyOwner {
        stage = _stage;
    }

    function setStageRemainSupply(uint256 _stageRemainSupply) public onlyOwner {
        stageRemainSupply = _stageRemainSupply;
    }

    function setStageAndSupply(uint256 _stage, uint256 _stageRemainSupply) public onlyOwner {
        stage = _stage;
        stageRemainSupply = _stageRemainSupply;
    }

    function tokenExist(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function checkWhitelistMint(bytes32[] calldata _merkleProof) public view returns(bool) {
        if (!whitelistEnabled) {
            return true;
        }
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, leaf);
    }

    function getStageBalance(address _sender) public view returns(uint256) {
        return stageMintedAddress[stage][_sender];
    }

    function _baseURI() internal view virtual override(ERC721AUpgradeable) returns (string memory) {
        return baseUri;
    }

    function getMintMetadata() public view returns (uint256, uint256, uint256, uint256, uint256, bool) {
        return (cost, stage, stageRemainSupply, maxMintAmountPerTx, totalSupply(), revealed);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool ok1,) = payable(0xe49A81b03659F755B0a9098F1F4466987E27D726).call{value: address(this).balance * 10 / 100}('');
        require(ok1);

        (bool ok2,) = payable(owner()).call{value: address(this).balance}("");
        require(ok2);
    }

    // blacklist
    function setMarketplaceRestriction(bool _state) public onlyOwner {
        marketplaceRestriction = _state;
    }

    function setApprovedMarketplace(address operator, bool _state) public onlyOwner {
        approvedMarketplace[operator] = _state;
    }

    function setBlacklistMarketplaces(address[] calldata markets, bool _state) external onlyOwner {
        for (uint256 i = 0; i < markets.length; i++) {
            blacklistedMarketplace[markets[i]] = _state;
        }
    }

    function checkGuardianOrMarketplace(address operator) internal view {
        // always allow guardian contract or marketplace restriction not enabled
        if (approvedMarketplace[operator] || !marketplaceRestriction) {
            return;
        }
        require(!blacklistedMarketplace[operator], "Please contact ibutsu for approval.");
    }

    // transaction verification
    function approve(address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable) {
        checkGuardianOrMarketplace(to);
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721AUpgradeable) {
        checkGuardianOrMarketplace(operator);
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable) {
        checkGuardianOrMarketplace(to);
        super.transferFrom(from, to, tokenId);
    }
}