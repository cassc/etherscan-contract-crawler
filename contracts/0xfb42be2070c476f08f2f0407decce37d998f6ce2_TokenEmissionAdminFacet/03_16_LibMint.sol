// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {AppStorage} from "./LibAppStorage.sol";
import {IMint} from "../interfaces/IMint.sol";
import {IERC721Receiver} from "../interfaces/IERC721Receiver.sol";

library LibMint {
    struct MintStorage {
        uint256 price;
        uint256 supply;
        uint256 maxMintsPerTx;
        uint256 maxMintsPerAddress;
        bytes32 privateSaleMerkleRoot;
        bytes32 claimingMerkleRoot;
        bool claimingActive;
        bool publicSaleActive;
        bool privateSaleActive;
        mapping(address => bool) minted;
    }

    bytes32 private constant MINT_STORAGE_POSITION = keccak256("lol.momentum.mint");

    /// @notice Emitted when `tokenId` token is transferred from `from` to `to`.
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    /// @param _from transfer address
    /// @param _to receiver address
    /// @param _tokenId the NFT transfered
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    function setPrice(uint256 price) internal {
        mintStorage().price = price;
    }

    function activateClaiming() internal {
        MintStorage storage ms = mintStorage();
        ms.claimingActive = true;
    }

    function deactivateClaiming() internal {
        MintStorage storage ms = mintStorage();
        ms.claimingActive = false;
    }

    function startPublicSale() internal {
        MintStorage storage ms = mintStorage();
        ms.publicSaleActive = true;
    }

    function stopPublicSale() internal {
        MintStorage storage ms = mintStorage();
        ms.publicSaleActive = false;
    }

    function startPrivateSale() internal {
        MintStorage storage ms = mintStorage();
        ms.privateSaleActive = true;
    }

    function stopPrivateSale() internal {
        MintStorage storage ms = mintStorage();
        ms.privateSaleActive = false;
    }

    function setClaimed(address user_) internal {
        mintStorage().minted[user_] = true;
    }

    function init(
        uint256 price,
        uint256 supply,
        uint256 maxMintsPerTx,
        uint256 maxMintsPerAddress,
        bytes32 privateSaleMerkleRoot,
        bytes32 claimingMerkleRoot
    ) internal {
        MintStorage storage ms = mintStorage();
        ms.price = price;
        ms.supply = supply;
        ms.maxMintsPerTx = maxMintsPerTx;
        ms.maxMintsPerAddress = maxMintsPerAddress;
        ms.privateSaleMerkleRoot = privateSaleMerkleRoot;
        ms.claimingMerkleRoot = claimingMerkleRoot;
    }

    function setMinted(address user_) internal {
        mintStorage().minted[user_] = true;
    }

    /// @notice Same as calling {safeMint} without data
    function safeMint(address _to,
        AppStorage storage s) internal {
        safeMint(_to, "", s);
    }

    /// @notice Same as calling {_mint} and then checking for IERC721Receiver
    function safeMint(
        address _to,
        bytes memory _data,
        AppStorage storage s
    ) internal {
        mint(_to, s);
        unchecked {
            if (_to.code.length != 0) {
                    if (
                        !_checkERC721Received(address(0), _to, s.nftStorage.nextTokenId - 1, _data)
                    ) {
                        revert IMint.TransferToNonERC721ReceiverImplementer();
                    }
            }
        }
    }

    /// @notice Mint a quantity of NFTs to an address
    /// @dev Saves the first token id minted by the address to a map of
    ///      used to verify ownership initially.
    ///      {s.nftStorage.tokenOwnersOrdered} will be used to find the owner unless the token
    ///      has been transfered. In that case, it will be available in {s.nftStorage.tokenOwners} instead.
    ///      This is done to reduce gas requirements of minting while keeping on-chain lookups
    ///      cheaper as tokens are transfered around. It helps with the burning of tokens.
    /// @param _to Receiver address
    function mint(address _to, AppStorage storage s) internal {
        if (_to == address(0)) revert IMint.InvalidTransferToZeroAddress();
        unchecked {
            s.nftStorage.balances[_to]++;
            s.nftStorage.tokenOwners[s.nftStorage.nextTokenId] = _to;
            emit Transfer(address(0), _to, s.nftStorage.nextTokenId);
            s.nftStorage.nextTokenId++;
        }
    }

    /// @notice Checking if the receiving contract implements IERC721Receiver
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /// @param _data Extra data
    function _checkERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool)
    {
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert IMint.TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function minted(address user_) internal view returns (bool) {
        return mintStorage().minted[user_];
    }

    function isClaimingActive() internal view returns (bool) {
        return mintStorage().claimingActive;
    }

    function isPrivateSaleActive() internal view returns (bool) {
        return mintStorage().privateSaleActive;
    }

    function isPublicSaleActive() internal view returns (bool) {
        return mintStorage().publicSaleActive;
    }

    function getPrice() internal view returns (uint256) {
        return mintStorage().price;
    }

    function claimed(address user_) internal view returns (bool) {
        return mintStorage().minted[user_];
    }

    function mintStorage() internal pure returns (MintStorage storage ms) {
        bytes32 position = MINT_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }
}