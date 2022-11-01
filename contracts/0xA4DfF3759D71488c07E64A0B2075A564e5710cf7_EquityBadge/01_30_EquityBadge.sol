// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OZ Upgrades imports
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

// Local OZ override
import { ERC1155VotesUpgradeable } from "../oz/ERC1155VotesUpgradeable.sol";

// Local imports
import { IEquityBadge } from "../interfaces/IEquityBadge.sol";

/**************************************

    Equity badge

 **************************************/

contract EquityBadge is Initializable, IEquityBadge, ERC1155VotesUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    
    // roles
    bytes32 public constant FUNDRAISING_ROLE = keccak256("FUNDRAISING");
    bytes32 public constant CAN_UPGRADE = keccak256("CAN_UPGRADE");

    // storage
    string public symbol;

    // supply
    mapping (uint256 => uint256) private _totalSupply;

    // errors
    error BadgeTransferNotYetPossible();

    /**************************************
        
        Constructor
    
    **************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    /**************************************
        
        Initializer
    
    **************************************/

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _url,
        address _fundraising
    ) external initializer {
        
        // super
        __ERC1155_init(_url);
        __EIP712_init(_name, "1");

        // admin setup
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(FUNDRAISING_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CAN_UPGRADE, DEFAULT_ADMIN_ROLE);

        // mint
        _setupRole(FUNDRAISING_ROLE, _fundraising);
        _setupRole(CAN_UPGRADE, msg.sender);

        // storage
        symbol = _symbol;

    }

    /**************************************

        Internal: Authorize upgrade

    **************************************/

    function _authorizeUpgrade(address newImplementation) internal override
    onlyRole(CAN_UPGRADE) {}

    /**************************************
        
        Mint
    
    **************************************/

    function mint(
        address _sender,
        uint256 _projectId,
        uint256 _amount,
        bytes memory _data
    ) external 
    onlyRole(FUNDRAISING_ROLE) {

        // storage
        _totalSupply[_projectId] += _amount;

        // mint
        _mint(_sender, _projectId, _amount, _data);

    }

    /**************************************

        Delegate on behalf

    **************************************/

    function delegateOnBehalf(
        address _account, address _delegatee, bytes memory _data
    ) external 
    onlyRole(FUNDRAISING_ROLE) {

        // delegate by fundraising
        _delegate(_account, _delegatee, _data);

    }

    /**************************************

        Disabled transfer

    **************************************/

    function _disabledTransfer() public pure virtual
    returns (bool) {

        // returns true, but can be overriden in child contracts
        return true;

    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {

        // revert
        if (_disabledTransfer()) {
            revert BadgeTransferNotYetPossible();
        } else {
            super._safeTransferFrom(
                from,
                to,
                id,
                amount,
                data
            );
        }

    }

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
            super._safeBatchTransferFrom(
                from,
                to,
                ids,
                amounts,
                data
            );
        }

    }

    /**************************************
        
        Total supply
    
    **************************************/

    function totalSupply(uint256 _projectId) external view override
    returns (uint256) {

        // return
        return _totalSupply[_projectId];

    }

    /**************************************
        
        Supports interface
    
    **************************************/

    function supportsInterface(bytes4 interfaceId) public view virtual
    override(ERC1155VotesUpgradeable, AccessControlUpgradeable, IERC165Upgradeable)
    returns (bool) {
        return
            interfaceId == type(IEquityBadge).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}