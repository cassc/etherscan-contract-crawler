/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: erc20-airdrop.sol


pragma solidity ^0.8.9;


/// @custom:security-contact [email protected]
contract Erc20Airdrop {
    address private _owner;
    address private _targetToken;
    uint256 private _claimAmount;

    constructor(address targetToken, uint256 claimAmount) {
        _targetToken = targetToken;
        _claimAmount = claimAmount;
        _owner = msg.sender;
    }

    function _checkOwner() private view {
        require(msg.sender == _owner, "Caller is not owner");
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    
    function owner() external view returns (address) {
        return _owner;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    mapping (address => bool) private _claimed;

    function isClaimed(address target) external view onlyOwner returns (bool result){
        return _claimed[target];
    }

    function emptyPool() external onlyOwner returns (bool result){
        return IERC20(_targetToken).transfer(_owner, IERC20(_targetToken).balanceOf(address(this)));
    }

    function checkClaimAvailability() external view returns (bool result){
        require(!_claimed[msg.sender], "You can receive token only once per wallet");
        require(_claimAmount <= IERC20(_targetToken).balanceOf(address(this)), "Not enough token left in airdrop pool");
        return true;
    }

    function claimToken() external returns (bool result){
        require(!_claimed[msg.sender], "You can receive token only once per wallet");
        _claimed[msg.sender]=true;

        return IERC20(_targetToken).transfer(msg.sender, _claimAmount);
    }
}