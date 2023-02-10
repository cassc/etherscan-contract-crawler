// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Airdrop {
    using SafeMath for uint;

    function airdropToken(address token, address[] memory recipients, uint256 amount) public returns (bool) {
        require(IERC20(token).balanceOf(msg.sender) >= amount, "balance not enough");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint amountForEach = amount.div(recipients.length) ;
        for(uint i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "");
            IERC20(token).approve(recipients[i], amountForEach);
            IERC20(token).transfer(recipients[i], amountForEach);
        }
        return true;
    }

    function airdropEth(address[] memory recipients, uint256 amount) public payable returns (bool) {
        require(msg.value >= amount, "not enough");
        uint amountForEach = amount.div(recipients.length) ;
        for(uint i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0));
            payable(recipients[i]).transfer(amountForEach);
        }
        return true;
    }

    receive() external payable {}
}