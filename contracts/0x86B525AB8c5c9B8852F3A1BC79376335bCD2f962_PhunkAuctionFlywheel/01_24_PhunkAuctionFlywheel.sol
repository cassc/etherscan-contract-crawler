// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";
import "solmate/src/utils/FixedPointMathLib.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

interface IWETH {
    function deposit() external payable;
}

contract PhunkAuctionFlywheel is ReentrancyGuard, AccessControl, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using BokkyPooBahsDateTimeLibrary for uint;
    using ECDSA for *;
    
    bytes32 public constant TESTER_ROLE = keccak256("TESTER_ROLE");
    
    struct ContractConfig {
        uint costOfOracleInJuels;
        bytes32 priceEstimationJobId;
        uint minPctOfNFTxSpotPriceToPay;
        uint minAmountOfPhunkInSushiPoolForValidSpotPrice;
        uint pctOfOraclePriceEstimateToPay;
        ContractStatus status;
    }
    
    struct AddressRegistry {
        address treasuryWalletAddress;
        address addressToSendBoughtPhunksTo;
        address phunkContractAddress;
        address wethContractAddress;
        address chainlinkTokenAddress;
        address appraisalOracleAddress;
        address phunkERC20Address;
        address sushiSwapPhunkERC20WethPoolAddress;
        address priceAppraisalSignerAddress;
    }
    
    ContractConfig public contractConfig;
    AddressRegistry public addressRegistry;
    
    enum ContractStatus {
        PAUSED,
        SIGNATURE_MODE_TESTING,
        SIGNATURE_MODE_ACTIVE,
        ORACLE_MODE_TESTING,
        ORACLE_MODE_ACTIVE
    }
    
    struct Offer {
        OfferStatus status;
        OfferCancellationReason cancellationReason;
        uint16 phunkId;
        uint64 offerValidUntil;
        bool enoughPhunkInSushiPoolForValidSpotPrice;
        address seller;
        uint minSalePrice;
        uint oraclePriceEstimate;
        bytes32 appraisalRequestId;
        uint minAppraisalConsideredValid;
        uint priceFlywheelIsWillingToPay;
    }
    
    Offer[] public offers;
    mapping(bytes32 => Offer) public priceRequestIdToOffer;
    
    enum OfferStatus {
        NEW_RECORD,
        PRICE_ESTIMATE_REQUESTED,
        ORACLE_REQUEST_FULFILLED,
        ORACLE_REQUEST_CANCELLED,
        SIGNATURE_REQUEST_FULFILLED
    }
    
    enum OfferCancellationReason {
        NONE,
        WRONG_PRICE,
        PHUNK_TRANSFER_FAILURE,
        FLYWHEEL_OUT_OF_ETH,
        INCORRECT_OFFER_STATUS,
        OFFER_EXPIRED
    }
    
    mapping(uint => uint) public startOfWeekToWeeklyAllowanceMapping;
    
    event PhunkSoldViaSignature(
        Offer offer,
        uint indexed phunkId,
        uint minSalePrice,
        address indexed seller
    );
    
    event PhunkOfferedForSale(
        Offer offer,
        uint indexed phunkId,
        uint minSalePrice,
        address indexed seller
    );
    
    event PriceEstimateRequested(
        uint256 indexed phunkId,
        bytes32 indexed requestId
    );
    
    event PriceEstimateFulfilled(
        Offer offer,
        bytes32 indexed requestId,
        uint priceToPay,
        uint minAppraisalConsideredValid
    );
    
    event PriceEstimateCancelled(
        Offer offer,
        bytes32 indexed requestId,
        uint priceToPay,
        uint minAppraisalConsideredValid
    );
    
    event ContractConfigUpdated(ContractConfig newConfig);
    event AddressRegistryUpdated(AddressRegistry newRegistry);
    
    event EthDeposited(uint[] weekStarts, uint[] weeklyLimits);
    event EthWithdrawn(uint[] weekStarts, uint[] amounts);
    event FailsafeWithdrawal(uint amount);

    address public constant middleAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
    address public constant hwonderAddress = 0xF9C2Ba78aE44ba98888B0e9EB27EB63d576F261B;
    
    constructor(
        AddressRegistry memory _addressRegistry,
        ContractConfig memory _contractConfig
    ) {
        contractConfig = _contractConfig;
        addressRegistry = _addressRegistry;
        
        _grantRole(DEFAULT_ADMIN_ROLE, addressRegistry.treasuryWalletAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, middleAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, hwonderAddress);

        _grantRole(TESTER_ROLE, addressRegistry.treasuryWalletAddress);
        _grantRole(TESTER_ROLE, middleAddress);
        _grantRole(TESTER_ROLE, hwonderAddress);
        
        setChainlinkToken(addressRegistry.chainlinkTokenAddress);
        setChainlinkOracle(addressRegistry.appraisalOracleAddress);
        
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        linkToken.approve(addressRegistry.treasuryWalletAddress, 2 ** 256 - 1);
    }
    
    function getCurrentMinimumValidPrice() public view returns (uint, bool) {
        uint poolWethBalance = getWethBalanceInSushiPool();
        uint poolPhunkBalance = getPhunkERC20BalanceInSushiPool();
        
        uint spotPrice = FixedPointMathLib.divWadDown(poolWethBalance, poolPhunkBalance);
        
        uint minValidPrice = (spotPrice * contractConfig.minPctOfNFTxSpotPriceToPay) / 100;
        bool priceValid = poolPhunkBalance >= contractConfig.minAmountOfPhunkInSushiPoolForValidSpotPrice;
        
        return (minValidPrice, priceValid);
    }
    
    function sellPhunkWithSignature(
        bytes memory signature,
        uint16 phunkId,
        uint phunkPrice,
        uint offerValidUntil
    ) external nonReentrant {
        require(contractConfig.status != ContractStatus.PAUSED, "Flywheel is paused");
        require(
            contractConfig.status == ContractStatus.SIGNATURE_MODE_ACTIVE ||
            (contractConfig.status == ContractStatus.SIGNATURE_MODE_TESTING && hasRole(TESTER_ROLE, msg.sender)),
            "Flywheel is in test mode"
        );
        
        bytes32 hashedMessage = keccak256(abi.encodePacked(
            phunkId,
            phunkPrice,
            offerValidUntil
        ));
        
        bytes32 message = hashedMessage.toEthSignedMessageHash();
        address signer = message.recover(signature);

        require(signer == addressRegistry.priceAppraisalSignerAddress, "Invalid Signature");
        require(offerValidUntil > block.timestamp, "Offer has expired");
        require(startOfWeekToWeeklyAllowanceMapping[getStartOfCurrentWeek()] >= phunkPrice, "Weekly allowance exceeded");
        
        IERC721(addressRegistry.phunkContractAddress).safeTransferFrom(
            msg.sender,
            addressRegistry.addressToSendBoughtPhunksTo,
            phunkId
        );
        
        startOfWeekToWeeklyAllowanceMapping[getStartOfCurrentWeek()] -= phunkPrice;
        _safeTransferETHWithFallback(msg.sender, phunkPrice);
        
        Offer memory newOffer = Offer({
            status: OfferStatus.SIGNATURE_REQUEST_FULFILLED,
            cancellationReason: OfferCancellationReason.NONE,
            seller: msg.sender,
            phunkId: phunkId,
            offerValidUntil: uint64(offerValidUntil),
            minSalePrice: phunkPrice,
            oraclePriceEstimate: 0,
            appraisalRequestId: bytes32(0),
            minAppraisalConsideredValid: 0,
            enoughPhunkInSushiPoolForValidSpotPrice: false,
            priceFlywheelIsWillingToPay: 0
        });
        
        offers.push(newOffer);
        
        emit PhunkSoldViaSignature(newOffer, phunkId, phunkPrice, msg.sender);
    }
    
    function tryToSellPhunkWithOracle(uint16 phunkId, uint minSalePrice, uint64 offerValidDuration) external nonReentrant {
        require(contractConfig.status != ContractStatus.PAUSED, "Flywheel is paused");
        require(
            contractConfig.status == ContractStatus.ORACLE_MODE_ACTIVE ||
            (contractConfig.status == ContractStatus.ORACLE_MODE_TESTING && hasRole(TESTER_ROLE, msg.sender)),
            "Flywheel is in test mode"
        );
        
        (uint minValidPrice, bool priceValid) = getCurrentMinimumValidPrice();
        
        IERC721 phunks = IERC721(addressRegistry.phunkContractAddress);
        
        require(offerValidDuration >= 30 seconds, "Offer must be valid for at least 30s");
        require(priceValid, "Too little PHUNK in Sushi pool");
        require(minSalePrice >= minValidPrice, "Minimum sale price is too low");
        require(phunks.ownerOf(phunkId) == msg.sender, "Sender does not own phunk");
        require(phunks.isApprovedForAll(msg.sender, address(this)) || phunks.getApproved(phunkId) == address(this), "Flywheel needs approval");
        require(startOfWeekToWeeklyAllowanceMapping[getStartOfCurrentWeek()] >= minSalePrice, "Weekly allowance exceeded");
        
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        
        try linkToken.transferFrom(
            msg.sender,
            address(this),
            contractConfig.costOfOracleInJuels
        ) {}
        catch Error(string memory err) {
            revert(string.concat("Send LINK to use the Flywheel: ", err));
        }
        
        bytes32 priceRequestId = getAppraisalFromOracle(phunkId);
        
        Offer memory newOffer = Offer({
            status: OfferStatus.PRICE_ESTIMATE_REQUESTED,
            cancellationReason: OfferCancellationReason.NONE,
            seller: msg.sender,
            phunkId: phunkId,
            offerValidUntil: uint64(block.timestamp) + offerValidDuration,
            minSalePrice: minSalePrice,
            oraclePriceEstimate: 0,
            appraisalRequestId: priceRequestId,
            minAppraisalConsideredValid: 0,
            enoughPhunkInSushiPoolForValidSpotPrice: false,
            priceFlywheelIsWillingToPay: 0
        });
        
        priceRequestIdToOffer[priceRequestId] = newOffer;
        offers.push(newOffer);
        
        emit PhunkOfferedForSale(newOffer, phunkId, minSalePrice, msg.sender);
    }
    
    function getAppraisalFromOracle(uint256 phunkId) internal returns (bytes32 requestId) {
        Chainlink.Request memory req = buildOperatorRequest(
            contractConfig.priceEstimationJobId,
            this.buyPhunkUsingOracleAppraisal.selector
        );

        req.addBytes("assetAddress", abi.encodePacked(addressRegistry.phunkContractAddress));
        req.addUint("tokenId", phunkId);
        req.add("pricingAsset", "ETH");

        requestId = sendOperatorRequest(req, contractConfig.costOfOracleInJuels);
        
        emit PriceEstimateRequested(phunkId, requestId);
    }
    
    function markOfferCancelledWithReason(Offer storage offer, OfferCancellationReason reason) internal {
        offer.status = OfferStatus.ORACLE_REQUEST_CANCELLED;
        offer.cancellationReason = reason;
        emit PriceEstimateCancelled(offer, offer.appraisalRequestId, offer.oraclePriceEstimate, offer.minAppraisalConsideredValid);
    }
    
    function buyPhunkUsingOracleAppraisal(bytes32 requestId, uint estimate) external nonReentrant recordChainlinkFulfillment(requestId) {
        Offer storage offer = priceRequestIdToOffer[requestId];
        
        offer.oraclePriceEstimate = estimate * 1e4;
        offer.priceFlywheelIsWillingToPay = (offer.oraclePriceEstimate * contractConfig.pctOfOraclePriceEstimateToPay) / 100;
        
        (uint minValidPrice, bool priceValid) = getCurrentMinimumValidPrice();
        
        offer.minAppraisalConsideredValid = minValidPrice;
        offer.enoughPhunkInSushiPoolForValidSpotPrice = priceValid;
        
        if (block.timestamp > offer.offerValidUntil) {
            return markOfferCancelledWithReason(offer, OfferCancellationReason.OFFER_EXPIRED);
        }
        
        if (offer.status != OfferStatus.PRICE_ESTIMATE_REQUESTED) {
            return markOfferCancelledWithReason(offer, OfferCancellationReason.INCORRECT_OFFER_STATUS);
        }
        
        if (!(
            offer.priceFlywheelIsWillingToPay >= offer.minSalePrice &&
            offer.oraclePriceEstimate >= offer.minAppraisalConsideredValid &&
            offer.enoughPhunkInSushiPoolForValidSpotPrice
        )) {
            return markOfferCancelledWithReason(offer, OfferCancellationReason.WRONG_PRICE);
        }
        
        uint availableBalance = startOfWeekToWeeklyAllowanceMapping[getStartOfCurrentWeek()];
        
        if (!(
            availableBalance >= offer.priceFlywheelIsWillingToPay
        )) {
            return markOfferCancelledWithReason(offer, OfferCancellationReason.FLYWHEEL_OUT_OF_ETH);
        }
        
        try IERC721(addressRegistry.phunkContractAddress).safeTransferFrom(
            offer.seller,
            addressRegistry.addressToSendBoughtPhunksTo,
            offer.phunkId
        ) {}
        catch Error(string memory) {
            return markOfferCancelledWithReason(offer, OfferCancellationReason.PHUNK_TRANSFER_FAILURE);
        }
        
        startOfWeekToWeeklyAllowanceMapping[getStartOfCurrentWeek()] -= offer.priceFlywheelIsWillingToPay;
        _safeTransferETHWithFallback(offer.seller, offer.priceFlywheelIsWillingToPay);
        offer.status = OfferStatus.ORACLE_REQUEST_FULFILLED;
        
        emit PriceEstimateFulfilled(offer, requestId, offer.priceFlywheelIsWillingToPay, offer.minAppraisalConsideredValid);
    }

    function depositEthWithWeeklySpendingLimits(uint[] calldata weekStarts, uint[] calldata weeklyLimits) public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        uint totalOfAllLimits;
        
        for (uint i; i < weeklyLimits.length; ++i) {
            uint weekStart = weekStarts[i];

            require(weekStart >= getStartOfWeek(block.timestamp), "Can't add spend to the past");
            require(timestampIsAStartOfWeek(weekStart), "Week start must be a start of week");
            
            startOfWeekToWeeklyAllowanceMapping[weekStart] += weeklyLimits[i];
            totalOfAllLimits += weeklyLimits[i];
        }
        
        emit EthDeposited(weekStarts, weeklyLimits);
        
        require(msg.value == totalOfAllLimits, "Total of all limits must equal the amount of ETH sent");
    }
    
    function withdrawEthFromWeeklySpendingLimits(uint[] calldata weekStarts, uint[] calldata amounts) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint totalToWithdraw;
        
        for (uint i; i < weekStarts.length; ++i) {
            startOfWeekToWeeklyAllowanceMapping[weekStarts[i]] -= amounts[i];
            
            totalToWithdraw += amounts[i];
        }
        
        _safeTransferETHWithFallback(addressRegistry.treasuryWalletAddress, totalToWithdraw);
        
        emit EthWithdrawn(weekStarts, amounts);
    }
    
    function getStartOfCurrentWeek() public view returns (uint) {
        return getStartOfWeek(block.timestamp);
    }
    
    function timestampIsAStartOfWeek(uint timestamp) public pure returns (bool) {
        return timestamp == getStartOfWeek(timestamp);
    }
    
    function getStartOfWeek(uint currentTime) public pure returns (uint) {
        (,,, uint hour, uint minute, uint second) = currentTime.timestampToDateTime();
        uint dayOfWeekIndex = currentTime.getDayOfWeek();
        
        return currentTime.
               subDays(dayOfWeekIndex - 1).
               subHours(hour).
               subMinutes(minute).
               subSeconds(second);
    }
    
   function getWethBalanceInSushiPool() public view returns (uint) {
        return IERC20(addressRegistry.wethContractAddress).balanceOf(addressRegistry.sushiSwapPhunkERC20WethPoolAddress);
    }
    
    function getPhunkERC20BalanceInSushiPool() public view returns (uint) {
        return IERC20(addressRegistry.phunkERC20Address).balanceOf(addressRegistry.sushiSwapPhunkERC20WethPoolAddress);
    }
    
    function grantAdminRole(address[] calldata users) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i; i < users.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, users[i]);
        }
    }
    
    function revokeAdminRole(address[] calldata users) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i; i < users.length; i++) {
            _revokeRole(DEFAULT_ADMIN_ROLE, users[i]);
        }
    }
    
    function grantTesterRole(address[] calldata users) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i; i < users.length; i++) {
            _grantRole(TESTER_ROLE, users[i]);
        }
    }
    
    function revokeTesterRole(address[] calldata users) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i; i < users.length; i++) {
            _revokeRole(TESTER_ROLE, users[i]);
        }
    }
    
    function setAddressRegistry(AddressRegistry calldata _addressRegistry) external onlyRole(DEFAULT_ADMIN_ROLE) {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        
        _revokeRole(DEFAULT_ADMIN_ROLE, addressRegistry.treasuryWalletAddress);
        linkToken.approve(addressRegistry.treasuryWalletAddress, 0);
        
        addressRegistry = _addressRegistry;
        
        linkToken.approve(addressRegistry.treasuryWalletAddress, 2 ** 256 - 1);
        _grantRole(DEFAULT_ADMIN_ROLE, addressRegistry.treasuryWalletAddress);

        emit AddressRegistryUpdated(addressRegistry);
    }
    
    function setContractConfig(ContractConfig calldata _contractConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractConfig = _contractConfig;
        emit ContractConfigUpdated(contractConfig);
    }
    
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(addressRegistry.wethContractAddress).deposit{ value: amount }();
            IERC20(addressRegistry.wethContractAddress).transfer(to, amount);
        }
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = payable(to).call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
    
    function failsafeWithdraw(uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount >= address(this).balance, "Insufficient balance");
        _safeTransferETHWithFallback(addressRegistry.treasuryWalletAddress, amount);
        emit FailsafeWithdrawal(amount);
    }
    
    function getOffers(uint limit, uint offset) external view returns (Offer[] memory) {
        Offer[] memory _offers = new Offer[](limit);
        for (uint i; i < limit; i++) {
            _offers[i] = offers[offset + i];
        }
        return offers;
    }
}