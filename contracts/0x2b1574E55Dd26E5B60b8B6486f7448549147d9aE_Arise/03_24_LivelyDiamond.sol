// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {AppStorage, RoyaltyInfo, Edition} from "./libraries/LibAppStorage.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";
import {Shared} from "./libraries/Shared.sol";
import {IERC173} from "./interfaces/IERC173.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {LibDiamondEtherscan} from "./libraries/LibDiamondEtherscan.sol";

import "hardhat/console.sol";

error PaymentSplitterMismatch();
error PaymentSplitterNoPayees();

/// @custom:security-contact [email protected]
contract LivelyDiamond {
    AppStorage internal s;

    struct DiamondArgs {
        uint256 _price;
        uint256 _maxSupply;
        uint256 _maxMintPerTx;
        uint256 _maxMintPerAddress;
        address _secondaryPayee;
        address _owner;
        uint96 _secondaryPoints;
        address[] _payees; // primary
        uint256[] _shares; // primary
        string _name;
        string _symbol;
        string _contractURI;
        string _baseTokenUri;
        bool _airdrop;
        bool _allowListEnabled;
        bool _isPriceUSD;
        bool _automaticUSDConversion;
        bool _isSoulbound;
        Edition[] _editions;
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

        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
        LibDiamond.setContractOwner(_args._owner);

        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IAccessControl).interfaceId] = true;

        // Initialize Data
        // s.paused = false; // Defaults to false
        // s.currentIndex = 0; // Defaults to 0
        s.name = _args._name;
        s.symbol = _args._symbol;
        s.airdrop = _args._airdrop;
        s.maxSupply = _args._maxSupply;
        s.isPriceUSD = _args._isPriceUSD;
        s.isSoulbound = _args._isSoulbound;
        s.contractURI = _args._contractURI;
        s.maxMintPerTx = _args._maxMintPerTx;
        s.baseTokenUri = _args._baseTokenUri;
        s.price = _args._airdrop ? 0 : _args._price;
        s.allowListEnabled = _args._allowListEnabled;
        s.maxMintPerAddress = _args._maxMintPerAddress;
        s.automaticUSDConversion = _args._automaticUSDConversion;

        // Initialize PaymentSplitter information
        for (uint256 i = 0; i < sharesLength; ) {
            Shared._addPayee(_args._payees[i], _args._shares[i]);
            // Gas Optimization
            unchecked {
                ++i;
            }
        }

        // Set Royalty Info
        s.defaultRoyaltyInfo = RoyaltyInfo(
            _args._secondaryPayee,
            _args._secondaryPoints
        );

        // Access Control Roles
        s.DEFAULT_ADMIN_ROLE = 0x00;
        s.OWNER_ROLE = keccak256("OWNER_ROLE");

        Shared._grantRole(s.DEFAULT_ADMIN_ROLE, msg.sender);
        Shared._grantRole(s.OWNER_ROLE, msg.sender);

        // Editions
        uint256 editionsLength = _args._editions.length;
        if (editionsLength > 0) {
            s.editionsEnabled = true;
            for (uint256 i = 0; i < editionsLength; ) {
                Edition memory _edition = _args._editions[i];

                Shared.createEdition(
                    _edition.name,
                    _edition.maxSupply,
                    _edition.price
                );

                unchecked {
                    ++i;
                }
            }
        }

        // Set implementation slot
        LibDiamondEtherscan._setDummyImplementation(
            0x71D964BC6e1Cc017eE05E012B8B70eCA9d049C85
        );
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
        emit Shared.PaymentReceived(msg.sender, msg.value);
    }
}