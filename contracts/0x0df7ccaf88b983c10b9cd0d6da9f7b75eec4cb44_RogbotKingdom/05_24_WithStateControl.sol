// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 

abstract contract WithStateControl is Ownable {

    enum ProjectState {
        Prepare, //0
        PioneerSale, //1
        PreWhitelist, //2
        WhitelistSale, //3
        PrePublic, //4
        PublicSale, //5
        Finished //6
    }

    ProjectState public state;

    // update project state
    function updateProjectState(ProjectState _newState) external onlyOwner {
        state = _newState;
    }


     

    

}