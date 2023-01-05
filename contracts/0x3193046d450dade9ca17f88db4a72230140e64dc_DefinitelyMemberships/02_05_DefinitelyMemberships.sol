//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
                                                      ...:--==***#@%%-
                                             ..:  -*@@@@@@@@@@@@@#*:  
                               -:::-=+*#%@@@@@@*[email protected]@@@@@@@@@@#+=:     
           .::---:.         +#@@@@@@@@@@@@@%*+-. [email protected]@@@@@+..           
    .-+*%@@@@@@@@@@@#-     [email protected]@@@@@@@@@%#*=:.    :@@@@@@@#%@@@@@%:     
 =#@@@@@@@@@@@@@@@@@@@%.   %@@@@@@-..           *@@@@@@@@@@@@%*.      
[email protected]@@@@@@@@#*+=--=#@@@@@%  [email protected]@@@@@%*#%@@@%*=-.. [email protected]@@@@@@%%*+=:         
 :*@@@@@@*       [email protected]@@@@@.*@@@@@@@@@@@@*+-      =%@@@@%                
  [email protected]@@@@@.       *@@@@@%:@@@@@@*==-:.          [email protected]@@@@:                
 [email protected]@@@@@=      [email protected]@@@@@%.*@@@@@=   ..::--=+*=+*[email protected]@@@=                 
 #@@@@@*    [email protected]@@@@@@* [email protected]@@@@#%%@@@@@@@@#+:.  =#@@=                  
 @@@@@%   :*@@@@@@@*:  .#@@@@@@@@@@@@@%#:       ---                   
:@@@@%. -%@@@@@@@+.     [email protected]@@@@%#*+=:.                                 
[email protected]@@%=*@@@@@@@*:        =*:                                           
:*#+%@@@@%*=.                                                         
 :+##*=:.

*/

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth} from "./lib/Auth.sol";
import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";
import {IDefinitelyMetadata} from "./interfaces/IDefinitelyMetadata.sol";

/**
 * @title
 * Definitely Memberships
 *
 * @author
 * DEF DAO
 *
 * @notice
 * A membership token for DEF DAO in the form of a ERC721 NFT.
 *
 * Features:
 *   - Non-transferrable tokens. This can be bypassed by a membership transfer contract to
 *     allow for social recovery if necessary.
 *   - Approved contracts for issuing memberships. This allows different issuing
 *     mechanisms e.g. invites, props, funding etc. at the same time.
 *   - Approved contracts for revoking memberships.
 *   - Approved contracts for transferring memberships.
 *   - A separate upgradable metadata contract.
 *   - Per token metadata overriding.
 *
 */
