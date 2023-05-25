// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract MurMurCat is ERC721Enumerable, Ownable, EIP712 {
    using Strings for uint256;

    // Sales variables
    // ------------------------------------------------------------------------
    uint256 public MAX_CATS = 999;
    uint256 public MAX_CATS_ON_TIER_SALE = 199;

    uint256 public MAX_MINT_PER_TX = 3; // Max number of token can be minted per tx
    uint256 public CAT_PRICE = 0.1 ether; 

    uint256 public saleStartTimestamp = 1641633300; // Public Sale start time in epoch format
    uint256 public saleStopTimestamp = 1641636000; // Public Sale stop time in epoch format
    
    // Dutch auction config
    uint256 public auctionStartTimestamp; 
    uint256 public auctionTimeStep;
    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;
    uint256 public auctionPriceStep;
    uint256 public auctionStepNumber;
    
    // Treasury addresses
    // ------------------------------------------------------------------------
    address private _treasury = 0xbA53C6831B496c8a40c02A3c2d1366DfC6503F4e; // address where ether Withdraw to


    // Signer addresses
    // ------------------------------------------------------------------------
    address private _signer = 0x3E7F691772793B62fEfd968Ead095330F6cFA4Cf; // address where signatures generated


    // State variables
    // Using toggles to open/close sale
    // ------------------------------------------------------------------------
    bool public isWhiteListSaleActive = false; 
    bool public isPublicSaleActive = true;
    bool public isLimitedSaleActive = true;
    bool public isDutchAuctionActive = false;


    // Sale arrays
    // ------------------------------------------------------------------------
    mapping(address => uint256) public whiteListSaleClaimed;  // current claimed number of a address on whiteListSale


    // URI variables
    // ------------------------------------------------------------------------
    string private _baseTokenURI;


    // Events
    // ------------------------------------------------------------------------
    event BaseTokenURIChanged(string baseTokenURI);
    event URIChanged(string tokenURI);
    event priceChanged(uint256 newTokenPrice);
    event supplyChanged(uint256 totalSupply,uint256 tierSupply, uint256 maxMintLimitPerTX);
    event CATSMinted(address owner, uint256 numMint, uint256 totalSupply);


    // Constructor
    // ------------------------------------------------------------------------
    constructor() 
    ERC721("MurMurCats", "MMC")
    EIP712("MurMurCats", "1.0.0")
    {}


    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyLimitedSale() {
        require(isLimitedSaleActive, "LIMITED_SALE_NOT_ACTIVE");
        _;
    }

    modifier onlyWhiteListSale() {
        require(isWhiteListSaleActive, "WHITELIST_SALE_NOT_ACTIVE");
        _;
    }

    modifier onlyPublicSale() {
        require(isPublicSaleActive, "PUBLIC_SALE_NOT_ACTIVE");
        require(block.timestamp >= saleStartTimestamp && block.timestamp <= saleStopTimestamp, "NOT_IN_PUBLIC_SALE_TIME");
        _;
    }

    modifier onlyDutchAuction() {
        require(isDutchAuctionActive, "DUTCH_AUCTION_NOT_ACTIVE");
        _;
    }
    
    // Block smart contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "CALLER_IS_CONTRACT");
        _;
    }


    // Sale functions
    // ------------------------------------------------------------------------
    function setTierSupply(uint256 _MAX_CATS_ON_TIER_SALE, uint256 _MAX_MINT_PER_TX) external onlyOwner {
        require(_MAX_CATS_ON_TIER_SALE <= MAX_CATS,"TIER_SUPPLY_EXCEEDS_MAX_CATS");
        MAX_CATS_ON_TIER_SALE = _MAX_CATS_ON_TIER_SALE;
        MAX_MINT_PER_TX = _MAX_MINT_PER_TX;

        emit supplyChanged(MAX_CATS,_MAX_CATS_ON_TIER_SALE, _MAX_MINT_PER_TX);
    }

    function setMaxSupply(uint256 _MAX_CATS) external onlyOwner {
        MAX_CATS = _MAX_CATS;

        emit supplyChanged(_MAX_CATS,MAX_CATS_ON_TIER_SALE,MAX_MINT_PER_TX);
    }
    
    function setPrice(uint256 _CAT_PRICE) external onlyOwner {
        CAT_PRICE = _CAT_PRICE;
        emit priceChanged(_CAT_PRICE);
    }

    function setWhiteListSaleStatus(bool _isWhiteListSaleActive) external onlyOwner {
        require(isWhiteListSaleActive != _isWhiteListSaleActive,"SETTING_TO_CURRENT_STATE");
        isWhiteListSaleActive = _isWhiteListSaleActive;
    }

    function setLimitedSaleStatus(bool _isLimitedSaleActive) external onlyOwner {
        require(isLimitedSaleActive != _isLimitedSaleActive,"SETTING_TO_CURRENT_STATE");
        isLimitedSaleActive = _isLimitedSaleActive;
    }

    function setPublicSale(bool _isPublicSaleActive,uint256 _saleStartTimestamp,uint256 _saleStopTimestamp) external onlyOwner {
        require(isPublicSaleActive != _isPublicSaleActive || saleStartTimestamp!=_saleStartTimestamp || saleStopTimestamp!=_saleStopTimestamp, "SETTING_CURRENT_PUBLIC_SALE_CONFIG");
        isPublicSaleActive = _isPublicSaleActive;
        saleStartTimestamp = _saleStartTimestamp;
        saleStopTimestamp = _saleStopTimestamp;
    }

    function setDutchAuctionStatus(bool _isDutchAuctionActive) external onlyOwner {
        require(isDutchAuctionActive != _isDutchAuctionActive,"SETTING_TO_CURRENT_STATE");
        isDutchAuctionActive = _isDutchAuctionActive;
    }

    function setDutchAuction(
        uint256 _auctionStartTimestamp, 
        uint256 _auctionTimeStep, 
        uint256 _auctionStartPrice, 
        uint256 _auctionEndPrice, 
        uint256 _auctionPriceStep, 
        uint256 _auctionStepNumber
    ) external onlyOwner {
        auctionStartTimestamp = _auctionStartTimestamp;
        auctionTimeStep = _auctionTimeStep;
        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;
        auctionPriceStep = _auctionPriceStep;
        auctionStepNumber = _auctionStepNumber;
    }

    function getDutchAuctionPrice() public view returns (uint256) {
        require(isDutchAuctionActive, "DUTCH_AUCTION_NOT_ACTIVE");
        if (block.timestamp < auctionStartTimestamp) {
            return auctionStartPrice;
        } else {
            // calculate step
            uint256 step = (block.timestamp - auctionStartTimestamp) / auctionTimeStep;
            if (step > auctionStepNumber) {
                step = auctionStepNumber;
            }

            // claculate final price
            if (auctionStartPrice > step * auctionPriceStep){
                return auctionStartPrice - step * auctionPriceStep;
            } else {
                return auctionEndPrice;
            }
        }
    }


    // Verification functions
    // ------------------------------------------------------------------------
    function isLimitedSaleEligible(uint256 _START_MINT_TIMESTAMP, uint256 _STOP_MINT_TIMESTAMP,bytes memory _SIGNATURE) public view returns (bool){
        address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(
            keccak256("VERIFY(address addressForLimitedSale,uint256 startTimestamp,uint256 stopTimestamp)"),
            _msgSender(),
            _START_MINT_TIMESTAMP,
            _STOP_MINT_TIMESTAMP
        ))), _SIGNATURE);
        
        return _signer == recoveredAddr;
    }

    function isWhiteListSaleEligible(uint256 _MAX_CLAIMED_ON_WHITELIST_SALE, uint256 _START_MINT_TIMESTAMP, uint256 _STOP_MINT_TIMESTAMP, bytes memory _SIGNATURE) public view returns (bool){
        address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(
            keccak256("VERIFY(address addressForWhiteListSale,uint256 maxClaimedOnWhiteListSale,uint256 startTimestamp,uint256 stopTimestamp)"),
            _msgSender(),
            _MAX_CLAIMED_ON_WHITELIST_SALE,
            _START_MINT_TIMESTAMP,
            _STOP_MINT_TIMESTAMP
        ))), _SIGNATURE);
        
        return _signer == recoveredAddr;
    }


    // Mint functions
    // ------------------------------------------------------------------------
    function mintLimitedSaleCAT(
        uint256 _START_MINT_TIMESTAMP, 
        uint256 _STOP_MINT_TIMESTAMP, 
        bytes memory _SIGNATURE
    )
        external
        payable
        onlyLimitedSale
        callerIsUser
    {
        require(isLimitedSaleEligible(_START_MINT_TIMESTAMP, _STOP_MINT_TIMESTAMP, _SIGNATURE), "NOT_ELIGIBLE_FOR_LIMITED_SALE");
        require(block.timestamp >= _START_MINT_TIMESTAMP && block.timestamp <= _STOP_MINT_TIMESTAMP, "NOT_ON_LIMITED_SALE_MINTING_TIME");
        require(balanceOf(msg.sender) == 0, "ALREADY_HAVE_CATS_ON_ADDRESS");
        require(totalSupply() + 1 <= MAX_CATS_ON_TIER_SALE , "EXCEEDS_MAX_CLAIMED_NUM_ON_LIMITED_SALE");
        require(CAT_PRICE == msg.value, "SENDING_INVALID_ETHERS");

        uint256 supply = totalSupply();
        _safeMint(msg.sender, supply++);
        
        emit CATSMinted(msg.sender, 1, supply);
    }

    function mintWhiteListSaleCATS(
        uint256 quantity, 
        uint256 _MAX_CLAIMED_ON_WHITELIST_SALE, 
        uint256 _START_MINT_TIMESTAMP, 
        uint256 _STOP_MINT_TIMESTAMP, 
        bytes memory _SIGNATURE
    )
        external
        payable
        onlyWhiteListSale
        callerIsUser
    {
        require(isWhiteListSaleEligible(_MAX_CLAIMED_ON_WHITELIST_SALE, _START_MINT_TIMESTAMP, _STOP_MINT_TIMESTAMP, _SIGNATURE), "NOT_ELIGIBLE_FOR_WHITELIST_SALE");
        require(block.timestamp >= _START_MINT_TIMESTAMP && block.timestamp <= _STOP_MINT_TIMESTAMP, "NOT_ON_WHITELIST_SALE_MINTING_TIME");
        require(quantity > 0 && whiteListSaleClaimed[ msg.sender ] + quantity <= _MAX_CLAIMED_ON_WHITELIST_SALE, "EXCEEDS_MAX_CLAIMED_NUM_ON_ADDR_OR_BELOW_ONE");
        require(CAT_PRICE * quantity == msg.value, "SENDING_INVALID_ETHERS");
        require(totalSupply() + quantity <= MAX_CATS, "EXCEEDS_MAX_SUPPLY");

        uint256 supply = totalSupply();

        for (uint256 i=0; i < quantity; i++) {
            _safeMint(msg.sender, supply++);
        }
        whiteListSaleClaimed[msg.sender] += quantity;
        
        emit CATSMinted(msg.sender, quantity, supply);
    }

    function mintPublicSaleCATS(uint256 quantity) external payable onlyPublicSale callerIsUser {
        require(quantity > 0 && quantity <= MAX_MINT_PER_TX, "EXCEEDS_MAX_MINT_PER_TX_OR_BELOW_ONE");
        require(totalSupply() + quantity <= MAX_CATS_ON_TIER_SALE, "EXCEEDS_MAX_CLAIMED_NUM_ON_PUBLIC_SALE");
        require(CAT_PRICE * quantity == msg.value, "SENDING_INVALID_ETHERS");

        uint256 supply = totalSupply();

        for (uint256 i=0; i < quantity; i++) {
            _safeMint(msg.sender, supply++);
        }
        
        emit CATSMinted(msg.sender, quantity, supply);
    }
    
    function mintDutchAuctionCATS(uint quantity) external payable onlyDutchAuction callerIsUser {
        require(totalSupply() + quantity <= MAX_CATS_ON_TIER_SALE, "EXCEEDS_MAX_CLAIMED_NUM_ON_DUTCH_AUCTION");
        require(quantity > 0 && quantity <= MAX_MINT_PER_TX, "EXCEEDS_MAX_MINT_PER_TX_OR_BELOW_ONE");
        require(getDutchAuctionPrice() * quantity <= msg.value, "SENDING_INSUFFICIENT_ETHERS");

        uint256 supply = totalSupply();

        for (uint256 i=0; i < quantity; i++) {
            _safeMint(msg.sender, supply++);
        }

        emit CATSMinted(msg.sender, quantity, supply);
    }

    function ownerClaimCATS(uint256 quantity, address addr) external onlyOwner {
        require(totalSupply() + quantity <= MAX_CATS, "EXCEEDS_MAX_SUPPLY");

        uint256 supply = totalSupply();

        for (uint256 i=0; i < quantity; i++) {
            _safeMint(addr, supply++);
        }
        
        emit CATSMinted(addr, quantity, supply);
    }

    function ownerClaimCATSId(uint256[] memory id, address addr) external onlyOwner {
        for(uint256 i = 0 ; i < id.length; i++) {
            _safeMint(addr, id[i]);
        }
    }

    // Burn Functions
    // ------------------------------------------------------------------------
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }


    // Base URI Functions
    // ------------------------------------------------------------------------
    function setURI(string calldata __tokenURI) external onlyOwner {
        _baseTokenURI = __tokenURI;
        emit URIChanged( __tokenURI);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "TOKEN_NOT_EXISTS");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // Query token list of specific address
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }


    // Withdrawal functions
    // ------------------------------------------------------------------------
    function setTreasury(address __treasury) external onlyOwner {
        require(__treasury != address(0), "SETTING_ZERO_ADDRESS");
        require(_treasury != __treasury, "SETTING_CURRENT_ADDRESS");

        _treasury = __treasury;
    }
    
    function withdraw() external onlyOwner {
        payable(_treasury).transfer(address(this).balance);
    }


    // Signer functions
    // ------------------------------------------------------------------------
    function setSigner(address __signer) external onlyOwner {
        require(__signer != address(0), "SETTING_ZERO_ADDRESS");
        require(_signer != __signer, "SETTING_CURRENT_ADDRESS");

        _signer = __signer;
    }


}