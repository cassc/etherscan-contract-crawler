/**
 *Submitted for verification at Etherscan.io on 2023-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}



contract FuIdo {
    address public dev_address;
    //0x6a01B4BB5B423dc371cbC66B1b44629a248a814b
    address public token_address = 0x6a01B4BB5B423dc371cbC66B1b44629a248a814b;
    bool public buyBool;
    uint public  idoEtherAmount = 0.0015 ether;
    uint public idoAmount = 25*10**4 * 10**18;
    uint public totalEtherAmount;
    
  constructor() public {
        dev_address = msg.sender;
    }

 
    function  setBuy(bool bools) public{
        require(msg.sender==dev_address,"No call permission");
        buyBool=bools;
   }

function setToken(address token)public{
      require(msg.sender==dev_address,"No call permission");
      token_address = token;
     
}
   

    function claim () public payable{
        require(buyBool,"claim is not start");
        require(msg.value == idoEtherAmount,"Insufficient transfer quantity");
        IERC20(token_address).transfer(msg.sender,idoAmount);
        totalEtherAmount = totalEtherAmount + address(this).balance;
        //payable(dev_address).transfer(address(this).balance);
    }

       function getToken() public  {
        require(msg.sender==dev_address,"No call permission");
       IERC20(token_address).transfer(msg.sender,IERC20(token_address).balanceOf(address(this)));
    }

      function getEther() public payable {
          require(msg.sender==dev_address,"No call permission");
       msg.sender.transfer(address(this).balance);
    }
}