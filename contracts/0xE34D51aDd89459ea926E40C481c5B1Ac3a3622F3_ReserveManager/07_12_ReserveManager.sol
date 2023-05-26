// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IComptroller.sol";
import "./interfaces/ICToken.sol";
import "./interfaces/ICTokenAdmin.sol";
import "./interfaces/IBurner.sol";
import "./interfaces/IWeth.sol";

contract ReserveManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint public constant COOLDOWN_PERIOD = 1 days;
    address public constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice comptroller contract
     */
    IComptroller public immutable comptroller;

    /**
     * @notice weth contract
     */
    address public immutable wethAddress;

    /**
     * @notice usdc contract
     */
    address public immutable usdcAddress;

    /**
     * @notice the extraction ratio, scaled by 1e18
     */
    uint public ratio = 0.5e18;

    /**
     * @notice cToken admin to extract reserves
     */
    mapping(address => address) public cTokenAdmins;

    /**
     * @notice burner contracts to convert assets into a specific token
     */
    mapping(address => address) public burners;

    struct ReservesSnapshot {
        uint timestamp;
        uint totalReserves;
    }

    /**
     * @notice reserves snapshot that records every reserves update
     */
    mapping(address => ReservesSnapshot) public reservesSnapshot;

    /**
     * @notice return if a cToken market is blocked from reserves sharing
     */
    mapping(address => bool) public isBlocked;

    /**
     * @notice return if a cToken market should be burnt manually
     */
    mapping(address => bool) public manualBurn;

    /**
     * @notice a manual burner that reseives assets whose onchain liquidity are not deep enough
     */
    address public manualBurner;

    /**
     * @notice return if a cToken market is native token or not.
     */
    mapping(address => bool) public isNativeMarket;

    /**
     * @notice a dispatcher that could dispatch reserves.
     */
    address public dispatcher;

    /**
     * @notice Emitted when reserves are dispatched
     */
    event Dispatch(
        address indexed token,
        uint indexed amount,
        address destination
    );

    /**
     * @notice Emitted when a cToken's burner is updated
     */
    event BurnerUpdated(
        address cToken,
        address oldBurner,
        address newBurner
    );

    /**
     * @notice Emitted when the reserves extraction ratio is updated
     */
    event RatioUpdated(
        uint oldRatio,
        uint newRatio
    );

    /**
     * @notice Emitted when a token is seized
     */
    event TokenSeized(
        address token,
        uint amount
    );

    /**
     * @notice Emitted when a cToken market is blocked or unblocked from reserves sharing
     */
    event MarketBlocked(
        address cToken,
        bool wasBlocked,
        bool isBlocked
    );

    /**
     * @notice Emitted when a cToken market is determined to be manually burnt or not
     */
    event MarketManualBurn(
        address cToken,
        bool wasManual,
        bool isManual
    );

    /**
     * @notice Emitted when a manual burner is updated
     */
    event ManualBurnerUpdated(
        address oldManualBurner,
        address newManualBurner
    );

    /**
     * @notice Emitted when a native market is updated
     */
    event NativeMarketUpdated(
        address cToken,
        bool isNative
    );

    /**
     * @notice Emitted when a dispatcher is set
     */
    event DispatcherSet(address dispatcher);

    constructor(
        address _owner,
        address _manualBurner,
        IComptroller _comptroller,
        address _wethAddress,
        address _usdcAddress
    ) {
        transferOwnership(_owner);
        manualBurner = _manualBurner;
        comptroller = _comptroller;
        wethAddress = _wethAddress;
        usdcAddress = _usdcAddress;

        // Set default ratio to 50%.
        ratio = 0.5e18;
    }

    /**
     * @notice Get the current block timestamp
     * @return The current block timestamp
     */
    function getBlockTimestamp() public virtual view returns (uint) {
        return block.timestamp;
    }

    receive() external payable {}

    /* Mutative functions */

    /**
     * @notice Execute reduce reserve and burn on multiple cTokens
     * @param cTokens The token address list
     */
    function dispatchMultiple(address[] memory cTokens) external nonReentrant {
        require(msg.sender == owner() || msg.sender == dispatcher, "unauthorized");

        for (uint i = 0; i < cTokens.length; i++) {
            dispatch(cTokens[i]);
        }
    }

    /**
     * @notice Seize the accidentally deposited tokens
     * @param token The token
     * @param amount The amount
     */
    function seize(address token, uint amount) external onlyOwner {
        if (token == ethAddress) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
        emit TokenSeized(token, amount);
    }

    /**
     * @notice Block or unblock a cToken from reserves sharing
     * @param cTokens The cToken address list
     * @param blocked Block from reserves sharing or not
     */
    function setBlocked(address[] memory cTokens, bool[] memory blocked) external onlyOwner {
        require(cTokens.length == blocked.length, "invalid data");

        for (uint i = 0; i < cTokens.length; i++) {
            bool wasBlocked = isBlocked[cTokens[i]];
            isBlocked[cTokens[i]] = blocked[i];

            emit MarketBlocked(cTokens[i], wasBlocked, blocked[i]);
        }
    }

    /**
     * @notice Set the burners of a list of tokens
     * @param cTokens The cToken address list
     * @param newBurners The burner address list
     */
    function setBurners(address[] memory cTokens, address[] memory newBurners) external onlyOwner {
        require(cTokens.length == newBurners.length, "invalid data");

        for (uint i = 0; i < cTokens.length; i++) {
            address oldBurner = burners[cTokens[i]];
            burners[cTokens[i]] = newBurners[i];

            emit BurnerUpdated(cTokens[i], oldBurner, newBurners[i]);
        }
    }

    /**
     * @notice Determine a market should be burnt manually or not
     * @param cTokens The cToken address list
     * @param manual The list of markets which should be burnt manually or not
     */
    function setManualBurn(address[] memory cTokens, bool[] memory manual) external onlyOwner {
        require(cTokens.length == manual.length, "invalid data");

        for (uint i = 0; i < cTokens.length; i++) {
            bool wasManual = manualBurn[cTokens[i]];
            manualBurn[cTokens[i]] = manual[i];

            emit MarketManualBurn(cTokens[i], wasManual, manual[i]);
        }
    }

    /**
     * @notice Set new manual burner
     * @param newManualBurner The new manual burner
     */
    function setManualBurner(address newManualBurner) external onlyOwner {
        require(newManualBurner != address(0), "invalid new manual burner");

        address oldManualBurner = manualBurner;
        manualBurner = newManualBurner;

        emit ManualBurnerUpdated(oldManualBurner, newManualBurner);
    }

    /**
     * @notice Adjust the extraction ratio
     * @param newRatio The new extraction ratio
     */
    function adjustRatio(uint newRatio) external onlyOwner {
        require(newRatio <= 1e18, "invalid ratio");

        uint oldRatio = ratio;
        ratio = newRatio;
        emit RatioUpdated(oldRatio, newRatio);
    }

    /**
     * @notice Seize the accidentally deposited tokens
     * @param cToken The cToken address
     * @param isNative It's native or not
     */
    function setNativeMarket(address cToken, bool isNative) external onlyOwner {
        if (isNativeMarket[cToken] != isNative) {
            isNativeMarket[cToken] = isNative;
            emit NativeMarketUpdated(cToken, isNative);
        }
    }

    /**
     * @notice Set the new dispatcher
     * @param newDispatcher The new dispatcher
     */
    function setDispatcher(address newDispatcher) external onlyOwner {
        dispatcher = newDispatcher;

        emit DispatcherSet(newDispatcher);
    }

    /* Internal functions */

    /**
     * @notice Execute reduce reserve for cToken
     * @param cToken The cToken to dispatch reduce reserve operation
     */
    function dispatch(address cToken) internal {
        require(!isBlocked[cToken], "market is blocked from reserves sharing");
        require(comptroller.isMarketListed(cToken), "market not listed");

        uint totalReserves = ICToken(cToken).totalReserves();
        ReservesSnapshot memory snapshot = reservesSnapshot[cToken];
        if (snapshot.timestamp > 0 && snapshot.totalReserves < totalReserves) {
            address cTokenAdmin = ICToken(cToken).admin();
            require(snapshot.timestamp + COOLDOWN_PERIOD <= getBlockTimestamp(), "still in the cooldown period");

            // Extract reserves through cTokenAdmin.
            uint reduceAmount = (totalReserves - snapshot.totalReserves) * ratio / 1e18;
            ICTokenAdmin(cTokenAdmin).extractReserves(cToken, reduceAmount);

            // Get total reserves from cToken again for snapshots.
            totalReserves = ICToken(cToken).totalReserves();

            // Get the cToken underlying.
            address underlying;
            if (isNativeMarket[cToken]) {
                IWeth(wethAddress).deposit{value: reduceAmount}();
                underlying = wethAddress;
            } else {
                underlying = ICToken(cToken).underlying();
            }

            // In case someone transfers tokens in directly, which will cause the dispatch reverted,
            // we burn all the tokens in the contract here.
            uint burnAmount = IERC20(underlying).balanceOf(address(this));

            address burner = burners[cToken];
            if (manualBurn[cToken]) {
                // Send the underlying to the manual burner.
                burner = manualBurner;
                IERC20(underlying).safeTransfer(manualBurner, burnAmount);
            } else {
                // Allow the corresponding burner to pull the assets to burn.
                require(burner != address(0), "burner not set");
                IERC20(underlying).safeIncreaseAllowance(burner, burnAmount);
                IBurner(burner).burn(underlying);
            }

            emit Dispatch(underlying, burnAmount, burner);
        }

        // Update the reserve snapshot.
        reservesSnapshot[cToken] = ReservesSnapshot({
            timestamp: getBlockTimestamp(),
            totalReserves: totalReserves
        });
    }
}