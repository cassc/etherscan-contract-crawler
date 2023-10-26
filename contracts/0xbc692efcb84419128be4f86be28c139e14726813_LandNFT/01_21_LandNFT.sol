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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "contracts/role/IRoleManager.sol";
import "contracts/nfts/INFTBase.sol";

contract LandNFT is Initializable, UUPSUpgradeable, ContextUpgradeable {

    using SafeMathUpgradeable for uint256;

    IRoleManager public roleManager;
    INFTBase public nftBase;

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private currentId;

    struct NFTInfo {
        uint256 isleId;
        string usage;
        uint256 scale;
        string form;
    }

    mapping(uint256 => NFTInfo) private nfts;

    mapping(string => uint256) public usageWeights;
    mapping(uint256 => uint256) public scaleWeights;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IRoleManager _roleManager, INFTBase _nftBase, uint256 _currentId) initializer public {
        __UUPSUpgradeable_init();

        roleManager = IRoleManager(_roleManager);
        nftBase = INFTBase(_nftBase);
        currentId = _currentId;
        
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(ADMIN_ROLE)
        override
    {}


    modifier onlyRole(bytes32 role) {
        require(roleManager.hasRole(role, _msgSender()),"NFT/has_no_role");
        _;
    }

    /**
    * @dev Set role manager contract
    */
    function setRoleManagerContract(IRoleManager newRoleManagerContractAddress) public onlyRole(ADMIN_ROLE) {
        roleManager = IRoleManager(newRoleManagerContractAddress);        
    }
    
    /**
     * @dev Set NFT current id
     *
     */
    function setCurrentId(uint256 _currentId) public onlyRole(ADMIN_ROLE) {
        currentId = _currentId;
    }

    /**
     * @dev Set usage weight
     *
     */
    function setUsageWeight(string memory usage, uint256 weight) public onlyRole(ADMIN_ROLE) {
        usageWeights[usage] = weight;
    }

    /**
     * @dev Set scale weight
     *
     */
    function setScaleWeight(uint256 scale, uint256 weight) public onlyRole(ADMIN_ROLE) {
        scaleWeights[scale] = weight;
    }

    /**
     * @dev Get usage weight
     *
     */
    function getUsageWeight(string memory usage) public view returns(uint256) {
        return usageWeights[usage];
    }

    /**
     * @dev Get scale weight
     *
     */
    function getScaleWeight(uint256 scale) public view returns(uint256) {
        return scaleWeights[scale];
    }

    /**
     * @dev mint : NFT 발행
     *
     * Event : TransferSingle
     */
    function mint(uint256 isleId, string memory usage, uint256 scale, string memory form, uint256 amount, address maker) public onlyRole(MINTER_ROLE) returns(uint256) {
        require(amount > 0,"NFT/amount_is_0");
        require(isleId > 0,"NFT/isleId_is_0");

        nfts[++currentId].isleId = isleId;
        nfts[currentId].usage = usage;
        nfts[currentId].scale = scale;
        nfts[currentId].form = form;
        
        nftBase.mint(maker, currentId, amount);

        return currentId;
    }

    /**
     * @dev mintBatch : NFT 다중 발행
     *
     * Event : TransferBatch
     */
    function mintBatch(uint256 isleId, string[] memory usages, uint256[] memory scales, string[] memory forms, uint256[] memory amounts, address maker) public onlyRole(MINTER_ROLE) returns(uint256[] memory) {
        for(uint256 i=0; i<amounts.length; i++){
            require(amounts[i] > 0,"NFT/amount_is_0");
        }
        require(isleId > 0,"NFT/isleId_is_0");

        uint256[] memory ids = new uint256[](amounts.length);
        for(uint256 i=0; i<amounts.length; i++){
            ids[i] = ++currentId;
            nfts[currentId].isleId = isleId;
            nfts[currentId].usage = usages[i];
            nfts[currentId].scale = scales[i];
            nfts[currentId].form = forms[i];
        }
        
        nftBase.mintBatch(maker, ids, amounts);

        return ids;
    }

    /**
     * @dev getNFT : NFT 정보
     *
     */
    function getNFT(uint256 id) public view returns(NFTInfo memory) {
        return nfts[id];
    }

}