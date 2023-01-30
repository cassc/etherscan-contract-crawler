// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMain {
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }
    function fee() external returns(uint);
    function claimRank(uint256 term) external payable;
    function claimMintReward() external payable;
    function userMints(address user) external view returns(MintInfo memory);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function getMintReward(uint256 cRank,
        uint256 term,
        uint256 maturityTs,
        uint256 amplifier,
        uint256 eeaRate) external view returns(uint);
}

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