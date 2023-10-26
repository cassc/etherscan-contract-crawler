// SPDX-License-Identifier: MIT
/***
 *              _____                _____                    _____                    _____            _____                    _____          
 *             /\    \              /\    \                  /\    \                  /\    \          /\    \                  /\    \         
 *            /::\    \            /::\    \                /::\    \                /::\____\        /::\    \                /::\    \        
 *           /::::\    \           \:::\    \              /::::\    \              /:::/    /       /::::\    \               \:::\    \       
 *          /::::::\    \           \:::\    \            /::::::\    \            /:::/    /       /::::::\    \               \:::\    \      
 *         /:::/\:::\    \           \:::\    \          /:::/\:::\    \          /:::/    /       /:::/\:::\    \               \:::\    \     
 *        /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \        /:::/    /       /:::/__\:::\    \               \:::\    \    
 *        \:::\   \:::\    \          /::::\    \      /::::\   \:::\    \      /:::/    /        \:::\   \:::\    \              /::::\    \   
 *      ___\:::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \    /:::/    /       ___\:::\   \:::\    \    ____    /::::::\    \  
 *     /\   \:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \  /:::/    /       /\   \:::\   \:::\    \  /\   \  /:::/\:::\    \ 
 *    /::\   \:::\   \:::\____\    /:::/  \:::\____\/:::/__\:::\   \:::\____\/:::/____/       /::\   \:::\   \:::\____\/::\   \/:::/  \:::\____\
 *    \:::\   \:::\   \::/    /   /:::/    \::/    /\:::\   \:::\   \::/    /\:::\    \       \:::\   \:::\   \::/    /\:::\  /:::/    \::/    /
 *     \:::\   \:::\   \/____/   /:::/    / \/____/  \:::\   \:::\   \/____/  \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/    / \/____/ 
 *      \:::\   \:::\    \      /:::/    /            \:::\   \:::\    \       \:::\    \       \:::\   \:::\    \       \::::::/    /          
 *       \:::\   \:::\____\    /:::/    /              \:::\   \:::\____\       \:::\    \       \:::\   \:::\____\       \::::/____/           
 *        \:::\  /:::/    /    \::/    /                \:::\   \::/    /        \:::\    \       \:::\  /:::/    /        \:::\    \           
 *         \:::\/:::/    /      \/____/                  \:::\   \/____/          \:::\    \       \:::\/:::/    /          \:::\    \          
 *          \::::::/    /                                 \:::\    \               \:::\    \       \::::::/    /            \:::\    \         
 *           \::::/    /                                   \:::\____\               \:::\____\       \::::/    /              \:::\____\        
 *            \::/    /                                     \::/    /                \::/    /        \::/    /                \::/    /        
 *             \/____/                                       \/____/                  \/____/          \/____/                  \/____/         
 *                                                                                                                                              
 */

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


import "contracts/role/IRoleManager.sol";

contract NFTBase is ERC1155SupplyUpgradeable, ERC2981Upgradeable, UUPSUpgradeable {

    using SafeMathUpgradeable for uint256;

    IRoleManager public roleManager;

    string public tokenUriPrefix;
    string public name;
    string public symbol;
    
    // id => creator
    mapping (uint256 => address) public creators;

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IRoleManager _roleManager, string memory _name, string memory _symbol, string memory _uri) initializer public {
        __ERC1155_init(_uri);
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        name = _name;
        symbol = _symbol;
        tokenUriPrefix = "";
        
        roleManager = IRoleManager(_roleManager);        
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(ADMIN_ROLE)
        override
    {}

    modifier onlyRole(bytes32 role) {
        require(roleManager.hasRole(role, _msgSender()),"NFTBase/has_no_role");
        _;
    }

    /**
    * @dev Returns an URI for a given token ID
    */
    // function tokenURI(uint256 id) public view returns (string memory) {
    //     return uri(id);
    // }
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(tokenUriPrefix, StringsUpgradeable.toString(tokenId), "/metadata.json"));
    }

    /**
    * @dev Set Default Royalty
    */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
    * @dev Set Token Royalty
    */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyRole(ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
    

    /**
    * @dev Set URI
    */
    function setURI(string memory newuri) public onlyRole(ADMIN_ROLE) {
        _setURI(newuri);
    }

    /**
    * @dev Set URI
    */
    function setTokenUriPrefix(string memory _tokenUriPrefix) public onlyRole(ADMIN_ROLE) {
        tokenUriPrefix = _tokenUriPrefix;
    }


    /**
    * @dev Set role manager contract
    */
    function setRoleManagerContract(IRoleManager newRoleManagerContractAddress) public onlyRole(ADMIN_ROLE) {
        roleManager = IRoleManager(newRoleManagerContractAddress);        
    }
    
    /**
    * @dev Get total supply (ERC1155SupplyUpgradeable)
    */
    function getTotalSupply(uint256 tokenId) external view returns (uint256) {
        return totalSupply(tokenId);
    }


    /**
     * @dev mint : NFT single mint - only admin
     *
     * Event : TransferSingle
     */
    function mint(uint256 tokenId, uint256 amount) public onlyRole(ADMIN_ROLE) returns(uint256) {        
        creators[tokenId] = msg.sender;
        _mint(_msgSender(), tokenId, amount, "");
        return tokenId;
    }

    /**
     * @dev mint : NFT single mint
     *
     * Event : TransferSingle
     */
    function mint(address maker, uint256 tokenId, uint256 amount) public onlyRole(MINTER_ROLE) returns(uint256) {
        creators[tokenId] = maker;
        _mint(maker, tokenId, amount, "");
        return tokenId;
    }

    
    /**
     * @dev mintBatch : NFT batch mint
     *
     * Event : TransferBatch
     */
    function mintBatch(address maker, uint256[] memory tokenIds, uint256[] memory amounts) public onlyRole(MINTER_ROLE) returns(uint256[] memory) {        
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            creators[tokenIds[i]] = maker;
        }
        _mintBatch(maker, tokenIds, amounts, "");
        return tokenIds;
    }

    /**
     * @dev burn : NFT burn
     *
     * Event : TransferSingle
     */
    function burn(uint256 tokenId, uint256 amount) public returns(uint256) {
        require(amount > 0,"NFTBase/supply_is_0");
        _burn(_msgSender(), tokenId, amount);

        return tokenId;
    }
    



}