//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/Withdrawable.sol";

contract Presale is Ownable, Withdrawable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public depositToken;
    address public treasuryAddress;

    bool public saleStarted;

    uint256 public depositCount;
    uint256 public hardcap = 125000 ether;
    uint256 public maxAmountPerWallet = 5000 ether;
    uint256 public minAmountPerBuy = 1 ether;
    uint256 public totalPayments;

    struct Depositor {
        address user;
        address receiver;
        uint256 depositAmount;
        bool tokensDistributed;
    }
    mapping(uint256 => Depositor) public deposits;
    mapping(address => uint256) public depositsPerWallet;

    event BuyFromPresale(
        address indexed user,
        address indexed receivingTokenWallet,
        uint256 indexed amount
    );
    event DistributeTokens(
        address indexed user,
        address indexed receiver,
        uint256 indexed amount
    );
    event TotalDistributed(
        address indexed user,
        uint256 indexed totalDistributed
    );

    error AmountIsZero();
    error BelowMinimumAmount();
    error ExistingDeposits();
    error HardCapExceeded();
    error MaxPerWalletExceeded();
    error PresaleNotStarted();
    error SaleStillActive();
    error TreasuryNotSet();

    constructor(
        address _depositToken,
        address _treasuryAddress
    ) checkZeroAddress(_depositToken) checkZeroAddress(_treasuryAddress) {
        depositToken = _depositToken;
        treasuryAddress = _treasuryAddress;
    }

    function buyFromPresale(
        address receivingTokenWallet,
        uint256 amount
    ) external checkZeroAddress(receivingTokenWallet) nonReentrant {
        if (!saleStarted) revert PresaleNotStarted();
        if (amount < minAmountPerBuy) revert BelowMinimumAmount();
        if (totalPayments + amount > hardcap) revert HardCapExceeded();
        if (depositsPerWallet[_msgSender()] + amount > maxAmountPerWallet) revert MaxPerWalletExceeded();
        IERC20(depositToken).transferFrom(_msgSender(), address(this), amount);
        depositsPerWallet[_msgSender()] += amount;
        deposits[depositCount] = Depositor({
            user: _msgSender(),
            receiver: receivingTokenWallet,
            depositAmount: amount,
            tokensDistributed: false
        });
        ++depositCount;
        totalPayments += amount;
        emit BuyFromPresale(_msgSender(), receivingTokenWallet, amount);
    }

    function distributeTokens(
        address token
    ) external onlyOwner checkZeroAddress(token) {
        if (saleStarted) revert SaleStillActive();
        uint256 tokensDistributed;
        for (uint256 x; x < depositCount; ++x) {
            Depositor storage depositor = deposits[x];
            if (depositor.tokensDistributed) continue;
            depositor.tokensDistributed = true;
            IERC20(token).transferFrom(
                _msgSender(),
                depositor.receiver,
                depositor.depositAmount
            );
            tokensDistributed += depositor.depositAmount;
            emit DistributeTokens(
                depositor.user,
                depositor.receiver,
                depositor.depositAmount
            );
        }
        emit TotalDistributed(_msgSender(), tokensDistributed);
    }

    function getHardCap() external view returns (uint256) {
        return hardcap;
    }

    function getTotalPayments() external view returns (uint256) {
        return totalPayments;
    }

    function isSaleStarted() external view returns (bool) {
        return saleStarted;
    }

    function setDepositToken(
        address value
    ) external checkZeroAddress(value) onlyOwner {
        if (totalPayments > 0) revert ExistingDeposits();
        depositToken = value;
    }

    function setHardCap(uint256 value) external onlyOwner {
        if (value == 0) revert AmountIsZero();
        hardcap = value;
    }

    function setMaxAmountPerWallet(uint256 value) external onlyOwner {
        if (value == 0) revert AmountIsZero();
        maxAmountPerWallet = value;
    }

    function setMinAmountForPurchase(uint256 value) external onlyOwner {
        if (value == 0) revert AmountIsZero();
        minAmountPerBuy = value;
    }

    function setSaleStarted(bool value) external onlyOwner {
        saleStarted = value;
    }

    function setTreasuryAddress(
        address value
    ) external checkZeroAddress(value) onlyOwner {
        treasuryAddress = value;
    }

    function withdrawBNB() external onlyOwner nonReentrant {
        _withdrawNativeToTreasury(treasuryAddress);
    }

    function withdrawDeposits() external onlyOwner nonReentrant {
        _withdrawTokensToTreasury(treasuryAddress, depositToken);
    }

    function withdrawTokens(
        address token
    ) external onlyOwner checkZeroAddress(token) nonReentrant {
        _withdrawTokensToTreasury(treasuryAddress, token);
    }

}