/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
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
contract withdrawalContract{
 
    address owner;
    address checkAddress;
    IERC20 tokenAddress;
    uint256 private lock = 0;
    mapping (uint256 => uint256) public order;  
    event GetToken(address indexed sender, uint256 num, uint256 timestamp); 
    constructor(address _checkAddress, IERC20 _tokenAddress) {
        owner = msg.sender;
        checkAddress = _checkAddress;
        tokenAddress = _tokenAddress;
    }
    modifier checkOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier checkLock() {
        require(lock == 0);
        lock = 1;
        _;
        lock = 0;
    }


    function getToken(uint256 _id, uint256 _num,uint8 v,bytes32 r,bytes32 s) checkLock public {

        require(order[_id] == 0, "ylq");

        bytes memory signMessage =  abi.encodePacked(
            _id,
            _num,
            address(this),
            address(msg.sender)
        );
     
        bytes32 hash = keccak256(signMessage);
        address signatory = ecrecover(hash, v, r, s);

        require(signatory == checkAddress, "checkAddress");

        tokenAddress.transfer(msg.sender, _num);
        order[_id] = 1;
        
        emit GetToken(msg.sender,_num, block.timestamp);
    }

    function withdraw(IERC20 _a, uint256 num, address _to) checkOwner public {
        _a.transfer(_to, num);
    }
    function setOwner(address _a) checkOwner public {
        owner = _a;
    }
    function setCheckAddress(address _a) checkOwner public {
        checkAddress = _a;
    }
}