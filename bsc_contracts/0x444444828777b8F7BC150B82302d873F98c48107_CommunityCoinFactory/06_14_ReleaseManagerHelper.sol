// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IReleaseManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ReleaseManagerHelper is Ownable{
    using Address for address;
    address public releaseManager;

    error RegisterReleaseManagerFirst();
    error ReleaseManagerIsNoneContract(address addr);
    error ReleaseManagerAlreadySetup(address addr);
    
    function registerInstance(address stateContractAddress) internal {
        if (releaseManager == address(0)) {
            revert RegisterReleaseManagerFirst();
        }
        IReleaseManager(releaseManager).registerInstance(stateContractAddress);
    }
    
    function registerReleaseManager(address releaseManager_) public onlyOwner {
        if (releaseManager_.isContract() == false) {
            revert ReleaseManagerIsNoneContract(releaseManager_);
        }
        if (releaseManager != address(0)) {
            revert ReleaseManagerAlreadySetup(releaseManager_);
        }

        releaseManager = releaseManager_;
    }

}