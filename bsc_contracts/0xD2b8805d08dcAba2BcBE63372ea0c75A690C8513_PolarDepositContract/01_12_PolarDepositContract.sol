// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}

error NotAllowedInPrivateSale(address account);

contract PolarDepositContract is AccessControl, EIP712 {
    using SafeERC20 for IERC20;
    
    AggregatorV3Interface internal priceFeed;

    event DepositedToken(address indexed tokenAddress, address indexed sender, uint256 quantity, uint256 status, uint256 amount);
    event WithdrawedToken(address indexed tokenAddress, address indexed recipient, uint256 amount);
    
    error InvalidPrivateSaleAddress(address account);

    bytes32 public constant DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");
    
    bytes32 constant public DEPOSIT_TYPEHASH = keccak256("DepositToken(address account,uint256 quantity,uint256 amount,uint256 deadline,uint256 nonce,uint256 status,bool isWhitelisted)");

    address private immutable _acceptToken;

    mapping(address => uint256) private _accountNonces;

    uint256 public constant PUBLIC_SALE_PRICE = 25; // 0.025 with 3 decimals
    uint256 public constant QUANTITY_DECIMAL = 1e6; // 6 decimals

    constructor(
        address acceptToken, 
        address owner, 
        address priceAggregator, 
        address depositRoleAccount
    ) EIP712("PolarDepositContract", "1.0.0") {
        _acceptToken = acceptToken;
        priceFeed = AggregatorV3Interface(priceAggregator);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(DEPOSIT_ROLE, depositRoleAccount);
    }

    /**
    @dev Setup deposit role
     */
    function setupDepositRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEPOSIT_ROLE, account);
    }
    
    /**
     * @dev Return nonce
     */
    function getAccountNonce(address account) external view returns(uint256) {
        return _accountNonces[account];
    }

    /**
    @dev Deposit Token
    @param quantity NFT items quantity
    @param amount deposit token amount
    @param deadline deposit deadline
    @param signature hashed signature
    * Contract can not execute this function
    */
    function depositToken(
        uint256 quantity, 
        uint256 amount, 
        uint256 deadline, 
        uint256 status, 
        bool isWhitelisted,
        bytes calldata signature
    ) external {
        require(_msgSender() == tx.origin, "Contract address is not allowed");
        require(block.timestamp <= deadline, "Invalid expiration in deposit");
        require(status > 0, "Sale is not started yet");
        if(status == 1 && !isWhitelisted) revert NotAllowedInPrivateSale(_msgSender());
        uint256 validNonce = _accountNonces[_msgSender()];
        require(_verify(_hash(_msgSender(), quantity, amount, deadline, validNonce, status, isWhitelisted), signature), "Invalid signature");

        unchecked {
            ++ _accountNonces[_msgSender()];
        }
        IERC20(_acceptToken).safeTransferFrom(_msgSender(), address(this), amount);
        emit DepositedToken(_acceptToken, _msgSender(), quantity, status, amount);
    }
    
    function depositNativeToken() payable external {
        ( , int nativeTokenPrice, , , ) = priceFeed.latestRoundData();

        uint depositedTokenPriceInUsd = msg.value * uint(nativeTokenPrice) / 1 ether;
        uint quantity = depositedTokenPriceInUsd * 1e3 * QUANTITY_DECIMAL / PUBLIC_SALE_PRICE / 1e8;
        // Send zero address to indicate native token
        emit DepositedToken(address(0), _msgSender(), quantity, 2, msg.value);
    }

    function _hash(address account, uint256 quantity, uint256 amount, uint256 deadline, uint256 nonce, uint256 status, bool isWhitelisted)
    internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            DEPOSIT_TYPEHASH,
            account,
            quantity,
            amount,
            deadline,
            nonce,
            status,
            isWhitelisted
        )));
    }

    function _verify(bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
        return hasRole(DEPOSIT_ROLE, ECDSA.recover(digest, signature));
    }

    /**
    @dev Withdraw Token
    * only Admin can execute this function
     */
    function withdrawToken(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_acceptToken).safeTransfer(recipient, amount);
        emit WithdrawedToken(_acceptToken, recipient, amount);
    }

    /// @dev Withdraw native token
    function withdrawNativeToken(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance >= amount, "Not enough balance");
        (bool sent, ) = payable(recipient).call{value: amount}("");
        require(sent, "Failed to send Native Token");
        emit WithdrawedToken(address(0), recipient, amount);
    }
}