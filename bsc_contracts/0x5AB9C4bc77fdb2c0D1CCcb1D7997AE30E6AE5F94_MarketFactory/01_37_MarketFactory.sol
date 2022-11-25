pragma solidity ^0.8.0;

import "../interfaces/ITeamNFT.sol";

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../market/BaseMarket.sol";
import "./IMarketFactory.sol";
import "../creator/MarketCreator.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error MarketFactory_InvalidPoolType();
error MarketFactory_UnknownCreator();
error MarketFactory_NotCreatorOwner();
error MarketFactory_DontHaveCreatorRole();
error MarketFactory_CreatorExisted();
error MarketFactory_CreatorNotExisted();

contract MarketFactory is
    IMarketFactory,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    uint256 private constant PERCENT_BASE = 1000;

    uint256 public platformFee;
    address public platformFeeReceiver;

    struct EventData {
        address poolAddress;
    }

    UpgradeableBeacon[] public upgradeableMarketBeacons;
    UpgradeableBeacon public upgradeableMarketCreatorBeacon;

    mapping(uint256 => EventData) public eventData;
    uint256 public eventCount;

    mapping(uint256 => address) public creators;
    // level of creator
    // benificial fee level
    uint256[] FEE_LEVELS;
    mapping(address => uint256) public creatorLevels;

    event EventDeployed(EventData _event);
    event CreatorAdded(address creatorAddress);

    function initialize(address[] memory markets_, address marketCreator_)
        public
        initializer
    {
        __AccessControl_init();
        __Ownable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < markets_.length; i++) {
            upgradeableMarketBeacons.push(new UpgradeableBeacon(markets_[i]));
        }
        upgradeableMarketCreatorBeacon = new UpgradeableBeacon(marketCreator_);

        // add default creator
        addCreator(1, msg.sender);

        // init default FEE_LEVELS
        FEE_LEVELS = [
            0,
            500,
            550,
            600,
            650,
            700,
            750,
            800,
            850,
            900,
            950,
            1000
        ];
    }

    function upgradeMarket(uint256 idx, address newLogicImpl) public onlyOwner {
        require(idx < upgradeableMarketBeacons.length, "Out of index");
        upgradeableMarketBeacons[idx].upgradeTo(newLogicImpl);
    }

    function addMarketType(address newLogicImpl) public onlyOwner {
        upgradeableMarketBeacons.push(new UpgradeableBeacon(newLogicImpl));
    }

    function upgradeMarketCreator(address newLogicImpl) public onlyOwner {
        upgradeableMarketCreatorBeacon.upgradeTo(newLogicImpl);
    }

    function createPoolAndInit(
        uint256 marketTypeIdx,
        uint256 creatorId,
        BaseMarket.InitData calldata _initData
    ) public {
        address creatorContract = creators[creatorId];
        if (creatorContract == address(0)) {
            revert MarketFactory_UnknownCreator();
        }

        if (!MarketCreator(creatorContract).hasControllerRole(msg.sender)) {
            revert MarketFactory_DontHaveCreatorRole();
        }

        if (marketTypeIdx > upgradeableMarketBeacons.length)
            revert MarketFactory_InvalidPoolType();
        // setup pool
        address newPool;
        BeaconProxy poolInstance = new BeaconProxy(
            address(upgradeableMarketBeacons[marketTypeIdx]),
            abi.encodeWithSelector(
                BaseMarket(address(0)).initialize.selector,
                address(this),
                creatorContract
            )
        );
        newPool = address(poolInstance);
        BaseMarket(newPool).setInitData(_initData);
        // Then fill init
        uint256 initLiquid = BaseMarket(newPool).initLiquid();
        if (initLiquid > 0) {
            IERC20(_initData.acceptedToken).transferFrom(
                msg.sender,
                newPool,
                initLiquid
            );
            BaseMarket(newPool).clearInitLiquid();
        }
        // BaseMarket(newPool).setMarketCreator(creatorContract);

        // setup partner

        EventData memory _event = EventData({poolAddress: newPool});
        // creatorOf[newPool] = msg.sender;
        eventData[eventCount] = _event;
        emit EventDeployed(_event);
        eventCount++;
    }

    function addCreator(uint256 creatorId, address creatorOwner)
        public
        onlyOwner
    {
        if (creators[creatorId] != address(0)) {
            revert MarketFactory_CreatorExisted();
        }
        // setup partner
        BeaconProxy marketCreator = new BeaconProxy(
            address(upgradeableMarketCreatorBeacon),
            abi.encodeWithSelector(
                MarketCreator(address(0)).initialize.selector,
                creatorOwner
            )
        );

        address newMarketCreatorContract = address(marketCreator);
        creators[creatorId] = newMarketCreatorContract;

        emit CreatorAdded(newMarketCreatorContract);
    }

    function updateCreatorLevel(uint256 creatorId, uint256 level)
        external
        onlyOwner
    {
        require(level < FEE_LEVELS.length, "Out of index");
        if (creators[creatorId] == address(0)) {
            revert MarketFactory_CreatorNotExisted();
        }
        creatorLevels[creators[creatorId]] = level;
    }

    function setPlatformFee(uint256 _platformFee, address _platformFeeReceiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        platformFee = _platformFee;
        platformFeeReceiver = _platformFeeReceiver;
    }

    function getPlatformFee() external view returns (uint256) {
        return platformFee;
    }

    function getPlatformFeeReceiver() external view returns (address) {
        return platformFeeReceiver;
    }

    function calcSplit(address pool, uint256 amount)
        external
        view
        returns (uint256, uint256)
    {
        return _calcSplit(pool, amount);
    }

    function _calcSplit(address pool, uint256 amount)
        internal
        view
        returns (uint256 eventSplit, uint256 platformSplit)
    {
        // get creator from market
        uint256 level = creatorLevels[BaseMarket(pool).marketCreator()];
        uint256 feeLevel = FEE_LEVELS[level];

        eventSplit = (amount * feeLevel) / PERCENT_BASE;
        platformSplit = (amount * (PERCENT_BASE - feeLevel)) / PERCENT_BASE;
    }

    function calFee(
        address pool,
        uint256 marketFee,
        uint256 amountPay
    )
        external
        view
        returns (uint256 marketFeeAmount, uint256 platformFeeAmount)
    {
        marketFeeAmount = 0;
        platformFeeAmount = 0;
        uint256 platformSplit = 0;
        uint256 valueEventFee = (amountPay * marketFee) / PERCENT_BASE;
        (marketFeeAmount, platformSplit) = _calcSplit(pool, valueEventFee);
        if (platformFee > 0) {
            platformFeeAmount =
                platformSplit +
                (amountPay * platformFee) /
                PERCENT_BASE;
        }
    }
}