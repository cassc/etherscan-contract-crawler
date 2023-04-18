// SPDX-License-Identifier: LGPL-3.0
/**
 *  @title Light DAO Token
 *  @author LT Finance
 *  @notice ERC20 with piecewise-linear mining supply.
 *  @dev Based on the ERC-20 token standard as defined at https://eips.ethereum.org/EIPS/eip-20
 */
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "../interfaces/ILT.sol";
import "./ERC20Permit.sol";

contract LT is ERC20Permit, Ownable2StepUpgradeable, ILT {
    //General constants
    uint256 private constant _DAY = 86400;
    uint256 private constant _YEAR = _DAY * 365;

    /// Allocation:
    /// =========
    /// total 1 trillion
    ///  30% to shareholders (team and investors) with 1 year cliff and 4 years vesting
    ///  5% to the treasury reserve
    ///  5% to LIGHT Foundation (grants)
    ///
    /// == 40% ==
    /// left for inflation: 60%

    /// Supply parameters
    uint256 private constant _INITIAL_SUPPLY = 400_000_000_000;
    /// _INITIAL_SUPPLY * 0.2387
    uint256 private constant _INITIAL_RATE = (95_480_000_000 * 10 ** 18) / _YEAR;
    uint256 private constant _RATE_REDUCTION_TIME = _YEAR;
    /// 2 ** (1/4) * 1e18
    uint256 private constant _RATE_REDUCTION_COEFFICIENT = 1189207115002721024;
    uint256 private constant _RATE_DENOMINATOR = 10 ** 18;
    uint256 private constant _INFLATION_DELAY = 2 * _DAY;

    address public minter;
    /// Supply variables
    int128 public miningEpoch;
    uint256 public startEpochTime;
    uint256 public rate;

    uint256 public startEpochSupply;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract constructor
     * @param _name Token full name
     * @param _symbol Token symbol
     */
    function initialize(string memory _name, string memory _symbol) external initializer {
        __Ownable2Step_init();
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init();

        uint256 initSupply = _INITIAL_SUPPLY * 10 ** decimals();
        _mint(_msgSender(), initSupply);

        startEpochTime = block.timestamp + _INFLATION_DELAY - _RATE_REDUCTION_TIME;
        miningEpoch = -1;
        rate = 0;
        startEpochSupply = initSupply;
    }

    /**
     *  @dev Update mining rate and supply at the start of the epoch
     *   Any modifying mining call must also call this
     */
    function __updateMiningParameters() internal {
        uint256 _rate = rate;
        uint256 _startEpochSupply = startEpochSupply;

        startEpochTime += _RATE_REDUCTION_TIME;
        miningEpoch += 1;

        if (_rate == 0) {
            _rate = _INITIAL_RATE;
        } else {
            _startEpochSupply += _rate * _RATE_REDUCTION_TIME;
            startEpochSupply = _startEpochSupply;
            _rate = (_rate * _RATE_DENOMINATOR) / _RATE_REDUCTION_COEFFICIENT;
        }
        rate = _rate;
        emit UpdateMiningParameters(block.timestamp, _rate, _startEpochSupply);
    }

    /**
     * @notice Update mining rate and supply at the start of the epoch
     * @dev   Callable by any address, but only once per epoch
     *  Total supply becomes slightly larger if this function is called late
     */
    function updateMiningParameters() external override {
        require(block.timestamp >= startEpochTime + _RATE_REDUCTION_TIME, "BA000");
        __updateMiningParameters();
    }

    /**
     * @notice Get timestamp of the next mining epoch start
     *       while simultaneously updating mining parameters
     * @return Timestamp of the next epoch
     */
    function futureEpochTimeWrite() external override returns (uint256) {
        uint256 _startEpochTime = startEpochTime;
        if (block.timestamp >= _startEpochTime + _RATE_REDUCTION_TIME) {
            __updateMiningParameters();
            return startEpochTime + _RATE_REDUCTION_TIME;
        } else {
            return _startEpochTime + _RATE_REDUCTION_TIME;
        }
    }

    function __availableSupply() internal view returns (uint256) {
        return startEpochSupply + (block.timestamp - startEpochTime) * rate;
    }

    /**
     * @notice Current number of tokens in existence (claimed or unclaimed)
     */
    function availableSupply() external view override returns (uint256) {
        return __availableSupply();
    }

    /**
     * @notice How much supply is mintable from start timestamp till end timestamp
     * @param start Start of the time interval (timestamp)
     * @param end End of the time interval (timestamp)
     * @return Tokens mintable from `start` till `end`
     */
    function mintableInTimeframe(uint256 start, uint256 end) external view override returns (uint256) {
        require(start <= end, "BA001");
        uint256 toMint = 0;
        uint256 currentEpochTime = startEpochTime;
        uint256 currentRate = rate;

        // Special case if end is in future (not yet minted) epoch
        if (end > currentEpochTime + _RATE_REDUCTION_TIME) {
            currentEpochTime += _RATE_REDUCTION_TIME;
            currentRate = (currentRate * _RATE_DENOMINATOR) / _RATE_REDUCTION_COEFFICIENT;
        }
        require(end <= currentEpochTime + _RATE_REDUCTION_TIME, "BA002");

        // LT will not work in 1000 years. Darn!
        for (uint256 i = 0; i < 1000; i++) {
            if (end >= currentEpochTime) {
                uint256 currentEnd = end;
                if (currentEnd > currentEpochTime + _RATE_REDUCTION_TIME) {
                    currentEnd = currentEpochTime + _RATE_REDUCTION_TIME;
                }
                uint256 currentStart = start;
                if (currentStart >= currentEpochTime + _RATE_REDUCTION_TIME) {
                    // We should never get here but what if...
                    break;
                } else if (currentStart < currentEpochTime) {
                    currentStart = currentEpochTime;
                }
                toMint += currentRate * (currentEnd - currentStart);
                if (start >= currentEpochTime) {
                    break;
                }
            }
            currentEpochTime -= _RATE_REDUCTION_TIME;
            //# double-division with rounding made rate a bit less => good
            currentRate = (currentRate * _RATE_REDUCTION_COEFFICIENT) / _RATE_DENOMINATOR;
            require(currentRate <= _INITIAL_RATE, "This should never happen");
        }
        return toMint;
    }

    /**
     *  @notice Set the minter address
     *  @dev Only callable once, when minter has not yet been set
     *  @param _minter Address of the minter
     */
    function setMinter(address _minter) external override onlyOwner {
        require(minter == address(0), "BA003");
        minter = _minter;
        emit SetMinter(_minter);
    }

    /**
     *  @notice Mint `value` tokens and assign them to `to`
     *   @dev Emits a Transfer event originating from 0x00
     *   @param to The account that will receive the created tokens
     *   @param value The amount that will be created
     *   @return bool success
     */
    function mint(address to, uint256 value) external override returns (bool) {
        require(msg.sender == minter, "BA004");
        require(to != address(0), "CE000");
        if (block.timestamp >= startEpochTime + _RATE_REDUCTION_TIME) {
            __updateMiningParameters();
        }
        uint256 totalSupply = totalSupply() + value;
        require(totalSupply <= __availableSupply(), "BA005");

        _mint(to, value);

        return true;
    }

    /**
     * @notice Burn `value` tokens belonging to `msg.sender`
     * @dev Emits a Transfer event with a destination of 0x00
     * @param value The amount that will be burned
     * @return bool success
     */
    function burn(uint256 value) external override returns (bool) {
        _burn(msg.sender, value);
        return true;
    }
}