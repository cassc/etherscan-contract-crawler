// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./YeyeVault.sol";

contract Yeyeverse is ERC1155, AccessControl, Pausable {
    /* =============================================================
    * CONSTANTS
    ============================================================= */

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /* =============================================================
    * STATES
    ============================================================= */

    // Name of the collection
    string public name = "Yeye Genesis/ Base Collection";

    // Base Blueprint
    struct TokenBlueprint {
        bool exist; // check if trait exist
        bool redeemable; // check if token redeemable
        bool equipable; // check if NFT is equipable
    }
    mapping(uint256 => TokenBlueprint) public tokenCheck;

    // Equipped Token Blueprint
    struct YeyeBlueprint {
        bool exist;
        uint256 base;
        uint256[] traits;
    }
    mapping(uint256 => YeyeBlueprint) public equippedToken;

    // Vault address
    address public vaultAddress;


    /* =============================================================
    * MODIFIER
    ============================================================= */

    // check if token id already registered/exist
    modifier notExist(uint256[] calldata ids) {
        for (uint i = 0; i < ids.length; i++) 
        {
            require(
                !tokenCheck[ids[i]].exist,
                string(abi.encodePacked("YEYE: token ID: ", Strings.toString(ids[i]), " already exists"))
            );
        }
        _;
    }

    /* =============================================================
    * CONSTRUCTOR
    ============================================================= */

    constructor(string memory _uri, address _vaultAddress) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(FACTORY_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        vaultAddress = _vaultAddress;
    }

    /* =============================================================
    * SETTERS
    ============================================================= */

    /*
    * @dev add standalone (special) NFT before minting, special NFT cannot be equipped with traits and be redeemed
    */
    function registerStandalone(uint256[] calldata newIds) external notExist(newIds) onlyRole(FACTORY_ROLE) {
        TokenBlueprint memory newCheck = TokenBlueprint(true, false, false);
        for (uint i = 0; i < newIds.length; i++) 
        {
            tokenCheck[newIds[i]] = newCheck;
        }
    }

    /*
    * @dev add Base NFT before minting, base NFT can be equipped with traits
    */
    function registerBase(uint256[] calldata newIds) external notExist(newIds) onlyRole(FACTORY_ROLE) {
        TokenBlueprint memory newCheck = TokenBlueprint(true, false, true);
        for (uint i = 0; i < newIds.length; i++) 
        {
            tokenCheck[newIds[i]] = newCheck;
        }
    }

    /*
    * @dev add Redeemable NFT (Tickets, Lootbox) before minting
    */
    function registerRedeemable(uint256[] calldata newIds) external notExist(newIds) onlyRole(FACTORY_ROLE) {
        TokenBlueprint memory newCheck = TokenBlueprint(true, true, false);
        for (uint i = 0; i < newIds.length; i++) 
        {
            tokenCheck[newIds[i]] = newCheck;
        }
    }

    /*
    * @dev add Equipped NFT before minting
    */
    function registerEquipped(uint256 newId, YeyeBlueprint memory blueprint) external onlyRole(FACTORY_ROLE) {
        require(
            !tokenCheck[newId].exist,
            string(abi.encodePacked("YEYE: token ID: ", Strings.toString(newId), " already exists"))
        );

        TokenBlueprint memory newCheck = TokenBlueprint(true, false, false);
        equippedToken[newId] = blueprint;
        tokenCheck[newId] = newCheck;
    }

    /*
    * @dev unregister token IDs
    */
    function unregisterToken(uint256[] calldata ids) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < ids.length; i++) 
        {
            tokenCheck[ids[i]].exist = false;
            equippedToken[ids[i]].exist = false;
        }
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /*
    * @dev set vault address
    */
    function setVaultAddress(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        vaultAddress = _newAddress;
    }

    /*
    * @dev set Uri of Metadata
    */
    function setUri(string memory _newUri) public onlyRole(URI_SETTER_ROLE) {
        ERC1155._setURI(_newUri);
    }

    /* =============================================================
    * GETTERS
    ============================================================= */

    /*
    * @dev get Uri of corresponding ID, this will produce link to uri/{ID}
    */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(ERC1155.uri(_tokenId), Strings.toString(_tokenId)));
    }

    function getBlueprint(uint256 _id) external view returns (YeyeBlueprint memory) {
        return equippedToken[_id];
    }

    /* =============================================================
    * MAIN FUNCTION
    ============================================================= */

    /*
    * @dev mint already added NFT
    */
    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    /*
    * @dev batch version of mint
    */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /*
    * @dev function for factory to burn stored token
    */
    function factoryBurn(address account, uint256 id, uint256 value) public onlyRole(FACTORY_ROLE) {
        require(account == tx.origin, "You do not own this NFT");
        _burn(account, id, value);
    }

    /*
    * @dev batch version of factoryBurn
    */
    function factoryBurnBatch(address account, uint256[] memory ids, uint256[] memory values) public onlyRole(FACTORY_ROLE) {
        require(account == tx.origin, "You do not own this NFT");
        _burnBatch(account, ids, values);
    }

    /*
    * @dev transfer base & traits saved in vault to destination address
    */
    function transferStored(address _from, address _to, uint256[] memory ids) private {
        for (uint i = 0; i < ids.length; i++) {
            YeyeBlueprint memory nftData = equippedToken[ids[i]];
            if (!nftData.exist) continue;
            YeyeVault vaultContract = YeyeVault(vaultAddress);
            vaultContract.transferBase(_from, _to, nftData.base);
            vaultContract.transferTraits(_from, _to, nftData.traits);
        }
    }

    /* =============================================================
    * HOOKS
    ============================================================= */

    /*
    * @dev before token transfer hook
    */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from == address(0)) {
            /*
            * @dev check if token with corresponding id is exist before mint
            */
            for (uint256 i; i < ids.length; i++) {
                require(
                    tokenCheck[ids[i]].exist,
                    string(abi.encodePacked("YEYE BASE: token ID: ", Strings.toString(ids[i]), " doesn't exists"))
                );
            }
        }
        if (from != address(0)) {
            transferStored(from, to, ids);
        }
    }

    /*
    * @dev override required by ERC1155
    */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}