//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interfaces/ITeamNFT.sol";
import "../interfaces/IMarket.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../price_strategy/AMMPriceStrategyV3.sol";
import "../factory/IMarketFactory.sol";
import "../interfaces/IMarketCreator.sol";

error Error_TeamPause(uint256 teamId);
error Error_TeamEliminated(uint256 teamId);
error Error_EventStarted();
error Error_EventNotEnd();
error Error_EventEnded();
error Error_AmountPayInvalid();
error Error_InsufficientFund(uint256 teamId, uint256 amount);
error Error_AmountNFTInvalid(address seller, uint256 amount);
error Error_MarketInitialized();
error Error_MarketNotEnded();
error Error_MarketNotOpen();
error Error_MarketEnded();
error Error_NotWinner();
error Error_NoReward();
error Error_NotRefundable();
error Error_InsufficientRewardFund(uint256 teamId, uint256 amount);
error Error_TeamOutOfRange();
error Error_NoTeamLeft();
error Error_BuyAmountInvalid();
error Error_MarketPause(uint256 poolId);
error Error_RefPriceInvalid();
error Error_InvalidLength();
error Error_InvalidTeamStatus();
error Error_InvalidGroup();
error Error_MarketLock();
error Error_MarketInactive();
error Error_NotAuthorized();
error Error_InitLiquidNotFill();
error Error_InitLiquidFilled();
error Error_UnsetableStatus();
error Error_NotClaimable();

