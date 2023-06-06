// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./libs/@openzeppelin/contracts/access/Ownable.sol";
import "./libs/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libs/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./timelocks/EvenDistributionTimelock.sol";
import "./timelocks/PresaleTimelock.sol";
import "./timelocks/TeamTimelock.sol";
import "./interfaces/IOwnable.sol";

contract TimelockFactory is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public timelockOwner;

    address[] public partnerships;
    address[] public marketings;
    address[] public presales;
    address[] public teams;

    mapping(address => bool) private _validAddress;

    event PartnershipTimelockCreated(
        address timelock,
        address beneficiary,
        uint256 totalAmount,
        uint256 initialUnlockAmount,
        uint256 monthlyUnlockAmount,
        uint256 durationInMonth
    );
    event MarketingTimelockCreated(
        address timelock,
        address beneficiary,
        uint256 totalAmount,
        uint256 initialUnlockAmount,
        uint256 monthlyUnlockAmount,
        uint256 durationInMonth
    );
    event PresaleTimelockCreated(
        address timelock,
        address beneficiary,
        uint256 totalAmount,
        uint256 cliffPeriodInMonth,
        uint256 vestingPeriodInMonth
    );
    event TeamTimelockCreated(
        address timelock,
        address beneficiary,
        uint256 totalAmount,
        uint256 cliffPeriodInMonth,
        uint256 vestingPeriodInMonth
    );
    event Rescued(address token, uint256 amount);
    event TimelockOwnerChanged(address timelockOwner, address newTimelockOwner, address msgSender);

    constructor(IERC20 _token) Ownable() {
        require(address(_token) != address(0), "token address cannot be zero");
        token = _token;
    }

    function createPartnershipsTimelock(
        address beneficiary,
        uint256 totalAmount,
        uint256 initialUnlockAmount,
        uint256 monthlyUnlockAmount,
        uint256 durationInMonth
    ) external onlyOwner nonReentrant {
        require(timelockOwner != address(0), "timelock owner address must not be zero");
        address timelock = address(
            new EvenDistributionTimelock(
                token,
                beneficiary,
                totalAmount,
                initialUnlockAmount,
                monthlyUnlockAmount,
                durationInMonth
            )
        );

        IOwnable(timelock).transferOwnership(timelockOwner);
        partnerships.push(timelock);
        _validAddress[timelock] = true;

        emit PartnershipTimelockCreated(
            timelock,
            beneficiary,
            totalAmount,
            initialUnlockAmount,
            monthlyUnlockAmount,
            durationInMonth
        );
    }

    function createMarketingTimelock(
        address beneficiary,
        uint256 totalAmount,
        uint256 initialUnlockAmount,
        uint256 monthlyUnlockAmount,
        uint256 durationInMonth
    ) external onlyOwner nonReentrant {
        require(timelockOwner != address(0), "timelock owner address must not be zero");
        address timelock = address(
            new EvenDistributionTimelock(
                token,
                beneficiary,
                totalAmount,
                initialUnlockAmount,
                monthlyUnlockAmount,
                durationInMonth
            )
        );

        IOwnable(timelock).transferOwnership(timelockOwner);
        marketings.push(timelock);
        _validAddress[timelock] = true;

        emit MarketingTimelockCreated(
            timelock,
            beneficiary,
            totalAmount,
            initialUnlockAmount,
            monthlyUnlockAmount,
            durationInMonth
        );
    }

    function createPresaleTimelock(
        address beneficiary,
        uint256 totalAmount,
        uint256 cliffPeriodInMonth,
        uint256 vestingPeriodInMonth
    ) external onlyOwner nonReentrant {
        require(timelockOwner != address(0), "timelock owner address must not be zero");
        address timelock = address(
            new PresaleTimelock(token, beneficiary, totalAmount, cliffPeriodInMonth, vestingPeriodInMonth)
        );

        IOwnable(timelock).transferOwnership(timelockOwner);
        presales.push(timelock);
        _validAddress[timelock] = true;

        emit PresaleTimelockCreated(timelock, beneficiary, totalAmount, cliffPeriodInMonth, vestingPeriodInMonth);
    }

    function createTeamTimelock(
        address beneficiary,
        uint256 totalAmount,
        uint256 cliffPeriodInMonth,
        uint256 vestingPeriodInMonth
    ) external onlyOwner nonReentrant {
        require(timelockOwner != address(0), "timelock owner address must not be zero");
        address timelock = address(
            new TeamTimelock(token, beneficiary, totalAmount, cliffPeriodInMonth, vestingPeriodInMonth)
        );

        IOwnable(timelock).transferOwnership(timelockOwner);
        teams.push(timelock);
        _validAddress[timelock] = true;

        emit TeamTimelockCreated(timelock, beneficiary, totalAmount, cliffPeriodInMonth, vestingPeriodInMonth);
    }

    function rescue(address targetToken) external onlyOwner nonReentrant {
        uint256 amount = IERC20(targetToken).balanceOf(address(this));
        if (amount > 0) {
            IERC20(targetToken).safeTransfer(owner(), amount);
            emit Rescued(targetToken, amount);
        }
    }

    function isValidAddress(address target) external view returns (bool) {
        return _validAddress[target];
    }

    function setTimelockOwner(address newTimelockOwner) external onlyOwner {
        require(newTimelockOwner != address(0), "timelock owner address must not be zero");

        emit TimelockOwnerChanged(timelockOwner, newTimelockOwner, msg.sender);
        timelockOwner = newTimelockOwner;
    }
}