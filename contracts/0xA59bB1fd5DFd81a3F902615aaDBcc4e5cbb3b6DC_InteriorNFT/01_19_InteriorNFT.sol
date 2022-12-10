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
import "contracts/base/INFTBase.sol";

contract InteriorNFT is Initializable, UUPSUpgradeable, ContextUpgradeable {

    using SafeMathUpgradeable for uint256;

    IRoleManager public _roleManager;
    INFTBase public _nftBase;

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private _currentId;

    struct NFTInfo {
        uint256 isleId;
        string[] possibleUsages;
    }

    mapping(uint256 => NFTInfo) private _nfts;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IRoleManager roleManager, INFTBase nftBase, uint256 currentId) initializer public {
        __UUPSUpgradeable_init();

        _roleManager = IRoleManager(roleManager);
        _nftBase = INFTBase(nftBase);
        _currentId = currentId;
        
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(ADMIN_ROLE)
        override
    {}


    modifier onlyRole(bytes32 role) {
        require(_roleManager.hasRole(role, _msgSender()),"NFT/has_no_role");
        _;
    }

    /**
    * @dev setRoleManagerContract : roleManger 변경
    */
    function setRoleManagerContract(IRoleManager newRoleManagerContractAddress) public onlyRole(ADMIN_ROLE) {
        _roleManager = IRoleManager(newRoleManagerContractAddress);        
    }

    /**
     * @dev setCurrentId : 현재 id 번호 변경
     *
     */
    function setCurrentId(uint256 id) public onlyRole(ADMIN_ROLE) {
        _currentId = id;
    }


    /**
     * @dev mint : NFT 발행
     *
     * Event : TransferSingle
     */
    function mint(uint256 isleId, string[] memory possibleUsages, uint256 amount, address maker) public onlyRole(MINTER_ROLE) returns(uint256) {
        require(amount > 0,"NFT/amount_is_0");
        require(isleId > 0,"NFT/isleId_is_0");

        _nfts[++_currentId].isleId = isleId;
        _nfts[_currentId].possibleUsages = possibleUsages;
        
        _nftBase.mint(maker, _currentId, 1);

        return _currentId;
    }

    /**
     * @dev mintBatch : NFT 다중 발행
     *
     * Event : TransferBatch
     */
    function mintBatch(uint256 isleId, string[][] memory possibleUsageses, uint256[] memory amounts, address maker) public onlyRole(MINTER_ROLE)returns(uint256[] memory) {
        for(uint256 i=0; i<amounts.length; i++){
            require(amounts[i] > 0,"NFT/amount_is_0");
        }
        require(isleId > 0,"NFT/isleId_is_0");

        uint256[] memory ids = new uint256[](amounts.length);
        for(uint256 i=0; i<amounts.length; i++){
            ids[i] = ++_currentId;
            _nfts[_currentId].isleId = isleId;
            _nfts[_currentId].possibleUsages = possibleUsageses[i];
        }
        
        _nftBase.mintBatch(maker, ids, amounts);

        return ids;
    }
    
    /**
     * @dev getNFT : NFT 정보
     *
     */
    function getNFT(uint256 id) public view returns(NFTInfo memory) {
        return _nfts[id];
    }

}