// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC165.sol";
import "./GenericErrors.sol";
import "../interfaces/INiftyEntityCloneable.sol";
import "../interfaces/INiftyRegistry.sol";
import "../libraries/Context.sol";

abstract contract NiftyPermissions is Context, ERC165, GenericErrors, INiftyEntityCloneable {    

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    // Only allow Nifty Entity to be initialized once
    bool internal initializedNiftyEntity;

    // If address(0), use enable Nifty Gateway permissions - otherwise, specifies the address with permissions
    address public admin;

    // To prevent a mistake, transferring admin rights will be a two step process
    // First, the current admin nominates a new admin
    // Second, the nominee accepts admin
    address public nominatedAdmin;

    // Nifty Registry Contract
    INiftyRegistry internal permissionsRegistry;    

    function initializeNiftyEntity(address niftyRegistryContract_) public {
        require(!initializedNiftyEntity, ERROR_REINITIALIZATION_NOT_PERMITTED);
        permissionsRegistry = INiftyRegistry(niftyRegistryContract_);
        initializedNiftyEntity = true;
    }       
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return         
        interfaceId == type(INiftyEntityCloneable).interfaceId ||
        super.supportsInterface(interfaceId);
    }        

    function renounceAdmin() external {
        _requireOnlyValidSender();
        _transferAdmin(address(0));
    }    

    function nominateAdmin(address nominee) external {
        _requireOnlyValidSender();
        nominatedAdmin = nominee;
    }

    function acceptAdmin() external {
        address nominee = nominatedAdmin;
        require(_msgSender() == nominee, ERROR_INVALID_MSG_SENDER);
        _transferAdmin(nominee);
    }
    
    function _requireOnlyValidSender() internal view {       
        address currentAdmin = admin;     
        if(currentAdmin == address(0)) {
            require(permissionsRegistry.isValidNiftySender(_msgSender()), ERROR_INVALID_MSG_SENDER);
        } else {
            require(_msgSender() == currentAdmin, ERROR_INVALID_MSG_SENDER);
        }
    }        

    function _transferAdmin(address newAdmin) internal {
        address oldAdmin = admin;
        admin = newAdmin;
        delete nominatedAdmin;        
        emit AdminTransferred(oldAdmin, newAdmin);
    }
}