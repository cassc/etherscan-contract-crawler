// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/ISnacksBase.sol";
import "./interfaces/IAveragePriceOracle.sol";

contract Zoinks is ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant MAX_SUPPLY = 35000000000000 * 1e18;
    uint256 private constant BASE_PERCENT = 10000;
    uint256 private constant EMISSION_LIMIT_PERCENT = 1000;
    uint256 private constant BUY_SNACKS_PERCENT = 1500;
    uint256 private constant SENIORAGE_PERCENT = 2000;
    uint256 private constant PULSE_PERCENT = 3333;
    uint256 private constant POOL_REWARD_DISTRIBUTOR_PERCENT = 6500;
    uint256 private constant ISOLATE_PERCENT = 6667;
    uint256 private constant EMISSION_PERCENT = 10001;

    address public immutable busd;
    address public authority;
    address public seniorage;
    address public pulse;
    address public snacks;
    address public poolRewardDistributor;
    address public averagePriceOracle;
    uint256 public buffer;
    uint256 public zoinksAmountStored;

    event BufferUpdated(uint256 buffer);
    event TimeWeightedAveragePrice(uint256 TWAP);

    modifier onlyAuthority {
        require(
            msg.sender == authority,
            "Zoinks: caller is not authorised"
        );
        _;
    }

    /**
    * @param busd_ Binance-Peg BUSD token address.
    */
    constructor(address busd_) ERC20("Zoinks", "HZUSD") {
        busd = busd_;
        // Mint for liquidity in DEXes.
        address marketMaker = 0xc249aE80c56fE28628d5d3679651D45d96C9d0de;
        _mint(marketMaker, 500000 ether);
    }

    /**
    * @notice Configures the contract.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param authority_ Authorised address.
    * @param seniorage_ Seniorage contract address.
    * @param pulse_ Pulse contract address.
    * @param snacks_ Snacks token address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param averagePriceOracle_ AveragePriceOracle contract address.
    */
    function configure(
        address authority_,
        address seniorage_,
        address pulse_,
        address snacks_,
        address poolRewardDistributor_,
        address averagePriceOracle_
    )
        external
        onlyOwner
    {
        authority = authority_;
        seniorage = seniorage_;
        pulse = pulse_;
        snacks = snacks_;
        poolRewardDistributor = poolRewardDistributor_;
        averagePriceOracle = averagePriceOracle_;
        if (allowance(address(this), snacks_) == 0) {
            _approve(address(this), snacks_, type(uint256).max);
        }
    }

    /**
    * @notice Triggers stopped state.
    * @dev Could be called by the owner in case of resetting addresses.
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @notice Returns to normal state.
    * @dev Could be called by the owner in case of resetting addresses.
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @notice Sets buffer parameter.
    * @dev Used for emission control. It does regulate the granularity 
    * of the emission parts (by multiplying the max amount of percents).
    * @param buffer_ New buffer parameter.
    */
    function setBuffer(uint256 buffer_) external onlyOwner {
        buffer = buffer_;
        emit BufferUpdated(buffer_);
    }

    /**
    * @notice Mints Zoinks for Binance-Peg BUSD at a ratio of 1 to 1.
    * @dev All spent Binance-Peg BUSD tokens are sent to the Seniorage contract.
    * @param amount_ Amount of Zoinks to mint.
    */
    function mint(uint256 amount_) external whenNotPaused nonReentrant {
        require(
            amount_ > 0,
            "Zoinks: invalid amount"
        );
        require(
            totalSupply() + amount_ <= MAX_SUPPLY,
            "Zoinks: max supply exceeded"
        );
        IERC20(busd).safeTransferFrom(msg.sender, seniorage, amount_);
        _mint(msg.sender, amount_);
    }

    /**
    * @notice Applies TWAP. If its value is greater than or equal to 1.0001, 
    * the emission starts, otherwise nothing happens.
    * @dev Called by the authorised address once every 12 hours.
    */
    function applyTWAP() external whenNotPaused onlyAuthority {
        IAveragePriceOracle(averagePriceOracle).update();
        uint256 TWAP = IAveragePriceOracle(averagePriceOracle).twapLast();
        emit TimeWeightedAveragePrice(TWAP);
        if (TWAP >= EMISSION_PERCENT) {
            _emission(TWAP);
        }
    }

    /**
    * @notice Implements the logic of Zoinks token emission.
    * @dev The emission percentage cannot exceed 10%. 
    * The emission itself is controlled by the buffer parameter.
    * Distribution of the emission amount: 65% goes to the PoolRewardDistributor contract,
    * 20% goes to the Seniorage contract, the remaining 15% is used for mint Snacks tokens
    * (66.67% of which are isolated to maintain the floor price and 33.33% goes to the Pulse contract).
    * @param TWAP_ Time-weighted average price for 12 hours.
    */
    function _emission(uint256 TWAP_) private {
        uint256 emissionPercent = Math.min(TWAP_ - BASE_PERCENT, EMISSION_LIMIT_PERCENT);
        uint256 emissionAmount = emissionPercent * totalSupply() / (BASE_PERCENT * buffer);
        require(
            totalSupply() + emissionAmount <= MAX_SUPPLY,
            "Zoinks: max supply exceeded"
        );
        _mint(poolRewardDistributor, emissionAmount * POOL_REWARD_DISTRIBUTOR_PERCENT / BASE_PERCENT);
        _mint(seniorage, emissionAmount * SENIORAGE_PERCENT / BASE_PERCENT);
        uint256 amountOfZoinksToBuySnacks = emissionAmount * BUY_SNACKS_PERCENT / BASE_PERCENT;
        _mint(address(this), amountOfZoinksToBuySnacks);
        uint256 zoinksAmount = amountOfZoinksToBuySnacks + zoinksAmountStored;
        address snacksAddress = snacks;
        if (ISnacksBase(snacksAddress).sufficientPayTokenAmountOnMint(zoinksAmount)) {
            uint256 snacksAmount = ISnacksBase(snacksAddress).mintWithPayTokenAmount(zoinksAmount);
            IERC20(snacksAddress).safeTransfer(DEAD_ADDRESS, snacksAmount * ISOLATE_PERCENT / BASE_PERCENT);
            IERC20(snacksAddress).safeTransfer(pulse, snacksAmount * PULSE_PERCENT / BASE_PERCENT);
            if (zoinksAmountStored != 0) {
                zoinksAmountStored = 0;
            }
        } else {
            zoinksAmountStored += amountOfZoinksToBuySnacks;
        }
    }
}