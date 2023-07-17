// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin imports
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Diamond imports
import { LibDiamond } from "../../diamond/libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../../diamond/interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../../diamond/interfaces/IDiamondCut.sol";
import { IERC173 } from "../../diamond/interfaces/IERC173.sol";

// Local imports
import { AccessTypes } from "../structs/AccessTypes.sol";
import { LibAccessControl } from "../libraries/LibAccessControl.sol";
import { LibAppStorage } from "../libraries/LibAppStorage.sol";
import { LibEscrow } from "../libraries/LibEscrow.sol";
import { IRaiseFacet } from "../interfaces/IRaiseFacet.sol";
import { IMilestoneFacet } from "../interfaces/IMilestoneFacet.sol";
import { IEquityBadge } from "../../interfaces/IEquityBadge.sol";

/**************************************

    Fundraising initializer

    ------------------------------

    Diamond deployment looks like this:
    - deploy diamond cutter
    - deploy main diamond
    - deploy initializer
    - deploy all facets
    - perform cut with facets and initializer

 **************************************/

/// @dev Main initializer for fundraising.
contract FundraisingInit {
    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Args for initializer.
    /// @param usdt USDT address
    /// @param signer AngelBlock validation address
    /// @param badge Equity badge
    struct Arguments {
        address usdt;
        address signer;
        address badge;
        address escrowSource;
    }

    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev External init function for a delegate call.
    /// @dev _args Arguments struct
    function init(Arguments calldata _args) external {
        // owner
        address _owner = msg.sender;

        // access control
        LibAccessControl.createAdmin(_owner);
        LibAccessControl.grantRole(AccessTypes.SIGNER_ROLE, _args.signer);

        // set escrow source
        LibEscrow.setSource(_args.escrowSource);

        // app storage
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        s.usdt = IERC20(_args.usdt);
        s.equityBadge = IEquityBadge(_args.badge);

        // interfaces
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IRaiseFacet).interfaceId] = true;
    }
}