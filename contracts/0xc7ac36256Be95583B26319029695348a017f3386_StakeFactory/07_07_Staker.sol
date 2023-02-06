// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMain.sol";


contract Staker {
    address public owner;
    IMain main;
    uint fee;
    error InvalidAmount();
    error InvalidTerm();
    constructor(address user, address _main){
        owner = user;
        main = IMain(_main);
        fee = main.fee();
    }
    function stake(uint256 amount, uint256 term) external payable {
        if( amount == 0 ) revert InvalidAmount();
        if( term == 0 ) revert InvalidTerm();
        main.stake{value : fee}(amount, term);
    }
    function withdraw() external payable {
        main.withdraw{value : fee}();
        main.transfer(owner, main.balanceOf(address(this)));
    }
    function getUserStakeInfo() public view returns(IMain.StakeInfo memory){
        return main.userStakes(address(this));
    }
}