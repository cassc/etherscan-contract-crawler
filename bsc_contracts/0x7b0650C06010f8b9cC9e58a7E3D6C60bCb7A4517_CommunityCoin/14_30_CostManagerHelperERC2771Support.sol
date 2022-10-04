// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICostManager.sol";
import "./interfaces/ICostManagerFactoryHelper.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@artman325/trustedforwarder/contracts/TrustedForwarder.sol";

/**
* used for instances that have created(cloned) by factory.
*/
abstract contract CostManagerHelperERC2771Support is TrustedForwarder {
    using AddressUpgradeable for address;

    address public costManager;
    address internal factory;

    /** 
    * @dev sets the costmanager token
    * @param costManager_ new address of costmanager token, or 0
    */
    function overrideCostManager(address costManager_) external {
        // require factory owner or operator
        // otherwise needed deployer(!!not contract owner) in cases if was deployed manually
        require (
            (factory.isContract()) 
                ?
                    ICostManagerFactoryHelper(factory).canOverrideCostManager(_msgSender(), address(this))
                :
                    factory == _msgSender()
            ,
            "cannot override"
        );
        
        _setCostManager(costManager_);
    }

    function __CostManagerHelper_init(address factory_) internal onlyInitializing
    {
        factory = factory_;
    }

     /**
     * @dev Private function that tells contract to account for an operation
     * @param info uint256 The operation ID (first 8 bits). in other bits any else info
     * @param param1 uint256 Some more information, if any
     * @param param2 uint256 Some more information, if any
     */
    function _accountForOperation(uint256 info, uint256 param1, uint256 param2) internal {
        if (costManager != address(0)) {
            try ICostManager(costManager).accountForOperation(
                msg.sender, info, param1, param2
            )
            returns (uint256 /*spent*/, uint256 /*remaining*/) {
                // if error is not thrown, we are fine
            } catch Error(string memory reason) {
                // This is executed in case revert() was called with a reason
                revert(reason);
            } catch {
                revert("unknown error");
            }
        }
    }
    
    function _setCostManager(address costManager_) internal {
        costManager = costManager_;
    }
    
}