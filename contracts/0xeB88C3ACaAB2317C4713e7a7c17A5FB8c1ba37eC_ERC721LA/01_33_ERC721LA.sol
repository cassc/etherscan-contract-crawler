// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../extensions/Burnable.sol";
import "../extensions/WithOperatorRegistry.sol";
import "../extensions/AirDropable.sol";
import "./IERC721LA.sol";
import "../extensions/Pausable.sol";
import "../extensions/Whitelistable.sol";
// import "../extensions/PermissionedTransfers.sol";
import "../extensions/LAInitializable.sol";
import "../libraries/LANFTUtils.sol";
import "../libraries/BPS.sol";
import "../libraries/CustomErrors.sol";
import "../platform/royalties/RoyaltiesState.sol";
import "./ERC721State.sol";
import "./ERC721LACore.sol";

/**
 * @notice LiveArt ERC721 implementation contract
 * Supports multiple edtioned NFTs and gas optimized batch minting
 */
contract ERC721LA is ERC721LACore, Burnable, AirDropable, Whitelistable {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            Royalties
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function setRoyaltyRegistryAddress(
        address _royaltyRegistry
    ) public onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._royaltyRegistry = IRoyaltiesRegistry(_royaltyRegistry);
    }

    function royaltyRegistryAddress() public view returns (IRoyaltiesRegistry) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._royaltyRegistry;
    }

    /// @dev see: EIP-2981
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return
            state._royaltyRegistry.royaltyInfo(address(this), _tokenId, _value);
    }

    function registerCollectionRoyaltyReceivers(
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public onlyAdmin {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        IRoyaltiesRegistry(state._royaltyRegistry)
            .registerCollectionRoyaltyReceivers(
                address(this),
                msg.sender,
                royaltyReceivers
            );
    }

    function primaryRoyaltyInfo(
        uint256 tokenId
    ) public view returns (address payable[] memory, uint256[] memory) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).primaryRoyaltyInfo(
                address(this),
                tokenId
            );
    }
}