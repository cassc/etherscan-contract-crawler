// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author MELD team
/// @title MeldBankSignup
/// @notice MeldBankSignup is a contract that allows users to redeem bank signup codes for 1$ worth of tokens
contract MeldBankSignup is AccessControl {
    using SafeERC20 for IERC20;

    /// @dev Address to identify native token
    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Error messages
    string public constant ERR_ADMIN_ZERO_ADDRESS =
        "MeldBankSignup: Default admin cannot be the zero address";
    string public constant ERR_FEE_RECEIVER_ZERO_ADDRESS =
        "MeldBankSignup: Fee Receiver cannot be the zero address";
    string public constant ERR_TOKEN_ZERO_ADDRESS =
        "MeldBankSignup: Token address cannot be the zero address";
    string public constant ERR_TOKEN_NOT_SUPPORTED = "MeldBankSignup: Token not supported";
    string public constant ERR_NATIVE_TOKEN_NOT_SUPPORTED =
        "MeldBankSignup: Native token not supported";
    string public constant ERR_ARRAY_LENGTHS =
        "MeldBankSignup: Token addresses and fees lengths mismatch";
    string public constant ERR_NATIVE_TOKEN_AMOUNT =
        "MeldBankSignup: Incorrect native token amount";
    string public constant ERR_NATIVE_TOKEN_TRANSFER =
        "MeldBankSignup: Failed to send native token fee";
    string public constant ERR_CODE_USED = "MeldBankSignup: Code already used";

    /// @dev The fee for redeeming a bank signup code, every token has a fee that is $1 worth of that token approx.
    mapping(address tokenAddress => uint256 fee) public tokenFees;

    /// @dev The bank signup codes that have been redeemed
    mapping(bytes32 => bool) public redeemedCodes;

    /// @dev The address that receives the fees
    address public feeReceiver;

    event TokenFeeChanged(address indexed tokenAddress, uint256 fee);
    event FeeReceiverChanged(address indexed oldFeeReceiver, address indexed newFeeReceiver);
    event BankSignupCodeRedeemed(bytes32 indexed code, address indexed userAddress);

    /// @notice Creates the contract and sets the default admin and fee receiver
    /// @param _defaultAdmin The address that will be the default admin
    /// @param _feeReceiver The address that will receive the fees
    constructor(address _defaultAdmin, address _feeReceiver) {
        require(_defaultAdmin != address(0), ERR_ADMIN_ZERO_ADDRESS);
        require(_feeReceiver != address(0), ERR_FEE_RECEIVER_ZERO_ADDRESS);
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        feeReceiver = _feeReceiver;
    }

    /// @notice Sets the fee for a list of tokens
    /// @dev Only the admin can call this function
    /// @param _tokenAddresses The list of token addresses
    /// @param _tokenFees The list of fees for each token
    function setFees(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenFees
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenAddresses.length == _tokenFees.length, ERR_ARRAY_LENGTHS);
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenFees[_tokenAddresses[i]] = _tokenFees[i];
            emit TokenFeeChanged(_tokenAddresses[i], _tokenFees[i]);
        }
    }

    /// @notice Sets the fee receiver
    /// @dev Only the admin can call this function
    /// @param _feeReceiver The new fee receiver
    function setFeeReceiver(address _feeReceiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeReceiver != address(0), ERR_FEE_RECEIVER_ZERO_ADDRESS);
        emit FeeReceiverChanged(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    /// @notice Redeems a bank signup code paying 1$ worth of the specified token
    /// @dev The user must approve the contract to spend the token
    /// @param _code The bank signup code
    /// @param _tokenAddress The token address
    function redeemCode(bytes32 _code, address _tokenAddress) external {
        require(!redeemedCodes[_code], ERR_CODE_USED);
        require(_tokenAddress != address(0), ERR_TOKEN_ZERO_ADDRESS);
        require(tokenFees[_tokenAddress] > 0, ERR_TOKEN_NOT_SUPPORTED);
        emit BankSignupCodeRedeemed(_code, msg.sender);
        redeemedCodes[_code] = true;
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, feeReceiver, tokenFees[_tokenAddress]);
    }

    /// @notice Redeems a bank signup code paying 1$ worth of the native token
    /// @dev The user must send the native token
    /// @param _code The bank signup code
    function redeemCodeNative(bytes32 _code) external payable {
        require(!redeemedCodes[_code], ERR_CODE_USED);
        require(tokenFees[NATIVE_TOKEN_ADDRESS] > 0, ERR_NATIVE_TOKEN_NOT_SUPPORTED);
        require(msg.value == tokenFees[NATIVE_TOKEN_ADDRESS], ERR_NATIVE_TOKEN_AMOUNT);
        redeemedCodes[_code] = true;
        emit BankSignupCodeRedeemed(_code, msg.sender);
        (bool sent, ) = payable(feeReceiver).call{value: msg.value}("");
        require(sent, ERR_NATIVE_TOKEN_TRANSFER);
    }
}