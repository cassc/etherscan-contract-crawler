// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {
    ERC20Upgradeable, IERC20Upgradeable
} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {
    ERC20PermitUpgradeable,
    IERC20PermitUpgradeable
} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKIBToken} from "./interfaces/IKIBToken.sol";
import {IKUMASwap} from "./interfaces/IKUMASwap.sol";
import {IMCAGRateFeed} from "./interfaces/IMCAGRateFeed.sol";
import {Roles} from "./libraries/Roles.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {WadRayMath} from "./libraries/WadRayMath.sol";

/**
 * @title KUMA Interest Bearing Token
 * @author MIMO Labs
 * @notice KIBTokens are burned and minted by KUMASwap contracts when selling and buying bonds
 * @dev ERC20 token representing a KUMA Interest Bearing Token
 */
contract KIBToken is IKIBToken, ERC20PermitUpgradeable, UUPSUpgradeable {
    using Roles for bytes32;
    using WadRayMath for uint256;

    uint256 public constant MAX_EPOCH_LENGTH = 365 days;
    uint256 public constant MIN_YIELD = WadRayMath.RAY;

    IKUMAAddressProvider private _KUMAAddressProvider;
    uint96 private _minEpochLength;
    bytes32 private _riskCategory;
    uint256 private _yield;
    uint256 private _previousEpochCumulativeYield;
    uint256 private _cumulativeYield;
    uint256 private _lastRefresh;
    uint256 private _epochLength;

    uint256 private _totalBaseSupply; // Underlying assets supply (does not include rewards)

    mapping(address => uint256) private _baseBalances; // (does not include rewards)

    modifier onlyRole(bytes32 role) {
        if (!_KUMAAddressProvider.getAccessController().hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    constructor() initializer {}

    /**
     * @notice The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it
     * @param name Token name
     * @param symbol Token symbol
     * @param epochLength Rebase intervals in seconds
     * @param KUMAAddressProvider Address Provider of the KUMA protocol
     * @param currency Currency of the risk category, given as bytes4
     * @param issuer Issuer of the risk category, given as bytes32
     * @param term Term of the risk category, in seconds, given as uint32
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 epochLength,
        IKUMAAddressProvider KUMAAddressProvider,
        bytes4 currency,
        bytes32 issuer,
        uint32 term
    ) external initializer {
        if (epochLength == 0) {
            revert Errors.EPOCH_LENGTH_CANNOT_BE_ZERO();
        }
        if (epochLength < 1 hours) {
            revert Errors.EPOCH_LENGTH_TOO_LOW(epochLength, 1 hours);
        }
        if (epochLength > MAX_EPOCH_LENGTH) {
            revert Errors.EPOCH_LENGTH_TOO_HIGH(epochLength, MAX_EPOCH_LENGTH);
        }
        if (address(KUMAAddressProvider) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (currency == bytes4(0) || issuer == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        _yield = MIN_YIELD;
        _epochLength = epochLength;
        _lastRefresh = block.timestamp % epochLength == 0
            ? block.timestamp
            : (block.timestamp / epochLength) * epochLength + epochLength;
        _cumulativeYield = MIN_YIELD;
        _previousEpochCumulativeYield = MIN_YIELD;
        _KUMAAddressProvider = KUMAAddressProvider;
        _riskCategory = keccak256(abi.encode(currency, issuer, term));
        _minEpochLength = 1 hours;
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);

        emit CumulativeYieldUpdated(0, MIN_YIELD);
        emit EpochLengthSet(0, epochLength);
        emit KUMAAddressProviderSet(address(KUMAAddressProvider));
        emit MinEpochLengthSet(0, 1 hours);
        emit PreviousEpochCumulativeYieldUpdated(0, MIN_YIELD);
        emit RiskCategorySet(_riskCategory);
        emit YieldUpdated(0, MIN_YIELD);
    }

    /**
     * @notice Sets the epoch length of this KIBT
     * @param epochLength The new rebase interval, given in seconds as a uint256
     */
    function setEpochLength(uint256 epochLength) external onlyRole(Roles.KUMA_SET_EPOCH_LENGTH_ROLE) {
        if (epochLength < _minEpochLength) {
            revert Errors.EPOCH_LENGTH_TOO_LOW(epochLength, _minEpochLength);
        }
        if (epochLength > MAX_EPOCH_LENGTH) {
            revert Errors.EPOCH_LENGTH_TOO_HIGH(epochLength, MAX_EPOCH_LENGTH);
        }
        if (_getPreviousEpochTimestamp() >= (block.timestamp / epochLength * epochLength)) {
            _refreshCumulativeYield();
            _refreshYield();
        }
        emit EpochLengthSet(_epochLength, epochLength);
        _epochLength = epochLength;
    }

    /**
     * @notice Updates yield based on current yield and oracle reference rate
     *   and updates the  _previousEpochCumulativeYield and _cumulativeYield
     */
    function refreshYield() external {
        _refreshCumulativeYield();
        _refreshYield();
    }

    /**
     * @notice Following logic has been added/updated :
     * - Cumulative yield refresh
     * - Balances are updated based on what balanceOf the account should be after minting
     * @dev See {ERC20-_mint}
     * @param account The account that will receive the minted tokens
     * @param amount The amount of KIBT that will be minted
     */
    function mint(address account, uint256 amount)
        external
        onlyRole(Roles.KUMA_MINT_ROLE.toGranularRole(_riskCategory))
    {
        if (block.timestamp < _lastRefresh) {
            revert Errors.START_TIME_NOT_REACHED();
        }
        if (account == address(0)) {
            revert Errors.ERC20_MINT_TO_THE_ZERO_ADDRESS();
        }
        _refreshCumulativeYield();
        _refreshYield();

        uint256 newAccountBalance = balanceOf(account) + amount;
        uint256 newBaseBalance = WadRayMath.wadToRay(newAccountBalance).rayDiv(_previousEpochCumulativeYield); // Store baseAmount in 27 decimals

        if (amount > 0) {
            _totalBaseSupply += newBaseBalance - _baseBalances[account];
            _baseBalances[account] = newBaseBalance;
        }

        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Following logic has been added/updated :
     * - Cumulative yield refresh
     * - Destroy baseAmount instead of amount
     * - Balances are updated based on what balanceOf the account should be after burning
     * @dev See {ERC20-_burn}.
     * @param account The account that will lose the burned tokens
     * @param amount The amount of KIBT that will be burned
     */
    function burn(address account, uint256 amount)
        external
        onlyRole(Roles.KUMA_BURN_ROLE.toGranularRole(_riskCategory))
    {
        if (account == address(0)) {
            revert Errors.ERC20_BURN_FROM_THE_ZERO_ADDRESS();
        }
        _refreshCumulativeYield();
        _refreshYield();

        uint256 startingAccountBalance = balanceOf(account);
        if (startingAccountBalance < amount) {
            revert Errors.ERC20_BURN_AMOUNT_EXCEEDS_BALANCE();
        }

        uint256 newAccountBalance = startingAccountBalance - amount;
        uint256 newBaseBalance = WadRayMath.wadToRay(newAccountBalance).rayDiv(_previousEpochCumulativeYield);
        if (amount > 0) {
            _totalBaseSupply -= _baseBalances[account] - newBaseBalance;
            _baseBalances[account] = newBaseBalance;
        }

        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice Sets a new minimum epoch length
     * @dev Only callable by the KUMA_SET_EPOCH_LENGTH_ROLE
     * @param minEpochLength The new minimum epoch length
     */
    function setMinEpochLength(uint96 minEpochLength) external onlyRole(Roles.KUMA_SET_EPOCH_LENGTH_ROLE) {
        if (minEpochLength == 0) {
            revert Errors.EPOCH_LENGTH_CANNOT_BE_ZERO();
        }
        if (minEpochLength > MAX_EPOCH_LENGTH) {
            revert Errors.EPOCH_LENGTH_TOO_HIGH(minEpochLength, MAX_EPOCH_LENGTH);
        }
        emit MinEpochLengthSet(_minEpochLength, minEpochLength);
        _minEpochLength = minEpochLength;
    }

    /**
     * @return The address provider for the KUMA protocol
     */
    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    /**
     * @return The minimum acceptable epoch length.
     */
    function getMinEpochLength() external view returns (uint256) {
        return _minEpochLength;
    }

    /**
     * @return Risk category hash of this KIBT as a bytes32
     */
    function getRiskCategory() external view returns (bytes32) {
        return _riskCategory;
    }

    /**
     * @return Current yield all KIBT are earning, formated to a uint256 RAY
     */
    function getYield() external view returns (uint256) {
        return _yield;
    }

    /**
     * @return Timestamp of last rebase
     */
    function getLastRefresh() external view returns (uint256) {
        return _lastRefresh;
    }

    /**
     * @return Current baseTotalSupply, formatted as a uint256 RAY
     */
    function getTotalBaseSupply() external view returns (uint256) {
        return _totalBaseSupply;
    }

    /**
     * @return User base balance, formatted as a uint256 RAY
     */
    function getBaseBalance(address account) external view returns (uint256) {
        return _baseBalances[account];
    }

    /**
     * @return Current epoch length in seconds
     */
    function getEpochLength() external view returns (uint256) {
        return _epochLength;
    }

    /**
     * @return Cumulative yield calculated at the _lastRefresh
     */
    function getCumulativeYield() external view returns (uint256) {
        return _cumulativeYield;
    }

    /**
     * @return Cumulative yield calculated at last epoch
     */
    function getUpdatedCumulativeYield() external view returns (uint256) {
        return _calculatePreviousEpochCumulativeYield();
    }

    /**
     * @return Timestamp of the previous epoch, in seconds
     */
    function getPreviousEpochTimestamp() external view returns (uint256) {
        return _getPreviousEpochTimestamp();
    }

    /**
     * @dev See {ERC20-balanceOf}
     * @dev Calculates the rewards at the last epoch
     * @param account The address to query the balance of
     * @return The amount of KIBT owned by account, formatted as a uint256 WAD
     */
    function balanceOf(address account) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return WadRayMath.rayToWad(_baseBalances[account].rayMul(_calculatePreviousEpochCumulativeYield()));
    }

    /**
     * @dev See {ERC20-totalSupply}
     * @return The total supply of KIBT, formatted as a uint256 WAD
     */
    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return WadRayMath.rayToWad(_totalBaseSupply.rayMul(_calculatePreviousEpochCumulativeYield()));
    }

    /**
     * @notice Following logic has been added/updated :
     * - Cumulative yield refresh
     * - Balances are updated based on what balanceOf the to and from accounts should be after transferring
     * @dev See {ERC20-_transfer}
     * @param to The address to transfer KIBT to
     * @param from The address to transfer KIBT from
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        if (from == address(0)) {
            revert Errors.ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS();
        }
        if (to == address(0)) {
            revert Errors.ERC20_TRANSER_TO_THE_ZERO_ADDRESS();
        }
        if (to == from) {
            revert Errors.CANNOT_TRANSFER_TO_SELF();
        }
        _refreshCumulativeYield();
        _refreshYield();

        uint256 startingFromBalance = balanceOf(from);
        if (startingFromBalance < amount) {
            revert Errors.ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE();
        }
        uint256 newFromBalance = startingFromBalance - amount;
        uint256 newToBalance = balanceOf(to) + amount;

        uint256 previousEpochCumulativeYield_ = _previousEpochCumulativeYield;
        uint256 newFromBaseBalance = WadRayMath.wadToRay(newFromBalance).rayDiv(previousEpochCumulativeYield_);
        uint256 newToBaseBalance = WadRayMath.wadToRay(newToBalance).rayDiv(previousEpochCumulativeYield_);

        if (amount > 0) {
            _totalBaseSupply -= (_baseBalances[from] - newFromBaseBalance);
            _totalBaseSupply += (newToBaseBalance - _baseBalances[to]);
            _baseBalances[from] = newFromBaseBalance;
            _baseBalances[to] = newToBaseBalance;
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @notice Updates the _previousEpochCumulativeYield and _cumulativeYield state
     */
    function _refreshCumulativeYield() private {
        uint256 newPreviousEpochCumulativeYield = _calculatePreviousEpochCumulativeYield();
        uint256 newCumulativeYield = _calculateCumulativeYield();

        if (newPreviousEpochCumulativeYield != _previousEpochCumulativeYield) {
            emit PreviousEpochCumulativeYieldUpdated(_previousEpochCumulativeYield, newPreviousEpochCumulativeYield);
            _previousEpochCumulativeYield = newPreviousEpochCumulativeYield;
        }
        if (newCumulativeYield != _cumulativeYield) {
            emit CumulativeYieldUpdated(_cumulativeYield, newCumulativeYield);
            _cumulativeYield = newCumulativeYield;
        }

        _lastRefresh = block.timestamp;
    }

    /**
     * @notice Updates _yield based on the minimum bond coupon of the KUMASwap and the oracle reference rate
     */
    function _refreshYield() private {
        IKUMASwap KUMASwap = IKUMASwap(_KUMAAddressProvider.getKUMASwap(_riskCategory));
        uint256 yield_ = _yield;
        if (KUMASwap.isExpired() || KUMASwap.isDeprecated()) {
            _yield = MIN_YIELD;
            emit YieldUpdated(yield_, MIN_YIELD);
            return;
        }
        uint256 referenceRate = IMCAGRateFeed(_KUMAAddressProvider.getRateFeed()).getRate(_riskCategory);
        uint256 minCoupon = KUMASwap.getMinCoupon();
        uint256 lowestYield = referenceRate < minCoupon ? referenceRate : minCoupon;
        if (lowestYield != yield_) {
            _yield = lowestYield;
            emit YieldUpdated(yield_, lowestYield);
        }
    }

    /**
     * @return Timestamp of the previous epoch
     */
    function _getPreviousEpochTimestamp() private view returns (uint256) {
        uint256 epochLength = _epochLength;
        uint256 epochTimestampRemainder = block.timestamp % epochLength;
        if (epochTimestampRemainder == 0) {
            return block.timestamp;
        }
        return (block.timestamp / epochLength) * epochLength;
    }

    /**
     * @notice Helper function to calculate cumulativeYield at call timestamp
     * @return Updated cumulative yield, in a uint256 RAY
     */
    function _calculateCumulativeYield() private view returns (uint256) {
        uint256 timeElapsed = block.timestamp - _lastRefresh;
        if (timeElapsed == 0) return _cumulativeYield;
        return _yield.rayPow(timeElapsed).rayMul(_cumulativeYield);
    }

    /**
     * @notice Helper function to calculate previousEpochCumulativeYield at call timestamp
     * @return Updated previous epoch cumulative yield, in a uint256 RAY
     */
    function _calculatePreviousEpochCumulativeYield() private view returns (uint256) {
        uint256 previousEpochTimestamp = _getPreviousEpochTimestamp();
        if (previousEpochTimestamp < _lastRefresh) {
            return _previousEpochCumulativeYield;
        }
        uint256 timeElapsedToEpoch = previousEpochTimestamp - _lastRefresh;
        return _yield.rayPow(timeElapsedToEpoch).rayMul(_cumulativeYield);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(Roles.KUMA_MANAGER_ROLE) {}
}