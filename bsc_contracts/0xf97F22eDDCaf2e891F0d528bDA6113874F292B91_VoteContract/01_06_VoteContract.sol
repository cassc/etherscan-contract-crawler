// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IDecubateMasterChef.sol";
import "../interfaces/IDCBVault.sol";

contract VoteContract is Ownable {
    IDecubateMasterChef public compoundStakingContract;
    IDCBVault public compounderContract;
    address CGPTAddress;
    uint256 voteRate;

    using SafeMath for uint256;

    constructor(
        address _compoundStakingContract,
        address _compounderContract,
        uint256 _voteRate
    ) 
    {
        compoundStakingContract = IDecubateMasterChef(_compoundStakingContract);
        compounderContract = IDCBVault(_compounderContract);
        voteRate = _voteRate;
        CGPTAddress = 0x9840652DC04fb9db2C43853633f0F62BE6f00f98;
    }

    function setVoteRate(uint256 newRate) external onlyOwner {
        voteRate = newRate;
    }

    function getVotingPower(address addr) public view returns (uint256 amount) {
        uint256 len = compoundStakingContract.poolLength();
        uint256 tempAmt;

        for (uint256 i = 0; i < len; i++) {
            (, uint256 localPeriodDays, , , , , address token) = compoundStakingContract.poolInfo(i);

            if (token == CGPTAddress) {
                (, , tempAmt, ) = compounderContract.users(i, addr);
                uint256 pw; //Power according to the localPeriodDayss
                if(localPeriodDays==15) pw=1;
                else if(localPeriodDays==45) pw=2;
                else if(localPeriodDays==180) pw=5;
                else if(localPeriodDays==365) pw=10;
                amount = amount.add(tempAmt.mul(pw));
            }
        }
        return
            amount.mul(voteRate).div(
                10 ** 4
            );
    }
}