//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "./ENS.sol";

import {BaseRegistrar} from "./BaseRegistrar.sol";
import {PublicResolver} from "./PublicResolver.sol";
import {ReverseRegistrar} from "./ReverseRegistrar.sol";
import {IETHRegistrarController, IPriceOracle} from "@ensdomains/ens-contracts/contracts/ethregistrar/IETHRegistrarController.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC20Recoverable} from "@ensdomains/ens-contracts/contracts/utils/ERC20Recoverable.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "./Normalize4.sol";
import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/SSTORE2.sol";

error NameNotAvailable(string name);
error DurationTooShort(uint256 duration);
error InsufficientValue();

import "hardhat/console.sol";

contract IPRegistrarController is
    Ownable,
    IETHRegistrarController,
    IERC165,
    ERC20Recoverable,
    ReentrancyGuard
{
    using LibString for *;
    using Address for *;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeTransferLib for address;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    uint256 public constant MIN_REGISTRATION_DURATION = 28 days;
    BaseRegistrar immutable base;
    IPriceOracle public immutable prices;
    
    ENS public immutable ens;
    address public defaultResolver;
    ReverseRegistrar public reverseRegistrar;
    Normalize4 public normalizer;
    
    string public constant tldString = 'ip';
    bytes32 public constant tldLabel = keccak256(abi.encodePacked(tldString));
    bytes32 public constant rootNode = bytes32(0);
    bytes32 public immutable tldNode = keccak256(abi.encodePacked(rootNode, tldLabel));
    
    mapping (uint => string) public hashToLabelString;
    
    uint64 public auctionTimeBuffer = 15 minutes;
    uint256 public auctionMinBidIncrementPercentage = 10;
    uint64 public auctionDuration = 24 hours;
    bool public contractInAuctionMode = true;
    
    mapping(uint => Auction) public auctions;
    EnumerableSet.UintSet activeAuctionIds;

    uint public ethAvailableToWithdraw;
    address payable public withdrawAddress;
    
    address public logoSVG;
    address[] public fonts;
    
    struct Auction {
        uint tokenId;
        string name;
        uint64 startTime;
        uint64 endTime;
        Bid[] bids;
    }
    
    struct AuctionInfo {
        uint tokenId;
        string name;
        uint64 startTime;
        uint64 endTime;
        Bid[] bids;
        uint minNextBid;
        address highestBidder;
        uint highestBidAMount;
    }
    
    struct Bid {
        uint80 amount;
        address bidder;
    }
    
    event AuctionStarted(uint indexed tokenId, uint startTime, uint endTime);
    event AuctionExtended(uint indexed tokenId, uint endTime);
    event AuctionBid(uint indexed tokenId, address bidder, uint bidValue, bool auctionExtended);
    event AuctionSettled(uint indexed tokenId, address winner, uint amount);

    event NameRegistered(
        string name,
        bytes32 indexed label,
        address indexed owner,
        uint256 baseCost,
        uint256 premium,
        uint256 expires
    );
    event NameRenewed(
        string name,
        bytes32 indexed label,
        uint256 cost,
        uint256 expires
    );
    
    event AuctionWithdraw(address indexed addr, uint indexed total);
    event Withdraw(address indexed addr, uint indexed total);
    
    function setDefaultResolver(address _defaultResolver) public onlyOwner {
        defaultResolver = _defaultResolver;
    }
    
    function setReverseRegistrar(ReverseRegistrar _reverseRegistrar) public onlyOwner {
        reverseRegistrar = _reverseRegistrar;
    }
    
    function setNormalizer(Normalize4 _normalizer) public onlyOwner {
        normalizer = _normalizer;
    }
    
    function setAuctionTimeBuffer(uint64 _auctionTimeBuffer) public onlyOwner {
        auctionTimeBuffer = _auctionTimeBuffer;
    }
    
    function setAuctionMinBidIncrementPercentage(uint256 _auctionMinBidIncrementPercentage) public onlyOwner {
        auctionMinBidIncrementPercentage = _auctionMinBidIncrementPercentage;
    }
    
    function setAuctionDuration(uint64 _auctionDuration) public onlyOwner {
        auctionDuration = _auctionDuration;
    }
    
    function setContractInAuctionMode(bool _contractInAuctionMode) public onlyOwner {
        contractInAuctionMode = _contractInAuctionMode;
    }
    
    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = payable(_withdrawAddress);
    }
    
    modifier onlyBaseRegistrar() {
        require(msg.sender == address(base), "Only base registrar");
        _;
    }

    constructor(
        ENS _ens,
        BaseRegistrar _base,
        IPriceOracle _prices,
        ReverseRegistrar _reverseRegistrar,
        Normalize4 _normalizer,
        string memory _logoSVG,
        string[5] memory _fonts
    ) {
        ens = _ens;
        base = _base;
        prices = _prices;
        reverseRegistrar = _reverseRegistrar;
        normalizer = _normalizer;
        
        setLogoSVG(_logoSVG);
        setFonts(_fonts);
    }
    
    bool preRegisterDone;
    function preRegisterNames(
        string[] calldata names,
        bytes[][] calldata data,
        address owner
    ) external onlyOwner {
        require(!preRegisterDone);
        
        for (uint i; i < names.length; ++i) {
            _registerWithoutCommitment(
                names[i],
                owner,
                365 days,
                address(0),
                data[0],
                false,
                0,
                0
            );
        }
        
        preRegisterDone = true;
    }
    
    function rentPrice(string memory name, uint256 duration)
        public
        view
        override
        returns (IPriceOracle.Price memory price)
    {
        bytes32 label = keccak256(bytes(name));
        price = prices.price(name, base.nameExpires(uint256(label)), duration);
    }

    function valid(string memory name) public view returns (bool) {
        if (bytes(name).length == 0) return false;
        
        try normalizer.normalize(name) returns (string[] memory _norm) {
            if (!(name.eq(_norm[0]) && _norm.length == 1)) return false;
        } catch {
            return false;
        }
        
        return true;
    }

    function available(string memory name) public view override returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint32 fuses,
        uint64 wrapperExpiry
    ) public payable override {
        return registerWithoutCommitment(
            name,
            owner,
            duration,
            resolver,
            data,
            reverseRecord
        );
    }
    
    function auctionMinNextBid(uint currentHighestBid) public view returns (uint) {
        return currentHighestBid + (currentHighestBid * auctionMinBidIncrementPercentage / 100);
    }
    
    function max(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }
    
    function auctionHighestBid(uint tokenId) public view returns (Bid memory) {
        Auction storage auction = auctions[tokenId];
        if (auction.bids.length == 0) {
            return Bid({amount: 0, bidder: address(0)});
        }
        return auction.bids[auction.bids.length - 1];
    }
    
    function getAuction(string memory name) public view returns (AuctionInfo memory) {
        uint256 tokenId = uint256(keccak256(bytes(name)));

        Auction memory auction = auctions[tokenId];
        Bid memory highestBid = auctionHighestBid(tokenId);
        
        uint reservePrice = (rentPrice(name, 365 days)).base;
        uint minNextBid = max(auctionMinNextBid(highestBid.amount), reservePrice);
        
        return AuctionInfo({
            tokenId: tokenId,
            name: name,
            startTime: auction.startTime,
            endTime: auction.endTime,
            bids: auction.bids,
            minNextBid: minNextBid,
            highestBidder: highestBid.bidder,
            highestBidAMount: highestBid.amount
        });
    }
    
    function bidOnName(string calldata name) external payable nonReentrant returns (bool success) {
        uint256 tokenId = uint256(keccak256(bytes(name)));

        Auction storage auction = auctions[tokenId];
        Bid memory highestBid = auctionHighestBid(tokenId);
        
        require(contractInAuctionMode, "Contract not in auction mode");
        require(msg.value < type(uint80).max, "Out of range");
        require(msg.value >= auctionMinNextBid(highestBid.amount), 'Must send at least min increment');
        
        require(auction.endTime == 0 || block.timestamp < auction.endTime, "Auction ended");
        
        if (auction.startTime == 0) {
            uint reservePrice = (rentPrice(name, 365 days)).base;
            require(msg.value >= reservePrice, 'Must send at least reservePrice');
            require(available(name), "Not available");
            
            auction.startTime = uint64(block.timestamp);
            auction.endTime = uint64(block.timestamp + auctionDuration);
            auction.tokenId = tokenId;
            auction.name = name;
            
            activeAuctionIds.add(tokenId);
            emit AuctionStarted(tokenId, auction.startTime, auction.endTime);
        }
        
        if (highestBid.bidder != address(0)) {
            highestBid.bidder.forceSafeTransferETH(highestBid.amount);
        }
        
        Bid memory newBid = Bid({
            amount: uint80(msg.value),
            bidder: msg.sender
        });
        
        auction.bids.push(newBid);
        
        bool extendAuction = auction.endTime - block.timestamp < auctionTimeBuffer;
        if (extendAuction) {
            auction.endTime = uint64(block.timestamp + auctionTimeBuffer);
            emit AuctionExtended(tokenId, auction.endTime);
        }

        emit AuctionBid(tokenId, newBid.bidder, newBid.amount, extendAuction);
        
        return true;
    }
    
    function settleAuction(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord
    ) external nonReentrant {
        uint tokenId = uint256(keccak256(bytes(name)));
        Auction memory auction = auctions[tokenId];
        Bid memory highestBid = auctionHighestBid(tokenId);

        require(owner == highestBid.bidder, "Only highest bidder");
        require(duration == 365 days, "Must be 365 days");
        require(auction.startTime != 0, "Auction hasn't begun");
        require(block.timestamp >= auction.endTime, "Auction hasn't completed");
        
        _registerWithoutCommitment(
            name,
            owner,
            duration,
            resolver,
            data,
            reverseRecord,
            highestBid.amount,
            0
        );
        
        ethAvailableToWithdraw += highestBid.amount;
        activeAuctionIds.remove(tokenId);
        
        emit AuctionSettled(tokenId, highestBid.bidder, highestBid.amount);
    }
    
    function registerWithoutCommitment(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord
    ) public payable nonReentrant {
        require(!contractInAuctionMode, "Contract in auction mode");
        
        uint tokenId = uint256(keccak256(bytes(name)));
        require(!activeAuctionIds.contains(tokenId), "Name in auction");
        
        IPriceOracle.Price memory price = rentPrice(name, duration);
        
        if (msg.value < price.base + price.premium) revert InsufficientValue();
        if (duration < MIN_REGISTRATION_DURATION) revert DurationTooShort(duration);

        _registerWithoutCommitment(
            name,
            owner,
            duration,
            resolver,
            data,
            reverseRecord,
            price.base,
            price.premium
        );

        if (msg.value > (price.base + price.premium)) {
            msg.sender.forceSafeTransferETH(
                msg.value - (price.base + price.premium)
            );
        }
    }
    
    function _registerWithoutCommitment(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint basePrice,
        uint pricePremium
    ) internal {
        if (!available(name)) {
            revert NameNotAvailable(name);
        }
        uint256 tokenId = uint256(keccak256(bytes(name)));
        
        uint256 expires = base.registerOnly(tokenId, owner, duration);
        if (resolver == address(0)) {
            resolver = defaultResolver;
        }
        
        ens.setSubnodeRecord(tldNode, bytes32(tokenId), owner, resolver, 0);
        bytes32 node = _makeNode(tldNode, keccak256(bytes(name)));
        
        PublicResolver(resolver).setAddr(node, owner);
        if (data.length > 0) {
            _setRecords(resolver, keccak256(bytes(name)), data);
        }

        if (reverseRecord && msg.sender == owner) {
            _setReverseRecord(name, resolver, msg.sender);
        }
        
        hashToLabelString[tokenId] = name;
        
        emit NameRegistered(
            name,
            keccak256(bytes(name)),
            owner,
            basePrice,
            pricePremium,
            expires
        );
    }

    function renew(string calldata name, uint256 duration) external payable override nonReentrant {
        bytes32 labelhash = keccak256(bytes(name));
        uint256 tokenId = uint256(labelhash);
        IPriceOracle.Price memory price = rentPrice(name, duration);
        if (msg.value < price.base) {
            revert InsufficientValue();
        }
        uint256 expires;
        expires = base.renew(tokenId, duration);

        if (msg.value > price.base) {
            msg.sender.forceSafeTransferETH(msg.value - price.base);
        }

        emit NameRenewed(name, labelhash, msg.value, expires);
    }
    
    function auctionWithdraw() external nonReentrant {
        require(contractInAuctionMode, "Contract not in auction mode");
        require(ethAvailableToWithdraw > 0, "Nothing to withdraw");
        require(withdrawAddress != address(0), "Withdraw address not set");
        
        uint balance = ethAvailableToWithdraw;
        ethAvailableToWithdraw = 0;
        
        withdrawAddress.sendValue(balance);
        emit AuctionWithdraw(withdrawAddress, balance);
    }
    
    function withdraw() external nonReentrant onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        
        withdrawAddress.sendValue(balance);
        emit Withdraw(withdrawAddress, balance);
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IETHRegistrarController).interfaceId;
    }
    
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external onlyBaseRegistrar {}
    
    function afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external onlyBaseRegistrar {
        if (from == address(0) || to == address(0)) return;
        
        ens.setSubnodeOwner(tldNode, bytes32(tokenId), to);
    }
    
    function getAllActiveAuctions() external view returns (AuctionInfo[] memory) {
        return getActiveAuctionsInBatches(0, activeAuctionIds.length());
    }
    
    function getActiveAuctionsInBatches(uint batchIdx, uint batchSize) public view returns (AuctionInfo[] memory) {
        uint auctionCount = activeAuctionIds.length();
        uint startIdx = batchIdx * batchSize;
        uint endIdx = startIdx + batchSize;
        if (endIdx > auctionCount) {
            endIdx = auctionCount;
        }
        AuctionInfo[] memory ret = new AuctionInfo[](endIdx - startIdx);
        
        for (uint i = startIdx; i < endIdx; ++i) {
            Auction memory auction = auctions[activeAuctionIds.at(i)];
            string memory name = auction.name;
            ret[i - startIdx] = getAuction(name);
        }
        return ret;
    }

    /* Internal functions */
    
    function _setRecords(
        address resolverAddress,
        bytes32 label,
        bytes[] calldata data
    ) internal {
        bytes32 nodehash = keccak256(abi.encodePacked(tldNode, label));
        PublicResolver resolver = PublicResolver(resolverAddress);
        resolver.multicallWithNodeCheck(nodehash, data);
    }

    function _setReverseRecord(
        string memory name,
        address resolver,
        address owner
    ) internal {
        reverseRegistrar.setNameForAddr(
            msg.sender,
            owner,
            resolver,
            string.concat(name, ".", tldString)
        );
    }
    
    function _makeNode(bytes32 node, bytes32 labelhash)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, labelhash));
    }
    
    function makeCommitment(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint32 fuses,
        uint64 wrapperExpiry
    ) public pure override returns (bytes32) {
        revert("No commitment required, call register() directly");
    }

    function commit(bytes32 commitment) public override {
        revert("No commitment required, call register() directly");
    }
    
   function allFonts() public view returns (string memory) {
        DynamicBufferLib.DynamicBuffer memory fontData;
        
        for (uint i = 0; i < fonts.length; i++) {
            fontData.append(SSTORE2.read(fonts[i]));
        }
        
        return string(fontData.data);
    }
    
    function setFonts(string[5] memory _fonts) public onlyOwner {
        for (uint i = 0; i < _fonts.length; i++) {
            fonts.push(SSTORE2.write(bytes(_fonts[i])));
        }
    }
    
    function setLogoSVG(string memory _logoSVG) public onlyOwner {
        logoSVG = SSTORE2.write(bytes(_logoSVG));
    }
}