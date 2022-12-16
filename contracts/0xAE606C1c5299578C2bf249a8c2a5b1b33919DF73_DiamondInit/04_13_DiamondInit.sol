// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Initialiser contract authored by Sibling Labs
 * Version 0.4.0
 * 
 * This initialiser contract has been written specifically for
 * ERC721A-DIAMOND-TEMPLATE by Sibling Labs
/**************************************************************/

import { GlobalState } from "./libraries/GlobalState.sol";
import { TokenFacetLib } from "./facets/TokenFacet.sol";
import { ERC165Lib } from "./facets/ERC165Facet.sol";
import "erc721a-upgradeable/contracts/ERC721AStorage.sol";
import "erc721a-upgradeable/contracts/ERC721A__InitializableStorage.sol";
import { RoyaltiesConfigLib } from "./facets/RoyaltiesConfigFacet.sol";

contract DiamondInit {

    function initAll() public {
        initTokenFacet();
        initERC165Facet();
        initRoyaltiesConfigFacet();
    }

    // TokenFacet //

    address private constant ash = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92; // mainnet
    address private constant authorisedSigner = 0x2aE288613B8c4AdCf01b68e7A90C82cF0E51512D;
    string private constant description = "This NFT changes depending on its owner\'s $ASH token balance. Each symbol represents 10 $ASH. Click to invert.";
    string private constant imageUrl = "ipfs://QmU78H5xJvPWWsWh3ueXMG5hwhqcAGetMaKyfbEdEmrcc2/";
    string private constant animUrlPrefix = "ipfs://QmSfPvpDfuvwSHKXgzZYFGkoTdNBk2auBdd4AcDAuojG2q/";

    string private name = "AshVaultV2";
    string private constant symbol = "ASHVAULT";

    function initTokenFacet() public {
        TokenFacetLib.state storage s1 = TokenFacetLib.getState();

        s1.ash = ash;
        s1.authorisedSigner = authorisedSigner;
        s1.description = description;
        s1.imageUrl = imageUrl;
        s1.animUrlPrefix = animUrlPrefix;

        ERC721AStorage.Layout storage s2 = ERC721AStorage.layout();

        s2._name = name;
        s2._symbol = symbol;

        ERC721A__InitializableStorage.layout()._initialized = true;
    }

    // ERC165Facet //

    bytes4 private constant ID_IERC165 = 0x01ffc9a7;
    bytes4 private constant ID_IERC173 = 0x7f5828d0;
    bytes4 private constant ID_IERC2981 = 0x2a55205a;
    bytes4 private constant ID_IERC721 = 0x80ac58cd;
    bytes4 private constant ID_IERC721METADATA = 0x5b5e139f;
    bytes4 private constant ID_IDIAMONDLOUPE = 0x48e2b093;
    bytes4 private constant ID_IDIAMONDCUT = 0x1f931c1c;

    function initERC165Facet() public {
        ERC165Lib.state storage s = ERC165Lib.getState();

        s.supportedInterfaces[ID_IERC165] = true;
        s.supportedInterfaces[ID_IERC173] = true;
        s.supportedInterfaces[ID_IERC2981] = true;
        s.supportedInterfaces[ID_IERC721] = true;
        s.supportedInterfaces[ID_IERC721METADATA] = true;

        s.supportedInterfaces[ID_IDIAMONDLOUPE] = true;
        s.supportedInterfaces[ID_IDIAMONDCUT] = true;
    }

    // RoyaltiesConfigFacet //

    address payable private constant royaltyRecipient = payable(0x93416306670d7936F1718168e2105C34099B9211);

    function initRoyaltiesConfigFacet() public {
        RoyaltiesConfigLib.state storage s = RoyaltiesConfigLib.getState();

        s.royaltyRecipient = royaltyRecipient;
    }

}