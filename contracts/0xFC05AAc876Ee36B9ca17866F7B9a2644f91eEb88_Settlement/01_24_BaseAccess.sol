//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./libs/LibAccess.sol";
import "./libs/LibStorage.sol";
import "./Types.sol";


import "hardhat/console.sol";

abstract contract BaseAccess {
    using LibAccess for Types.AccessControl;
    

    //bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
    //bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant PAUSER_ROLE = 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    //bytes32 public constant RELAY_ROLE = keccak256("RELAY_ROLE");
    bytes32 public constant RELAY_ROLE = 0x077a1d526a4ce8a773632ab13b4fbbf1fcc954c3dab26cd27ea0e2a6750da5d7;
    //bytes32 public constant ACTION_ROLE = keccak256("ACTION_ROLE");
    bytes32 public constant ACTION_ROLE = 0xd95061bdf0c43d77b6cbe1c15072292976244ec8d5012de75baa36e42da4625e;

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function hasRole(bytes32 role, address actor) public view returns (bool) {
        return LibStorage.getAccessStorage().hasRole(role, actor);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Not admin");
        _;
    }

    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Not pauser");
        _;
    }

    modifier onlyRelay() {
        require(hasRole(RELAY_ROLE, _msgSender()), "Not relay");
        _;
    }

    modifier initializer() {
        Types.InitControls storage ic = LibStorage.getInitControls();
        require(ic.initializing || !ic.initialized, "Already initialized");
        
        bool tlc = !ic.initializing;
        if(tlc) {
            ic.initializing = true;
            ic.initialized = true;
        }
        _;
        if(tlc) {
            ic.initializing = false;
        }
    }

    modifier nonReentrant() {
        
        require(!LibStorage.getAccessStorage().reentrantFlag, "Attempting to re-enter function recursively");
        LibStorage.getAccessStorage().reentrantFlag = true;
        _;
        LibStorage.getAccessStorage().reentrantFlag = false;
    }

    //================ MUTATIONS ===============/
    
    function addRole(bytes32 role, address actor) public onlyAdmin {
        _setupRole(role, actor);
    }

    function swapRelay(address oldRelay, address newRelay) public onlyAdmin {
        revokeRole(RELAY_ROLE, oldRelay);
        addRole(RELAY_ROLE, newRelay);
    }

    function revokeRole(bytes32 role, address actor) public onlyAdmin {
        LibStorage.getAccessStorage()._revokeRole(role, actor);
    }

    function _setupRole(bytes32 role, address actor) internal {
        LibStorage.getAccessStorage()._addRole(role, actor);
    }

    function initAccess() internal initializer {
        address o = _msgSender();
        _setupRole(ADMIN_ROLE, o);
        _setupRole(PAUSER_ROLE, o);
    }
}