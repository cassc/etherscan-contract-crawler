// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@artman325/releasemanager/contracts/CostManagerFactoryHelper.sol";
import "@artman325/releasemanager/contracts/ReleaseManagerHelper.sol";
import "@artman325/releasemanager/contracts/ReleaseManager.sol";
import "./interfaces/ISubscriptionsManagerUpgradeable.sol";
import "./interfaces/ISubscriptionsManagerFactory.sol";


contract SubscriptionsManagerFactory  is CostManagerFactoryHelper, ReleaseManagerHelper, ISubscriptionsManagerFactory {
    using Clones for address;
    using Address for address;

    /**
    * @custom:shortd implementation address
    * @notice implementation address
    */
    address public immutable implementation;

    mapping(address => bool) public instances;
    uint256 internal totalInstancesCount;
    
    //error InstanceCreatedFailed();
    error UnauthorizedContract(address controller);
    error OnlyInstances();

    event InstanceCreated(address instance, uint instancesCount);

    modifier onlyInstance() {
        if (instances[msg.sender] == false) {
            revert OnlyInstances();
        }
        _;
    }
    /**
    */
    constructor(
        address _implementation,
        address _costManager,
        address _releaseManager
    ) 
        CostManagerFactoryHelper(_costManager) 
        ReleaseManagerHelper(_releaseManager) 
    {
        implementation = _implementation;
    }

    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
    * @dev view amount of created instances
    * @return amount amount instances
    * @custom:shortd view amount of created instances
    */
    function instancesCount()
        external 
        view 
        returns (uint256 amount) 
    {
        amount = totalInstancesCount;
    }

    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
    * @param interval interval count
    * @param intervalsMax max interval
    * @param intervalsMin min interval
    * @param retries amount of retries
    * @param token token address to charge
    * @param price price for subsription on single interval
    * @param controller [optional] controller address
    * @param recipient address which will obtain pay for subscription
    * @param hook address if present  then contract will try to call ISubscriptionsHook(hook).onCharge
    * @return instance address of created instance `SubscriptionsManager`
    * @custom:shortd creation SubscriptionsManager instance
    */
    function produce(
        uint32 interval,
        uint16 intervalsMax,
        uint16 intervalsMin,
        uint8 retries,
        address token,
        uint256 price,
        address controller,
        address recipient,
        address hook
    ) 
        public 
        returns (address instance) 
    {
        instance = address(implementation).clone();
        _produce(instance, interval, intervalsMax, intervalsMin, retries, token, price, controller, recipient, hook);
    }

    /**
    * @param interval interval count
    * @param intervalsMax max interval
    * @param intervalsMin min interval
    * @param retries amount of retries
    * @param token token address to charge
    * @param price price for subsription on single interval
    * @param controller [optional] controller address
    * @param recipient address which will obtain pay for subscription
    * @param hook address if present  then contract will try to call ISubscriptionsHook(hook).onCharge
    * @return instance address of created instance `SubscriptionsManager`
    * @custom:shortd creation SubscriptionsManager instance
    */
    function produceDeterministic(
        bytes32 salt,
        uint32 interval,
        uint16 intervalsMax,
        uint16 intervalsMin,
        uint8 retries,
        address token,
        uint256 price,
        address controller,
        address recipient,
        address hook
    ) 
        public 
        returns (address instance) 
    {
        instance = address(implementation).cloneDeterministic(salt);
        _produce(instance, interval, intervalsMax, intervalsMin, retries, token, price, controller, recipient, hook);
    }

    function doCharge(
        address targetToken, 
        uint256 amount, 
        address from, 
        address to
    ) 
        external 
        onlyInstance
        returns(bool returnSuccess) 
    {
        returnSuccess = false;
        
        // we shoud not revert transaction, just return failed condition of `transferFrom` attempt
        bytes memory data = abi.encodeWithSelector(IERC20(targetToken).transferFrom.selector, from, to, amount);
        (bool success, bytes memory returndata) = address(targetToken).call{value: 0}(data);

        if (success) {
            returnSuccess = true;

            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                //require(targetToken.isContract(), "Address: call to non-contract");
                if (!targetToken.isContract()) {
                    returnSuccess = false;
                }
            }
            
        // } else {
        //     returnSuccess = false;
        }
    
    }


    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    function _produce(
        address instance,
        uint32 interval,
        uint16 intervalsMax,
        uint16 intervalsMin,
        uint8 retries,
        address token,
        uint256 price,
        address controller,
        address recipient,
        address hook
    ) 
        internal
    {
        //before initialize

        // already cheched in clone/cloneDeterministic
        // if (instance == address(0)) {
        //     revert InstanceCreatedFailed();
        // }
        instances[instance] = true;
        totalInstancesCount++;
        emit InstanceCreated(instance, totalInstancesCount);

        if (controller != address(0)) {
            bool isControllerinOurEcosystem = ReleaseManager(releaseManager()).checkInstance(controller);
            if (!isControllerinOurEcosystem) {
                revert UnauthorizedContract(controller);
            }
        }
    
        //initialize
        ISubscriptionsManagerUpgradeable(instance).initialize(interval, intervalsMax, intervalsMin, retries, token, price, controller, recipient, hook, costManager, msg.sender);

        //after initialize
        Ownable(instance).transferOwnership(msg.sender);
        //----

        //-- register instance in release manager
        registerInstance(instance);
        //-----------------
    }

}