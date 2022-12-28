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

contract DepositPRVTX is AccessControl, EIP712 {
    using SafeERC20 for IERC20;
    
    AggregatorV3Interface internal priceFeed;

    event DepositedToken(address indexed tokenAddress, address indexed sender, uint256 quantity, uint256 status, uint256 amount);
    event WithdrawedToken(address indexed tokenAddress, address indexed recipient, uint256 amount);
    
    error InvalidPrivateSaleAddress(address account);

    bytes32 public constant DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");
    
    bytes32 constant public DEPOSIT_TYPEHASH = keccak256("DepositToken(address account,uint256 quantity,uint256 amount,uint256 deadline,uint256 nonce,uint256 status,bool isWhitelisted)");

    address private immutable _acceptToken;

    mapping(address => uint256) private depositedQuantity;

    uint256 public constant PRIVATE_SALE_PRICE = 1; // 0.001 with 3 decimals
    uint256 public constant QUANTITY_DECIMAL = 1e6; // 6 decimals

    constructor(
        address acceptToken, 
        address owner, 
        address priceAggregator, 
        address depositRoleAccount
    ) EIP712("DepositPRVTX", "1.0.0") {
        _acceptToken = acceptToken;
        priceFeed = AggregatorV3Interface(priceAggregator);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(DEPOSIT_ROLE, depositRoleAccount);
    }

    /**
    @dev Setup deposit role
     */
    function setupAdminRole(address owner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    /**
    @dev Setup deposit role
     */
    function setupDepositRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEPOSIT_ROLE, account);
    }

    /**
     * @dev Return deposited quantity
     */
    function getDepositedQty(address account) external view returns(uint256) {
        return depositedQuantity[account];
    }
    
    /**
    @dev Deposit Token
    @param quantity NFT items quantity
    @param amount deposit token amount
    * Contract can not execute this function
    */
    function depositToken(
        uint256 quantity, 
        uint256 amount, 
        uint256 status, 
        bool isWhitelisted
    ) external {
        require(_msgSender() == tx.origin, "Contract address is not allowed");
        require(status > 0, "Sale is not started yet");
        if(status == 1 && !isWhitelisted) revert NotAllowedInPrivateSale(_msgSender());

        IERC20(_acceptToken).safeTransferFrom(_msgSender(), address(this), amount);
        depositedQuantity[_msgSender()] += quantity;
        emit DepositedToken(_acceptToken, _msgSender(), quantity, status, amount);
    }
    
    function depositNativeToken() payable external {
        ( , int nativeTokenPrice, , , ) = priceFeed.latestRoundData();

        uint depositedTokenPriceInUsd = msg.value * uint(nativeTokenPrice) / 1 ether;
        uint quantity = depositedTokenPriceInUsd * 1e3 * QUANTITY_DECIMAL / PRIVATE_SALE_PRICE / 1e8;
        depositedQuantity[_msgSender()] += quantity;
        // Send zero address to indicate native token
        emit DepositedToken(address(0), _msgSender(), quantity, 2, msg.value);
    }    

    /**
    @dev Withdraw Token
    * only Admin can execute this function
     */
    function withdrawToken(address recipient, uint256 amount, uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(depositedQuantity[recipient] >= quantity, "Not enough quantity");
        IERC20(_acceptToken).safeTransfer(recipient, amount);        
        depositedQuantity[recipient] -= quantity;

        emit WithdrawedToken(_acceptToken, recipient, amount);
    }

    /// @dev Withdraw native token
    function withdrawNativeToken(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(depositedQuantity[recipient] > 0, "Not enough quantity for this recipient");

        require(address(this).balance >= amount, "Not enough balance");
        (bool sent, ) = payable(recipient).call{value: amount}("");
        require(sent, "Failed to send Native Token");
        
        ( , int nativeTokenPrice, , , ) = priceFeed.latestRoundData();
        uint depositedTokenPriceInUsd = amount * uint(nativeTokenPrice) / 1 ether;
        uint quantity = depositedTokenPriceInUsd * 1e3 * QUANTITY_DECIMAL / PRIVATE_SALE_PRICE / 1e8;
        
        if(depositedQuantity[recipient] >= quantity) {
            depositedQuantity[recipient] -= quantity;
        } else {
            depositedQuantity[recipient] = 0;
        }

        emit WithdrawedToken(address(0), recipient, amount);
    }
}