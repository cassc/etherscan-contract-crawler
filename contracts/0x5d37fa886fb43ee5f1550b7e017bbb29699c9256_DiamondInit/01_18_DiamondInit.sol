// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibRoosting } from "../libraries/LibRoosting.sol";
import { LibOwls } from "../libraries/LibOwls.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import { IERC721, IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC2981 } from "../interfaces/IERC2981.sol";
import { ERC721AStorage } from "../ERC721AUpgradeableContracts/ERC721AStorage.sol";
import { RoyaltyStorage } from "../libraries/RoyaltyStorage.sol";
import { IOperatorFilterRegistry } from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit {
    IOperatorFilterRegistry constant OPERATOR_FILTER_REGISTRY = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    function init(address _owlsContract) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        // Royalties ERC2981 Interface
        ds.supportedInterfaces[type(IERC2981).interfaceId] = true;
        // Operator Filter Interface
        ds.supportedInterfaces[type(IOperatorFilterRegistry).interfaceId] = true;

        // Initialize ERC721A state variables
        ERC721AStorage.Layout storage ercs = ERC721AStorage.layout();
        ercs._name = "ASCIITreeOfLife";
        ercs._symbol = "ATOL";

        // roosting state variables
        LibRoosting.RoostingStorage storage rs = LibRoosting.roostingStorage();
        rs.roostingAdmins[ds.contractOwner] = true;

        LibOwls.OwlsStorage storage ls = LibOwls.owlsStorage();
        ls.owlsContract = _owlsContract;

        // Initialize ERC2981 state variables
        RoyaltyStorage.RoyaltyInfo storage ryl = RoyaltyStorage.royaltyInfo();
        ryl.defaultRoyaltyBPS = 500;
        ryl.royaltyReceiver = msg.sender;

        // Initialize Operator Registry Filter state variables
        OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    }
}