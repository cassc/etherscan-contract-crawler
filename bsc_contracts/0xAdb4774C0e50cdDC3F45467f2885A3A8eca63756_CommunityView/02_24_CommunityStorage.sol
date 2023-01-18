// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@artman325/trustedforwarder/contracts/TrustedForwarder.sol";
import "@artman325/releasemanager/contracts/CostManagerHelperERC2771Support.sol";

import "./lib/ECDSAExt.sol";
import "./lib/StringUtils.sol";
import "./lib/PackedSet.sol";

import "./interfaces/ICommunityHook.sol";
//import "hardhat/console.sol";

abstract contract CommunityStorage is Initializable, ReentrancyGuardUpgradeable, TrustedForwarder, CostManagerHelperERC2771Support, IERC721Upgradeable, IERC721MetadataUpgradeable, OwnableUpgradeable {
    
    using PackedSet for PackedSet.Set;

    using StringUtils for *;

    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;


    ////////////////////////////////
    ///////// structs //////////////
    ////////////////////////////////

    struct inviteSignature {
        bytes sSig;
        bytes rSig;
        uint256 gasCost;
        ReimburseStatus reimbursed;
        bool used;
        bool exists;
    }

    struct GrantSettings {
        uint8 requireRole;   //=0, 
        uint256 maxAddresses;//=0, 
        uint64 duration;    //=0
        uint64 lastIntervalIndex;
        uint256 grantedAddressesCounter;
    }
    struct Role {
        bytes32 name;
        string roleURI;
        mapping(address => string) extraURI;
        //EnumerableSetUpgradeable.UintSet canManageRoles;
        EnumerableSetUpgradeable.UintSet canGrantRoles;
        EnumerableSetUpgradeable.UintSet canRevokeRoles;

        mapping(uint8 => GrantSettings) grantSettings;

        EnumerableSetUpgradeable.AddressSet members;
    }

    // Please make grantedBy(uint160 recipient => struct ActionInfo) mapping, and save it when user grants role. (Difference with invitedBy is that invitedBy the user has to ACCEPT the invite while grantedBy doesn’t require recipient to accept).
    // And also make revokedBy same way.
    // Please refactor invited and invitedBy and to return struct ActionInfo also. Here is struct ActionInfo, it fits in ONE slot:
    struct ActionInfo {
        address actor;
        uint64 timestamp;
        uint32 extra; // used for any other info, eg up to four role ids can be stored here !!!
    }

    /////////////////////////////
    ///////// vars //////////////
    /////////////////////////////

    /**
    * @notice getting name
    * @custom:shortd ERC721'name
    * @return name 
    */
    string public name;
    
    /**
    * @notice getting symbol
    * @custom:shortd ERC721's symbol
    * @return symbol 
    */
    string public symbol;
    
    uint8 internal rolesCount;
    address public hook;
    uint256 addressesCounter;

    uint8 internal constant NONE_ROLE_INDEX = 0;
    /**
    * @custom:shortd role name "owners" in bytes32
    * @notice constant role name "owners" in bytes32
    */
    bytes32 public constant DEFAULT_OWNERS_ROLE = 0x6f776e6572730000000000000000000000000000000000000000000000000000;

    /**
    * @custom:shortd role name "admins" in bytes32
    * @notice constant role name "admins" in bytes32
    */
    bytes32 public constant DEFAULT_ADMINS_ROLE = 0x61646d696e730000000000000000000000000000000000000000000000000000;

    /**
    * @custom:shortd role name "members" in bytes32
    * @notice constant role name "members" in bytes32
    */
    bytes32 public constant DEFAULT_MEMBERS_ROLE = 0x6d656d6265727300000000000000000000000000000000000000000000000000;

    /**
    * @custom:shortd role name "relayers" in bytes32
    * @notice constant role name "relayers" in bytes32
    */
    bytes32 public constant DEFAULT_RELAYERS_ROLE = 0x72656c6179657273000000000000000000000000000000000000000000000000;

    /**
    * @custom:shortd role name "alumni" in bytes32
    * @notice constant role name "alumni" in bytes32
    */
    bytes32 public constant DEFAULT_ALUMNI_ROLE = 0x616c756d6e690000000000000000000000000000000000000000000000000000;

    /**
    * @custom:shortd role name "visitors" in bytes32
    * @notice constant role name "visitors" in bytes32
    */
    bytes32 public constant DEFAULT_VISITORS_ROLE = 0x76697369746f7273000000000000000000000000000000000000000000000000;
    
    /**
    * @notice constant reward that user-relayers will obtain
    * @custom:shortd reward that user-relayers will obtain
    */
    uint256 public constant REWARD_AMOUNT = 1000000000000000; // 0.001 * 1e18
    /**
    * @notice constant reward amount that user-recepient will replenish
    * @custom:shortd reward amount that user-recepient will replenish
    */
    uint256 public constant REPLENISH_AMOUNT = 1000000000000000; // 0.001 * 1e18

    uint8 internal constant OPERATION_SHIFT_BITS = 240;  // 256 - 16
    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_GRANT_ROLES = 0x1;
    uint8 internal constant OPERATION_REVOKE_ROLES = 0x2;
    uint8 internal constant OPERATION_CREATE_ROLE = 0x3;
    uint8 internal constant OPERATION_MANAGE_ROLE = 0x4;
    uint8 internal constant OPERATION_SET_TRUSTED_FORWARDER = 0x5;
    uint8 internal constant OPERATION_INVITE_PREPARE = 0x6;
    uint8 internal constant OPERATION_INVITE_ACCEPT = 0x7;
    uint8 internal constant OPERATION_SET_ROLE_URI = 0x8;
    uint8 internal constant OPERATION_SET_EXTRA_URI = 0x9;
    uint8 internal constant OPERATION_TRANSFEROWNERSHIP = 0xa;
    uint8 internal constant OPERATION_RENOUNCEOWNERSHIP = 0xb;
    
    
    enum ReimburseStatus{ NONE, PENDING, CLAIMED }

    // enum used in method when need to mark what need to do when error happens
    enum FlagFork{ NONE, EMIT, REVERT }
   
    ////////////////////////////////
    ///////// mapping //////////////
    ////////////////////////////////

    //receiver => sender
    mapping(address => address) public invitedBy;
    //sender => receivers
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal invited;
    
    mapping (bytes32 => uint8) internal _roles;
    mapping (address => PackedSet.Set) internal _rolesByAddress;
    mapping (uint8 => Role) internal _rolesByIndex;
    mapping (bytes => inviteSignature) inviteSignatures;          
    
    /**
    * @notice map users granted by
    * @custom:shortd map users granted by
    */
    mapping(address => ActionInfo[]) public grantedBy;
    /**
    * @notice map users revoked by
    * @custom:shortd map users revoked by
    */
    mapping(address => ActionInfo[]) public revokedBy;
    /**
    * @notice history of users granted
    * @custom:shortd history of users granted
    */
    mapping(address => ActionInfo[]) public granted;
    /**
    * @notice history of users revoked
    * @custom:shortd history of users revoked
    */
    mapping(address => ActionInfo[]) public revoked;

    ////////////////////////////////
    ///////// events ///////////////
    ////////////////////////////////
    event RoleCreated(bytes32 indexed role, address indexed sender);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleManaged(
        uint8 indexed sourceRole, 
        uint8 indexed targetRole, 
        bool canGrantRole, 
        bool canRevokeRole, 
        uint8 requireRole, 
        uint256 maxAddresses, 
        uint64 duration,
        address indexed sender
    );
    event RoleAddedErrorMessage(address indexed sender, string msg);
    event RenounceOwnership();
    ///////////////////////////////////////////////////////////
    /// modifiers  section
    ///////////////////////////////////////////////////////////

    /**
     * @param sSig signature of admin whom generate invite and signed it
     */
    modifier accummulateGasCost(bytes memory sSig)
    {
        uint remainingGasStart = gasleft();

        _;

        uint remainingGasEnd = gasleft();
        // uint usedGas = remainingGasStart - remainingGasEnd;
        // // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
        // // usedGas += 21000 + 9700;
        // usedGas += 30700;
        // // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
        // uint gasCost = usedGas * tx.gasprice;
        // // accummulate refund gas cost
        // inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + gasCost;
        inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + (remainingGasStart - remainingGasEnd + 30700) * tx.gasprice;
        //----
    }

    /**
     * @param sSig signature of admin whom generate invite and signed it
     */
    modifier refundGasCost(bytes memory sSig)
    {
        uint remainingGasStart = gasleft();

        _;
        
        uint gasCost;
        
        if (inviteSignatures[sSig].reimbursed == ReimburseStatus.NONE) {
            uint remainingGasEnd = gasleft();
            // uint usedGas = remainingGasStart - remainingGasEnd;
            // // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
            // usedGas += 21000 + 9700 + 47500;
            // // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
            // gasCost = usedGas * tx.gasprice;

            // inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + gasCost;
            inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + ((remainingGasStart - remainingGasEnd + 78200) * tx.gasprice);
        }
        // Refund gas cost
        gasCost = inviteSignatures[sSig].gasCost;

        if (
            (gasCost <= address(this).balance) && 
            (
            inviteSignatures[sSig].reimbursed == ReimburseStatus.NONE ||
            inviteSignatures[sSig].reimbursed == ReimburseStatus.PENDING
            )
        ) {
            inviteSignatures[sSig].reimbursed = ReimburseStatus.CLAIMED;
            //payable (inviteSignatures[sSig].caller).transfer(gasCost);
           
            payable(_msgSender()).transfer(gasCost);

        } else {
            inviteSignatures[sSig].reimbursed = ReimburseStatus.PENDING;
        }
        
        
    }

    ///////////////////////////////////////////////////
    // common to use
    //////////////////////////////////////////////////
    /**
     * @dev Returns the first address in getAddresses(OWNERS_ROLE). usually(if not transferownership/renounceownership) it's always will be deployer.
     * @return address first address on owners role list.
     */
    function owner() public view override returns (address) {
        return _rolesByIndex[_roles[DEFAULT_OWNERS_ROLE]].members.at(0);
    }

    /**
     * @dev Returns true if account is belong to DEFAULT_OWNERS_ROLE
     * @param account account address
     * @return bool 
     */
    function isOwner(address account) public view returns(bool) {
        //hasRole(address, OWNERS_ROLE)
        return _isTargetInRole(account, _roles[DEFAULT_OWNERS_ROLE]);
    }
    function _isTargetInRole(address target, uint8 targetRoleIndex) internal view returns(bool) {
        return _rolesByAddress[target].contains(targetRoleIndex);
    }
    /**
     * @dev Throws if the sender is not in the DEFAULT_OWNERS_ROLE.
     */
    function _checkOwner() internal view override {
        require(_isTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]), "Ownable: caller is not the owner");
    }

    function _msgSender() internal view override(ContextUpgradeable, TrustedForwarder) returns (address)  {
        return TrustedForwarder._msgSender();
    }


    ///////////////////////////////////////////////////
    // stub
    //////////////////////////////////////////////////
    function setTrustedForwarder(
        address forwarder
    ) 
        public 
        virtual
        override 
    {
        
    }

    function balanceOf(
        address account
    ) 
        external 
        view 
        virtual
        returns (uint256 balance) 
    {
    }

    function ownerOf(
        uint256 tokenId
    ) 
        external 
        view 
        virtual
        returns (address) 
    {
    }

    function tokenURI(
        uint256 tokenId
    ) 
        external 
        view 
        virtual
        returns (string memory)
    {
        
    }

    /**
    * @notice 
    * @custom:shortd 
    */
    function operationReverted(
    ) 
        internal 
        pure
    {
        revert("CommunityContract: NOT_AUTHORIZED");
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function transferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }
    
    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function approve(
        address /*to*/, 
        uint256 /*tokenId*/
    )
        external 
        pure
        override
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function getApproved(
        uint256/* tokenId*/
    ) 
        external
        pure 
        override 
        returns (address/* operator*/) 
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function setApprovalForAll(
        address /*operator*/, 
        bool /*_approved*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function isApprovedForAll(
        address /*owner*/, 
        address /*operator*/
    ) 
        external 
        pure 
        override
        returns (bool) 
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId;
    }
}