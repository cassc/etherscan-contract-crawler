// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

//                ,|||||<              ~|||||'         `_+7ykKD%RDqmI*~`          
//                [email protected]@@@@@8'           `[email protected]@@@@`     `^[email protected]@@@@@@@@@@@@@@@@R|`       
//               [email protected]@@@@@@@Q;          [email protected]@@@@J    '}[email protected]@@@@@[email protected]@@@@@@Q,      
//               [email protected]@@@@@@@@@j        `[email protected]@@@Q`  `[email protected]@@@@@h^`         `[email protected]@@@@*      
//              [email protected]@@@@@@@@@@@D.      [email protected]@@@@i  [email protected]@@@@w'              ^@@@@@*      
//              [email protected]@@@@[email protected]@@@@@@Q!    `@@@@@Q  ;@@@@@@;                .txxxx:      
//             |@@@@@u *@@@@@@@@z   [email protected]@@@@* `[email protected]@@@@^                              
//            `[email protected]@@@Q`  '[email protected]@@@@@@R.'@@@@@B  [email protected]@@@@%        :DDDDDDDDDDDDDD5       
//            [email protected]@@@@7    `[email protected]@@@@@@[email protected]@@@@+  [email protected]@@@@K        [email protected]@@@@@@*       
//           `@@@@@Q`      ^[email protected]@@@@@@@@@@W   [email protected]@@@@@;             ,[email protected]@@@@@#        
//           [email protected]@@@@L        ,[email protected]@@@@@@@@@!   '[email protected]@@@@@u,        [email protected]@@@@@@@^        
//          [email protected]@@@@Q           }@@@@@@@@D     '[email protected]@@@@@@@gUwwU%[email protected]@@@@@@@@@g         
//          [email protected]@@@@<            [email protected]@@@@@@;       ;[email protected]@@@@@@@@@@@@@@Wf;[email protected]@@;         
//          ~;;;;;              .;;;;;~           '!Lx5mEEmyt|!'    ;;;~          
//
// Powered By:    @niftygateway
// Author:        @niftynathang
// Collaborators: @conviction_1 
//                @stormihoebe
//                @smatthewenglish
//                @dccockfoster
//                @blainemalone

import "../interfaces/IERC721Cloneable.sol";
import "../interfaces/IERC721DefaultOwnerCloneable.sol";
import "../interfaces/IERC721MetadataGenerator.sol";
import "../interfaces/INiftyEntityCloneable.sol";
import "../libraries/Clones.sol";
import "../utils/NiftyPermissions.sol";

contract NiftyCloneFactory is NiftyPermissions {

    event ClonedERC721(address newToken);    
    event ClonedERC721MetadataGenerator(address metadataGenerator);    
    
    constructor(address niftyRegistryContract_) {
        initializeNiftyEntity(niftyRegistryContract_);
    }
        
    function cloneERC721(address implementation, address niftyRegistryContract_, address defaultOwner_, string calldata name_, string calldata symbol_, string calldata baseURI_) external returns (address) {
        _requireOnlyValidSender();
        require(IERC165(implementation).supportsInterface(type(IERC721Cloneable).interfaceId), "Not a valid ERC721 Token");        
        address clone = Clones.clone(implementation);

        emit ClonedERC721(clone);

        IERC721Cloneable(clone).initializeERC721(name_, symbol_, baseURI_);        

        if(IERC165(implementation).supportsInterface(type(INiftyEntityCloneable).interfaceId)) {
            INiftyEntityCloneable(clone).initializeNiftyEntity(niftyRegistryContract_);
        }

        if(IERC165(implementation).supportsInterface(type(IERC721DefaultOwnerCloneable).interfaceId)) {
            IERC721DefaultOwnerCloneable(clone).initializeDefaultOwner(defaultOwner_);
        }        

        return clone;
    }
    
    function cloneMetadataGenerator(address implementation, address niftyRegistryContract_) external returns (address) {
        _requireOnlyValidSender();
        require(IERC165(implementation).supportsInterface(type(IERC721MetadataGenerator).interfaceId), "Not a valid Metadata Generator");
        address clone = Clones.clone(implementation);        

        emit ClonedERC721MetadataGenerator(clone);
        
        if(IERC165(implementation).supportsInterface(type(INiftyEntityCloneable).interfaceId)) {
            INiftyEntityCloneable(clone).initializeNiftyEntity(niftyRegistryContract_);
        }        

        return clone;
    }
}