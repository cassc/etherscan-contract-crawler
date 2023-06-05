// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMintable {
    function mint(address _receiver, uint256 _amount) external;
    function mintDao(address _receiver, uint256 _amount, bool community) external;
}

abstract contract GROBaseVesting is Ownable {
    using SafeERC20 for IERC20;

    uint256 internal constant ONE_YEAR_SECONDS = 31556952; // average year (including leap years) in seconds
    uint256 internal constant START_TIME_LOWER_BOUND = 604800 * 3; // 3 Weeks
    uint256 internal constant VESTING_TIME = ONE_YEAR_SECONDS * 3; // 3 years period
    uint256 internal constant VESTING_CLIFF = ONE_YEAR_SECONDS; // 1 years period
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = 10000; // BP
    uint256 public immutable QUOTA;
    uint256 public immutable VESTING_START_TIME;

    uint256 public vestingAssets;

    IMintable public distributer;

    event LogNewDistributer(address indexed distributer);

    constructor(uint256 startTime, uint256 quota) {
        VESTING_START_TIME = startTime;
        QUOTA = quota;
    }

    function setDistributer(address _distributer) external onlyOwner {
        distributer = IMintable(_distributer);
        emit LogNewDistributer(_distributer);
    }

    /// @notice Create or modify a vesting position
    function vest(address account, uint256 startDate, uint256 amount) external virtual;

    /// @notice Claim an amount of tokens
    function claim(uint256 amount) external virtual;

    /// @notice See the amount of vested assets the account has accumulated
    /// @param account Account to get vested amount for
    function unlockedBalance(address account)
        internal
        view
        virtual
        returns ( uint256, uint256, uint256, uint256 );

    /// @notice How much of the quota is unlocked, vesting and available
    function globallyUnlocked() public view virtual returns (uint256 unlocked, uint256 vesting, uint256 available) {
        if (block.timestamp > VESTING_START_TIME + VESTING_TIME) {
            unlocked = QUOTA;
        } else {
            unlocked = (QUOTA) * (block.timestamp - VESTING_START_TIME) / (VESTING_TIME);
        }
        vesting = vestingAssets;
        available = unlocked - vesting;
    }

    /// @notice Get total size of position, vested + vesting
    /// @param account Target account
    function totalBalance(address account) external view virtual returns (uint256 unvested);

    /// @notice Get current vested position
    /// @param account Target account
    function vestedBalance(address account) external view returns (uint256 vested, uint256 available) {
        (vested, available, , ) = unlockedBalance(account);
    }
}