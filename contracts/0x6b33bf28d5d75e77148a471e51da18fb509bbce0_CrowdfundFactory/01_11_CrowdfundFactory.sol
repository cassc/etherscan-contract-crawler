//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "hardhat/console.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { CrowdfundImplementation } from "./CrowdfundImplementation.sol";

contract CrowdfundFactory is Ownable {
    uint256 public totalCrowdfunds;

    CrowdfundImplementation public crowdfundContract;

    event CrowdfundImplementationUpdated(address implementation);
    event CrowdfundCreated(address creator, address crowdfund);

    constructor (CrowdfundImplementation _crowdfund) {
        crowdfundContract = _crowdfund;
    }

    function setCrowdfundImplementation(CrowdfundImplementation _crowdfund) public onlyOwner {
        crowdfundContract = _crowdfund;

        emit CrowdfundImplementationUpdated(address(_crowdfund));
    }

    function createCrowdfund(bytes calldata meta) public {
        // Crowdfund _crowdfund = new Crowdfund(meta);

        address _crowdfund = Clones.clone(address(crowdfundContract));

        // console.log(_crowdfund);

        CrowdfundImplementation(_crowdfund).initialize(meta);
        
        emit CrowdfundCreated(msg.sender, _crowdfund);
    }
}