contract BaseMarket is IMarket, Initializable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    event BuyTeam(address buyer, uint256 teamId, uint256 amount, uint256 amountPay);
    event SellTeam(address seller, uint256 teamId, uint256 amount, uint256 amountPay);
    event ClaimReward(address user, uint256 teamId, uint256 amountPay);
    event ClaimRefund(address user, uint256 amountPay);
    event EliminateTeam(uint256 teamId);

    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant PERCENT_BASE = 1000;


    enum MarketStatus {ACTIVE, PENDING, LOCK, ENDED, REFUND}

    mapping(uint256 => TeamData) internal allTeamData;
    mapping(uint256 => mapping(address => uint256)) internal userShare;

    // token accept to buy nft
    IERC20Upgradeable public acceptedToken;

    MarketStatus public marketStatus;
    uint256 public maxTeam;
    uint256 public openTime;
    uint256 public startTime;
    uint256 public eventFee;
    uint256 public refPrice;
    uint256 public prizeFee;
    uint256 public prizeFeeAmount;
    uint256 public sellTax;
    address public marketFactory;

    address public marketCreator;
    address public createBy;

    // liquid for first share of each outcome
    uint256 public initLiquid;
    uint256 public initShares;
    // winner state
    uint256 public winner;
    uint256 public winnerRewardPerNFT;
    uint256 public winnerShares;
    uint256 public winnerLiquid;

    event MarketResolved();
    event MarketCanceled();
    event EndGroup(uint256 groupId);
    event UpdatePauseGroup(uint256 groupId);

    function requireFactory_() internal view {
        if (marketFactory != msg.sender) {
            revert Error_NotAuthorized(); 
        }
    }
    
    function requireController_() internal view {
        if (!IMarketCreator(marketCreator).hasControllerRole(msg.sender)) {
            revert Error_NotAuthorized(); 
        }
    }

    function requireInRange_(uint256 id) internal view {
        if (id <= 0 || id > maxTeam) {
            revert Error_TeamOutOfRange();
        }
    }

    function requireMarketNotEnded_() internal view {
        if (marketStatus == MarketStatus.REFUND || marketStatus == MarketStatus.ENDED) {
            revert Error_MarketEnded();
        }
    }

    function requireMarketActive_() internal view virtual {
        if (initLiquid > 0) {
            revert Error_InitLiquidNotFill();
        }
        if (block.timestamp < openTime) {
            revert Error_MarketNotOpen();
        }
        if (marketStatus != MarketStatus.ACTIVE) {
            revert Error_MarketInactive();
        }
    }

    function requireMarketEnded_() internal view virtual {
        if (marketStatus != MarketStatus.ENDED) {
            revert Error_MarketNotEnded();
        }
    }

    function requireMarketRefund_() internal view virtual {
        if (marketStatus != MarketStatus.REFUND) {
            revert Error_NotRefundable();
        }
    }

    function requireOutcomeActive_(uint256 id) internal view {
        TeamData memory data = allTeamData[id];
        if (data.pause || data.eliminated) {
            revert Error_TeamPause(id);
        }        
    }

    function initialize(address factory, address marketCreator_) initializer public {
        __ReentrancyGuard_init();
        __AccessControl_init();
        //__Pausable_init();

        marketFactory = factory;
        _setupRole(DEFAULT_ADMIN_ROLE, factory);

        // creator owner
        marketCreator = marketCreator_;
        // address marketCreatorAddress = IMarketCreator(marketCreator).creatorOnwer();
        // _setupRole(DEFAULT_ADMIN_ROLE, marketCreatorAddress);

        // creator by
        createBy = msg.sender;
    }

    function setInitData(InitData calldata _initData) external {
        // requireController_();
        requireFactory_(); // allow market create through proxy only

        if (_initData.refPrice <= 0) {
            revert Error_RefPriceInvalid();
        }

        if (refPrice > 0) {
            revert Error_MarketInitialized();
        }

        maxTeam = _initData.teamCount;
        refPrice = _initData.refPrice;
        openTime = _initData.openTime;
        startTime = _initData.startTime;
        prizeFee = _initData.prizeFee;
        acceptedToken = IERC20Upgradeable(_initData.acceptedToken);
        sellTax = _initData.sellTax;
        eventFee = _initData.eventFee;
        initShares = _initData.initShares;

        // init strength
        uint256 totalStrength;
        for (uint256 i = 1; i <= maxTeam; i++) {
            allTeamData[i].id = i;
            allTeamData[i].strength = _initData.strengthData[i - 1];
            totalStrength +=_initData.strengthData[i - 1];
        }

        // system buy first shares for each outcome
        if (initShares > 0) {
            uint256 decimals = 10 ** IERC20Metadata(address(acceptedToken)).decimals();
            for (uint256 i = 1; i <= maxTeam; i++) {
                if (allTeamData[i].shares == 0) {
                    allTeamData[i].liquid = AMMPriceStrategyV3.openPrice(_buildPriceParams(i, 1)) * initShares;
                    initLiquid = allTeamData[i].liquid + initLiquid;
                    allTeamData[i].shares = initShares;
                }
            }
        }
    }

    function updateTime(uint256 openTime_, uint256 startTime_) external {
        requireController_();
        if (openTime_ > 0) openTime = openTime_;
        if (startTime_ > 0) startTime = startTime_;
    }

    /* Anyone can fill init liquid */
    function fillInitLiquid() external {
        if (initLiquid == 0) revert Error_InitLiquidFilled();
        acceptedToken.safeTransferFrom(msg.sender, address(this), initLiquid);
        initLiquid = 0;
    }

    /* Factory fill initliquid */
    function clearInitLiquid() external {
        requireFactory_();
        initLiquid = 0;
    }

    function setStatus(MarketStatus status) external {
        requireController_();
        requireMarketNotEnded_();
        // cannot set status for REFUND & END
        if (status >= MarketStatus.ENDED) revert Error_UnsetableStatus();
        marketStatus = status;
    }

    function getStatus() public view virtual returns (MarketStatus status){
        if (initLiquid > 0 || block.timestamp < openTime) return MarketStatus.PENDING;
        return marketStatus;
    }

    //END: set contract components
    function _buildPriceParams(uint256 teamId, uint256 amount) internal view returns (IPriceStrategy3.PriceParams memory priceParams) {
        (uint256 totalStrength, uint256 totalShares, uint256 totalLiquid, uint256 totalLiquidReserved, uint256 num_teams) = getTotalData();
        TeamData memory team = allTeamData[teamId];
        uint256 decimal = 10 ** IERC20Metadata(address(acceptedToken)).decimals();

        priceParams = IPriceStrategy3.PriceParams({
            //        teamId : teamId,
            DECIMAL : decimal,
            TOTAL_TEAMS : maxTeam,
            //        LOCK_RATIO : nftLockPercent,
            REF_PRICE : refPrice,
            num_of_teams : num_teams,
            totalShares : totalShares,
            shares : team.shares,

            liquid : team.liquid,
            liquidReserved : team.liquidReserved,
            totalLiquid : totalLiquid,
            totalLiquidReserved : totalLiquidReserved,

            totalStrength : totalStrength,
            strength : team.strength,
            amount : amount
        });
    }

    function getTotalData() public view returns (uint256 totalStrength, uint256 totalShares, uint256 totalLiquid, uint256 totalLiquidReserved, uint256 num_teams){
        
        for (uint256 i = 1; i <= maxTeam; i++) {
            TeamData memory data = allTeamData[i];
            if (!data.eliminated) {
                num_teams += 1;
                totalStrength += data.strength;
                totalShares += data.shares;
                totalLiquid += data.liquid;
                totalLiquidReserved += data.liquidReserved;
            }
        }
    }

    function buyPrice(uint256 teamId, uint256 amount) public view returns (uint256) {
        IPriceStrategy3.PriceParams memory _priceParams = _buildPriceParams (teamId, amount);
        return AMMPriceStrategyV3.ammPriceBuy(_priceParams);
    }

    function sellPrice(uint256 teamId, uint256 amount) public view returns (uint256) {
        IPriceStrategy3.PriceParams memory _priceParams = _buildPriceParams (teamId, amount);
        return AMMPriceStrategyV3.ammPriceSell(_priceParams);
    }


    function getAllTeam() external view returns (TeamData[] memory){
        TeamData[] memory data = new TeamData[](maxTeam);
        for (uint256 i = 1; i <= maxTeam; i++) {
            TeamData storage team = allTeamData[i];
            data[i - 1] = team;
        }
        return data;
    }

    function calFee(address buyer, uint256 amountPay) public view returns (uint256 eventFeeAmount, uint256 platformFeeAmount){
        return IMarketFactory(marketFactory).calFee(address(this), eventFee, amountPay);
    }

    function claimReward() nonReentrant public {
        requireMarketEnded_();
        
        if (userShare[winner][msg.sender] == 0) {
            revert Error_NotClaimable();
        }

        uint256 amountPay = winnerRewardPerNFT * userShare[winner][msg.sender];
        if (amountPay > 0) {
            userShare[winner][msg.sender] = 0;
            acceptedToken.safeTransfer(msg.sender, amountPay);
            emit ClaimReward(msg.sender, winner, amountPay);
        }
    }

    function claimRefund() nonReentrant public {
        requireMarketRefund_();

        uint256 refundValue;
        for (uint256 i = 1; i <= maxTeam; i++) {
            if (userShare[i][msg.sender] > 0 && userShare[i][msg.sender] <= allTeamData[i].shares) {
                uint256 liquidRefund = allTeamData[i].liquid  / allTeamData[i].shares * userShare[i][msg.sender];
                uint256 liquidReserveRefund = allTeamData[i].liquidReserved / allTeamData[i].shares * userShare[i][msg.sender];
                refundValue += (liquidRefund + liquidReserveRefund);
                allTeamData[i].liquid -= liquidRefund;
                allTeamData[i].liquidReserved -= liquidReserveRefund;
                allTeamData[i].shares -= userShare[i][msg.sender];
                userShare[i][msg.sender] = 0;
            }
        }
    
        if (refundValue == 0) {
            revert Error_NotRefundable();
        }
        acceptedToken.safeTransfer(msg.sender, refundValue);
        emit ClaimRefund(msg.sender, refundValue);
    }

    function refundMarket() public {
        requireController_();

        if (marketStatus != MarketStatus.ACTIVE) {
            revert Error_MarketEnded();
        }
        marketStatus = MarketStatus.REFUND;

        emit MarketCanceled();
    }

    function withdrawToken(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        acceptedToken.transfer(msg.sender, amount);
    }

    function getAllPositions(address user) external view returns (uint256[] memory){
        uint256[] memory userShares = new uint256[](maxTeam);
        for (uint256 i = 1; i <= maxTeam; i++) {
            uint256 share = userShare[i][user];
            userShares[i - 1] = share;
        }
        return userShares;
    }

    function platformFee() external view returns (uint256 fee) {
        fee = IMarketFactory(marketFactory).getPlatformFee();
    }

    /// BUY - SELL

    // buy sell function
    function buyTeam(
        uint256 teamId,
        uint256 amount,
        uint256 maxAmountPay,
        uint256 partnerId
    ) external nonReentrant {
        requireMarketActive_();
        requireInRange_(teamId);
        requireOutcomeActive_(teamId);

        uint256 amountPay = buyPrice(teamId, amount);

        (uint256 eventFeeAmount, uint256 platformFeeAmount) = calFee(
            msg.sender,
            amountPay
        );

        uint256 totalAmountPay = amountPay + eventFeeAmount + platformFeeAmount;

        if (totalAmountPay > maxAmountPay) {
            revert Error_BuyAmountInvalid();
        }

        acceptedToken.safeTransferFrom(msg.sender, address(this), amountPay);

        if (eventFeeAmount > 0) {
            address eventFeeBeneficiary = getBeneficiary(partnerId);
            acceptedToken.safeTransferFrom(
                msg.sender,
                eventFeeBeneficiary,
                eventFeeAmount
            );
        }
        if (platformFeeAmount > 0) {
            acceptedToken.safeTransferFrom(
                msg.sender,
                IMarketFactory(marketFactory).getPlatformFeeReceiver(),
                platformFeeAmount
            );
        }

        TeamData storage data = allTeamData[teamId];

        userShare[teamId][msg.sender] += amount;
        data.shares += amount;
        data.liquid += amountPay;

        emit BuyTeam(msg.sender, teamId, amount, amountPay);
    }

    function getSellTax() public view virtual returns (uint256 _sellTax) {
        _sellTax = sellTax;
    }

    function getBeneficiary(uint256 partnerId) public view returns(address beneficiary) {
        beneficiary = IMarketCreator(marketCreator).getBeneficiary(partnerId);        
    }

    function sellTeam(
        uint256 teamId,
        uint256 amount,
        uint256 minAmountGet,
        uint256 partnerId
    ) external nonReentrant {
        requireMarketActive_();
        requireInRange_(teamId);
        requireOutcomeActive_(teamId);

        uint256 amountPay = sellPrice(teamId, amount);

        TeamData storage data = allTeamData[teamId];

        if (amountPay <= 0 || amountPay > data.liquid) {
            revert Error_InsufficientFund(teamId, amount);
        }

        if (userShare[teamId][msg.sender] < amount) {
            revert Error_AmountNFTInvalid(msg.sender, amount);
        }

        (uint256 eventFeeAmount, uint256 platformFeeAmount) = calFee(
            msg.sender,
            amountPay
        );

        uint256 sellTaxAmount = (amountPay * getSellTax()) / PERCENT_BASE;
        uint256 realAmountSell = amountPay -
            eventFeeAmount -
            platformFeeAmount -
            sellTaxAmount;

        if (minAmountGet > realAmountSell) {
            revert Error_AmountPayInvalid();
        }

        userShare[teamId][msg.sender] -= amount;

        data.shares = data.shares - amount;
        data.liquid = data.liquid - amountPay;
        data.liquidReserved += sellTaxAmount;

        if (eventFeeAmount > 0) {
            address eventFeeBeneficiary = getBeneficiary(partnerId);
            acceptedToken.safeTransfer(eventFeeBeneficiary, eventFeeAmount);
        }
        if (platformFeeAmount > 0) {
            acceptedToken.safeTransfer(
                IMarketFactory(marketFactory).getPlatformFeeReceiver(),
                platformFeeAmount
            );
        }
        acceptedToken.safeTransfer(msg.sender, realAmountSell);

        emit SellTeam(msg.sender, teamId, amount, amountPay);
    }


    function resolveMarket(uint256 _winner) external virtual {
        requireController_();
        requireMarketNotEnded_();
        requireInRange_(_winner);

        TeamData memory data = allTeamData[_winner];

        if (data.eliminated) {
            revert Error_TeamEliminated(_winner);
        }

        winner = _winner;
        marketStatus = MarketStatus.ENDED;

        winnerShares = data.shares;

        (
            uint256 totalStrength,
            uint256 totalShares,
            uint256 totalLiquid,
            uint256 totalLiquidReserved,
            uint256 num_teams
        ) = getTotalData();

        winnerLiquid = totalLiquid + totalLiquidReserved;

        // remove all value from other pools
        for (uint256 i = 1; i <= maxTeam; i++) {
            if (i == winner) {
                allTeamData[i].liquid = winnerLiquid;
                allTeamData[i].liquidReserved = 0;
            } else {
                allTeamData[i].liquid = 0;
                allTeamData[i].liquidReserved = 0;
                allTeamData[i].eliminated = true;
            }
        }

        updateEndGame_();
    }

    function updateEndGame_() internal {
        prizeFeeAmount = (winnerLiquid * prizeFee) / BaseMarket.PERCENT_BASE;
        uint256 amountRemain = winnerLiquid - prizeFeeAmount;
        winnerRewardPerNFT = amountRemain / winnerShares;
        prizeFeeAmount += winnerRewardPerNFT * initShares; // init shares for system

        // transfer fee
        (uint256 eventSplit, uint256 platformSplit) = IMarketFactory(
            marketFactory
        ).calcSplit(address(this), prizeFeeAmount);
        if (eventSplit > 0) {
            acceptedToken.safeTransfer(getBeneficiary(0), eventSplit);
        }
        if (platformSplit > 0) {
            acceptedToken.safeTransfer(
                IMarketFactory(marketFactory).getPlatformFeeReceiver(),
                platformSplit
            );
        }

        emit MarketResolved();
    }
}