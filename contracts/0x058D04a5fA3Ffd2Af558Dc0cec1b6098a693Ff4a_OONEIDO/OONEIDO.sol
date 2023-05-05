/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
contract OONEIDO {

    address public constant deployer = 0xfd4Ba3881d78241060Bd196b5819C8E618D22D51;
    IERC20 public OONE;
    uint256 public constant minDeposit = 2668089647812 wei; // 0.000002668089647812 ETH
    uint256 public constant minOONEAllocation = 2*10**15; // 0.002 OONE
    uint256 public constant maxOONEAllocation = 4*10**15; // 0.004 OONE
    mapping(address => bool) public claimed;

    constructor(IERC20 _OONE) {
        OONE = _OONE;
    }

    function participate() public payable {
        require(msg.value >= minDeposit, "Not enough ETH deposited");
        require(!claimed[msg.sender], "Already claimed");

        claimed[msg.sender] = true;
        uint256 randomOONEAllocation = _getRandomOONE(msg.sender);
        OONE.transfer(msg.sender, randomOONEAllocation);
    }

    function _getRandomOONE(address user) private view returns (uint256) {
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.gaslimit, user)));
        uint256 range = maxOONEAllocation - minOONEAllocation;
        return randomness % (range + 1) + minOONEAllocation;
    }

    function withdrawETH() public {
        require(msg.sender==deployer);
        payable(deployer).transfer(address(this).balance);
    }

    function withdrawRemainingOONE() public {
        require(msg.sender==deployer);
        uint256 remainingOONE = OONE.balanceOf(address(this));
        OONE.transfer(deployer, remainingOONE);
    }
}