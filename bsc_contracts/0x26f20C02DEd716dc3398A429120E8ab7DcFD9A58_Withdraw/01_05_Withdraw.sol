// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Withdraw is Ownable {
    using SafeMath for uint256;

    event TransferTokenEvent(
        address indexed token,
        address indexed receiver,
        uint256 amount
    );

    constructor() {}

    receive() external payable {}

    // transfer token to address
    function transferToken(
        address _tokenAddress,
        uint256 _amount,
        address _receiver
    ) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );
        require(
            contractBalance >= _amount,
            "Contract not enough balance to transfer"
        );

        IERC20(_tokenAddress).transfer(_receiver, _amount);
        emit TransferTokenEvent(_tokenAddress, _receiver, _amount);
    }

    // transfer eth to address
    function transferETH(uint256 _amount, address _receiver) public onlyOwner {
        uint256 contractBalance = address(this).balance;

        require(
            contractBalance >= _amount,
            "Contract not enough balance to transfer"
        );
        payable(_receiver).transfer(_amount);
        emit TransferTokenEvent(address(0), _receiver, _amount);
    }

    // Clear unknown token
    function clearUnknownToken(address _tokenAddress) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );
        IERC20(_tokenAddress).transfer(address(msg.sender), contractBalance);
    }

    /**
	Withdraw bnb
	*/
    function clearBNB() public onlyOwner {
        payable(address(msg.sender)).transfer(address(this).balance);
    }
}