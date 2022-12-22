// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Party} from "../Party.sol";
import {InitArgs} from "../init/PartyInit.sol";
import {PartyInfo} from "../libraries/LibAppStorage.sol";
import {IPartyFactory} from "../interfaces/IPartyFactory.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// @openzeppelin/contracts-upgradeable
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// @openzeppelin/contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PartyFactory
 * @author PartyFinance
 * @notice Factory contract that deploys new Parties as EIP-2535 Diamond
 */
contract PartyFactory is UUPSUpgradeable, OwnableUpgradeable, IPartyFactory {
    /**
     * @notice PartyBeacon address
     * @dev Used for the old protocol. No longer used but must remain to avoid storage collision on upgrade
     */
    address public partyBeacon;

    /**
     * @notice Platform Fee Collector address
     * @dev Address where the collected fees will be transferred
     */
    address public PLATFORM_ADDRESS;
    /**
     * @notice Platform Fee amount
     * @dev Fee amount in bps
     */
    uint256 public PLATFORM_FEE;

    /// Mapping of created parties
    mapping(address => bool) public parties;

    /// PartyFinance (pFi) token address
    address public PFI;
    /// PartyFinance (pFi) fee amount for party creations
    uint256 public PFI_FEE;

    /// Platform Sentinel address
    address public PLATFORM_SENTINEL;

    /**
     * @notice Factory status
     * @dev Indicates whether the party creation is available or not
     */
    bool public ready;

    /// Party default facet cut for Diamond implementation
    IDiamondCut.FacetCut[] public partyDefaultCut;
    /// DiamondCutFacet address
    address public PARTY_DIAMOND_CUT;
    /// PartyInit address
    address public PARTY_DIAMOND_INIT;

    // @inheritdoc IPartyFactory
    function initialize(
        IDiamondCut.FacetCut[] memory _partyFacets,
        address _partyDiamondCut,
        address _partyDiamondInit,
        address _sentinel,
        address _collector,
        uint256 _fee,
        address _pfi,
        uint256 _pfi_fee,
        bool _ready
    ) external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        setPartyFacets(_partyFacets);
        setDiamondCut(_partyDiamondCut);
        setPartyInit(_partyDiamondInit);
        setPlatformSentinel(_sentinel);
        setPlatformCollector(_collector);
        setPlatformFee(_fee);
        setPfi(_pfi);
        setPfiFee(_pfi_fee);
        setStatus(_ready);
    }

    // @inheritdoc IPartyFactory
    function setPlatformSentinel(address _sentinel) public onlyOwner {
        require(_sentinel != address(0), "Sentinel is zero address");
        PLATFORM_SENTINEL = _sentinel;
        emit PlatformSentinelChanged(_sentinel);
    }

    // @inheritdoc IPartyFactory
    function setPlatformCollector(address _platform) public onlyOwner {
        require(_platform != address(0), "Collector is zero address");
        PLATFORM_ADDRESS = _platform;
        emit PlatformCollectorChanged(_platform);
    }

    // @inheritdoc IPartyFactory
    function setPlatformFee(uint256 _fee) public onlyOwner {
        PLATFORM_FEE = _fee;
        emit PlatformFeeChanged(_fee);
    }

    // @inheritdoc IPartyFactory
    function setPfi(address _pfi) public onlyOwner {
        require(_pfi != address(0), "pFi is zero address");
        PFI = _pfi;
        emit PfiChanged(_pfi);
    }

    // @inheritdoc IPartyFactory
    function setPfiFee(uint256 _pfi_fee) public onlyOwner {
        PFI_FEE = _pfi_fee;
        emit PfiFeeChanged(_pfi_fee);
    }

    // @inheritdoc IPartyFactory
    function setStatus(bool _ready) public onlyOwner {
        ready = _ready;
        emit StatusChanged(_ready);
    }

    // @inheritdoc IPartyFactory
    function setPartyFacets(
        IDiamondCut.FacetCut[] memory _partyFacets
    ) public onlyOwner {
        require(_partyFacets.length > 0, "Empty facet cut not allowed");
        delete partyDefaultCut;
        for (uint256 i = 0; i < _partyFacets.length; i++) {
            require(
                _partyFacets[i].action == IDiamondCut.FacetCutAction.Add,
                "Only ADD facet action allowed"
            );
            require(
                _partyFacets[i].facetAddress != address(0),
                "Only non-zero facet address allowed"
            );
            require(
                _partyFacets[i].functionSelectors.length > 0,
                "Only non-empty functionSelectors allowed"
            );
            partyDefaultCut.push(_partyFacets[i]);
        }
        emit DefaultCutChanged(partyDefaultCut);
    }

    // @inheritdoc IPartyFactory
    function setDiamondCut(address _partyDiamondCut) public onlyOwner {
        require(_partyDiamondCut != address(0), "DiamondCut is zero address");
        PARTY_DIAMOND_CUT = _partyDiamondCut;
        emit DiamondCutChanged(_partyDiamondCut);
    }

    // @inheritdoc IPartyFactory
    function setPartyInit(address _partyDiamondInit) public onlyOwner {
        require(_partyDiamondInit != address(0), "PartyInit is zero address");
        PARTY_DIAMOND_INIT = _partyDiamondInit;
        emit PartyInitChanged(_partyDiamondInit);
    }

    // @inheritdoc IPartyFactory
    function createParty(
        PartyInfo memory partyInfo,
        string memory tokenSymbol,
        uint256 initialDeposit,
        address denominationAsset
    ) external payable returns (address party) {
        require(ready, "Factory is not ready");

        // Create the Party as a Diamond Standard EIP-2535
        party = address(new Party(PARTY_DIAMOND_CUT));

        // Initialize the Party and set the default facets
        IDiamondCut(party).diamondCut(
            partyDefaultCut,
            PARTY_DIAMOND_INIT,
            abi.encodeWithSignature(
                "init((address,(string,string,string,string,string,bool,uint256,uint256),string,uint256,address,address,uint256,address))",
                InitArgs(
                    msg.sender,
                    partyInfo,
                    tokenSymbol,
                    initialDeposit,
                    denominationAsset,
                    PLATFORM_ADDRESS,
                    PLATFORM_FEE,
                    PLATFORM_SENTINEL
                )
            )
        );

        // Transfer funds to party
        IERC20(denominationAsset).transferFrom(
            msg.sender,
            party,
            initialDeposit
        );

        // Collect fees
        uint256 fee = (initialDeposit * PLATFORM_FEE) / 10000;
        IERC20(denominationAsset).transferFrom(
            msg.sender,
            PLATFORM_ADDRESS,
            fee
        );
        // Collect Pfi fee (if applied)
        if (PFI_FEE > 0) {
            IERC20(PFI).transferFrom(msg.sender, address(this), PFI_FEE);
        }

        // Add created Party to PartyFactory
        parties[party] = true;

        // Emit party creation event;
        emit PartyCreated(party);
    }

    // @inheritdoc IPartyFactory
    function getPlatformInfo()
        external
        view
        returns (address, uint256, address)
    {
        return (PLATFORM_ADDRESS, PLATFORM_FEE, PLATFORM_SENTINEL);
    }

    // @inheritdoc IPartyFactory
    function getPartyDefaultFacetCut()
        external
        view
        returns (IDiamondCut.FacetCut[] memory _defaultCut)
    {
        _defaultCut = new IDiamondCut.FacetCut[](partyDefaultCut.length + 1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        _defaultCut[0] = IDiamondCut.FacetCut({
            facetAddress: PARTY_DIAMOND_CUT,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        for (uint256 i = 0; i < partyDefaultCut.length; i++) {
            _defaultCut[i + 1] = partyDefaultCut[i];
        }
        return _defaultCut;
    }

    /**
     * @notice Inherited from UUPSUpgradeable.
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by `upgradeTo` and `upgradeToAndCall`.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}