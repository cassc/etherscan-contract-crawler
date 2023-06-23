// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MetaIsland is ERC721Enumerable, PaymentSplitter, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    bytes32 public merkleRoot;

    uint256 public constant MAXIMUM_SUPPLY = 7777;
    uint256 public constant MAXIMUM_GIFT = 50;
    uint256 public constant MAXIMUM_MINT = 5;

    uint256 public giftCount;

    string public baseURI;
    string public notRevealedUri;

    bool public isRevealed = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        SoldOut,
        Reveal
    }

    struct SaleConfig {
        uint256 startTime;
        uint256 duration;
    }

    WorkflowStatus public workflow;
    SaleConfig public saleConfig;

    address private _owner;

    mapping(address => uint256) public tokensPerWallet;

    event ChangePresaleConfig(uint256 _startTime, uint256 _duration, uint256 _maxCount);
    event ChangeSaleConfig(uint256 _startTime, uint256 _maxCount);
    event ChangeIsBurnEnabled(bool _isBurnEnabled);
    event ChangeBaseURI(string _baseURI);
    event GiftMint(address indexed _recipient, uint256 _amount);
    event PresaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event SaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    address[] private team_ = [0x9C012C7469759092537876DFA0E4BCB66CF1e393,
                                0x4a75A7e26D04d354b9C7514b29ef0c3B43060Db5,
                                0x85a0c5270aa5c5058349a825eC941a762458003A,
                                0x2BC0291B7A33f0672792c103334450f81a1974ff,
                                0x5fD51C6FaacBF40c511511f64CF118031DB728C1];
    uint256[] private teamShares_ = [5200, 2800, 1300, 500, 200];

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721("MetaIsland", "MI") PaymentSplitter(team_, teamShares_) {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    //GETTERS

    function publicSaleLimit() public pure returns (uint256) {
        return MAXIMUM_SUPPLY;
    }

    function privateSalePrice() public pure returns (uint256) {
        return 0.2 ether;
    }

    function allowedGiftLimit() public pure returns (uint256) {
        return MAXIMUM_GIFT;
    }

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function hasWhitelist(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function getPrice() public view returns (uint256) {
        uint256 _price;
        SaleConfig memory _saleConfig = saleConfig;
        if (block.timestamp <= _saleConfig.startTime + 6 hours) {
            _price = 0.35 ether;
        } else if (
            (block.timestamp >= _saleConfig.startTime + 6 hours) &&
            (block.timestamp <= _saleConfig.startTime + 12 hours)
        ) {
            _price = 0.3 ether;
        } else if (
            (block.timestamp > _saleConfig.startTime + 12 hours) &&
            (block.timestamp <= _saleConfig.startTime + 18 hours)
        ) {
            _price = 0.25 ether;
        } else {
            _price = 0.25 ether;
        }
        return _price;
    }

    function presaleMint(bytes32[] calldata _merkleProof) external payable nonReentrant
    {
        uint256 price = 0.2 ether;

        require(workflow == WorkflowStatus.Presale, "MetaIsland: Presale is not started yet!");
        require(tokensPerWallet[msg.sender] < 1, "MetaIsland: Presale mint is one token only.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "MetaIsland: You are not whitelisted");

        require(msg.value >= price, "INVALID_PRICE");

        tokensPerWallet[msg.sender] += 1;

        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function publicSaleMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();
        require(workflow != WorkflowStatus.SoldOut, "MetaIsland: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "MetaIsland: public sale is not started yet");
        require(msg.value >= price * ammount, "MetaIsland: Insuficient funds");
        require(ammount <= 5, "MetaIsland: You can only mint up to five token at once!");
        require(tokensPerWallet[msg.sender] + ammount <= 5, "MetaIsland: You can't mint more than 5 tokens!");
        require(supply + ammount <= MAXIMUM_SUPPLY, "MetaIsland: Mint too large!");
        uint256 initial = 1;
        uint256 condition = ammount;
        tokensPerWallet[msg.sender] += ammount;
         if (supply + ammount == MAXIMUM_SUPPLY) {
            workflow = WorkflowStatus.SoldOut;
        }
        for (uint256 i = initial; i <= condition; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function gift(uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MAXIMUM_SUPPLY, "The presale is not endend yet!");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(giftCount + _mintAmount <= MAXIMUM_GIFT, "max NFT limit exceeded");
        uint256 initial = 1;
        uint256 condition = _mintAmount;
        giftCount += _mintAmount;
        for (uint256 i = initial; i <= condition; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // Before All.

    function restart() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        require(workflow == WorkflowStatus.Presale, "MetaIsland: Unauthorized Transaction");
        uint256 _startTime = block.timestamp;
        uint256 _duration = 18 hours;
        saleConfig = SaleConfig(_startTime, _duration);
        emit ChangeSaleConfig(_startTime, _duration);
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Presale, WorkflowStatus.Sale);
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // FACTORY

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

}