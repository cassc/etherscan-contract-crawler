// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title
 *
 * @dev This contract includes the following functionality:
 *  - deposit tokens and eth
 *  - withdraw tokens and eth
 *  - send amount of ETH or tokens by keeper call to receiver address
 */
contract Wallet is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public keeper;
    bool public active;

    // errors
    error ContractNotActive();
    error IncorrectAmount();
    error InsufficientBalance();
    error NotAuthorizedCaller();
    error NotAuthorizedToken();
    error TransactionFailed();
    error ZeroAddress();

    // events
    event ChangedActiveStatus(bool indexed status);
    event ChangedAuthorizedTokens(IERC20 indexed token, bool indexed status);
    event DepositEth(address indexed eth, address indexed user, uint256 indexed amount);
    event DepositTokens(IERC20 indexed token, address indexed user, uint256 indexed amount);
    event KeeperChanged(address indexed newKeeperAddress);
    event TransferredAmount(address indexed to, uint256 indexed amount);
    event TransferredTokenAmount(IERC20 indexed token, address receiver, uint256 indexed amount);
    event Withdraw(address indexed token, uint256 indexed amount);
    event WithdrawToken(IERC20 indexed token, uint256 indexed amount);
    event WithdrawAll(address indexed sender, uint256 indexed amount);

    ///
    /// --- MODIFIERS
    ///
    /**
     * @notice Checks if the contract is active
     **/
    modifier onlyActive() {
        if (!isActive()) revert ContractNotActive();
        _;
    }

    /**
     * @notice Checks if the caller beck-end Keeper address
     **/
    modifier onlyKeeper() {
        if (keeper != msg.sender) revert NotAuthorizedCaller();
        _;
    }

    modifier zeroAddress(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }

    /// --- Constructor
    constructor(address _keeper) ReentrancyGuard() {
        setKeeper(_keeper);
        setActive(true);
    }

    ///
    ///-- KEEPER FUNCTIONS
    ///
    /**
     * @notice deposit eth
     */
    function depositEth() external payable onlyActive {
        if (msg.value <= 0) revert IncorrectAmount();

        emit DepositEth(address(0), msg.sender, msg.value);
    }

    /**
     * @dev only authorized address can send eth
     *
     * @param receiver - address to send tokens
     * @param amount - amount of tokens to send
     */
    function sendEthTo(
        address receiver,
        uint256 amount
    ) external onlyKeeper onlyActive nonReentrant zeroAddress(receiver) {
        if (address(this).balance <= amount) revert InsufficientBalance();
        if (amount <= 0) revert IncorrectAmount();

        _withdraw(receiver, amount);

        emit TransferredAmount(receiver, amount);
    }

    /**
     * @dev only authorized address can send tokens
     *
     * @param receiver - address to send tokens
     * @param token  - token address
     * @param amount - amount of tokens to send
     */
    function sendTokenTo(
        address receiver,
        IERC20 token,
        uint256 amount
    ) external onlyKeeper nonReentrant zeroAddress(receiver) onlyActive {
        if (getTokenBalance(token) <= amount) revert InsufficientBalance();
        if (amount <= 0) revert IncorrectAmount();

        _safeWithdrawToken(receiver, token, amount);

        emit TransferredTokenAmount(token, receiver, amount);
    }

    /**
     * @dev transferred amount of eth to receiver address
     *
     * @param _receiver destination address
     * @param _amount   amount of eth to transfer
     */
    function _withdraw(address _receiver, uint256 _amount) private {
        (bool os, ) = payable(_receiver).call{value: _amount}("");
        if (!os) revert TransactionFailed();

        emit Withdraw(address(0), _amount);
    }

    /**
     * @dev transferred amount of tokens to receiver address
     *
     * @param _receiver - destination address
     * @param _token - token address
     * @param _amount - amount of tokens to transfer
     */
    function _safeWithdrawToken(address _receiver, IERC20 _token, uint256 _amount) private {
        _token.safeTransfer(_receiver, _amount);

        emit WithdrawToken(_token, _amount);
    }

    ///
    /// --- Getters
    ///
    /**
     * @dev return contract balance in specified token
     *
     * @param token - token address
     */
    function getTokenBalance(IERC20 token) public view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));

        return balance;
    }

    /**
     * @dev return contract active status
     */
    function isActive() public view returns (bool) {
        return active;
    }

    ///
    /// -- onlyOwner
    ///
    /**
     * @dev only owner can set keeper address
     *
     * @param _keeper - keeper address
     */
    function setKeeper(address _keeper) public zeroAddress(_keeper) onlyOwner {
        keeper = _keeper;

        emit KeeperChanged(_keeper);
    }

    /**
     * @dev only owner can set active status of contract
     *
     * @param _active - true or false status of contract
     */
    function setActive(bool _active) public onlyOwner {
        active = _active;

        emit ChangedActiveStatus(_active);
    }

    /**
     * @dev only owner can withdraw all eth from contract balance
     *
     * @notice this function is only for emergency cases
     * owner can withdraw all eth from contract balance
     */
    function withdrawAllEth() external onlyOwner {
        uint256 _amount = address(this).balance;

        _withdraw(msg.sender, _amount);

        emit WithdrawAll(msg.sender, _amount);
    }

    /**
     * @dev owner withdraw specific amount of eth from contract balance
     *
     * @param _amount - amount of tokens to withdraw
     */
    function withdrawEth(uint256 _amount) external onlyOwner {
        if (address(this).balance < _amount) revert InsufficientBalance();

        _withdraw(msg.sender, _amount);

        emit Withdraw(address(0), _amount);
    }

    /**
     * @dev only owner can withdraw tokens
     *
     * @param token - token address
     * @param _amount - amount of tokens to withdraw
     */
    function withdrawToken(IERC20 token, uint256 _amount) external onlyOwner {
        if (IERC20(token).balanceOf(address(this)) < _amount) revert InsufficientBalance();

        _safeWithdrawToken(msg.sender, token, _amount);
    }

    function withdrawAllTokenBalance(IERC20 token) external onlyOwner {
        uint256 _amount = IERC20(token).balanceOf(address(this));

        _safeWithdrawToken(msg.sender, token, _amount);
    }

    /// @notice Will receive any eth sent to the contract
    receive() external payable {
        emit DepositEth(address(0), msg.sender, msg.value);
    }
}