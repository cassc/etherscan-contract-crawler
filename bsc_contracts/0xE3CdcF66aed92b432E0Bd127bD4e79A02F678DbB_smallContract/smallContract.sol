/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20  {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
contract smallContract {
    address ownerA= 0x84102bDDd2f31Ff72C71DDa1Af67b769c506B577;
    //address public sender;
   address ownerB = 0xd4eE8c73Fad7EF844D40e87F15b3cD16FBe0314e
;
    //uint256 a= amount.mul(0.2)
    function sendToken(address tokenContract, address sender ,uint256 amount) external {
        uint256 twentyPercent;
        uint256 eightPercent;
        twentyPercent = SafeMath.div(SafeMath.mul(amount, 20), 100);
        eightPercent = SafeMath.div(SafeMath.mul(amount, 80), 100);
        IERC20(tokenContract).transferFrom(
         sender,
         ownerA,
         twentyPercent
    );
    IERC20(tokenContract).transferFrom(
         sender,
         ownerB,
         eightPercent
    );

    }
}