// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @custom:security-contact [email protected]
contract SP is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    uint256 public CLAIM_FEE_PERCENT;
    uint32 public MIN_PAYMENT_AMOUNT;
    address public BUSD_ADDRESS;
    uint256 public BASIC_PACKAGE_PRICE;
    uint256 public DEVELOPER_FEE;
    IERC20 usdt;

    struct User {
        uint32 total_left_point;
        uint32 total_right_point;
        uint32 saved_left_point;
        uint32 saved_right_point;
        uint256 total_gift;
        address account;
        address refAccount;
        uint256 rank;
    }
    struct Account {
        address user;
        bool valid;
    }
    mapping(address => User) public users;
    mapping(address => Account) public accounts;
    mapping(address => uint256) balances;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("SP", "SMP");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        BUSD_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        usdt = IERC20(address(BUSD_ADDRESS));
        MIN_PAYMENT_AMOUNT = 0;
        DEVELOPER_FEE = 11 ether;
        CLAIM_FEE_PERCENT = 5;
        BASIC_PACKAGE_PRICE = 100 ether;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    receive() external payable {}

    function deposit() external payable {
        uint256 totalPrice = BASIC_PACKAGE_PRICE + DEVELOPER_FEE;
        require(msg.value == totalPrice, "Payable amount is not valid");
        balances[msg.sender] += msg.value;
    }

    function transferTo(address _to, uint256 _amount)
        public
        whenNotPaused
        onlyOwner
    {
        usdt.safeTransfer(_to, _amount);
    }

    function withdraw(address[] calldata recipients, uint256[] calldata amount)
        external
        onlyOwner
        whenNotPaused
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            transferTo(recipients[i], amount[i]);
        }
    }

    function addAccount(address account) public onlyOwner {
        accounts[account] = Account(account, true);
    }

    function userExist(address account) public view onlyOwner returns (bool) {
        if (accounts[account].valid) {
            return true;
        }
        return false;
    }

    function setBasicPackagePrice(uint256 newPrice) public onlyOwner {
        BASIC_PACKAGE_PRICE = newPrice * 1 ether;
    }

    function setClaimFee(uint256 newFee) public onlyOwner {
        CLAIM_FEE_PERCENT = newFee;
    }

    function setDevFee(uint256 newFee) public onlyOwner {
        DEVELOPER_FEE = newFee * 1 ether;
    }

    function getUserTotalProfit(User calldata user)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return user.total_left_point + user.total_right_point;
    }

    function claimGift(User memory user) public onlyOwner {
        require(user.total_gift > 0, "No gift available for claim");
        transferTo(user.account, user.total_gift);
        user.total_gift = 0;
    }

    function getUserRightPoint(User calldata user)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return user.total_right_point;
    }

    function getUserLeftPoint(User calldata user)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return user.total_left_point;
    }

    function balanceAcount(User memory user) public onlyOwner {
        require(
            user.saved_left_point > 0 && user.saved_right_point > 0,
            "Insufficient Points"
        );
        user.saved_left_point -= 1;
        user.saved_right_point -= 1;
        user.total_left_point += 1;
        user.total_right_point += 1;
        transferTo(user.account, 20);
    }

    function checkRank(User memory user) public onlyOwner {
        if (user.total_left_point == 250 && user.total_right_point == 250) {
            user.rank = 1;
        } else if (
            user.total_left_point == 1000 && user.total_right_point == 1000
        ) {
            user.rank = 2;
        } else if (
            user.total_left_point == 2500 && user.total_right_point == 2500
        ) {
            user.rank = 3;
        } else if (
            user.total_left_point == 5000 && user.total_right_point == 5000
        ) {
            user.rank = 4;
        } else if (
            user.total_left_point == 10000 && user.total_right_point == 10000
        ) {
            user.rank = 5;
        }
        paymentByRank(user.account, user.rank);
    }

    function fixedIncomePayment(address to, uint256 rank) public onlyOwner {
        require(rank > 3, "User rank must be greater than level 3");
        uint256 amount = 0;
        if (rank == 4) {
            // Payments for 5000:5000 points
            amount = 5000;
        } else if (rank == 5) {
            // Payments for 10000:10000 points
            amount = 10000;
        }
        transferTo(to, amount);
    }

    function paymentByRank(address to, uint256 rank) public onlyOwner {
        uint256 amount = 0;
        if (rank == 1) {
            // Payments for 250:250 points
            amount = 1000;
        } else if (rank == 2) {
            // Payments for 1000:1000 points
            amount = 2500;
        } else if (rank == 3) {
            // Payments for 2500:2500 points
            amount = 8000;
        }
        transferTo(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}