// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMain.sol";

contract Minter {
    address public owner;
    IMain main;
    uint public term;
    constructor(address user, address _main){
        owner = user;
        main = IMain(_main);
    }
    function claimRank(uint256 _term) external {
        term = _term;
        main.claimRank(term);
    }
    function claimMintReward() external payable {
        uint fee = main.fee();
        main.claimMintReward{value : fee}();
        main.transfer(owner, main.balanceOf(address(this)));
    }
    function getUserMintInfo() public view returns(IMain.MintInfo memory){
        return main.userMints(address(this));
    }
    function getMintReward() external view returns(uint){
        IMain.MintInfo memory r = getUserMintInfo();
        return main.getMintReward(r.rank, r.term, r.maturityTs, r.amplifier, r.eaaRate);
    }
}