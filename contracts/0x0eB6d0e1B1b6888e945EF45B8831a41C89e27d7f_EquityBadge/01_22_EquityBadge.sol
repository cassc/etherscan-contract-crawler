// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - mikolaj[email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OZ Upgrades imports
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

// Local imports
import { IEquityBadge } from "../interfaces/IEquityBadge.sol";
import { IERC1155Supply } from "../interfaces/IERC1155Supply.sol";

/**************************************

    Equity badge

 **************************************/

/// @notice Upgradeable ERC1155 reward that allows to vote on milestones.
contract EquityBadge is Initializable, IEquityBadge, IERC1155Supply, ERC1155Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Fundraising role that is able to register and mint new badges.
    bytes32 public constant FUNDRAISING_ROLE = keccak256("FUNDRAISING");
    /// @dev Admin role used for upgrade of proxy source.
    bytes32 public constant CAN_UPGRADE = keccak256("CAN_UPGRADE");

    // -----------------------------------------------------------------------
    //                              State variables
    // -----------------------------------------------------------------------

    /// @dev Total supply for each badge id.
    mapping(uint256 => uint256) private _totalSupply;
    /// @dev URI per each badge id.
    mapping(uint256 => string) private _uris;

    // -----------------------------------------------------------------------
    //                              Setup
    // -----------------------------------------------------------------------

    /**************************************
        
        Constructor
    
    **************************************/

    /// @dev Constructor that is only called on bytecode deployment and disables initializers from non-proxy contract.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**************************************
        
        Initializer
    
    **************************************/

    /// @dev Initializer called from UUPS proxy contract.
    /// @dev Validation: Can be called only once per proxy contract.
    /// @param _fundraising Address of FundraisingDiamond contract
    function initialize(address _fundraising) external initializer {
        // admin setup
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // mint
        _setupRole(FUNDRAISING_ROLE, _fundraising);
        _setupRole(CAN_UPGRADE, msg.sender);
    }

    /**************************************

        Internal: Authorize upgrade

    **************************************/

    /// @dev Authorization hook for proxy implementation upgrade.
    /// @dev Validation: Can be called only by CAN_UPGRADE role.
    /// @param newImplementation Address of new implementation.
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(CAN_UPGRADE) {}

    // -----------------------------------------------------------------------
    //                              URI section
    // -----------------------------------------------------------------------

    /**************************************

        Set URI
    
    **************************************/

    /// @dev Set URI for badge id.
    /// @dev Validation: Can be called only by FundraisingDiamond.
    /// @param _badgeId Id of badge
    /// @param _uri IPFS uri to JSON depicting badge
    function setURI(uint256 _badgeId, string memory _uri) external onlyRole(FUNDRAISING_ROLE) {
        _uris[_badgeId] = _uri;
    }

    /**************************************

        Get URI

    **************************************/

    /// @dev Get URI for badge id.
    /// @param _badgeId Id of badge
    /// @return IPFS uri for given badge id
    function uri(uint256 _badgeId) public view override returns (string memory) {
        return _uris[_badgeId];
    }

    // -----------------------------------------------------------------------
    //                              External
    // -----------------------------------------------------------------------

    /**************************************
        
        Mint
    
    **************************************/

    /// @dev Mint amount of ERC1155 badges to given user account.
    /// @dev Validation: Can be called only by FundraisingDiamond.
    /// @dev Validation: Can be only minted for an existing badge with registered URI.
    /// @dev Events: TransferSingle(address operator, address from, address to, uint256 id, uint256 value).
    /// @param _sender Address of badge recipient
    /// @param _badgeId Number of badge (derived from project uuid)
    /// @param _amount Quantity of badges to mint
    /// @param _data Additional data for transfer hooks
    function mint(address _sender, uint256 _badgeId, uint256 _amount, bytes memory _data) external onlyRole(FUNDRAISING_ROLE) {
        // revert if uri is not set up
        if (bytes(_uris[_badgeId]).length == 0) {
            revert InvalidURI(_badgeId);
        }

        // storage
        _totalSupply[_badgeId] += _amount;

        // mint
        _mint(_sender, _badgeId, _amount, _data);
    }

    // -----------------------------------------------------------------------
    //                              Transfer section
    // -----------------------------------------------------------------------

    /// @dev Function that can disable or enable badge transfer.
    /// @return Boolean that if true disables transfers
    function _disabledTransfer() public pure virtual returns (bool) {
        // returns true, but can be overriden in child contracts
        return true;
    }

    /// @dev Transfer given amount of badges within a single badge type.
    /// @dev Validation: Fails if _disabledTransfer() returns true.
    /// @param from Address of sender
    /// @param to Address of receiver
    /// @param id Number of badge id
    /// @param amount Quantity of badges to transfer
    /// @param data Additional data for transfer hooks
    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        // revert
        if (_disabledTransfer()) {
            revert BadgeTransferNotYetPossible();
        } else {
            super._safeTransferFrom(from, to, id, amount, data);
        }
    }

    /// @dev Transfer number of badges within different badge types.
    /// @dev Validation: Fails if _disabledTransfer() returns true.
    /// @param from Address of sender
    /// @param to Address of receiver
    /// @param ids List of badge ids
    /// @param amounts List of quantities of badges to transfer
    /// @param data Additional data for transfer hooks
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // revert
        if (_disabledTransfer()) {
            revert BadgeTransferNotYetPossible();
        } else {
            super._safeBatchTransferFrom(from, to, ids, amounts, data);
        }
    }

    /**************************************
        
        Exists
    
    **************************************/

    /// @dev Returns if given id exists.
    /// @param _id Id to verify
    /// @return Information if given id exists
    function exists(uint256 _id) external view override returns (bool) {
        return bytes(_uris[_id]).length > 0;
    }

    /**************************************
        
        TotalSupply
    
    **************************************/

    /// @dev Total supply for id.
    /// @param _id Id to verify
    /// @return Total amount of minted tokens for given id
    function totalSupply(uint256 _id) external view override returns (uint256) {
        // return
        return _totalSupply[_id];
    }

    /**************************************
        
        Supports interface
    
    **************************************/

    // -----------------------------------------------------------------------
    //                              ERC165
    // -----------------------------------------------------------------------

    /// @dev ERC165-compliant function that returns true on supported interface id.
    /// @param interfaceId interface that could be supported
    /// @return Boolean depicting if interface is supported or not
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IEquityBadge).interfaceId ||
            interfaceId == type(IERC1155Supply).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}