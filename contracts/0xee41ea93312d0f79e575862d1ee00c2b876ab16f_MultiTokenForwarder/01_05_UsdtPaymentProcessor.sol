// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiTokenForwarder {
    using SafeERC20 for IERC20;

    address public owner;
    address public targetWallet;

    mapping(uint256 => address) private targetsArray; // Maps packageId to an address

    mapping(uint256 => bool) public orderIDs;
    mapping(address => bool) public approvedTokens;

    event PaymentForwarded(address indexed token, address indexed payer, uint256 amount, uint256 orderID, uint256 packageID);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenApproved(address indexed token);
    event TokenDisapproved(address indexed token);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(address _targetWallet) {
        owner = msg.sender;
        targetWallet = _targetWallet;
    }

    function setTargetWallet(address _newWallet) external onlyOwner {
        targetWallet = _newWallet;
    }

    function setPackageTarget(uint256 packageId, address _target) external onlyOwner {
        targetsArray[packageId] = _target;
    }

    function getTargetByPackageId(uint256 packageId) external view onlyOwner returns (address) {
        return targetsArray[packageId];
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    function forwardPayment(address tokenAddress, uint256 amount, uint256 orderID, uint256 packageId) external {
        require(!orderIDs[orderID], "Order ID already used");
        require(approvedTokens[tokenAddress], "Token not approved for interaction");

        address paymentRecipient = (targetsArray[packageId] != address(0)) ? targetsArray[packageId] : targetWallet;

        IERC20 token = IERC20(tokenAddress);

        token.safeTransferFrom(msg.sender, paymentRecipient, amount);

        orderIDs[orderID] = true;
        emit PaymentForwarded(tokenAddress, msg.sender, amount, orderID, packageId);
    }

    function rescueTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        bool success = IERC20(_tokenAddress).transfer(owner, _amount);
        require(success, "Token transfer failed");
    }

    function approveToken(address tokenAddress) external onlyOwner {
        approvedTokens[tokenAddress] = true;
        emit TokenApproved(tokenAddress);
    }

    function disapproveToken(address tokenAddress) external onlyOwner {
        approvedTokens[tokenAddress] = false;
        emit TokenDisapproved(tokenAddress);
    }

    receive() external payable {
        revert("Ether not accepted");
    }
}