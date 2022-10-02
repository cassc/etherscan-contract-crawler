pragma solidity ^0.5.16;

import "./ErrorReporter.sol";
import "./MtrollerInterface.sol";
import "./MTokenInterfaces.sol";
import "./MTokenStorage.sol";

/**
 * @title MDelegator
 * @dev Storage for the delegatee is at this contract, while execution is delegated.
 * @author mmo.finance
 */
contract MDelegator is MDelegatorIdentifier {

    // Storage position of the address of the user part of the current implementation
    bytes32 private constant mDelegatorUserImplementationPosition = 
        keccak256("com.mmo-finance.mDelegator.user.implementation.address");
    
    // Storage position of the address of the admin part of the current implementation
    bytes32 private constant mDelegatorAdminImplementationPosition = 
        keccak256("com.mmo-finance.mDelegator.admin.implementation.address");
    
    // Storage position base of the implemented admin function selector verifiers
    bytes32 private constant mDelegatorAdminImplementationSelectorPosition = 
        keccak256("com.mmo-finance.mDelegator.admin.implementation.selector.bool");
    
    // Storage position of the enable implementation update flag
    bytes32 private constant mDelegatorEnableUpdate = 
        keccak256("com.mmo-finance.mDelegator.enableUpdate.bool");
    
    /**
    * @dev the constructor sets the admin
    */
    constructor() public {
        _setMDelegatorAdmin(msg.sender);
        // initially enable implementation updates
        bool _enable = true;
        bytes32 position = mDelegatorEnableUpdate;
        assembly {
            sstore(position, _enable)
        }
    }
    
    /**
     * @notice Tells the address of the current mDelegatorUserImplementation
     * @return implementation The address of the current mDelegatorUserImplementation
     */
    function mDelegatorUserImplementation() public view returns (address implementation) {
        bytes32 position = mDelegatorUserImplementationPosition;
        assembly {
            implementation := sload(position)
        }
    }
    
    /**
     * @notice Tells the address of the current mDelegatorAdminImplementation
     * @return implementation The address of the current mDelegatorAdminImplementation
     */
    function mDelegatorAdminImplementation() public view returns (address implementation) {
        bytes32 position = mDelegatorAdminImplementationPosition;
        assembly {
            implementation := sload(position)
        }
    }
    
    /**
     * @notice Tells if the current mDelegatorAdminImplementation supports the given function selector
     * @param selector The function selector (signature) to check, e.g. bytes4(keccak256('func()'))
     * @return supported Returns true if the selector is supported
     */
    function mDelegatorAdminImplementationSelectorSupported(bytes4 selector) public view returns (bool supported) {
        bytes32 position = keccak256(abi.encode(selector, mDelegatorAdminImplementationSelectorPosition));
        assembly {
            supported := sload(position)
        }
    }

    /**
     * @notice Tells if updating implementations is enabled
     * @return enabled Returns true if the admin and user implementations can be updated
     */
    function mDelegatorImplementationUpdateEnabled() public view returns (bool enabled) {
        bytes32 position = mDelegatorEnableUpdate;
        assembly {
            enabled := sload(position)
        }
    }

    /**
     * @notice Tells the address of the current admin
     * @return admin The address of the current admin
     */
    function mDelegatorAdmin() public view returns (address admin) {
        bytes32 position = mDelegatorAdminPosition;
        assembly {
            admin := sload(position)
        }
    }
    
    /**
     * @notice Sets the two addresses of the current implementation
     * @dev Gets implementedSelectors[] from new admin implementation and marks them as supported
     * @param _newUserImplementation address of the new mDelegatorUserImplementation
     * @param _newAdminImplementation address of the new mDelegatorAdminImplementation
     */
    function _setImplementation(address _newUserImplementation, address _newAdminImplementation) public {
        require(msg.sender == mDelegatorAdmin(), "only admin");
        require(mDelegatorImplementationUpdateEnabled(), "update disabled");
        require(MTokenInterface(_newUserImplementation).isMDelegatorUserImplementation(), "invalid user implementation");
        require(MTokenInterface(_newAdminImplementation).isMDelegatorAdminImplementation(), "invalid admin implementation");
        MDelegateeStorage oldAdminImpl = MDelegateeStorage(mDelegatorAdminImplementation());
        MDelegateeStorage newAdminImpl = MDelegateeStorage(_newAdminImplementation);

        // delete mapping entries for previously supported selectors (if needed)
        if (address(oldAdminImpl) != address(0)) {
            uint len = oldAdminImpl.implementedSelectorsLength();
            for (uint i = 0; i < len; i++) {
                _setAdminSelectorSupported(oldAdminImpl.implementedSelectors(i), false);
            }
        }

        // change to new implementations
        bytes32 positionUser = mDelegatorUserImplementationPosition;
        bytes32 positionAdmin = mDelegatorAdminImplementationPosition;
        assembly {
            sstore(positionUser, _newUserImplementation)
            sstore(positionAdmin, _newAdminImplementation)
        }

        // add mapping entries for newly supported selectors
        uint len = newAdminImpl.implementedSelectorsLength();
        for (uint i = 0; i < len; i++) {
            _setAdminSelectorSupported(newAdminImpl.implementedSelectors(i), true);
        }
    }
    
    /**
     * @notice Marks the given function selector as supported by the current mDelegatorAdminImplementation
     * @param selector The function selector (signature) to mark as supported, e.g. bytes4(keccak256('func()'))
     * @param supported Set true if to be marked as supported, else set to false
     */
    function _setAdminSelectorSupported(bytes4 selector, bool supported) public {
        require(msg.sender == mDelegatorAdmin(), "only admin");
        bytes32 position = keccak256(abi.encode(selector, mDelegatorAdminImplementationSelectorPosition));
        assembly {
            sstore(position, supported)
        }
    }

    /**
     * @notice Disable further implementation updates (NOTE: irreversible change!)
     */
    function _disableFurtherImplementationUpdates() public {
        require(msg.sender == mDelegatorAdmin(), "only admin");
        bool _enable = false;
        bytes32 position = mDelegatorEnableUpdate;
        assembly {
            sstore(position, _enable)
        }
    }

    /**
     * @notice Sets the address of the admin
     */
    function _setMDelegatorAdmin(address _newAdmin) public {
        if (mDelegatorAdmin() != address(0)) {
            require(msg.sender == mDelegatorAdmin(), "only admin");
            require(_newAdmin != address(0), "invalid new admin");
        }
        bytes32 position = mDelegatorAdminPosition;
        assembly {
            sstore(position, _newAdmin)
        }
    }

    /**
     * @notice Delegates execution of all other functions to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function () payable external {
        address implementation;

        // if the function selector msg.sig is supported by the admin implementation, choose the admin implementation
        // else choose the user implementation (default)
        if (mDelegatorAdminImplementationSelectorSupported(msg.sig)) {
            implementation = mDelegatorAdminImplementation();
        }
        else {
            implementation = mDelegatorUserImplementation();
        }
        
        // delegate call to chosen implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }
}

/* The three contracts that are currently using MDelegator */

contract Mtroller is MDelegator {
    constructor(MtrollerUserInterface userImpl, MtrollerAdminInterface adminImpl) public MDelegator() {
        _setImplementation(address(userImpl), address(adminImpl));
    }
}

contract MEther is MDelegator {
    constructor(MEtherUserInterface userImpl, MEtherAdminInterface adminImpl) public MDelegator() {
        _setImplementation(address(userImpl), address(adminImpl));
    }
}

contract MERC721Token is MDelegator {
    constructor(MERC721UserInterface userImpl, MERC721AdminInterface adminImpl) public MDelegator() {
        _setImplementation(address(userImpl), address(adminImpl));
    }
}