// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Diamond Contract Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
* @team https://twitter.com/quirkiesnft
* @url https://quirkies.io/
* @author GrizzlyDesign 
* @url https://twitter.com/grizzlywebdev
/******************************************************************************/

/*
..........................................................................................
...............,:;;;:,....................................................................
...........,+?#@@@@@@#%,..................................................................
........,+%@@@S%%?+;#@@;..............................................:*?%%?;,............
.......+#@@%*?S#%[email protected]@%,.............................................;@@@SS#@@%:..........
.....,[email protected]@S:*%%*+;[email protected]@@[email protected]@:+*.:[email protected]@%:........
.....:@@@%+**?S#@@@@@%:............,,,:::::,,,,......................%@@,[email protected]*,,%@@;.......
.....,?#@@@@@@@@?;,:%@@+.....,:+?%##@@@@@@@@@@##S%*+:,..............,[email protected]@S,*@@@*.*@@;......
.......,;;;::[email protected]@*....*@@?,:*[email protected]@@@@#S%?*++++++++*?%#@@@#%+:,.......:?#@@@@S::%@@;[email protected]#,.....
..............*@@%:...;#@#@@@S?+:,,................,:[email protected]@#%;,..:[email protected]@#*+*#@@?::*?;;@@:.....
...............:%@@+,:*@@#?;,...........................,;?#@#[email protected]@#*,...:@@@@S***#@#,.....
.................;#@#@@%;,.................................,;[email protected]@#+,....;%@@%%#@@@@%:......
................,*@@@?:.....................................:?S+,...,[email protected]@%;...,::,........
...............;#@@?,......................................*%;....,*#@@?:.................
.............,[email protected]@S:........................................,....:?#@@%,...................
............,[email protected]@?,............................................:%%;:#@#:...................
...........,#@@*..............................................::...:@@S,..................
..........,[email protected]@?.....................................................*@@+..................
..........*@@S,.....................................................,@@#,.................
.........,#@@;......,*%[email protected]@:.................
.........;@@#,......,@@@+:*SS+.............::,...,:,[email protected]@+.................
.........*@@?........*@@@@@@S+............:@@#;:[email protected]@%[email protected]@*.................
.........*@@*.....,+%@@@@@*:...............+#@@@@@%:[email protected]@;.................
.........;@@S;...,#@@#%#@@?................,%@@@@*..................:@@@,.................
[email protected]@+,....;+:,.:#@#,.....,:,.....,*#@@[email protected]@@*,................%@@?..................
........;@@?............,:,....;[email protected]@#:....:#@S;.;[email protected],[email protected]@#,..................
........:@@S,..:S%+:..........;@@@@@?.....,,.....,,............,*,;@@@;...................
[email protected]@#%?#@@@@%:........;@@@@@*...........................*#@@@;....................
..........;S#@@#%;:#@@?;.......::,::,...............,,,,,,.......%@@;.....................
............,,,,..*@@%+,.....................,..,;[email protected]@@@@#?;[email protected]#,.....................
.................;@@*.......;,..............,?%*#@@#%[email protected]@?:[email protected]@?......................
[email protected]@,......%S,................;@@#;,....*@@@%?%#@@%,......................
[email protected]@[email protected],.......*+.........%@@,......,+%#@@#%;........................
.................:#@@*,...+#........#?........,#@@,.........,,,,..........................
..................,?#@@S%%#@?,.....,#%.......:[email protected]@*........................................
....................,;*%[email protected]@@%***%@@@S+:::+%@@#+.........................................
...........................:*S#@@@#%*[email protected]@@@@@@%+,..........................................
..............................,,,,....,:;;;:,.............................................
..........................................................................................
*/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";
import {IERC173} from "./interfaces/IERC173.sol";
import "@flair-sdk/contracts/src/access/ownable/OwnableStorage.sol";
import "@flair-sdk/contracts/src/token/common/metadata/MetadataStorage.sol";
import "@flair-sdk/contracts/src/token/common/metadata/TokenMetadataStorage.sol";
import "./libraries/PyramidStorage.sol";
import "@flair-sdk/contracts/src/finance/royalty/RoyaltyEnforcementStorage.sol";
import "@flair-sdk/contracts/src/token/ERC721/extensions/supply/ERC721SupplyStorage.sol";
import "@flair-sdk/contracts/src/finance/royalty/RoyaltyStorage.sol";
import "@flair-sdk/contracts/src/introspection/ERC165Storage.sol";

