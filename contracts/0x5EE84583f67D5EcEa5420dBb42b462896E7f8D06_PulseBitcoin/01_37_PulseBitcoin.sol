/*

 /$$$$$$$            /$$                     /$$$$$$$  /$$   /$$                         /$$          
| $$__  $$          | $$                    | $$__  $$|__/  | $$                        |__/          
| $$  \ $$ /$$   /$$| $$  /$$$$$$$  /$$$$$$ | $$  \ $$ /$$ /$$$$$$    /$$$$$$$  /$$$$$$  /$$ /$$$$$$$ 
| $$$$$$$/| $$  | $$| $$ /$$_____/ /$$__  $$| $$$$$$$ | $$|_  $$_/   /$$_____/ /$$__  $$| $$| $$__  $$
| $$____/ | $$  | $$| $$|  $$$$$$ | $$$$$$$$| $$__  $$| $$  | $$    | $$      | $$  \ $$| $$| $$  \ $$
| $$      | $$  | $$| $$ \____  $$| $$_____/| $$  \ $$| $$  | $$ /$$| $$      | $$  | $$| $$| $$  | $$
| $$      |  $$$$$$/| $$ /$$$$$$$/|  $$$$$$$| $$$$$$$/| $$  |  $$$$/|  $$$$$$$|  $$$$$$/| $$| $$  | $$
|__/       \______/ |__/|_______/  \_______/|_______/ |__/   \___/   \_______/ \______/ |__/|__/  |__/
                                                                                                                                                                                     
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./tokens/ASIC.sol";
import "./tokens/ATM.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

import "./lib/TickMath.sol";
import "./lib/FullMath.sol";

/// @title PulseBitcoin smart contract
/// @author 01101000 01100101 01111000 01101001 01101110 01100110 01101111 00100000 00100110 00100000 01101011 01101111 01100100 01100101
/// @notice PulseBitcoin is a premier store of value that is mined through the process of a 30 day timelock deposit of ASIC.
contract PulseBitcoin is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // ASIC Token
    ASIC private immutable _asic;
    address public asic;

    // ASIC Token Miner NFT
    ATM private immutable _atm;
    address public atm;

    // constants
    uint256 private immutable LAUNCH_TIME;
    uint8 private constant TWAP_INTERVAL = 15;
    uint256 private constant MAX_MINER_SIZE = 140 * 1e6 * 1e12;
    uint256 private constant MIN_MINING_DURATION = 30;
    uint256 private constant WITHDRAW_GRACE_PERIOD = 30;
    uint256 private constant ATM_EVENT_LENGTH = 30;
    uint256 private constant DAYS_FOR_PENALTY = MIN_MINING_DURATION + WITHDRAW_GRACE_PERIOD;
    uint256 private constant SCALE_FACTOR = 1e6;
    uint256 private constant MIN_MINING_BITOSHIS = 1 * 1e12;
    uint256 private constant DECIMAL_RESOLUTION = 1e18;
    uint256 private constant TOTAL_MINTABLE_SUPPLY = 21 * 1e6 * 1e12; // 21 million

    // address constants
    address private constant WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address private constant USDC_ADDRESS = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private constant USDT_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address private constant DAI_ADDRESS = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address private constant HEX_ADDRESS = address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
    address private constant HDRN_ADDRESS = address(0x3819f64f282bf135d62168C1e513280dAF905e06);
    address private constant DEAD_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    address payable private constant BA_ADDRESS = payable(address(0x7686640F09123394Cd8Dc3032e9927767aD89344));

    // variables
    Counters.Counter private _globalMinerId;
    uint256 public miningRate;
    uint256 public miningFee;
    uint256 public totalpSatoshisMined;
    uint256 public previousHalvingThresold;
    uint256 public currentHalvingThreshold;
    uint256 public numOfHalvings;
    uint256 public atmMultiplier;

    // mappings
    mapping(address => MinerStore[]) public minerList;
    mapping(uint256 => ATMStore) public atmList;
    mapping(address => address) private _uniswapPools;

    // structs
    struct MinerStore {
        uint128 bitoshisMiner;
        uint128 bitoshisReturned;
        uint96 pSatoshisMined;
        uint96 bitoshisBurned;
        uint40 minerId;
        uint24 day;
    }

    struct MinerCache {
        uint256 _bitoshisMiner;
        uint256 _bitoshisReturned;
        uint256 _pSatoshisMined;
        uint256 _bitoshisBurned;
        uint256 _minerId;
        uint256 _day;
    }

    struct ATMStore {
        uint248 points;
        bool isActive;
    }

    struct ATMCache {
        uint256 _points;
        bool _isActive;
    }

    // errors
    error ATMEventIsOver(uint256 eventLength, uint256 currentDay);
    error InvalidToken();
    error ATMPointsToSmall();
    error NotOwnerOfATM();
    error ATMNotActive();
    error AsicMinerToLarge();
    error CannotEndATMWithinEventPeriod(uint256 eventLength, uint256 currentDay);
    error InsufficientBalance(uint256 available, uint256 required);
    error InvalidAmount(uint256 sent, uint256 minRequired);
    error InvalidMinerId(uint256 sentId, uint256 expectedId);
    error MinerListEmpty();
    error InvalidMinerIndex(uint256 sentIndex, uint256 lastIndex);
    error CannotEndMinerEarly(uint256 servedDays, uint256 requiredDays);

    // events
    event MinerStart(uint256 data0, uint256 data1, address indexed account, uint40 indexed minerId);
    event MinerEnd(uint256 data0, uint256 data1, address indexed accountant, uint40 indexed minerId);
    event ATMStart(uint256 data0, address indexed account, uint40 indexed atmId, address indexed tokenAddress);
    event ATMEnd(uint256 data0, address indexed account, uint40 indexed atmId);

    constructor() ERC20("PulseBitcoin", "PLSB") {
        asic = address(new ASIC());
        _asic = ASIC(asic);

        atm = address(new ATM());
        _atm = ATM(atm);

        LAUNCH_TIME = block.timestamp;
        previousHalvingThresold = 0; // initialize @ 0
        currentHalvingThreshold = TOTAL_MINTABLE_SUPPLY / 2; // initialize @ 10.5 Million
        atmMultiplier = 1; // initialize @ 1x
        miningRate = (75 * DECIMAL_RESOLUTION) / 1000; // initialize @ 7.5% Mine Rate
        miningFee = (25 * DECIMAL_RESOLUTION) / 10000; // initialize @ 0.25% Burn Rate

        // uniswap mappings
        _uniswapPools[USDT_ADDRESS] = address(0x3416cF6C708Da44DB2624D63ea0AAef7113527C6); // USDT/USDC V3 0.01%
        _uniswapPools[DAI_ADDRESS] = address(0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168); // DAI/USDC V3 0.01%
        _uniswapPools[WETH_ADDRESS] = address(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640); // WETH/USDC V3 0.05%
        _uniswapPools[HEX_ADDRESS] = address(0x69D91B94f0AaF8e8A2586909fA77A5c2c89818d5); // HEX/USDC  V3 0.3%
        _uniswapPools[HDRN_ADDRESS] = address(0xE859041c9C6D70177f83DE991B9d757E13CEA26E); // HDRN/USDC V3 1.0%
    }

    /// @dev Overrides the ERC-20 decimals function
    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    /// @dev Public getter function for _currentDay
    function currentDay() external view returns (uint256) {
        return _currentDay();
    }

    /// @dev Public function to return the number of active miners
    /// @param minerAddress The address of the miner owner
    function minerCount(address minerAddress) external view returns (uint256) {
        return minerList[minerAddress].length;
    }

    /// @dev Calculate the payout and fee amounts for a miner instance
    /// @param bitoshis The size of the miner instance (in bitoshis)
    /// @return pSatoshisMine The PLSB (in pSatoshis) mined from the miner instance
    /// @return bitoshisBurn The ASIC (in bitoshis) burned from the miner instance
    /// @return bitoshisReturn The ASIC (in bitoshis) returned from the miner instance
    /// @return isHalving Does the miner instance cause a halving event
    function calcPayoutAndFee(uint256 bitoshis)
        public
        view
        returns (
            uint256 pSatoshisMine,
            uint256 bitoshisBurn,
            uint256 bitoshisReturn,
            bool isHalving
        )
    {
        if (bitoshis > MAX_MINER_SIZE) {
            revert AsicMinerToLarge();
        }

        pSatoshisMine = (bitoshis * miningRate) / DECIMAL_RESOLUTION;

        // Halving Event
        if (totalpSatoshisMined + pSatoshisMine > currentHalvingThreshold) {
            isHalving = true;
            pSatoshisMine =
                (((((pSatoshisMine - ((totalpSatoshisMined + pSatoshisMine) - currentHalvingThreshold)) * bitoshis) /
                    pSatoshisMine) * miningRate) / DECIMAL_RESOLUTION) +
                (((bitoshis -
                    (((pSatoshisMine - ((totalpSatoshisMined + pSatoshisMine) - currentHalvingThreshold)) * bitoshis) /
                        pSatoshisMine)) * (miningRate / 2)) / DECIMAL_RESOLUTION);
            bitoshisBurn =
                (((((pSatoshisMine - ((totalpSatoshisMined + pSatoshisMine) - currentHalvingThreshold)) * bitoshis) /
                    pSatoshisMine) * miningFee) / DECIMAL_RESOLUTION) +
                (((bitoshis -
                    (((pSatoshisMine - ((totalpSatoshisMined + pSatoshisMine) - currentHalvingThreshold)) * bitoshis) /
                        pSatoshisMine)) * (miningFee / 2)) / DECIMAL_RESOLUTION);
        } else {
            bitoshisBurn = (bitoshis * miningFee) / DECIMAL_RESOLUTION;
        }
        bitoshisReturn = bitoshis - bitoshisBurn;
        return (pSatoshisMine, bitoshisBurn, bitoshisReturn, isHalving);
    }

    /// @dev Start PulseBitcoin (PLSB) time lock mining instance
    /// @param bitoshisMiner The amount of ASIC (in bitoshis) that are used to create a miner instance
    function minerStart(uint256 bitoshisMiner) external nonReentrant {
        // Validations
        if (bitoshisMiner < MIN_MINING_BITOSHIS) {
            revert InvalidAmount({sent: bitoshisMiner, minRequired: MIN_MINING_BITOSHIS});
        }

        if (bitoshisMiner > _asic.balanceOf(msg.sender))
            revert InsufficientBalance({available: _asic.balanceOf(msg.sender), required: bitoshisMiner});

        (uint256 pSatoshisMined, uint256 bitoshisBurned, uint256 bitoshisReturned, bool isHalving) = calcPayoutAndFee(
            bitoshisMiner
        );

        _asic.burn(msg.sender, bitoshisMiner);

        totalpSatoshisMined += pSatoshisMined;

        // halving event
        if (isHalving) {
            uint256 newPreviousHalvingThresold = currentHalvingThreshold;
            currentHalvingThreshold =
                currentHalvingThreshold +
                ((currentHalvingThreshold - previousHalvingThresold) / 2);
            previousHalvingThresold = newPreviousHalvingThresold;
            miningRate = miningRate / 2;
            miningFee = miningFee / 2;
            ++numOfHalvings;
            ++atmMultiplier;
        }

        uint256 day = _currentDay();
        _globalMinerId.increment();
        uint256 newMinerId = _globalMinerId.current();

        _minerAdd(
            minerList[msg.sender],
            bitoshisMiner,
            bitoshisReturned,
            pSatoshisMined,
            bitoshisBurned,
            newMinerId,
            day
        );

        emit MinerStart(
            uint256(uint40(block.timestamp)) |
                (uint256(uint24(day)) << 40) |
                (uint256(uint96(pSatoshisMined)) << 64) |
                (uint256(uint96(bitoshisBurned)) << 160),
            uint256(uint128(bitoshisMiner)) | (uint256(uint128(bitoshisReturned)) << 128),
            msg.sender,
            uint40(newMinerId)
        );
    }

    /// @dev End PulseBitcoin (PLSB) time lock mining instance
    /// @param minerIndex Index of the existing miner in the wallet's miner list
    /// @param minerId ID of the miner instance
    /// @param minerAddr The account address of the miner
    function minerEnd(
        uint256 minerIndex,
        uint256 minerId,
        address minerAddr
    ) external nonReentrant {
        MinerStore[] storage minerListStore = minerList[minerAddr];

        /* Ensure caller's MinerList is not empty */
        if (minerListStore.length == 0) {
            revert MinerListEmpty();
        }

        /* minerIndex within the valid range */
        if (minerIndex >= minerListStore.length) {
            revert InvalidMinerIndex({sentIndex: minerIndex, lastIndex: minerListStore.length - 1});
        }

        /* minerIndex is still current */
        if (minerId != minerListStore[minerIndex].minerId) {
            revert InvalidMinerId({sentId: minerId, expectedId: minerListStore[minerIndex].minerId});
        }

        MinerCache memory minerCache;
        _minerLoad(minerListStore[minerIndex], minerCache);

        uint256 servedDays = _currentDay() - minerCache._day;

        /* miner instance has been active for minimum mining duration */
        if (servedDays < MIN_MINING_DURATION) {
            revert CannotEndMinerEarly({servedDays: servedDays, requiredDays: MIN_MINING_DURATION});
        }

        /* late end miner instance, caller address gets 1/2 of ASIC and PLSB minted to dead address */
        if (servedDays > DAYS_FOR_PENALTY) {
            _asic.mint(msg.sender, minerCache._bitoshisReturned / 2);
            _asic.mint(minerAddr, minerCache._bitoshisReturned / 2);
            // burn PLSB
            _mint(DEAD_ADDRESS, minerCache._pSatoshisMined);
        } else {
            // return ASIC
            _asic.mint(minerAddr, minerCache._bitoshisReturned);
            // mine PLSB
            _mint(minerAddr, minerCache._pSatoshisMined);
        }

        _minerRemove(minerListStore, minerIndex);

        emit MinerEnd(
            uint256(uint40(block.timestamp)) |
                (uint256(uint24(servedDays)) << 40) |
                (uint256(uint96(minerCache._pSatoshisMined)) << 64) |
                (uint256(uint96(minerCache._bitoshisBurned)) << 160),
            uint256(uint128(minerCache._bitoshisMiner)) | (uint256(uint128(minerCache._bitoshisReturned)) << 128),
            msg.sender,
            uint40(minerCache._minerId)
        );
    }

    /// @dev Starts and determines the point value of a new ATM instance
    /// @param amount The amount of tokens sent
    /// @param tokenAddress The address of the coin/token that is sent
    function atmStart(uint256 amount, address tokenAddress) external nonReentrant returns (uint256) {
        // validation
        if (_currentDay() > ATM_EVENT_LENGTH) {
            revert ATMEventIsOver({eventLength: ATM_EVENT_LENGTH, currentDay: _currentDay()});
        }

        uint256 tokenPrice;
        uint256 atmPoints;

        IERC20 token = IERC20(tokenAddress);

        address uniswapPool = _uniswapPools[tokenAddress];

        // invalid token; revert.
        if (tokenAddress != USDC_ADDRESS && uniswapPool == address(0)) {
            revert InvalidToken();
        }

        if (tokenAddress != USDC_ADDRESS) {
            // weth pools are backwards for some reason.
            if (tokenAddress == WETH_ADDRESS) {
                tokenPrice = getPriceX96FromSqrtPriceX96(getSqrtTwapX96(uniswapPool));
                atmPoints = (amount * (2**96)) / tokenPrice;
            } else {
                tokenPrice = getPriceX96FromSqrtPriceX96(getSqrtTwapX96(uniswapPool));
                atmPoints = (amount * tokenPrice) / (2**96);
            }
        } else {
            atmPoints = amount;
        }

        token.safeTransferFrom(msg.sender, BA_ADDRESS, amount);

        if (atmPoints == 0) {
            revert ATMPointsToSmall();
        }

        uint256 atmId = _atm.mint(msg.sender);

        atmPoints = atmPoints * SCALE_FACTOR;
        // add ATM entry
        _atmAdd(atmPoints, atmId);

        emit ATMStart(
            uint256(uint40(block.timestamp)) | (uint256(uint216(atmPoints)) << 40),
            msg.sender,
            uint40(atmId),
            tokenAddress
        );

        return atmPoints;
    }

    /// @dev Ends and determines the payout of an existing ATM instance
    /// @param atmId The unique NTF ID of the ATM
    /// @return payout The amount of reward ASIC tokens
    function atmEnd(uint256 atmId) external nonReentrant returns (uint256) {
        // check valid end day
        if (_currentDay() <= ATM_EVENT_LENGTH) {
            revert CannotEndATMWithinEventPeriod({eventLength: ATM_EVENT_LENGTH, currentDay: _currentDay()});
        }

        // load ATM into memory
        ATMCache memory atmCache;
        _atmLoad(atmList[atmId], atmCache);

        // check if ATM has been burned
        if (atmCache._isActive != true) {
            revert ATMNotActive();
        }

        // check valid owner
        if (_atm.ownerOf(atmId) != msg.sender) {
            revert NotOwnerOfATM();
        }

        uint256 payout = (atmCache._points * atmMultiplier);

        atmCache._points = 0;
        atmCache._isActive = false;

        _atmUpdate(atmList[atmId], atmCache);

        // mint ASIC
        if (payout > 0) {
            _asic.mint(msg.sender, payout);
        }

        // burn ATM
        _atm.burn(atmId);

        emit ATMEnd(uint256(uint40(block.timestamp)) | (uint256(uint216(payout)) << 40), msg.sender, uint40(atmId));

        return payout;
    }

    /// @dev Returns the current payout for an ATM
    /// @param atmId The unique NTF ID of the ATM
    /// @return payout The amount of reward ASIC tokens
    function atmCurrentPayout(uint256 atmId) external view returns (uint256 payout) {
        return (atmList[atmId].points * atmMultiplier);
    }

    /// @dev Private function to determine the current day
    function _currentDay() internal view returns (uint256) {
        return ((block.timestamp - LAUNCH_TIME) / 1 days);
    }

    /// @dev Loads the miner instance from storage into memory
    /// @param minerStore Miner store to a wallet's miner list
    /// @param minerCache The miner instance in memory
    function _minerLoad(MinerStore storage minerStore, MinerCache memory minerCache) internal view {
        minerCache._minerId = minerStore.minerId;
        minerCache._bitoshisMiner = minerStore.bitoshisMiner;
        minerCache._pSatoshisMined = minerStore.pSatoshisMined;
        minerCache._bitoshisBurned = minerStore.bitoshisBurned;
        minerCache._bitoshisReturned = minerStore.bitoshisReturned;
        minerCache._day = minerStore.day;
    }

    /// @dev Add a new miner instance to a wallet's miner list
    /// @param minerListRef Memory reference to a wallet's miner list
    /// @param newMinerId ID of the new miner
    /// @param bitoshisMiner Amount of tokens added to the miner
    /// @param pSatoshisMined Amount of tokens mined
    /// @param bitoshisBurned Amount of tokens burned
    /// @param bitoshisReturned Amount of tokens returned
    /// @param day The day the mining instance is started
    function _minerAdd(
        MinerStore[] storage minerListRef,
        uint256 bitoshisMiner,
        uint256 bitoshisReturned,
        uint256 pSatoshisMined,
        uint256 bitoshisBurned,
        uint256 newMinerId,
        uint256 day
    ) internal {
        minerListRef.push(
            MinerStore(
                uint128(bitoshisMiner),
                uint128(bitoshisReturned),
                uint96(pSatoshisMined),
                uint96(bitoshisBurned),
                uint40(newMinerId),
                uint24(day)
            )
        );
    }

    /// @dev Remove a miner instance from a wallet's miner list
    /// @param minerListRef Memory reference to a wallet's miner list
    /// @param minerIndex Index of the existing miner in the wallet's miner list
    function _minerRemove(MinerStore[] storage minerListRef, uint256 minerIndex) internal {
        uint256 lastIndex = minerListRef.length - 1;
        if (minerIndex != lastIndex) {
            minerListRef[minerIndex] = minerListRef[lastIndex];
        }
        minerListRef.pop();
    }

    /// @dev Adds a new ATM instance to the list of ATMs
    /// @param points The number of ATM points associated with the ATM
    /// @param atmId The unique NTF ID of the ATM
    function _atmAdd(uint256 points, uint256 atmId) internal {
        atmList[atmId] = ATMStore(uint248(points), true);
    }

    /// @dev Loads the ATM instance from storage into memory
    /// @param atmStore The ATM store struct
    /// @param atmCache The ATM cache
    function _atmLoad(ATMStore storage atmStore, ATMCache memory atmCache) internal view {
        atmCache._points = atmStore.points;
        atmCache._isActive = atmStore.isActive;
    }

    /// @dev Updates the ATM instance
    /// @param atmStore The ATM store struct
    /// @param atmCache The ATM cache
    function _atmUpdate(ATMStore storage atmStore, ATMCache memory atmCache) internal {
        atmStore.points = uint96(atmCache._points);
        atmStore.isActive = atmCache._isActive;
    }

    /// @dev Fetches time weighted price square root (scaled 2 ** 96) from a uniswap v3 pool.
    /// @param uniswapV3Pool Address of the uniswap v3 pool.
    /// @return sqrtPriceX96 Time weighted square root token price (scaled 2 ** 96).
    function getSqrtTwapX96(address uniswapV3Pool) internal view returns (uint160 sqrtPriceX96) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = TWAP_INTERVAL;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

        sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
            int24((tickCumulatives[1] - tickCumulatives[0]) / int8(TWAP_INTERVAL))
        );

        return sqrtPriceX96;
    }

    /// @dev Converts a uniswap v3 square root price into a token price (scaled 2 ** 96).
    /// @param sqrtPriceX96 Square root uniswap pool price (scaled 2 ** 96).
    /// @return priceX96 Token price (scaled 2 ** 96).
    function getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256 priceX96) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }
}