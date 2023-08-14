// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {OwnableStorage, OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {PaymentSplitterInternal} from "./utils/PaymentSplitter/PaymentSplitterInternal.sol";
import {ERC1155Facet} from "./facets/ERC1155Facet.sol";

// EIP-165 Imports
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC173} from "@solidstate/contracts/interfaces/IERC173.sol";
import {IERC1155} from "@solidstate/contracts/interfaces/IERC1155.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {IERC1155Metadata} from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

// Storage
import {ERC165Storage} from "@solidstate/contracts/introspection/ERC165Storage.sol";
import {ERC2981Storage} from "@solidstate/contracts/token/common/ERC2981/ERC2981Storage.sol";
import {ERC1155Storage} from "./storage/ERC1155Storage.sol";
import {ERC1155MetadataStorage} from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";
import {ERC1155EnumerableStorage} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol";

import "hardhat/console.sol";

contract Lively1155Diamond is PaymentSplitterInternal, OwnableInternal {
    using ERC165Storage for ERC165Storage.Layout;
    using ERC2981Storage for ERC2981Storage.Layout;

    event URI(string _value, uint256 indexed _id);

    /** @dev Think about cutting this constructor down and using multicall
     * transactions to set up in the contract in efficient way without bloating
     * the main constructor.  */
    struct DiamondArgs {
        address[] _payees;
        uint256[] _shares;
        address _secondaryPayee;
        uint16 _secondaryShare;
        bool _airdrop;
        string _name;
        string _symbol;
        string _contractURI;
        string _baseURI;
        ERC1155Storage.TokenStructure[] _tokenData;
    }

    constructor(
        IDiamondCut.FacetCut[] memory _diamondCut,
        DiamondArgs memory _args
    ) payable {
        uint256 payeesLength;
        uint256 sharesLength = _args._shares.length;
        if (!_args._airdrop) {
            payeesLength = _args._payees.length;
            if (payeesLength != sharesLength) {
                revert PaymentSplitterMismatch();
            }

            if (payeesLength == 0) {
                revert PaymentSplitterNoPayees();
            }
        }

        // Set various state variables
        OwnableStorage.layout().owner = msg.sender;
        ERC1155MetadataStorage.layout().baseURI = _args._baseURI;
        ERC1155Storage.layout().airdrop = _args._airdrop;
        ERC1155Storage.layout().name = _args._name;
        ERC1155Storage.layout().symbol = _args._symbol;

        // Set EIP-165 Supported Interfaces
        ERC165Storage.layout().setSupportedInterface(
            type(IERC165).interfaceId,
            true
        );
        ERC165Storage.layout().setSupportedInterface(
            type(IERC1155).interfaceId,
            true
        );
        ERC165Storage.layout().setSupportedInterface(
            type(IDiamondCut).interfaceId,
            true
        );
        ERC165Storage.layout().setSupportedInterface(
            type(IDiamondLoupe).interfaceId,
            true
        );
        ERC165Storage.layout().setSupportedInterface(
            type(IERC173).interfaceId,
            true
        );
        ERC165Storage.layout().setSupportedInterface(
            type(IERC1155Metadata).interfaceId,
            true
        );
        ERC165Storage.layout().setSupportedInterface(
            type(IERC2981).interfaceId,
            true
        );

        // Initial Cut
        LibDiamond.diamondCut(_diamondCut, address(0), "");

        // Initialize PaymentSplitter information (Primary Royalties)
        uint256 i = 0;
        for (; i < sharesLength; ) {
            _addPayee(_args._payees[i], _args._shares[i]);
            // Gas Optimization
            unchecked {
                ++i;
            }
        }

        // Initialize initial token data if available
        i = 0;
        uint256 tokenDataLength = _args._tokenData.length;
        ERC1155Storage.TokenStructure memory _token;
        for (; i < tokenDataLength; ) {
            console.log("About to create token: %s", i);

            _token = _args._tokenData[i];
            _token.creator = msg.sender;
            console.log("Max Supply: %s", _token.maxSupply);
            console.log("Price: %s", _token.price);
            console.log("creator: %s", _token.creator);
            console.log("Token URI: %s", _token.tokenUri);
            console.log("Allow List Enabled: %s", _token.allowListEnabled);

            console.log("Successfully called create function");
            uint256 _id = ERC1155Storage.layout().currentTokenId;

            // Do we want to store everything in top level mappings or use the tokenData struct mapping?
            // Not sure if there's a huge difference in gas costs here.
            ERC1155Storage.TokenStructure storage tokenData = ERC1155Storage
                .layout()
                .tokenData[_id];

            tokenData.maxSupply = _token.maxSupply;
            tokenData.price = _token.price;
            tokenData.creator = msg.sender;
            tokenData.tokenUri = _token.tokenUri;
            tokenData.allowListEnabled = _token.allowListEnabled;

            if (bytes(_token.tokenUri).length > 0) {
                emit URI(_token.tokenUri, _id);
            }

            ERC1155EnumerableStorage.layout().totalSupply[_id] = 0;
            ++ERC1155Storage.layout().currentTokenId;
            ++i;
        }
        // Set 2981 Royalty Info (Secondary Royalties)
        ERC2981Storage.layout().defaultRoyaltyBPS = _args._secondaryShare;
        ERC2981Storage.layout().defaultRoyaltyReceiver = _args._secondaryPayee;
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
        address facet = address(bytes20(ds.facets[msg.sig]));
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

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }
}