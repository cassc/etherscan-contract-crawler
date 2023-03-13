/**
 *Submitted for verification at BscScan.com on 2023-03-13
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/TokenVesting.sol


pragma solidity ^0.8.0;



contract TokenVesting is ReentrancyGuard {

    event ERC20Released(address indexed token, uint256 amount); 


    mapping(address => uint256) public memberReleased;
    mapping(address => uint256) public memberTotal;

    address public  tokenAddr;
    address[] public memberKeys;

    uint256 public cliff;
    bool    public start;
    uint256 public duration; 
    address public immutable owner;





  
    constructor(address[] memory _memberKeys,uint256[] memory _memberTotal) {
        owner=msg.sender;
        start=true;
        cliff=uint256(block.timestamp);
        duration =36*30*24*3600;
        memberKeys= _memberKeys;
        
        for (uint256 i = 0; i < memberKeys.length; i++) {
             memberTotal[memberKeys[i]]=_memberTotal[i]* 10 ** 18;
        }
        
        tokenAddr=0xFddA64aaa73Bd03Fc287cB183D5C38d77b7253DC;


    }

     modifier  onlyOwner {
      require(msg.sender == owner);
      _; 
   }




   function setMember(address memberAddr, uint256 releaseQty,uint256 totalQty  ) external onlyOwner{
         memberReleased[memberAddr] =releaseQty;
         memberTotal[memberAddr]=totalQty;
         address[] storage keys = memberKeys;
         bool isFound = false;

        for (uint256 i = 0; i < keys.length; i++) {
            if (keys[i] == memberAddr) {
                isFound = true;
                break;
            }
        }
       if(!isFound){
            memberKeys.push(memberAddr);
        }

   }

   function setAddress(address token) external onlyOwner{
           tokenAddr=token;  
   }


 function setStart(uint256 start_date,uint256 dur) external onlyOwner{
           start=true;
           cliff=start_date;
           duration=dur;

   }
 
    function release() public  nonReentrant {

        require(start, "TokenVesting Not started");
       
        
        uint256 releasable = vestedAmount(msg.sender)-memberReleased[ msg.sender];
        memberReleased[ msg.sender] += releasable;

        IERC20(tokenAddr).transfer( msg.sender, releasable);
        emit ERC20Released( msg.sender, releasable);
    }

 
    function vestedAmount(address token ) public  view returns (uint256) {
        uint256 totalAllocation = memberTotal[token];
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp > cliff + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (block.timestamp - cliff)) / duration;
        }
    }
   
    function memberLength() public  view returns (uint256) {
         return memberKeys.length;
    }
    
}