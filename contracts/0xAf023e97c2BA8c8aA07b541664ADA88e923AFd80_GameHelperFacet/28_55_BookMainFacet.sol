// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibString.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import "./LibStorage.sol";

import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {BookInternalFacet} from "./BookInternalFacet.sol";
import {BookRenderFacet} from "./BookRenderFacet.sol";
import {GameMainFacet} from "./GameMainFacet.sol";
import "@solidstate/contracts/utils/Multicall.sol";

import { ERC721D } from "./ERC721D/ERC721D.sol";

contract BookMainFacet is ERC721D, UsingDiamondOwner, WithStorage, Multicall, BookInternalFacet, OperatorFilterer {
    using LibString for *;
    using EnumerableSet for EnumerableSet.UintSet;
    
    function setGameContract(address _gameContract) external onlyOwner {
        bk().gameContract = _gameContract;
    }
    
    function setMintIsActive(bool newState) external onlyRole(ADMIN) {
        bk().isMintActive = newState;
    }
    
    function setMetadata(
        string calldata _name,
        string calldata symbol,
        string calldata _nameSingular,
        string calldata _externalLink,
        string calldata _tokenDescription
    ) external onlyRole(ADMIN) {
        _setName(_name);
        _setSymbol(symbol);
        bk().nameSingular = _nameSingular;
        bk().externalLink = _externalLink;
        bk().tokenDescription = _tokenDescription;
    }
    
    function punkHealth(uint punkId) public view returns (int) {
        uint32[] memory damageSlots = bk().punkIdToPunkDamageEvents[punkId];
        uint damageTaken;
    
        for (uint i; i < damageSlots.length; i++) {
            if (damageSlots[i] + 1 weeks > block.timestamp) {
                damageTaken++;
            }
        }
        
        return int(punkHealthCapacity(punkId) - damageTaken);
    }
    
    function mintPunkToUser(address to, uint punkId) internal {
        _mint(to, punkId);
        
        if (bk().userToPrimaryPunkId[to] == 0) {
            bk().userToPrimaryPunkId[to] = punkId;
        }
    }
    
    function upgradePunkToLevel(uint punkId, uint level) internal returns (bool) {
        _setTokenExtraData(punkId, uint96(level));
        delete bk().punkIdToPunkDamageEvents[punkId];
        
        emit UpgradePunk(punkId, _punkIdToPunkUpradeLevel(punkId));
        
        return true;
    }
    
    function _punkIdToPunkUpradeLevel(uint tokenId) internal view returns (uint) {
        return _getTokenExtraData(tokenId);
    }
    
    function punkIdToPunkUpradeLevel(uint tokenId) public view returns (uint) {
        return _punkIdToPunkUpradeLevel(tokenId);
    }
    
    function getPunkDamageEvents(uint punkId) external view returns (uint32[] memory) {
        return bk().punkIdToPunkDamageEvents[punkId];
    }
    
    function punkHealthCapacity(uint punkId) public view returns (uint) {
        return 3 + punkIdToPunkUpradeLevel(punkId);
    }
    
    function makePunkTakeDamageRevertIfAlreadyDead(uint punkId) external {
        require(msg.sender == bk().gameContract, "Only chest contract can call this");
        
        uint32[] storage damageSlots = bk().punkIdToPunkDamageEvents[punkId];
        uint healthCapacity = punkHealthCapacity(punkId);
        uint damageSlotCount = damageSlots.length;

        if (damageSlotCount < healthCapacity) {
            damageSlots.push(uint32(block.timestamp));
        } else {
            uint damageTaken;
            uint oldestEventIndex = damageSlots[0];
            
            unchecked {
                for (uint i; i < damageSlotCount; ++i) {
                    if (damageSlots[i] + 1 weeks > block.timestamp) {
                        damageTaken++;
                    }
                    
                    if (damageSlots[i] < damageSlots[oldestEventIndex]) {
                        oldestEventIndex = i;
                    }
                }
            }
            
            require(healthCapacity - damageTaken > 0, "Punk is already dead");
            
            damageSlots[oldestEventIndex] = uint32(block.timestamp);
        }
        
        emit MetadataUpdate(punkId);
        emit PunkTakeDamage(punkId);
    }
    
    function upgradePunkWithGameItem(uint punkId) external {
        require(_exists(punkId), "Punk does not exist");
        
        burnGameItemFromSender("book_upgrade");
        upgradePunkToLevel(punkId, punkIdToPunkUpradeLevel(punkId) + 1);
        
        emit MetadataUpdate(punkId);
    }
    
    function mintPunkWithRegularKey(uint80 assets) external {
        require (
            punkIsValid(assets) &&
            // ps().packedAssetsToOldPunksIdPlusOneMap[assets] == 0 &&
            _punkConformsToTheme(assets),
            "Not mintable"
        );
        
        burnGameItemFromSender("regular_key");
        mintPunkToUser(msg.sender, assets);
        
        emit MintPunkWithKey(msg.sender, assets, "regular_key", bk().currentThemeVersion);
    }
    
    function mintPunkWithSkeletonKey(uint80 assets) external {
        require (
            punkIsValid(assets),
            // ps().packedAssetsToOldPunksIdPlusOneMap[assets] == 0 &&
            "Not mintable"
        );
        
        burnGameItemFromSender("skeleton_key");
        mintPunkToUser(msg.sender, assets);
        
        emit MintPunkWithKey(msg.sender, assets, "skeleton_key", bk().currentThemeVersion);
    }
    
    function mintPunkWithDiamondSkeletonKey(uint80 assets) external {
        require (
            punkIsValid(assets),
            // ps().packedAssetsToOldPunksIdPlusOneMap[assets] == 0 &&
            "Not mintable"
        );
        
        burnGameItemFromSender("diamond_skeleton_key");
        mintPunkToUser(msg.sender, assets);
        upgradePunkToLevel(assets, 4);
        
        emit MintPunkWithKey(msg.sender, assets, "diamond_skeleton_key", bk().currentThemeVersion);
    }
    
    function burnGameItemFromSender(string memory gameItemSlug) internal {
        GameMainFacet(bk().gameContract).burnFromPunkContract(
            msg.sender,
            gameItemSlug,
            1
        );
    }

    function exists(uint punkId) external view returns (bool) {
        return _exists(punkId);
    }
    
    function ownerOfNoRevert(uint punkId) external view returns (address) {
        return _ownerOf(punkId);
    }
    
    function userToPrimaryPunkId(address user) external view returns (uint) {
        return bk().userToPrimaryPunkId[user];
    }
    
    function updatePrimaryPunkId(uint punkId) external {
        require(_ownerOf(punkId) == msg.sender, "User does not own punk");
        bk().userToPrimaryPunkId[msg.sender] = punkId;
    }
    
    function stringIsASCII(string memory str) internal pure returns (bool) {
        return bytes(str).length == str.runeCount();
    }
    
    function punkNameValid(string memory name) public view returns (bool) {
        if (name.runeCount() > bk().maxNameRuneCount) return false;
        
        return stringIsASCII(name);
        
        // try Normalize4(address(this)).normalize(name) returns (string[] memory _norm) {
        //     if (!(name.eq(_norm[0]) && _norm.length == 1)) return false;
        // } catch {
        //     return false;
        // }
        
        // return true;
    }
    
    function setPunkName(uint punkId, string memory newName) public {
        bytes32 newNameHash = keccak256(bytes(newName));
        bytes32 oldNameHash = keccak256(bytes(bk().punkIdToName[punkId]));
        
        require(_ownerOf(punkId) == msg.sender, "User does not own punk");
        require(punkNameValid(newName), "Name is not valid");
        require(bk().punkNameHashToPunkId[newNameHash] == 0, "Name is already taken");
        
        burnGameItemFromSender("book_name_tag");
        
        bk().punkIdToName[punkId] = newName;
        bk().punkNameHashToPunkId[newNameHash] = punkId;
        delete bk().punkNameHashToPunkId[oldNameHash];
        
        emit MetadataUpdate(punkId);
        emit SetPunkName(msg.sender, punkId, newName);
    }
    
    function getGameContract() external view returns (address) {
        return bk().gameContract;
    }

    function tokenURI(uint256 id) public view override(ERC721D) returns (string memory) {
        require(_exists(id), "Token does not exist");
        return BookRenderFacet(address(this)).constructTokenURI(id);
    }
    
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return bk().operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}