// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

contract BlankTokenVesting is Ownable {
    using SafeMath for uint256;
    using BokkyPooBahsDateTimeLibrary for uint256;
    using SafeERC20 for IERC20;

    event DistributionAdded(address indexed investor, address indexed caller, uint256 allocation);

    event DistributionRemoved(address indexed investor, address indexed caller, uint256 allocation);

    event WithdrawnTokens(address indexed investor, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    enum DistributionType { MARKETING, LIQUIDITY, TEAM, ADVISORS, DEVELOPMENT }

    uint256 private _initialTimestamp;
    IERC20 private _blankToken;

    struct Distribution {
        address beneficiary;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
        DistributionType distributionType;
    }

    mapping(DistributionType => Distribution) public distributionInfo;

    /// @dev Boolean variable that indicates whether the contract was initialized.
    bool public isInitialized = false;
    /// @dev Boolean variable that indicates whether the investors set was finalized.
    bool public isFinalized = false;

    uint256 constant _SCALING_FACTOR = 10**18; // decimals

    uint256[] marketingVesting = [
        25000000000000000000,
        32500000000000000000,
        40000000000000000000,
        47500000000000000000,
        55000000000000000000,
        62500000000000000000,
        70000000000000000000,
        75000000000000000000,
        80000000000000000000,
        85000000000000000000,
        90000000000000000000,
        95000000000000000000,
        100000000000000000000
    ];

    uint256[] liqudityVesting = [
        10000000000000000000,
        17500000000000000000,
        25000000000000000000,
        32500000000000000000,
        40000000000000000000,
        45000000000000000000,
        50000000000000000000,
        55000000000000000000,
        60000000000000000000,
        65000000000000000000,
        70000000000000000000,
        75000000000000000000,
        80000000000000000000,
        85000000000000000000,
        90000000000000000000,
        95000000000000000000,
        100000000000000000000
    ];

    uint256[] cliffVesting = [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        10000000000000000000,
        17500000000000000000,
        25000000000000000000,
        35000000000000000000,
        42500000000000000000,
        50000000000000000000,
        60000000000000000000,
        67500000000000000000,
        75000000000000000000,
        85000000000000000000,
        92500000000000000000,
        100000000000000000000
    ];

    /// @dev Checks that the contract is initialized.
    modifier initialized() {
        require(isInitialized, "not initialized");
        _;
    }

    /// @dev Checks that the contract is initialized.
    modifier notInitialized() {
        require(!isInitialized, "initialized");
        _;
    }

    // Marketing: 0x10535712A3cFA961b82615D1FF0252604B4b0455
    // Liquidity: 0xAF03Ee6959663A93df252D2423587AA7715c67A0
    // Team: 0x67cC023e03051a3901849390e3EEDBd429840858
    // Advisors: 0x8e07271e057b4FA4aA127926955Fb6EFe4ab80FC
    // Development: 0xE6bC3cE3290E3411c4E46fD4747e0f789F89F23c
    constructor(
        address _token,
        address _marketing,
        address _liquidity,
        address _team,
        address _advisors,
        address _development
    ) {
        require(address(_token) != address(0x0), "Blank token address is not valid");
        _blankToken = IERC20(_token);

        _addDistribution(_marketing, DistributionType.MARKETING, 12500000 * _SCALING_FACTOR, 3125000 * _SCALING_FACTOR);
        _addDistribution(_liquidity, DistributionType.LIQUIDITY, 40000000 * _SCALING_FACTOR, 4000000 * _SCALING_FACTOR);
        _addDistribution(_team, DistributionType.TEAM, 15000000 * _SCALING_FACTOR, 0);
        _addDistribution(_advisors, DistributionType.ADVISORS, 5000000 * _SCALING_FACTOR, 0);
        _addDistribution(_development, DistributionType.DEVELOPMENT, 15625000 * _SCALING_FACTOR, 0);
    }

    /// @dev Returns initial timestamp
    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return _initialTimestamp;
    }

    /// @dev Adds Distribution. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _beneficiary The address of distribution.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    function _addDistribution(
        address _beneficiary,
        DistributionType _distributionType,
        uint256 _tokensAllotment,
        uint256 _withdrawnTokens
    ) internal {
        require(_beneficiary != address(0), "Invalid address");
        require(_tokensAllotment > 0, "the investor allocation must be more than 0");
        Distribution storage distribution = distributionInfo[_distributionType];

        require(distribution.tokensAllotment == 0, "investor already added");

        distribution.beneficiary = _beneficiary;
        distribution.withdrawnTokens = _withdrawnTokens;
        distribution.tokensAllotment = _tokensAllotment;
        distribution.distributionType = _distributionType;

        emit DistributionAdded(_beneficiary, _msgSender(), _tokensAllotment);
    }

    function withdrawTokens(uint256 _distributionType) external onlyOwner() initialized() {
        Distribution storage distribution = distributionInfo[DistributionType(_distributionType)];

        uint256 tokensAvailable = withdrawableTokens(DistributionType(_distributionType));

        require(tokensAvailable > 0, "no tokens available for withdrawl");

        distribution.withdrawnTokens = distribution.withdrawnTokens.add(tokensAvailable);
        _blankToken.safeTransfer(distribution.beneficiary, tokensAvailable);

        emit WithdrawnTokens(_msgSender(), tokensAvailable);
    }

    /// @dev The starting time of TGE
    /// @param _timestamp The initial timestamp, this timestap should be used for vesting
    function setInitialTimestamp(uint256 _timestamp) external onlyOwner() notInitialized() {
        // isInitialized = true;
        _initialTimestamp = _timestamp;
    }

    function withdrawableTokens(DistributionType distributionType) public view returns (uint256 tokens) {
        Distribution storage distribution = distributionInfo[distributionType];
        uint256 availablePercentage = _calculateAvailablePercentage(distributionType);
        // console.log("Available Percentage: %s", availablePercentage);
        uint256 noOfTokens = _calculatePercentage(distribution.tokensAllotment, availablePercentage);
        uint256 tokensAvailable = noOfTokens.sub(distribution.withdrawnTokens);

        // console.log("Withdrawable Tokens: %s",  tokensAvailable);
        return tokensAvailable;
    }

    function _calculatePercentage(uint256 _amount, uint256 _percentage) private pure returns (uint256 percentage) {
        return _amount.mul(_percentage).div(100).div(1e18);
    }

    function _calculateAvailablePercentage(DistributionType distributionType)
        private
        view
        returns (uint256 _availablePercentage)
    {
        uint256 currentTimeStamp = block.timestamp;
        uint256 noOfMonths = BokkyPooBahsDateTimeLibrary.diffMonths(_initialTimestamp, currentTimeStamp);

        if (currentTimeStamp > _initialTimestamp) {
            if (distributionType == DistributionType.MARKETING) {
                return marketingVesting[noOfMonths];
            } else if (distributionType == DistributionType.LIQUIDITY) {
                return liqudityVesting[noOfMonths];
            } else if (
                distributionType == DistributionType.TEAM ||
                distributionType == DistributionType.ADVISORS ||
                distributionType == DistributionType.DEVELOPMENT
            ) {
                return cliffVesting[noOfMonths];
            }
        }
    }

    function recoverExcessToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }
}