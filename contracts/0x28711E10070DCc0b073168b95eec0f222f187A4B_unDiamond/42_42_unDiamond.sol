// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {ERC165BaseStorage} from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseStorage.sol";
import {ERC721MetadataStorage} from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import "@drad/eip-5173-diamond/contracts/nFR/InFR.sol";

import "./management/ManagementStorage.sol";

contract unDiamond is SolidStateDiamond {
    using ERC165BaseStorage for ERC165BaseStorage.Layout;

    constructor(
        address untradingManager,
        uint256 managerCut,
        string memory name,
        string memory symbol,
        string memory baseURI
    ) {
        require(managerCut <= 1e18, "managerCut exceeds 100%");
        // Init the ERC721 Metadata for the unNFT Shared Contract
        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
        l.name = name;
        l.symbol = symbol;
        l.baseURI = baseURI;

        // Declare all interfaces supported by the Diamond
        ERC165BaseStorage.layout().supportedInterfaces[type(IERC165).interfaceId] = true;
        ERC165BaseStorage.layout().supportedInterfaces[type(IERC721).interfaceId] = true;
        ERC165BaseStorage.layout().supportedInterfaces[type(InFR).interfaceId] = true;

        // Init the manager and managerCut used by oTokens
        ManagementStorage.Layout storage m = ManagementStorage.layout();
        m.untradingManager = untradingManager;
        m.managerCut = managerCut;
    }
}