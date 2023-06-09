// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./ERC721A.sol";

error InvalidSignature();
error NotMeetDutchMint();
error NotMeetWhiteListMint();
error NotMeetPublicMint();
error NotMeetFreeMint();

contract Token0913 is Ownable, ERC721A, ReentrancyGuard {
    struct DutchItem {
        uint64 dutchStartTime;
        uint64 dutchCyclePriceWei;
        uint64 dutchStartPriceWei;
        uint64 dutchEndPriceWei;
        uint256 total;
    }
    struct WhiteListItem {
        uint64 whiteFutures;
        uint64 whitePriceWei;
        uint64 whitelistStartTime;
        uint64 whitelistEndTime;
        uint256 total;
        address checkAddress;
    }
    struct FreeItem {
        uint64 freeFutures;
        uint64 freeStartTime;
        uint64 freeEndTime;        
        uint64 total;
        address checkAddress;
    }
    struct PublicItem {
        uint64 publicPriceWei;
        uint64 publicStartTime;
        uint64 publicEndTime;
        uint64 total;
    }

    FreeItem public freeCofig;
    DutchItem public dutchConfig;
    PublicItem public publicConfig;
    WhiteListItem public whiteListConfig;
    address public adminAddress;

    uint256 public constant MAX_TOTAL_SUPPLY = 10000;
    uint256 public constant AIRDROP_LOCK_TIMES = 30 days;
    uint256 public constant AUCTION_DROP_INTERVAL = 30 minutes;

    string _baseTokenURI;
    uint256 _curveLength;    
    mapping(address => uint64) freeAddress;
    mapping(address => uint64) whiteListAddress;

    constructor() ERC721A("Token 0913", "0913", 20) {}

    // limit another contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // imit admin
    modifier onlyAdmin() {
        require(
            (adminAddress == _msgSender()) || (owner() == _msgSender()),
            "Ownable: caller not Admin"
        );
        _;
    }

    // limit total
    modifier maxTotal(uint256 total){
        require(
            (total != 0) && (totalSupply() + total <= MAX_TOTAL_SUPPLY),
            "Error: Exceed max total nor zero"
        );
        _;
    }

    function setDutchConfig(DutchItem calldata configData) external onlyAdmin maxTotal(configData.total) {
        require(!isDutchSaleOn(),"Error: activity has started");
        require(
            configData.dutchStartPriceWei > configData.dutchEndPriceWei,
            "Error: Price misallocation"
        );
        dutchConfig = configData;

        uint256 _startPrice = uint256(configData.dutchStartPriceWei);
        uint256 _endPrice = uint256(configData.dutchEndPriceWei);
        uint256 _cyclePrice = uint256(configData.dutchCyclePriceWei);
        _curveLength = (((_startPrice - _endPrice) / _cyclePrice) + 1) * AUCTION_DROP_INTERVAL;
    }

    function setWhiteListConfig(WhiteListItem calldata configData) external onlyAdmin maxTotal(configData.total) {
        require(!isWhiteListSaleOn(),"Error: activity has started");
        whiteListConfig = configData;
    }

    function setFreeConfig(FreeItem calldata configData) external onlyAdmin maxTotal(configData.total) {
        require(!isFreeSaleOn(),"Error: activity has started");
        freeCofig = configData;
    }

    function setPublicConfig(PublicItem calldata configData) external onlyAdmin maxTotal(configData.total) {
        require(!isPublicSaleOn(),"Error: activity has started");
        publicConfig = configData;
    }

    function endDutch() external onlyAdmin {
        dutchConfig = DutchItem(
            dutchConfig.dutchStartTime,
            0,
            0,
            0,
            0
        );
    }

    function endWhiteList() external onlyAdmin {
        whiteListConfig = WhiteListItem(
            whiteListConfig.whiteFutures,
            0,
            whiteListConfig.whitelistStartTime,
            uint64(block.timestamp),
            0,
            whiteListConfig.checkAddress
        );
    }

    function endPublic() external onlyAdmin {
        publicConfig = PublicItem(
            0,
            publicConfig.publicStartTime,
            uint64(block.timestamp),
            0
        );
    }

    function endFree() external onlyAdmin {
        freeCofig = FreeItem(
            freeCofig.freeFutures,
            freeCofig.freeStartTime,
            uint64(block.timestamp),
            0,
            freeCofig.checkAddress
        );
    }

    function setAdmin(address newAdmin) external onlyOwner {
        adminAddress = newAdmin;
    }

    function airdropMint(address[] calldata tos, uint256[] calldata nums, bool isLock) external onlyAdmin {
        uint256 length = tos.length;
        require(length == nums.length,"Parameter length error");        
        uint256 total = totalSupply();
        for(uint256 t=0; t<length; t++){
            total += nums[t];
        }
        require(total <= MAX_TOTAL_SUPPLY,"Not enough for mint");

        uint64 lockTime = isLock ? uint64(block.timestamp + AIRDROP_LOCK_TIMES) : 0;
        for (uint256 i = 0; i < length; i++) {
            _safeMint(tos[i], nums[i], lockTime);
        }
    }

    function isDutchSaleOn() public view returns (bool) {
        return
            dutchConfig.total > 0 &&
            dutchConfig.dutchStartPriceWei > 0 &&
            dutchConfig.dutchEndPriceWei > 0 &&
            dutchConfig.dutchStartTime <= uint64(block.timestamp) &&
            (dutchConfig.dutchStartTime + _curveLength) > uint64(block.timestamp);
    }

    // Dutch auction
    function dutchMint(uint256 quantity) public payable callerIsUser {
        if (!isDutchSaleOn()) {
            revert NotMeetDutchMint();
        }

        uint256 nowDutchTotal = dutchConfig.total;
        require(nowDutchTotal >= quantity, "Not enough for mint");
        uint256 CostOne = getAuctionPrice();
        uint256 price = (CostOne * quantity);
        require(CostOne != 0 && msg.value >= price, "Need to send more ETH.");

        _safeMint(msg.sender, quantity, 0);
        nowDutchTotal -= quantity;

        dutchConfig.total = nowDutchTotal;
        //Must refund the price difference
        refundIfOver(price);
    }
    
    function isWhiteListSaleOn() public view returns (bool) {
        return
            whiteListConfig.total > 0 &&
            whiteListConfig.whitePriceWei > 0 &&
            whiteListConfig.whitelistStartTime <= uint64(block.timestamp) &&
            whiteListConfig.whitelistEndTime > uint64(block.timestamp);
    }

    // WhiteList Mint
    function whitelistMint(uint256 salt, bytes calldata signature) public payable callerIsUser {
        if (!isWhiteListSaleOn()) {
            revert NotMeetWhiteListMint();
        }

        WhiteListItem memory config = whiteListConfig;
        require(config.total >= 1, "Not enough for mint");
        require(msg.value >= uint256(config.whitePriceWei), "Need to send more ETH.");
        require(whiteListAddress[msg.sender] != config.whiteFutures, "Whitelist Restriction");

        checkSigna(salt,signature,config.checkAddress);
        _safeMint(msg.sender, 1 , 0);
        config.total -= 1;

        whiteListConfig.total = config.total;
        whiteListAddress[msg.sender] = config.whiteFutures;
    }

    function isPublicSaleOn() public view returns (bool) {
        return
            publicConfig.total > 0 &&
            publicConfig.publicPriceWei > 0 &&
            publicConfig.publicStartTime <= uint64(block.timestamp) &&
            publicConfig.publicEndTime > uint64(block.timestamp);
    }

    function publicMint(uint256 quantity) public payable callerIsUser {
        if (!isPublicSaleOn()) {
            revert NotMeetPublicMint();
        }

        PublicItem memory config = publicConfig;
        require(config.total >= quantity, "Not enough for mint");
        require(msg.value >= (uint256(config.publicPriceWei) * quantity), "Need to send more ETH.");

        _safeMint(msg.sender, quantity, 0);
        config.total -= uint64(quantity);

        publicConfig.total = config.total;
    }

    function isFreeSaleOn() public view returns (bool) {
        return
            freeCofig.total > 0 &&
            freeCofig.freeStartTime <= uint64(block.timestamp) &&
            freeCofig.freeEndTime > uint64(block.timestamp);
    }

    //Freemint
    function freeMint(uint256 salt, bytes calldata signature) public {
        if (!isFreeSaleOn()) {
            revert NotMeetFreeMint();
        }

        FreeItem memory config = freeCofig;
        require(config.total >= 1, "Not enough for mint");
        require(freeAddress[msg.sender] != config.freeFutures, "FreeMint Restriction");

        checkSigna(salt,signature,config.checkAddress);
        _safeMint(msg.sender, 1, 0);
        config.total -= 1;
        
        freeCofig.total = config.total;
        freeAddress[msg.sender] = config.freeFutures;
    }

    function getAuctionPrice() public view returns (uint256) {
        require(_curveLength > 0,"config missing");

        uint256 _startTime = uint256(dutchConfig.dutchStartTime);
        uint256 _startPrice = uint256(dutchConfig.dutchStartPriceWei);
        uint256 _endPrice = uint256(dutchConfig.dutchEndPriceWei);
        uint256 _cyclePrice = uint256(dutchConfig.dutchCyclePriceWei);

        if (block.timestamp <= _startTime) {
            return _startPrice;
        }
        if (block.timestamp - _startTime >= _curveLength) {
            return _endPrice;
        } else {
            uint256 steps = (block.timestamp - _startTime) / AUCTION_DROP_INTERVAL;
            return _startPrice - (steps * _cyclePrice);
        }
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyAdmin {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function refundIfOver(uint256 price) private nonReentrant {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function checkSigna(uint256 salt, bytes calldata signature,address checkAddr) private view{
        bytes32 HashData = keccak256(abi.encodePacked(msg.sender, salt));
        if (
            !SignatureChecker.isValidSignatureNow(
                checkAddr,
                HashData,
                signature
            )
        ) {
            revert InvalidSignature();
        }
    }
}