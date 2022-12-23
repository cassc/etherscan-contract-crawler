// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMintable20 is IERC20 {
	function mint(address _user, uint256 _amount) external;
	function burnFrom(address _from, uint256 _amount) external;
}

contract ES2VendingMachinev1 is Ownable {
	using SafeMath for uint256;

	address public creditToken = address(0);
    address public payToken = address(0);

    function getCredits(address _to, uint256 _mintAmount) public {
        uint256 cost;
        uint256 totalMint;
        cost = _mintAmount;
        require(_mintAmount > 0);
        totalMint = _mintAmount * 10**13;
        IERC20(payToken).transferFrom(msg.sender, address(this), cost);
        IMintable20(creditToken).mint(_to, totalMint);
    }

    function setCreditToken(address token) public onlyOwner {
        require(token != address(0), "Can't Set Zero Address");
        creditToken = token;
    }

    function setPayToken(address token) public onlyOwner {
        require(token != address(0), "Can't Set Zero Address");
        payToken = token;
    }

    //utility extrasa
    //get stuck tokens ftom contract
    function rescueToken(address tokenAddress, address to) external onlyOwner returns (bool success) {
    	uint256 _contractBalance = IERC20(tokenAddress).balanceOf(address(this));

        return IERC20(tokenAddress).transfer(to, _contractBalance);
    }

    //gets stuck bnb from contract
    function rescueBNB(uint256 amount) external onlyOwner{
    	payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}