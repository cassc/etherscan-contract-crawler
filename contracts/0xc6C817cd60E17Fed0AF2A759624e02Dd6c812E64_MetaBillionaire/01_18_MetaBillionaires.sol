// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetaBillionaire is ERC721Enumerable, PaymentSplitter, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAXSUPPLY = 7777;
    uint256 public constant ALLOWED_GIFT_LIMIT = 150;
    uint256 public constant MAX_SELF_MINT = 5;

    address private signerAddress = 0x6b666395701E0A98ED59B4053353c4e0E8A3605E;

    uint256 public giftCount;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;

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
    
    address[] private team_ = [0x483aacff26559a05D42a7431c41BC2b0002Bce66, 
                                0x5B8B3eE5D2d99537E0DBe24B01353a38529D9727, 
                                0x2828D3280801B15C5061F80f752be4130adea2Ed, 
                                0x584BE9377137D1C34b13FF1D6C8D556feC448100, 
                                0x5Bd342AAdE55C91aa75694AEef9a10a828e23Cf0,
                                0x0323196BD6f5ed0CCc8B0f90eDC8b11435fB7c61];
    uint256[] private teamShares_ = [3080, 2816, 2024, 880, 200, 1000];

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721("MetaBillionaire", "MB") PaymentSplitter(team_, teamShares_) {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    //GETTERS

    function publicSaleLimit() public pure returns (uint256) {
        return MAXSUPPLY;
    }

    function privateSalePrice() public pure returns (uint256) {
        return 0.2 ether;
    }

    function allowedGiftLimit() public pure returns (uint256) {
        return ALLOWED_GIFT_LIMIT;
    }

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function getPrice() public view returns (uint256) {
        uint256 _price;
        SaleConfig memory _saleConfig = saleConfig;
        if (block.timestamp <= _saleConfig.startTime + 6 hours) {
            _price = 0.5 ether;
        } else if (
            (block.timestamp >= _saleConfig.startTime + 6 hours) &&
            (block.timestamp <= _saleConfig.startTime + 12 hours)
        ) {
            _price = 0.4 ether;
        } else if (
            (block.timestamp > _saleConfig.startTime + 12 hours) &&
            (block.timestamp <= _saleConfig.startTime + 18 hours)
        ) {
            _price = 0.3 ether;
        } else {
            _price = 0.3 ether;
        }
        return _price;
    }


    function verifyAddressSigner(bytes32 messageHash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encode(sender));
    }

    function presaleMint(bytes32 messageHash, bytes calldata signature)
    external
    payable
    nonReentrant
    {
        uint256 price = 0.2 ether;
        require(workflow == WorkflowStatus.Presale, "MetaBillionaire: Presale is not started yet!");
        require(tokensPerWallet[msg.sender] < 1, "MetaBillionaire: Presale mint is one token only.");
        require(hashMessage(msg.sender) == messageHash, "MESSAGE_INVALID");
        require(
            verifyAddressSigner(messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(msg.value >= price, "INVALID_PRICE");

        tokensPerWallet[msg.sender] += 1;

        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function publicSaleMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();
        require(workflow != WorkflowStatus.SoldOut, "MetaBillionaire: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "MetaBillionaire: public sale is not started yet");
        require(msg.value >= price * ammount, "MetaBillionaire: Insuficient funds");
        require(ammount <= 5, "MetaBillionaire: You can only mint up to five token at once!");
        require(tokensPerWallet[msg.sender] + ammount <= 5, "MetaBillionaire: You can't mint more than 5 tokens!");
        require(supply + ammount <= MAXSUPPLY, "MetaBillionaire: Mint too large!");
        uint256 initial = 1;
        uint256 condition = ammount;
        tokensPerWallet[msg.sender] += ammount;
         if (supply + ammount == MAXSUPPLY) {
            workflow = WorkflowStatus.SoldOut;
        }
        for (uint256 i = initial; i <= condition; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function gift(uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MAXSUPPLY, "The presale is not endend yet!");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(giftCount + _mintAmount <= ALLOWED_GIFT_LIMIT, "max NFT limit exceeded");
        uint256 initial = 1;
        uint256 condition = _mintAmount;
        giftCount += _mintAmount;
        for (uint256 i = initial; i <= condition; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // Before All.

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        require(workflow == WorkflowStatus.Presale, "MetaBillionaire: Unauthorized Transaction");
        uint256 _startTime = block.timestamp;
        uint256 _duration = 18 hours;
        saleConfig = SaleConfig(_startTime, _duration);
        emit ChangeSaleConfig(_startTime, _duration);
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Presale, WorkflowStatus.Sale);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }


    function setSignerAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        signerAddress = _newAddress;
    }

  

    // FACTORY
  
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

}