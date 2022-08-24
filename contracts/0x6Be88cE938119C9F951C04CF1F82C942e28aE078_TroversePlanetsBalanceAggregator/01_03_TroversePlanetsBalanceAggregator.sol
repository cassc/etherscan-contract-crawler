// contracs/TroversePlanetsBalanceAggregator.sol
// SPDX-License-Identifier: MIT

// ████████╗██████╗  ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗    
// ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    
//    ██║   ██████╔╝██║   ██║██║   ██║█████╗  ██████╔╝███████╗█████╗      
//    ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      
//    ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗    
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IPlanetHolderContract {
    function balanceOf(address owner) external view returns (uint256 balance);
}


contract TroversePlanetsBalanceAggregator is Ownable {
    IPlanetHolderContract public planetsContract;
    IPlanetHolderContract public planetsStakingContract;
    
    constructor() {
        planetsContract = IPlanetHolderContract(0x762Bc5880F128DCAc29cffdDe1Cf7DdF4cFC39Ee);
        planetsStakingContract = IPlanetHolderContract(0x98727FB35AdDf1eE92d62B36CeabFF1b5d3E2503);
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return planetsContract.balanceOf(owner) + planetsStakingContract.balanceOf(owner);
    }

    function setPlanetsContract(address _planetsContract) external onlyOwner {
        planetsContract = IPlanetHolderContract(_planetsContract);
    }

    function setPlanetsStakingContract(address _planetsStakingContract) external onlyOwner {
        planetsStakingContract = IPlanetHolderContract(_planetsStakingContract);
    }
}