contract DefinitelyMemberships is IDefinitelyMemberships, ERC721, Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /* ERC-721 ------------------------------------------------------------- */

    /// @dev Tracks ERC-721 token ids
    uint256 private _nextMembershipId = 1;

    /* ISSUING MEMBERSHIPS ------------------------------------------------- */

    /// @dev Contracts that are allowed to issue memberships
    mapping(address => bool) private _allowedMembershipIssuingContracts;

    /// @dev Maps a token id to the block number it was issued at for "insight" score
    mapping(uint256 => uint256) private _memberSinceBlock;

    /* REVOKING MEMBERSHIPS ------------------------------------------------ */

    /// @dev Contracts that are allowed to revoke memberships
    mapping(address => bool) private _allowedMembershipRevokingContracts;

    /// @dev Prevents an address from becoming an owner of this token
    mapping(address => bool) private _denyList;

    /* TRANSFERRING MEMBERSHIPS -------------------------------------------- */

    /// @dev Contracts that are allowed to transfer memberships between accounts
    mapping(address => bool) private _allowedMembershipTransferContracts;

    bool public globalTransferLocked;

    /* METADATA ------------------------------------------------------------ */

    /// @dev A fallback metadata address for all tokens that don't specify an override
    address private _defaultMetadata;

    /// @dev Allows a specific token ID to use it's own metadata address
    mapping(uint256 => address) private _tokenMetadataOverrideAddress;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /* INIT ---------------------------------------------------------------- */

    event DefinitelyShipping();

    /* ISSUING MEMBERSHIPS ------------------------------------------------- */

    event MembershipIssuingContractAdded(address indexed contractAddress);
    event MembershipIssuingContractRemoved(address indexed contractAddress);
    event MembershipIssued(uint256 indexed id, address indexed newOwner);

    /* REVOKING MEMBERSHIPS ------------------------------------------------ */

    event MembershipRevokingContractAdded(address indexed contractAddress);
    event MembershipRevokingContractRemoved(address indexed contractAddress);
    event MembershipRevoked(uint256 indexed id, address indexed prevOwner);
    event AddedToDenyList(address indexed account);
    event RemovedFromDenyList(address indexed account);

    /* TRANSFERRING MEMBERSHIPS -------------------------------------------- */

    event MembershipTransferContractAdded(address indexed contractAddress);
    event MembershipTransferContractRemoved(address indexed contractAddress);
    event TransferLockSet(bool indexed isTransferLocked);

    /* METADATA ------------------------------------------------------------ */

    event DefaultMetadataUpdated(address indexed metadata);
    event MetadataOverridden(uint256 indexed id, address indexed metadata);
    event MetadataResetToDefault(uint256 indexed id);

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    error NotAuthorizedToIssueMembership();
    error NotAuthorizedToRevokeMembership();
    error NotAuthorizedToTransferMembership();

    error NotDefMember();
    error AlreadyDefMember();
    error NotOwnerOfToken();
    error OnDenyList();

    error CannotTransferToZeroAddress();

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /// @dev Reverts if not a member
    modifier onlyDefMember() {
        if (_balanceOf[msg.sender] < 1) revert NotDefMember();
        _;
    }

    /// @dev Reverts if `account` is already a member
    modifier whenNotDefMember(address account) {
        if (_balanceOf[account] > 0) revert AlreadyDefMember();
        _;
    }

    /// @dev Reverts if `account` is on the deny list
    modifier whenNotOnDenyList(address account) {
        if (_denyList[account]) revert OnDenyList();
        _;
    }

    /// @dev Reverts if not an allowed minting contract
    modifier onlyMembershipIssuingContract() {
        if (!_allowedMembershipIssuingContracts[msg.sender]) {
            revert NotAuthorizedToIssueMembership();
        }
        _;
    }

    /// @dev Reverts if not the allowed membership revoking
    modifier onlyMembershipRevokingContract() {
        if (!_allowedMembershipRevokingContracts[msg.sender]) {
            revert NotAuthorizedToRevokeMembership();
        }
        _;
    }

    /// @dev Reverts if not the allowed membership transfer contract
    modifier onlyMembershipTransferContract() {
        if (!_allowedMembershipTransferContracts[msg.sender]) {
            revert NotAuthorizedToTransferMembership();
        }
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ Contract owner address
     */
    constructor(address owner_) ERC721("DEF", "Definitely Memberships") Auth(owner_) {
        emit DefinitelyShipping();

        globalTransferLocked = true;
        emit TransferLockSet(true);
    }

    /* ------------------------------------------------------------------------
       I S S U I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Allows another contract to issue a membership token to someone
     *
     * @dev
     * Reverts if:
     *   - the caller is not an approved issuing contract
     *   - `to` is already a member
     *   - `to` is on the deny list
     *
     * @param to Address to issue a membership NFT to
     */
    function issueMembership(address to)
        external
        override
        onlyMembershipIssuingContract
        whenNotDefMember(to)
        whenNotOnDenyList(to)
    {
        _mint(to, _nextMembershipId);
        _memberSinceBlock[_nextMembershipId] = block.number;
        emit MembershipIssued(_nextMembershipId, to);
        unchecked {
            ++_nextMembershipId;
        }
    }

    /* ------------------------------------------------------------------------
       R E V O K I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Revokes a membership by burning a token
     *
     * @dev
     * This allows some level of governance for when a membership should be revoked.
     * Optionally adds the address to the deny list so they cannot be issued a new
     * membership in the future.
     *
     * Reverts if:
     *   - the caller is not an approved revoking contract
     *
     * @param id The token id of the membership to revoke
     * @param addToDenyList Whether to add the current owner to the deny list
     */
    function revokeMembership(uint256 id, bool addToDenyList)
        external
        onlyMembershipRevokingContract
    {
        address prevOwner = _ownerOf[id];
        if (addToDenyList) _setDenyListStatus(prevOwner, true);
        _burn(id);
        emit MembershipRevoked(id, prevOwner);
    }

    /**
     * @notice
     * Adds an address to the deny list
     *
     * @dev
     * This allows some level of governance for when an address should be added
     * to the deny list.
     *
     * Reverts if:
     *   - the caller is not an approved revoking contract
     *
     * @param account The account to add to the deny list
     */
    function addAddressToDenyList(address account) public onlyMembershipRevokingContract {
        _setDenyListStatus(account, true);
    }

    /**
     * @notice
     * Removes an address from the deny list
     *
     * @dev
     * This allows some level of governance for when an address should be removed
     * from the deny list.
     *
     * Reverts if:
     *   - the caller is not an approved revoking contract
     *
     * @param account The account to remove from the deny list
     */
    function removeAddressFromDenyList(address account) external onlyMembershipRevokingContract {
        _setDenyListStatus(account, false);
    }

    /**
     * @dev
     * Internal function to manage deny list status and emit relevant events
     *
     * @param account The account to set the deny list status for
     * @param isDenied Whether the account should be on the deny list or not
     */
    function _setDenyListStatus(address account, bool isDenied) internal {
        _denyList[account] = isDenied;

        if (isDenied) emit AddedToDenyList(account);
        if (!isDenied) emit RemovedFromDenyList(account);
    }

    /* ------------------------------------------------------------------------
       T R A N S F E R R I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Allows an account to bypass the transfer lock mechanic and transfer a membership
     *
     * @dev
     * This allows for some level of governance around when to actually allow a
     * membership transfer to happen.
     *
     * Reverts if:
     *   - the caller is not an approved transfer contract
     *
     * @param id The token id of the membership being transferred
     * @param to The new owner of the membership token
     */
    function transferMembership(uint256 id, address to) external onlyMembershipTransferContract {
        if (to == address(0)) revert CannotTransferToZeroAddress();
        address from = _ownerOf[id];

        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
    }

    /* ------------------------------------------------------------------------
       T R A N S F E R   L O C K
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Overridden `transferFrom` to prevent membership transfer if transfers are locked
     *
     * @dev
     * If a transfer is required while `globalTransferLocked` is true, use an approved
     * membership transfer contract instead
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (globalTransferLocked) revert NotAuthorizedToTransferMembership();
        super.transferFrom(from, to, id);
    }

    /* ------------------------------------------------------------------------
       M E T A D A T A
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Allows a token holder to set a new metadata address for tokenURI customization
     *
     * @param id The token to override metadata for
     * @param metadata The new metadata contract address for this token
     */
    function overrideMetadataForToken(uint256 id, address metadata) external {
        if (_ownerOf[id] != msg.sender) revert NotOwnerOfToken();
        _tokenMetadataOverrideAddress[id] = address(metadata);
        emit MetadataOverridden(id, metadata);
    }

    /**
     * @notice
     * Allows a token holder to use the default metadata address for their token
     *
     * @param id The token that should use the default metadata contract
     */
    function resetMetadataForToken(uint256 id) external {
        delete _tokenMetadataOverrideAddress[id];
        emit MetadataResetToDefault(id);
    }

    /* ------------------------------------------------------------------------
       E R C - 7 2 1
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Burn your membership token
     *
     * @param id The token you want to burn
     */
    function burn(uint256 id) external {
        if (_ownerOf[id] != msg.sender) revert NotOwnerOfToken();
        _burn(id);
    }

    /**
     * @notice
     * ERC-721 tokenURI returns the metadata for a given token
     *
     * @dev
     * Returns the metadata override if present, or fall back to the default metadata address
     *
     * @param id The token id to get metadata for
     */
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        address metadataOverride = _tokenMetadataOverrideAddress[id];
        return
            IDefinitelyMetadata(
                metadataOverride != address(0) ? metadataOverride : _defaultMetadata
            ).tokenURI(id);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Adds a new membership issuing contract
     *
     * @dev
     * The new contract will be able to mint membership tokens to people who aren't already
     * members, and who aren't on the deny list. There are no other restrictions so the issuing
     * contract must implement additional checks if necessary
     *
     * @param addr A membership issuing contract address
     */
    function addMembershipIssuingContract(address addr) external onlyOwnerOrAdmin {
        _allowedMembershipIssuingContracts[addr] = true;
        emit MembershipIssuingContractAdded(addr);
    }

    /**
     * @notice
     * Removes an existing membership issuing contract
     *
     * @dev
     * This will prevent the contract from calling `issueMembership`
     *
     * @param addr A membership issuing contract address
     */
    function removeMembershipIssuingContract(address addr) external onlyOwnerOrAdmin {
        _allowedMembershipIssuingContracts[addr] = false;
        emit MembershipIssuingContractRemoved(addr);
    }

    /**
     * @notice
     * Adds a new membership revoking contract
     *
     * @dev
     * The new contract will be able to burn tokens effectively revoking membership
     *
     * @param addr A membership revoking contract address
     */
    function addMembershipRevokingContract(address addr) external onlyOwnerOrAdmin {
        _allowedMembershipRevokingContracts[addr] = true;
        emit MembershipRevokingContractAdded(addr);
    }

    /**
     * @notice
     * Removes an existing membership revoking contract
     *
     * @dev
     * This will prevent the contract from calling `revokeMembership`
     *
     * @param addr A membership revoking contract address
     */
    function removeMembershipRevokingContract(address addr) external onlyOwnerOrAdmin {
        _allowedMembershipRevokingContracts[addr] = false;
        emit MembershipRevokingContractRemoved(addr);
    }

    /**
     * @notice
     * Adds a new membership transfer contract
     *
     * @dev
     * The new contract will be able to bypass the transfer lock mechanic and transfer tokens
     *
     * @param addr A membership transfer contract address
     */
    function addMembershipTransferContract(address addr) external onlyOwnerOrAdmin {
        _allowedMembershipTransferContracts[addr] = true;
        emit MembershipTransferContractAdded(addr);
    }

    /**
     * @notice
     * Removes an existing membership transfer contract
     *
     * @dev
     * This will prevent the contract from calling `transferMembership`
     *
     * @param addr A membership transfer contract address
     */
    function removeMembershipTransferContract(address addr) external onlyOwnerOrAdmin {
        _allowedMembershipTransferContracts[addr] = false;
        emit MembershipTransferContractRemoved(addr);
    }

    /**
     * @notice
     * Updates the fallback metadata used for all tokens that haven't set an override
     *
     * @param addr A metadata contract address
     */
    function setDefaultMetadata(address addr) external onlyOwnerOrAdmin {
        _defaultMetadata = address(addr);
        emit DefaultMetadataUpdated(addr);
    }

    /**
     * @notice
     * Updates the global transfer lock flag to lock/unlock standard ERC721 transfers
     *
     * @param locked If global direct ERC721 transfers should be prevented
     */
    function setGlobalTransferLock(bool locked) external onlyOwnerOrAdmin {
        globalTransferLocked = locked;
        emit TransferLockSet(locked);
    }

    /* ------------------------------------------------------------------------
       P U B L I C   G E T T E R S
    ------------------------------------------------------------------------ */

    /**
     * @notice Checks if an account is part of DEF with a simple balance check
     */
    function isDefMember(address account) external view returns (bool) {
        return _balanceOf[account] > 0;
    }

    /**
     * @notice
     * Checks if an account is on the DEF deny list
     *
     * @dev
     * If the account is on the deny list then they will not be allowed to become a member
     * until they are removed from the deny list by a revoking contract.
     */
    function isOnDenyList(address account) external view returns (bool) {
        return _denyList[account];
    }

    /**
     * @notice Returns the block number for when the token was issued
     */
    function memberSinceBlock(uint256 id) external view returns (uint256) {
        return _memberSinceBlock[id];
    }

    /**
     * @notice Gets the metadata address for a given token
     */
    function metadataAddressForToken(uint256 id) external view returns (address) {
        address metadataOverride = _tokenMetadataOverrideAddress[id];
        return metadataOverride != address(0) ? metadataOverride : _defaultMetadata;
    }

    /**
     * @notice Gets the fallback metadata contract address
     */
    function defaultMetadataAddress() external view returns (address) {
        return _defaultMetadata;
    }

    /**
     * @notice Checks if an address is allowed to issue memberships
     */
    function allowedMembershipIssuingContract(address addr) external view returns (bool) {
        return _allowedMembershipIssuingContracts[addr];
    }

    /**
     * @notice Checks if an address is allowed to revoke memberships
     */
    function allowedMembershipRevokingContract(address addr) external view returns (bool) {
        return _allowedMembershipRevokingContracts[addr];
    }

    /**
     * @notice Checks if an address is allowed to transfer memberships
     */
    function allowedMembershipTransferContract(address addr) external view returns (bool) {
        return _allowedMembershipTransferContracts[addr];
    }
}