// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {AppStorage, RoyaltyInfo} from "./libraries/LibAppStorage.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";
import {AppStorage} from "./libraries/LibAppStorage.sol";
import {Shared} from "./libraries/Shared.sol";
import {IERC173} from "./interfaces/IERC173.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import "hardhat/console.sol";

/// @custom:security-contact [email protected]
contract TheNewMastersoundsTheDeplarEffectSilver {
    AppStorage internal s;

    struct DiamondArgs {
        address _owner;
        string _name;
        string _symbol;
        address[] _payees; // primary
        uint256[] _shares; // primary
        address _secondaryPayee;
        uint96 _secondaryPoints;
        string _contractURI;
        uint256 _price;
        uint256 _maxSupply;
        string _baseTokenUri;
        bool _airdrop;
        uint256 _maxMintPerTx;
        uint256 _maxMintPerAddress;
        bool _allowListEnabled;
        bool _isPriceUSD;
        bool _automaticUSDConversion;
    }

    constructor(
        IDiamondCut.FacetCut[] memory _diamondCut,
        DiamondArgs memory _args
    ) payable {
        require(
            _args._payees.length == _args._shares.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(_args._payees.length > 0, "PaymentSplitter: no payees");

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
        s.paused = false;
        s.currentIndex = 0;
        s.name = _args._name;
        s.symbol = _args._symbol;
        s.airdrop = _args._airdrop;
        s.maxSupply = _args._maxSupply;
        s.isPriceUSD = _args._isPriceUSD;
        s.contractURI = _args._contractURI;
        s.maxMintPerTx = _args._maxMintPerTx;
        s.baseTokenUri = _args._baseTokenUri;
        s.price = _args._airdrop ? 0 : _args._price;
        s.allowListEnabled = _args._allowListEnabled;
        s.maxMintPerAddress = _args._maxMintPerAddress;
        s.automaticUSDConversion = _args._automaticUSDConversion;

        // Initialize PaymentSplitter information
        for (uint256 i = 0; i < _args._payees.length; ) {
            Shared._addPayee(_args._payees[i], _args._shares[i]);
            // Gas Optimization
            unchecked {
                i++;
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