// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

contract PullPaymentMarket is Ownable, Pausable, ReentrancyGuard, PullPayment {
    // Market fee recipient and amount in basis points
    address public feeRecipient;
    uint256 public feeBasisPoints;

    // Initial state variables on creation
    constructor(uint256 _feeBasisPoints, address _feeRecipient) {
        require(_feeBasisPoints <= 10000, "Fee can't be more than 100%");
        feeBasisPoints = _feeBasisPoints;
        feeRecipient = _feeRecipient;
    }

    // Map vendor IDs to their payment addresses
    mapping(uint256 => address) public vendors;

    // Whitelist for approved payment tokens
    mapping(address => bool) public whitelistedTokens;

    // Token balance mapping for revenue recipients
    mapping(address => mapping(address => uint256)) public tokenBalances;

    // Event when a purchase is made
    event Purchase(
        address indexed buyer,
        uint256 indexed vendorId,
        uint256 indexed orderId,
        uint256 amount,
        address token
    );

    // Event when a vendor is registered
    event VendorRegistered(
        uint256 indexed vendorId,
        address indexed vendorAddress
    );

    // Function to add a token to the whitelist
    function addToWhitelist(address _token) external onlyOwner {
        whitelistedTokens[_token] = true;
    }

    // Function to remove a token from the whitelist
    function removeFromWhitelist(address _token) external onlyOwner {
        whitelistedTokens[_token] = false;
    }

    // Register a vendor's payment address
    function registerVendor(uint256 _vendorId, address _vendorAddress) external onlyOwner {
        require(
            _vendorAddress != address(0),
            "Vendor address cannot be the zero address"
        );
        require(
            vendors[_vendorId] == address(0),
            "Vendor ID is already registered"
        );

        vendors[_vendorId] = _vendorAddress;

        emit VendorRegistered(_vendorId, _vendorAddress);
    }

    // Update a vendor's payment address
    function updateVendorAddress(uint256 _vendorId, address _newVendorAddress) external onlyOwner {
        require(
            _newVendorAddress != address(0),
            "New vendor address cannot be the zero address"
        );
        require(
            vendors[_vendorId] != address(0),
            "Vendor ID is not registered"
        );

        vendors[_vendorId] = _newVendorAddress;
    }

    // Update the market fee basis points
    function updateFeeBasisPoints(uint256 _newFeeBasisPoints) external onlyOwner {
        require(_newFeeBasisPoints <= 10000, "Fee can't be more than 100%");
        feeBasisPoints = _newFeeBasisPoints;
    }

    // Update the market fee recipient
    function updateFeeRecipient(address _newFeeRecipient) external onlyOwner {
        feeRecipient = _newFeeRecipient;
    }

    function purchaseWithERC20(uint256 _vendorId, uint256 _orderId, uint256 _amount, address _token) external nonReentrant whenNotPaused {
        require(whitelistedTokens[_token], "Token is not accepted for payment");
        require(vendors[_vendorId] != address(0), "Vendor ID is not registered");
        require(_amount > 0, "Amount must be greater than zero");

        uint256 fee = (_amount * feeBasisPoints) / 10000;
        uint256 amountAfterFee = _amount - fee;

        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        tokenBalances[_token][vendors[_vendorId]] += amountAfterFee;
        tokenBalances[_token][feeRecipient] += fee;

        emit Purchase(msg.sender, _vendorId, _orderId, amountAfterFee, _token);
    }

    function purchaseWithEther(uint256 _vendorId, uint256 _orderId) external payable nonReentrant whenNotPaused {
        require(
            vendors[_vendorId] != address(0),
            "Vendor ID is not registered"
        );
        require(msg.value > 0, "Amount must be greater than zero");

        uint256 fee = (msg.value * feeBasisPoints) / 10000;
        uint256 amountAfterFee = msg.value - fee;

        _asyncTransfer(vendors[_vendorId], amountAfterFee);
        _asyncTransfer(feeRecipient, fee);

        emit Purchase(
            msg.sender,
            _vendorId,
            _orderId,
            amountAfterFee,
            address(0)
        );
    }

    function withdrawTokens(address _token, address _payee) external nonReentrant {
        uint256 tokenBalance = tokenBalances[_token][_payee];

        require(tokenBalance != 0, "No token balance available for withdrawal");
        require(IERC20(_token).balanceOf(address(this)) >= tokenBalance, "Insufficient contract token balance");

        tokenBalances[_token][_payee] -= tokenBalance;

        require(
            IERC20(_token).transfer(_payee, tokenBalance),
            "Token transfer failed"
        );
    }

}