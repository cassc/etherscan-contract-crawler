// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {PartyInfo} from "../libraries/LibAppStorage.sol";
import {IDiamondCut} from "./IDiamondCut.sol";

/**
 * @title PartyFactory Interface
 * @author PartyFinance
 */
interface IPartyFactory {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when a new party is created
     * @param partyAddress Address of the new party created
     */
    event PartyCreated(address partyAddress);
    /**
     * @notice Emitted when the default cut is changed
     * @param newCut Array of FacetCut structs
     */
    event DefaultCutChanged(IDiamondCut.FacetCut[] newCut);
    /**
     * @notice Emitted when the Platform Sentinel is changed
     * @param sentinel Address of the Platform Sentinel
     */
    event PlatformSentinelChanged(address sentinel);
    /**
     * @notice Emitted when the Platform Fee Collector is changed
     * @param collector Address of the Platform Fee Collector
     */
    event PlatformCollectorChanged(address collector);
    /**
     * @notice Emitted when the Platform Fee is changed
     * @param fee Amount of the Platform Fee (in bps)
     */
    event PlatformFeeChanged(uint256 fee);
    /**
     * @notice Emitted when the pFi token address is changed
     * @param pfi Address of pFi token
     */
    event PfiChanged(address pfi);
    /**
     * @notice Emitted when the pFi party creation fee is changed
     * @param pfiFee Amount of pFi party creation fee
     */
    event PfiFeeChanged(uint256 pfiFee);
    /**
     * @notice Emitted when the PartyFactory status is changed
     * @param status Status of the PartyFactory
     */
    event StatusChanged(bool status);
    /**
     * @notice Emitted when the DiamondCut address is changed
     * @param diamondCut Address of DiamondCut
     */
    event DiamondCutChanged(address diamondCut);
    /**
     * @notice Emitted when the PartyInit address is changed
     * @param partyInit Address of pFi token
     */
    event PartyInitChanged(address partyInit);

    /* ========== METHODS ========== */

    /**
     * @notice Initializes the PartyFactory
     * @param _partyFacets Party facets data
     * @param _partyDiamondCut DiamondCutFacet address
     * @param _partyDiamondInit PartyInit address
     * @param _sentinel Platform sentinel address
     * @param _collector Platform collector address
     * @param _fee Platform fee in bps
     * @param _pfi pFi ERC20 Address
     * @param _pfi_fee Party fee creation in pFi
     * @param _ready Factory status
     */
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
    ) external;

    /**
     * @notice Set platform sentinel address
     * @dev Lets the PartyFactory owner to change the Platform sentinel address
     * @param _sentinel Address of the new Platform Sentinel
     */
    function setPlatformSentinel(address _sentinel) external;

    /**
     * @notice Set platform fee collector address
     * @dev Lets the PartyFactory owner to change the platform fee collector address
     * @param _platform Address of the new Platform Fee Collector
     */
    function setPlatformCollector(address _platform) external;

    /**
     * @notice Set platform fee
     * @dev Lets the PartyFactory owner to change the Platform fee
     * @param _fee New fee in bps (50 bps equals 0.5%)
     */
    function setPlatformFee(uint256 _fee) external;

    /**
     * @notice Set pFi token
     * @dev Lets the PartyFactory owner to change the PFI token address
     * @param _pfi Address of the pFi Token address
     */
    function setPfi(address _pfi) external;

    /**
     * @notice Set PFI token fee
     * @dev Lets the PartyFactory owner to change the PFI token fee
     * @param _pfi_fee New pFi party creation fee
     */
    function setPfiFee(uint256 _pfi_fee) external;

    /**
     * @notice Set Factory status
     * @dev Lets the PartyFactory owner change the status of the party creation
     * @param _ready New status
     */
    function setStatus(bool _ready) external;

    /**
     * @notice Set the Facets which all newly created Parties will share
     * @dev Lets the PartyFactory owner change the initial diamond cut for new Parties
     * @param _partyFacets Array of FacetCut structs
     */
    function setPartyFacets(
        IDiamondCut.FacetCut[] memory _partyFacets
    ) external;

    /**
     * @notice Set the EIP-2535 DiamondCutFacet address
     * @dev Lets the PartyFactory owner change the DiamondCutFacet address
     * @param _partyDiamondCut New DiamondCut address
     */
    function setDiamondCut(address _partyDiamondCut) external;

    /**
     * @notice Set the Party init contract
     * @dev Lets the PartyFactory owner change the PartyInit address
     * @param _partyDiamondInit New PartyInit contract address
     */
    function setPartyInit(address _partyDiamondInit) external;

    /**
     * @notice Create Party
     * @dev Deploys a new Party Contract that follows the Diamond Standard (EIP-2535)
     * @param partyInfo PartyInfo struct containing basic information of the Party
     * @param tokenSymbol Party ERC-20 symbol
     * @param initialDeposit Initial deposit in denomination asset to be made by the party creator
     * @param denominationAsset ERC-20 denomination asset (stable coin)
     */
    function createParty(
        PartyInfo memory partyInfo,
        string memory tokenSymbol,
        uint256 initialDeposit,
        address denominationAsset
    ) external payable returns (address party);

    /**
     * @dev Returns the platform related info
     * @return Platform fee collector address
     * @return Platform fee amount
     * @return Platform sentinel address
     */
    function getPlatformInfo()
        external
        view
        returns (address, uint256, address);

    /**
     * @notice Returns the default party facet cut
     * @dev It will always include the DiamondCutFacet
     * @return _defaultCut Default DiamondCut for fresh new Parties
     */
    function getPartyDefaultFacetCut()
        external
        view
        returns (IDiamondCut.FacetCut[] memory _defaultCut);
}