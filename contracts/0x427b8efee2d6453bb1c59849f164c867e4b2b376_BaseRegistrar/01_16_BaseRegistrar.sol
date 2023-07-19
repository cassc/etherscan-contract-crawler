/////////
// bebOS Labs
// https://beb.domains
// SPDX-License-Identifier: UNLICENSED
/////////

pragma solidity >=0.8.4;

import "./IBaseRegistrar.sol";
import "./IBEBRegistry.sol";
import "./IRoyaltyController.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseRegistrar is ERC721, IBaseRegistrar, Ownable  {
    // A map of expiry times
    mapping(uint256=>uint) expiries;

    // The BEB registry
    IBEBRegistry public bebRegistry;
    // The Royalty Controller
    IRoyaltyController public royaltyController;
    // The namehash of the TLD this registrar owns (eg, .beb)
    bytes32 public baseNode;
    
    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;

    // the grace period where the owner can renew but not reclaim the name
    uint256 public constant GRACE_PERIOD = 90 days;

    // The base metadata uri for the registrar
    string public baseURI;

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // // control the royalty information
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    //     internal virtual override
    // {
    //     (address royaltyAddress, uint256 royaltyAmount) = this.royaltyInfo(tokenId, msg.value);
    //     if (from == address(0)) {
    //         // if the from address is 0, then this is a transfer from the contract itself
    //         // so we don't need to do anything
    //         return;
    //     }
    //     payable(royaltyAddress).transfer(royaltyAmount); // transfer the royalty to the royalty receiver
    //     payable(to).transfer(msg.value - royaltyAmount); // transfer the rest to the receiver
    //     super._beforeTokenTransfer(from, to, tokenId); // Call parent hook;
    // }

    constructor(IBEBRegistry _bebRegistry, bytes32 _baseNode) ERC721("BEB","BEB") {
        bebRegistry = _bebRegistry;
        baseNode = _baseNode;
    }

    /** 
    * @dev make sure the owner of base TLD (i.e .beb) is of this registrar in the BEB registry
    */
    modifier live() {
        require(bebRegistry.owner(baseNode) == address(this));
        _;
    }


    modifier onlyController {
        require(controllers[msg.sender]);
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override(IERC721, ERC721) returns (address) {
        require(expiries[tokenId] > block.timestamp);
        return super.ownerOf(tokenId);
    }

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view override returns(uint) {
        return expiries[id];
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view override returns(bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }
    
    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external override returns (uint256) {
        return _register(id, owner, duration, true);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256) {
        return _register(id, owner, duration, false);
    }

    function renew(uint256 id, uint duration) external override onlyController returns(uint) {
        require(expiries[id] + GRACE_PERIOD >= block.timestamp); // Name must be registered here or in grace period
        require(expiries[id] + duration + GRACE_PERIOD > duration + GRACE_PERIOD); // Prevent future overflow

        expiries[id] += duration;
        emit NameRenewed(id, expiries[id]);
        return expiries[id];
    }

    /**
    * Internal functions
     */

    function _register(uint256 id, address owner, uint duration, bool updateRegistry) internal live onlyController returns(uint) {
        require(available(id));
        require(block.timestamp + duration + GRACE_PERIOD > block.timestamp + GRACE_PERIOD); // Prevent future overflow

        expiries[id] = block.timestamp + duration;
        if(_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
        if (updateRegistry) {
            bebRegistry.setSubnodeOwner(baseNode, bytes32(id), owner);
        }

        emit NameRegistered(id, owner, block.timestamp + duration);

        return block.timestamp + duration;
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external live {
        require(_isApprovedOrOwner(msg.sender, id));
        bebRegistry.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    /**
     * @dev Modify the baseURI.
     * @param uri The new baseURI.
     */
    function setBaseURI(string calldata uri) external {
      return _setBaseURI(uri);
    }

    function _setBaseURI(string calldata uri) internal onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns(string memory) {
        return baseURI;
    }

    /**
     * @dev Modify the royaltyController.
     * @param _royaltyController The new royaltyController.
     */
    function setRoyaltyController(IRoyaltyController _royaltyController) external {
      return _setRoyaltyController(_royaltyController);
    }
        
    function _setRoyaltyController(IRoyaltyController _royaltyController) internal onlyOwner {
        royaltyController = _royaltyController;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return royaltyController.royaltyInfo(tokenId, salePrice);
    }
}