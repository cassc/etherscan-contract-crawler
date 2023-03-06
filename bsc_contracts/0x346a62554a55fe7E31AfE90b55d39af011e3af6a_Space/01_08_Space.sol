// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vesting.sol";
import "./PlayAndEarnVesting.sol";
import "./EcosystemFundVesting.sol";
import "./TeamVesting.sol";

contract Space is Ownable {
    IERC20 lhc;

    Vesting[] public vestingList;
    uint public bigBang;

    constructor() {
        vestingList.push(new PlayAndEarnVesting());
        vestingList.push(new EcosystemFundVesting());
        vestingList.push(new TeamVesting());
    }

    function allocate(address erc20) onlyOwner external {
        require(address(lhc) == address(0), "It had allocated");
        lhc = IERC20(erc20);
        bigBang = block.timestamp;
        for (uint iVesting = 0; iVesting < vestingList.length; iVesting++) {
            Vesting vesting = vestingList[iVesting];
            uint max = vesting.max();
            lhc.transfer(address(vesting), max);
            vesting.invoke(bigBang, erc20);
        }
    }

    function claim(uint iVesting, address to, uint amount) onlyOwner external {
        Vesting vesting = vestingList[iVesting];
        vesting.claim(to, amount);
    }

    function destroy() onlyOwner external {
        uint len = vestingList.length;
        for(uint iVesting = 0; iVesting < len; iVesting++) {
            Vesting vesting = vestingList[iVesting];
            vesting.destroy();
        }
        address owner = owner();
        selfdestruct(payable(owner));
    }
}