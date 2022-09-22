// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract AniseedMarketplaceERC1155Upgradeable is 
    Initializable, 
    ContextUpgradeable, 
    AccessControlEnumerableUpgradeable, 
    OwnableUpgradeable, 
    ERC1155BurnableUpgradeable, 
    ERC1155PausableUpgradeable 
{
    function initialize(string memory uri, address rootAdmin) public virtual initializer {
        __AniseedMarketplaceERC1155Upgradeable_init(uri, rootAdmin);
    }
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    string private constant _name = "Aniseed";
    string private constant _symbol = "ANSD";

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    function __AniseedMarketplaceERC1155Upgradeable_init(string memory uri, address rootAdmin) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC1155_init_unchained(uri);
        __ERC1155Burnable_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC1155Pausable_init_unchained();
        __AniseedMarketplaceERC1155Upgradeable_init_unchained(uri, rootAdmin);
    }

    function __AniseedMarketplaceERC1155Upgradeable_init_unchained(string memory uri, address rootAdmin) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, rootAdmin);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    /**
    * @dev overriding the inherited {transferOwnership} function to reflect the admin changes into the {DEFAULT_ADMIN_ROLE}
    */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    /**
    * @dev overriding the inherited {grantRole} function to have a single root admin
    */
    function grantRole(bytes32 role, address account) public override {
        if(role == ADMIN_ROLE)
            require(getRoleMemberCount(ADMIN_ROLE) == 0, "exactly one address can have admin role");
            
        super.grantRole(role, account);
    }

    /**
    * @dev modifier to check admin rights.
    * contract owner and root admin have admin rights
    */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()) || owner() == _msgSender(), "Restricted to admin.");
        _;
    }
    
    /**
    * @dev modifier to check mint rights.
    * contract owner, root admin and minter's have mint rights
    */
    modifier onlyMinter() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) || 
            hasRole(MINTER_ROLE, _msgSender()) || 
            owner() == _msgSender(), "Restricted to minter."
            );
        _;
    }
    
    /**
    * @dev modifier to check pause rights.
    * contract owner, root admin and pauser's have pause rights
    */
    modifier onlyPauser() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) || 
            hasRole(PAUSER_ROLE, _msgSender()) || 
            owner() == _msgSender(), "Restricted to pauser."
            );
        _;
    }
    
    /**
    * @dev This function is to change the root admin 
    * exaclty one root admin is allowed per contract
    * only contract owner have the authority to add, remove or change
    */
    function changeRootAdmin(address newAdmin) public {
        address oldAdmin = getRoleMember(ADMIN_ROLE, 0);
        revokeRole(ADMIN_ROLE, oldAdmin);
        grantRole(ADMIN_ROLE, newAdmin);
    }
    
    /**
    * @dev This function is to add minters into the contract, 
    * only root admin and contract owner have the authority to add them
    * but only the root admin can revoke them using {revokeRole}
    * minter can also self renounce the access using {renounceRole}
    */
    function addMinter(address account) public onlyAdmin{
        _setupRole(MINTER_ROLE, account);
    }
    
  
    // As part of the lazy minting this mint function will be called by the admin and will transfer the NFT to the buyer
    function mint(address receiver,uint collectibleId,  uint ntokens, bytes memory IPFS_hash) public onlyMinter {
        _mint(receiver, collectibleId, ntokens, IPFS_hash);
    }

    // As part of the lazy minting, this batch mint function will be called by the admin and will transfer the NFT to the buyer
    function mintBatch(address receiver,uint[] memory collectibleIds,  uint[] memory ntokens, bytes memory IPFS_hash) public onlyMinter {
        _mintBatch(receiver, collectibleIds, ntokens, IPFS_hash);
    }

    /**
    * @dev This funtion is to give authority to root admin to transfer token to the
    * buyer on behalf of the token owner
    *
    * The token owner can approve and renounce the access via this function
    */
    function setApprovalForOwner(bool approval) public {
        address defaultAdmin = getRoleMember(ADMIN_ROLE, 0);
        setApprovalForAll(defaultAdmin, approval);
    }
    
    /**
    * @dev This funtion is to give authority to minter to transfer token to the
    * buyer on behalf of the token owner
    *
    * The token owner can approve and renounce the access via this function
    */
    function setApprovalForMinter(bool approval, address minterAccount) public {
        require(hasRole(MINTER_ROLE, minterAccount), "not a minter address");
        setApprovalForAll(minterAccount, approval);
    }

    /**
    * @dev This funtion is to check weather the contract admin have approval from a token owner
    *
    */
    function isApprovedForOwner(address account) public view returns (bool approval){
        address defaultAdmin = getRoleMember(ADMIN_ROLE, 0);
        return isApprovedForAll(account, defaultAdmin);
    }


    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual onlyPauser{

        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual onlyPauser{
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155PausableUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    uint256[50] private __gap;
}