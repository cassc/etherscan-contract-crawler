/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract KatanaPresale {
    mapping(address => uint256) public balances;
    address public token;
    address public owner;
    uint256 public totalEthReceived;
    uint256 public totalTokensSold;
    uint256 public tokenRate = 150000000; // Tokens received per 1 ETH  
    event TokensPurchased(address buyer, uint256 amount);

    constructor(address _token) {
        token = _token;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    receive() external payable {
        require(msg.value > 0, "Amount must be greater than 0");

        uint256 tokenAmount = msg.value * tokenRate;

        require(tokenAmount > 0, "Insufficient funds to purchase tokens");

        balances[msg.sender] += tokenAmount;

        IERC20(token).approve(address(this), tokenAmount);
        IERC20(token).transferFrom(address(this), msg.sender, tokenAmount);

        totalEthReceived += msg.value;
        totalTokensSold += tokenAmount;

        emit TokensPurchased(msg.sender, tokenAmount);
    }

    function getETH() external onlyOwner {
    uint256 amount = address(this).balance;
    require(amount > 0, "No ETH available in the contract");
    (bool success, ) = owner.call{value: amount}("");
    require(success, "ETH transfer failed");
    }

    function getTokens() external onlyOwner {
    uint256 tokenBalance = IERC20(token).balanceOf(address(this));
    require(tokenBalance > 0, "No tokens available in the contract");

    IERC20(token).transfer(owner, tokenBalance);
    }

}