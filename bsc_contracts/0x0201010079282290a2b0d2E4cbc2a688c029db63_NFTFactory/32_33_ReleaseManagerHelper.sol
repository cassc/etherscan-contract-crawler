// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IReleaseManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ReleaseManagerHelper is Ownable{
    using Address for address;
    address public releaseManager;

    function registerInstance(address stateContractAddress) internal {
        require(releaseManager != address(0), "register releaseManager first");
        IReleaseManager(releaseManager).registerInstance(stateContractAddress);
    }
    
    function registerReleaseManager(address releaseManager_) public onlyOwner {
        require(releaseManager_.isContract(), "non-contract");
        require(releaseManager == address(0), "already setup");
        releaseManager = releaseManager_;
    }

}