contract QuirkiesDiamond {
    using OwnableStorage for OwnableStorage.Layout;
    using MetadataStorage for MetadataStorage.Layout;
    using PyramidStorage for PyramidStorage.Layout;
    using TokenMetadataStorage for TokenMetadataStorage.Layout;
    using RoyaltyEnforcementStorage for RoyaltyEnforcementStorage.Layout;
    using RoyaltyStorage for RoyaltyStorage.Layout;
    using ERC721SupplyStorage for ERC721SupplyStorage.Layout;
    using ERC165Storage for ERC165Storage.Layout;

    constructor(
        address _contractOwner,
        address _diamondCutFacet,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _baseURI,
        string memory _uriSuffix,
        uint256 _maxSupply,
        address _royaltyRecipient,
        uint16 _bps
    ) payable {
        // set owner
        OwnableStorage.layout().setOwner(_contractOwner);

        // set metadata
        MetadataStorage.layout().name = _name;
        MetadataStorage.layout().symbol = _symbol;

        // set contract URI
        PyramidStorage.layout().contractURI = _contractURI;

        // set BaseURI
        TokenMetadataStorage.layout().baseURI = _baseURI;
        TokenMetadataStorage.layout().uriSuffix = _uriSuffix;

        // set Max Supply
        ERC721SupplyStorage.layout().maxSupply = _maxSupply;

        // set royalty enforcement
        RoyaltyEnforcementStorage.layout().enforceRoyalties = true;

        // set default royalty
        IRoyaltyInternal.TokenRoyalty memory royalty = IRoyaltyInternal
            .TokenRoyalty({recipient: _royaltyRecipient, bps: _bps});
        RoyaltyStorage.layout().defaultRoyalty = royalty;

        // set supported interfaces
        ERC165Storage.layout().setSupportedInterface(0x01ffc9a7, true);
        ERC165Storage.layout().setSupportedInterface(0x1f931c1c, true);
        ERC165Storage.layout().setSupportedInterface(0x48e2b093, true);
        ERC165Storage.layout().setSupportedInterface(0x2a848091, true);
        ERC165Storage.layout().setSupportedInterface(0x8153916a, true);
        ERC165Storage.layout().setSupportedInterface(0xb45a3c0e, true);
        ERC165Storage.layout().setSupportedInterface(0x80ac58cd, true);
        ERC165Storage.layout().setSupportedInterface(0xcdbde6dc, true);
        ERC165Storage.layout().setSupportedInterface(0xf69e0366, true);
        ERC165Storage.layout().setSupportedInterface(0x459bd11c, true);
        ERC165Storage.layout().setSupportedInterface(0xc82b5d4d, true);
        ERC165Storage.layout().setSupportedInterface(0xffa6b6b8, true);
        ERC165Storage.layout().setSupportedInterface(0x5b5e139f, true);
        ERC165Storage.layout().setSupportedInterface(0x93254542, true);
        ERC165Storage.layout().setSupportedInterface(0x1f0b49eb, true);
        ERC165Storage.layout().setSupportedInterface(0x7f5828d0, true);
        ERC165Storage.layout().setSupportedInterface(0x06ad59bc, true);
        ERC165Storage.layout().setSupportedInterface(0xbe561268, true);
        ERC165Storage.layout().setSupportedInterface(0x52ef6f9a, true);
        ERC165Storage.layout().setSupportedInterface(0x3f963a7f, true);
        ERC165Storage.layout().setSupportedInterface(0x2a55205a, true);
        ERC165Storage.layout().setSupportedInterface(0x821be678, true);
        ERC165Storage.layout().setSupportedInterface(0xb7799584, true);
        ERC165Storage.layout().setSupportedInterface(0xd5a06d4c, true);
        ERC165Storage.layout().setSupportedInterface(0xc7627428, true);
        ERC165Storage.layout().setSupportedInterface(0x150b7a02, true);
        ERC165Storage.layout().setSupportedInterface(0x49064906, true);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}