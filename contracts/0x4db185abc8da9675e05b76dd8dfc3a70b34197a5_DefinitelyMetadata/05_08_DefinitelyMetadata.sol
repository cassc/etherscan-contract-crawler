//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
                                                      ...:--==***#@%%-
                                             ..:  -*@@@@@@@@@@@@@#*:  
                               -:::-=+*#%@@@@@@*[email protected]@@@@@@@@@@#+=:     
           .::---:.         +#@@@@@@@@@@@@@%*+-. [email protected]@@@@@+..           
    .-+*%@@@@@@@@@@@#-     [email protected]@@@@@@@@@%#*=:.    :@@@@@@@#%@@@@@%:     
 =#@@@@@@@@@@@@@@@@@@@%.   %@@@@@@-..           *@@@@@@@@@@@@%*.      
[email protected]@@@@@@@@#*+=--=#@@@@@%  [email protected]@@@@@%*#%@@@%*=-.. [email protected]@@@@@@%%*+=:         
 :*@@@@@@*       [email protected]@@@@@.*@@@@@@@@@@@@*+-      =%@@@@%                
  [email protected]@@@@@.       *@@@@@%:@@@@@@*==-:.          [email protected]@@@@:                
 [email protected]@@@@@=      [email protected]@@@@@%.*@@@@@=   ..::--=+*=+*[email protected]@@@=                 
 #@@@@@*    [email protected]@@@@@@* [email protected]@@@@#%%@@@@@@@@#+:.  =#@@=                  
 @@@@@%   :*@@@@@@@*:  .#@@@@@@@@@@@@@%#:       ---                   
:@@@@%. -%@@@@@@@+.     [email protected]@@@@%#*+=:.                                 
[email protected]@@%=*@@@@@@@*:        =*:                                           
:*#+%@@@@%*=.                                                         
 :+##*=:.

*/

import {Auth} from "./lib/Auth.sol";
import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";
import {IDefinitelyMetadata} from "./interfaces/IDefinitelyMetadata.sol";
import {Strings} from "openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "openzeppelin/contracts/utils/Base64.sol";

/**
 * @title
 * Definitely Metadata
 *
 * @author
 * DEF DAO
 *
 * @notice
 * The default metadata contract for DEF DAO membership tokens.
 *
 * Features:
 *   - On-chain metadata
 *   - Off-chain image URI
 *   - Image URI and token description can be updated by the contract owner/admins
 */
contract DefinitelyMetadata is IDefinitelyMetadata, Auth {
    using Strings for uint256;

    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Used to query `memberSinceBlock`
    IDefinitelyMemberships public memberships;

    /// @notice Token metadata description
    string public description;

    /// @notice Token metadata image URI
    string public imageURI;

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(
        address owner_,
        address memberships_,
        string memory imageURI_
    ) Auth(owner_) {
        memberships = IDefinitelyMemberships(memberships_);
        description = "[DEF DAO](https://www.defdao.xyz/) membership token for people tinkering on the edge of the internet.";
        imageURI = imageURI_;
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    function setImageURI(string memory imageURI_) external onlyOwnerOrAdmin {
        imageURI = imageURI_;
    }

    function setDescription(string memory description_) external onlyOwnerOrAdmin {
        description = description_;
    }

    /* ------------------------------------------------------------------------
       M E T A D A T A
    ------------------------------------------------------------------------ */

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        uint256 memberSinceBlock = memberships.memberSinceBlock(id);

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"DEF Membership #',
                    id.toString(),
                    '","description":"',
                    description,
                    '","image":"',
                    imageURI,
                    '","attributes":[{"trait_type":"Member since block","value":"',
                    memberSinceBlock.toString(),
                    '"}]}'
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }
}