/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Lock.sol


pragma solidity =0.8.19;


contract ShidoLock {
    uint256 public lockTimestamp;
    address public shidoV1;
    address public shidoV2;
    address public rewardWallet;

    error ZeroAmount();
    error AddressZero();
    error WaitNotOver();

    mapping(address => uint256) public userShidoV1;
    mapping(address => uint256) public userShidoV2;

    constructor(
        address _shidoV1,
        address _shidoV2,
        uint256 _lockTimestamp,
        address _rewardWallet
    ) {
        if (
            _shidoV1 == address(0) ||
            _shidoV2 == address(0) ||
            _rewardWallet == address(0)
        ) revert AddressZero();

        if (_lockTimestamp == 0) revert ZeroAmount();

        shidoV1 = _shidoV1;
        shidoV2 = _shidoV2;
        rewardWallet = _rewardWallet;
        lockTimestamp = _lockTimestamp;
    }

    function lockTokens() external {
        uint256 amount = IERC20(shidoV1).balanceOf(msg.sender);

        if (amount == 0) revert ZeroAmount();

        userShidoV1[msg.sender] += amount;

        IERC20(shidoV1).transferFrom(msg.sender, rewardWallet, amount);
    }

    function claimTokens() external {
        if (block.timestamp < lockTimestamp) revert WaitNotOver();

        uint256 amount = userShidoV1[msg.sender] * 10 ** 9;

        if (amount == 0) revert ZeroAmount();

        userShidoV1[msg.sender] = 0;

        userShidoV2[msg.sender] += amount;

        IERC20(shidoV2).transferFrom(rewardWallet, msg.sender, amount);
    }
}