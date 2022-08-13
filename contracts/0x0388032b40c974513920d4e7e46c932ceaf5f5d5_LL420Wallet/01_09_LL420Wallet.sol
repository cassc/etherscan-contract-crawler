//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Wallet
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error ZeroAddress();
error InvalidAmount();
error ExceededAmount();
error NotAllowedSender();
error NotAllowedAction();
error InvalidSignature();

contract LL420Wallet is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSA for bytes32;

    struct UserWallet {
        uint256 balance;
    }

    mapping(address => UserWallet) public wallets;
    mapping(address => bool) public permissioned;
    bool public selfWithdrawAllowed;
    address public highTokenAddress;

    /// @dev validator for verification
    mapping(bytes => bool) public isUsedSig;
    address private _validator;

    event Deposit(address indexed _user, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _amount);
    event WithdrawToPoint(address indexed _user, uint256 _amount, uint256 _timestamp);
    event WithdrawToWallet(address indexed _user, uint256 _amount);
    event ConvertFromBP(address indexed _who, uint256 _amount);

    modifier onlyAllowed() {
        if (permissioned[_msgSender()] == false) revert NotAllowedSender();
        _;
    }

    function initialize() external initializer {
        __Context_init();
        __Ownable_init();

        allowAddress(_msgSender(), true);
    }

    function deposit(address _user, uint256 _amount) external onlyAllowed {
        _deposit(_user, _amount);
    }

    function withdraw(address _user, uint256 _amount) external onlyAllowed {
        _withdraw(_user, _amount);
    }

    function balance(address _user) external view returns (uint256) {
        return wallets[_user].balance;
    }

    function withdraw(uint256 _amount) external {
        if (selfWithdrawAllowed == false) revert NotAllowedAction();

        _withdraw(_msgSender(), _amount);
    }

    function withdrawToPoint(uint256 _amount) external {
        if (selfWithdrawAllowed == false) revert NotAllowedAction();

        _withdraw(_msgSender(), _amount);

        emit WithdrawToPoint(_msgSender(), _amount, block.timestamp);
    }

    function withdrawToWallet(uint256 _amount) external {
        if (selfWithdrawAllowed == false) revert NotAllowedAction();
        if (_msgSender() == address(0) || highTokenAddress == address(0)) revert ZeroAddress();
        if (_amount <= 0) revert InvalidAmount();
        if (wallets[_msgSender()].balance < _amount) revert ExceededAmount();

        wallets[_msgSender()].balance -= _amount;

        IERC20Upgradeable(highTokenAddress).safeTransferFrom(address(this), _msgSender(), _amount);

        emit WithdrawToWallet(_msgSender(), _amount);
    }

    /**
     * @dev converts the BP to high balance in wallet
     *
     * @param _to BP will be converted and charged to this address
     * @param _amount Amount to deposit
     * @param _timestamp Timestamp to verify the signature
     * @param _signature Signature is generated from LL backend
     */
    function convertFromBP(
        address _to,
        uint256 _amount,
        uint256 _timestamp,
        bytes memory _signature
    ) external {
        if (isUsedSig[_signature] == true) revert InvalidSignature();
        if (_msgSender() != _to) revert NotAllowedSender();
        if (_verify(_to, 0, _amount, _timestamp, _signature) == false) revert NotAllowedSender();

        isUsedSig[_signature] = true;
        wallets[_to].balance += _amount;

        emit ConvertFromBP(_to, _amount);
    }

    /* ==================== OWNER METHODS ==================== */

    function allowAddress(address _user, bool _allowed) public onlyOwner {
        if (_user == address(0)) revert ZeroAddress();

        permissioned[_user] = _allowed;
    }

    function setHighToken(address _address) external onlyOwner {
        highTokenAddress = _address;
    }

    function allowSelfWithdraw(bool _enable) public onlyOwner {
        selfWithdrawAllowed = _enable;
    }

    /**
     * @dev Owner can set the validator address
     *
     * @param _account The validator address
     */
    function setValidator(address _account) external onlyOwner {
        _validator = _account;
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev Verify if the signature is right and available to deposit
     *
     * @param _to BP will be converted and charged to this address
     * @param _amount Amount to deposit
     * @param _timestamp Timestamp to verify the signature
     * @param _signature Signature is generated from LL backend
     */
    function _verify(
        address _to,
        uint256 _id,
        uint256 _amount,
        uint256 _timestamp,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 signedHash = keccak256(abi.encodePacked(_to, keccak256("ConvertBP2HIGH"), _id, _amount, _timestamp));
        bytes32 messageHash = signedHash.toEthSignedMessageHash();
        address messageSender = messageHash.recover(_signature);

        if (messageSender != _validator) return false;

        return true;
    }

    function _deposit(address _user, uint256 _amount) internal {
        if (_user == address(0)) revert ZeroAddress();
        if (_amount <= 0) revert InvalidAmount();

        wallets[_user].balance += _amount;

        emit Deposit(_user, _amount);
    }

    function _withdraw(address _user, uint256 _amount) internal {
        if (_user == address(0)) revert ZeroAddress();
        if (_amount <= 0) revert InvalidAmount();
        if (wallets[_user].balance < _amount) revert ExceededAmount();

        wallets[_user].balance -= _amount;

        emit Withdraw(_user, _amount);
    }
}