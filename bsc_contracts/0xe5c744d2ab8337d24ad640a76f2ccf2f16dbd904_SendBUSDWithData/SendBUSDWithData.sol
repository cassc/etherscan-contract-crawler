/**
 *Submitted for verification at BscScan.com on 2023-05-03
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts\SendBusdWithData.sol

contract SendBUSDWithData {
    IERC20 public busdToken;
    address public owner;

    event TransferWithData(
        address indexed from,
        address indexed revenueWallet,  
        uint256 revenueAmount,
        address indexed playerWallet,
        uint256 playerAmount,
        bytes data
    );

    constructor(address _busdTokenAddress) {
        busdToken = IERC20(_busdTokenAddress);
        owner = msg.sender;
    }

     function sendBUSDWithData(bytes memory _data, address _revenueWallet, uint256 _revenueAmount, address _playerWallet, uint256 _playerAmount) public {
        uint256 totalAmount = _revenueAmount + _playerAmount;
        require(busdToken.allowance(msg.sender, address(this)) >= totalAmount, "Not enough allowance");

        bool success2 = busdToken.transferFrom(msg.sender, _playerWallet, _playerAmount);
        require(success2, "Token transfer to player wallet failed");

        bool success1 = busdToken.transferFrom(msg.sender, _revenueWallet, _revenueAmount);
        require(success1, "Token transfer to revenue wallet failed");

      

        emit TransferWithData(msg.sender, _revenueWallet, _revenueAmount, _playerWallet, _playerAmount, _data);
    }
}