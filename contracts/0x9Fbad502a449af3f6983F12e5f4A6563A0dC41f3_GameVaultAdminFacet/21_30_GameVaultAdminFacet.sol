//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/LibSort.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeCastLib.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./LibStorage.sol";

import {ERC1155DInternal} from "./ERC1155D/ERC1155DInternal.sol";
import {IERC1155} from "@solidstate/contracts/interfaces/IERC1155.sol";

import {GameInternalFacet} from "./GameInternalFacet.sol";
import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

contract GameVaultAdminFacet is WithStorage, ERC1155DInternal, GameInternalFacet {
    error AlreadyInitialized();
    
    // So we can remove the init facet which we would otherwise have to redeploy for some reason
    function isInitialized() external pure returns (bool) {
        return true;
    }
    
    function setInitialized(bool) external pure {
        revert AlreadyInitialized();
    }
    
    function adminMoveNFTsBetweenVaults(
        string calldata fromVaultSlug,
        string calldata toVaultSlug,
        uint[] calldata indicesToMove
    ) external onlyRoleStr("nft_admin") {
        NFTVault storage fromVault = gs().nftVaults[fromVaultSlug];
        NFTVault storage toVault = gs().nftVaults[toVaultSlug];
        
        for (uint i; i < indicesToMove.length; ++i) {
            uint indexToMove = indicesToMove[i];
            
            StoredNFT memory storedNFT = fromVault.storedNFTs[indexToMove];
            
            toVault.storedNFTs.push(storedNFT);
            
            _removeNFTFromVaultAtIndex(fromVaultSlug, indexToMove);
        }
    }
    
    function adminWithdrawNftsFromVaultAtIndices(
        string calldata vaultSlug,
        address to,
        uint[] calldata indices
    ) external onlyRoleStr("nft_admin") {
        NFTVault storage vault = gs().nftVaults[vaultSlug];
        
        for (uint i; i < indices.length; ++i) {
            uint index = indices[i];
            
            StoredNFT memory storedNFT = vault.storedNFTs[index];
            
            IERC721(storedNFT.contractAddress).safeTransferFrom(address(this), to, storedNFT.tokenId);
            
            _removeNFTFromVaultAtIndex(vaultSlug, index);
        }
    }
    
    function _removeNFTFromVaultAtIndex(string memory vaultSlug, uint indexToRemove) internal {
        NFTVault storage vault = gs().nftVaults[vaultSlug];

        uint lastIndex = vault.storedNFTs.length - 1;
        
        if (lastIndex != indexToRemove) {
            StoredNFT memory lastValue = vault.storedNFTs[lastIndex];
            vault.storedNFTs[indexToRemove] = lastValue;
        }
        
        vault.storedNFTs.pop();
    }
}