// SPDX-License-Identifier: MIT



pragma solidity ~0.8.17;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/wrapper/INameWrapper.sol";
import "@ensdomains/ens-contracts/contracts/wrapper/NameWrapper.sol";

import "https://github.com/ensdomains/ens-contracts/blob/lockable-resolver/contracts/resolvers/profiles/ContentHashResolver.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/** @title ClaimSubdomain
   * @author Samudai - 2023
   * @notice This contract aims to provide the functionality of creating a subdomain and setting the content hash and burning the appropriate amount of fuses all under one transaction. This is IERC1155ReceiverUpgradeable,Initializable,UUPSUpgradeable,OwnableUpgradeable
*/
contract ClaimSubdomain is 
    IERC1155ReceiverUpgradeable,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable{

    ENS public ens;
    INameWrapper public nameWrapper;


    /** @dev Used to disallow initializing the implementation contract by an attacker for extra safety.
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     @custom:oz-upgrades-unsafe-allow constructor
     */

    constructor() {
        _disableInitializers();
    }
    
    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     * @param _ens The interface of the ENS registry to be used.
     * @param _nameWrapper The interface of the NameWrapper registry to be used.
    */

    function initialize(ENS _ens,INameWrapper _nameWrapper) public initializer {
        ens = _ens;
        nameWrapper = _nameWrapper;
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    /**
     * @notice Checks if msg.sender is the owner or operator of the owner of a name
     * @param node namehash of the name to check
     */
    
    modifier onlyTokenOwner(bytes32 node) {
        if (!nameWrapper.canModifyName(node, msg.sender)) {
            revert Unauthorised(node, msg.sender);
        }
        _;
    }

    /**
     * @notice Gets the data for a name
     * @param parentNode Namehash of the name
     * @return owner Owner of the name
     * @return fuses Fuses of the name
     * @return maxExpiry Expiry of the name
     */

    function getData(bytes32 parentNode) view  public returns(address owner,uint32 fuses,uint64 maxExpiry){
        (owner,fuses,maxExpiry) = nameWrapper.getData(uint256(parentNode));
    }

    /**
     * @notice Transfers the ownership of subdomain
     * @param subNode namehash of the subdomain to check
     * @param subdomainOwner new owner in the wrapper
     */

    function transferSubdomainOwnership(bytes32 subNode,address subdomainOwner ) public onlyTokenOwner(subNode){
        nameWrapper.safeTransferFrom(msg.sender,subdomainOwner, uint256(subNode),1,bytes(""));
    }

    /**
     * @notice Let's you create a subdomain with the required name and sets the content hash for the subname.
     * @dev If you want to make the contract as the owner of the subname then use address(this)
     * @param parentNode parent namehash of the subdomain
     * @param label label of the subdomain as a string
     * @param resolver_add resolver contract in the registry 
     * @param fuses initial fuses for the wrapped subdomain
     * @param hash ipfs hash of the website that need to be set as the content hash
     */

    function createSubdomainWithContentHash(bytes32 parentNode,string memory label, bytes calldata hash,uint32 fuses,address resolver_add) public onlyTokenOwner(parentNode){
        (,,uint64 maxExpiry) = getData(parentNode);
        bytes32 subnode = nameWrapper.setSubnodeRecord(parentNode,label,address(this),resolver_add,0,0,maxExpiry); 
        ContentHashResolver resolver = ContentHashResolver(resolver_add);
        resolver.setContenthash(subnode,hash);
        resolver.lockContenthash(subnode);
        bytes32 labelhash = keccak256(abi.encodePacked(label));
        nameWrapper.setChildFuses(parentNode,labelhash,fuses, maxExpiry);
        nameWrapper.safeTransferFrom(address(this),msg.sender, uint256(subnode),1,bytes(""));
    }

    /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
   
  function transferContractOwnership(address newOwner) public  onlyOwner {
      transferOwnership(newOwner);
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */

    function onERC1155Received(address operator,address from,uint256 id,uint256 value,bytes calldata data) external returns (bytes4) {
    return ClaimSubdomain.onERC1155Received.selector;
  }
    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */

    function onERC1155BatchReceived(address operator,address from,uint256[] memory ids,uint256[] memory values,bytes calldata data) external returns (bytes4) {
        return ClaimSubdomain.onERC1155BatchReceived.selector;
    }

    function supportsInterface(
        bytes4 interfaceID
    ) external view override returns (bool) {
        return
            interfaceID == 0x01ffc9a7 || // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    // @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZeppelin's guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[48] private __gap;
}