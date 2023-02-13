// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../meta-transactions/ContextMixin.sol";
import "../meta-transactions/NativeMetaTransaction.sol";

contract BUSDFactory is ContextMixin, AccessControl, Pausable, ReentrancyGuard, NativeMetaTransaction {
    using SafeERC20 for IERC20;
    string public constant name = "Playbux BUSD Factory";
    uint256 public constant BLOCK_PER_DAY = 28000;

    IERC20 public immutable busd;

    address public admin;
    uint256 public withdrawalLimitPerDay = 5000 ether;

    mapping(address => uint256) public withdrawAmount;
    mapping(address => uint256) public lastWithdraw;

    event Withdraw(string _transactionId, address indexed _receiver, uint256 _value);
    event EmergencyWithdraw(address indexed _from, uint256 _value);
    event WithdrawalLimitPerDayChanged(uint256 oldLimit, uint256 newLimit);
    event AdminChanged(address oldAdmin, address newAdmin);

    constructor(IERC20 _busd, address _admin) {
        require(address(_busd) != address(0), "BUSD address is invalid");
        require(_admin != address(0), "Admin address is invalid");
        busd = _busd;
        admin = _admin;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _initializeEIP712(name);
        _pause();
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin, "Only admin can call this function");
        _;
    }

    function withdraw(
        string memory _transactionId,
        uint256 _expirationBlock,
        address _receiver,
        uint256 _amount
    ) external nonReentrant whenNotPaused onlyAdmin {
        require(block.number < _expirationBlock, "Meta transaction is expired");

        if (block.number - lastWithdraw[_receiver] > BLOCK_PER_DAY) {
            require(_amount <= withdrawalLimitPerDay, "Withdrawal limit exceeded");
            withdrawAmount[_receiver] = 0; // reset amount
            lastWithdraw[_receiver] = block.number;
        } else {
            require(
                withdrawAmount[_receiver] + _amount <= withdrawalLimitPerDay,
                "Withdrawal limit per day is exceeded"
            );
        }

        withdrawAmount[_receiver] += _amount;
        require(busd.transfer(_receiver, _amount), "Transfer failed");

        emit Withdraw(_transactionId, _receiver, _amount);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setWithdrawalLimitPerDay(uint256 _limit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _oldLimit = withdrawalLimitPerDay;
        withdrawalLimitPerDay = _limit;

        emit WithdrawalLimitPerDayChanged(_oldLimit, _limit);
    }

    function setAdmin(address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "Admin address is invalid");
        address _oldAdmin = admin;
        admin = _admin;

        emit AdminChanged(_oldAdmin, _admin);
    }

    function emergencyWithdraw(IERC20 _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _token.safeTransfer(_msgSender(), _token.balanceOf(address(this)));

        emit EmergencyWithdraw(_msgSender(), _token.balanceOf(address(this)));
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    fallback() external {}
}