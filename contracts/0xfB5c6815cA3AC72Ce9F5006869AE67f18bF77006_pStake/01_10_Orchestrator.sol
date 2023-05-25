/*
 Copyright [2019] - [2021], PERSISTENCE TECHNOLOGIES PTE. LTD. and the ERC20 contributors
 SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { pStake } from "./pStake.sol";
import { StepVesting } from "./StepVesting.sol";

contract Orchestrator is Ownable {

    struct VestingInfo {
        address beneficiary;
        uint64 cliffTime;
        uint256 stepAmount;
        uint256 cliffAmount;
        uint64 stepDuration;
        uint256 numOfSteps;
    }

    VestingInfo[] vestingInfos;

    address public mainOwner;

    address public immutable vestingImplementation;

    pStake public immutable token;

    mapping(address => address) public vestingMapping;

    constructor(VestingInfo[] memory _vestingInfos, address _mainOwner) {
        mainOwner = _mainOwner;
        
        for(uint i = 0; i<_vestingInfos.length; i++){
            VestingInfo memory vestingInfo = _vestingInfos[i];
            vestingInfos.push(vestingInfo);
        }

        StepVesting stepVesting = new StepVesting();
        vestingImplementation = address(stepVesting);
        token = new pStake(address(this), mainOwner);
    }


    function mintAndTransferTokens() external onlyOwner returns (address[] memory vestings) {

        vestings = new address[](vestingInfos.length);
        for(uint i = 0; i<vestingInfos.length; i++){
            VestingInfo memory vestingInfo = vestingInfos[i];
            address vesting = deploy();
            StepVesting(vesting).initialize(
                token, 
                vestingInfo.cliffTime, 
                vestingInfo.stepDuration, 
                vestingInfo.cliffAmount, 
                vestingInfo.stepAmount, 
                vestingInfo.numOfSteps, 
                vestingInfo.beneficiary);
            token.transfer(vesting, vestingInfo.cliffAmount + vestingInfo.stepAmount*vestingInfo.numOfSteps);
            vestings[i] = vesting;
            vestingMapping[vestingInfo.beneficiary] = vesting;
        }

    }

    function getAmountToMint() public view returns (uint256 amount) {
        for(uint i=0; i<vestingInfos.length; i++){
            VestingInfo memory vestingInfo = vestingInfos[i];
            amount += (vestingInfo.cliffAmount + vestingInfo.stepAmount*vestingInfo.numOfSteps);
        }
    }

    function deploy() internal returns (address cloneAddress) {
        bytes20 targetBytes = bytes20(vestingImplementation); // Takes the first 20 bytes of the masterContract's address
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            cloneAddress := create(0, clone, 0x37)
        }

    }

}