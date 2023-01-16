// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProxyWithdrawer is Ownable{

    using SafeMath for uint256;
    address public withdrawer;

    modifier onlyWithdrawer() {
        require(withdrawer == msg.sender, "caller is not the withdrawer");
        _;
    }

    event Withdraw(address indexed receiver, address indexed token, uint256 amount);

    constructor() {
        withdrawer = msg.sender;
    }

    function updateWithdrawer(address _withdrawer) external onlyOwner{
        require(withdrawer != _withdrawer, "already set same address");
        withdrawer = _withdrawer;
    }

    function withdraw(address _token, uint256 _amount, address _receiver) external onlyWithdrawer{
        
        if(_token == address(0)) {
            require(_amount <= address(this).balance, "insufficient balance");
            payable(_receiver).transfer(_amount);
        } else {
            require(_amount <= IERC20(_token).balanceOf(address(this)), "insufficient balance");
            IERC20(_token).transfer(_receiver, _amount);
        }

        emit Withdraw(_receiver, _token, _amount);
    }

}