// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";
import "../libraries/SafeERC20.sol";

interface ICloneablePaymentSplitter is IERC165 {
    
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    
    function initialize(address[] calldata payees, uint256[] calldata shares_) external;        
    function totalShares() external view returns (uint256);    
    function totalReleased() external view returns (uint256);
    function totalReleased(IERC20 token) external view returns (uint256);
    function shares(address account) external view returns (uint256);    
    function released(address account) external view returns (uint256);
    function released(IERC20 token, address account) external view returns (uint256);
    function payee(uint256 index) external view returns (address);    
    function release(address payable account) external;
    function release(IERC20 token, address account) external;
    function pendingPayment(address account) external view returns (uint256);
    function pendingPayment(IERC20 token, address account) external view returns (uint256);
}