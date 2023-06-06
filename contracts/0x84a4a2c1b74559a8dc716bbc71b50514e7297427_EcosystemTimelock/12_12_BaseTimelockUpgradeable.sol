// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../../libs/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../libs/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../libs/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../libs/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../libs/DateTime.sol";

abstract contract BaseTimelockUpgradeable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using DateTime for uint256;

    IERC20 public token;
    address public beneficiary;

    uint256 public totalAmount;
    uint256 public claimedAmount;

    uint256 public start;

    event Started(uint256 start, uint256 totalAmount, address beneficiary);
    event Claimed(address token, address beneficiary, uint256 claimAmount, uint256 claimedAmount);
    event Rescued(address targetToken, uint256 amount);

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "caller is not the beneficiary");
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __BaseTimelock_init(IERC20 _token, address _beneficiary, uint256 _totalAmount) internal onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init();
        __BaseTimelock_init_unchained(_token, _beneficiary, _totalAmount);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __BaseTimelock_init_unchained(
        IERC20 _token,
        address _beneficiary,
        uint256 _totalAmount
    ) internal onlyInitializing {
        token = _token;
        beneficiary = _beneficiary;
        totalAmount = _totalAmount;
        start = type(uint256).max;
    }

    function setStart(uint256 _start) external onlyOwner {
        require(start == type(uint256).max, "start timestamp is already set");

        start = _start;
        token.safeTransferFrom(owner(), address(this), totalAmount);
        emit Started(start, totalAmount, beneficiary);
    }

    function claim(uint256 amount) public virtual nonReentrant {
        require(amount > 0, "amount cannot be zero");
        require(claimableAmount() >= amount, "claim amount exceeds claimable amount");
        claimedAmount += amount;
        emit Claimed(address(token), beneficiary, amount, claimedAmount);
        token.safeTransfer(beneficiary, amount);
    }

    function claimableAmount() public view returns (uint256) {
        return unlockedAmount() - claimedAmount;
    }

    function unlockedAmount() public view returns (uint256) {
        return unlockedAmountAt(block.timestamp);
    }

    function unlockedAmountAt(uint256 timestamp) public view virtual returns (uint256);

    function rescue(address targetToken) external onlyOwner {
        uint256 amount = IERC20(targetToken).balanceOf(address(this));
        if (start != type(uint256).max && targetToken == address(token)) {
            amount = amount + claimedAmount - totalAmount;
        }
        if (amount > 0) {
            IERC20(targetToken).safeTransfer(owner(), amount);
            emit Rescued(targetToken, amount);
        }
    }

    /**
     * calculate the month difference between two timestamps
     */
    function _diffMonth(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 month) {
        require(fromTimestamp <= toTimestamp, "invalid usage");
        month = fromTimestamp.diffMonths(toTimestamp);
        if (fromTimestamp.addMonths(month) > toTimestamp) {
            month -= 1;
        }
        // we decide to unlock in advance
        month += 1;
    }

    uint256[50] private __gap;
}