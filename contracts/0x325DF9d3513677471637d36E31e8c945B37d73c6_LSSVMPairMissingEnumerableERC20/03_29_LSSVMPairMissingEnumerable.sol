// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LSSVMPair} from "./LSSVMPair.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";
import {LSSVMPairFactory} from "./LSSVMPairFactory.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";
import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";

/**
    @title An NFT/Token pair for an NFT that does not implement ERC721Enumerable
    @author boredGenius and 0xmons
 */
abstract contract LSSVMPairMissingEnumerable is LSSVMPair {
    using SafeTransferLib for ERC20;

    using EnumerableSet for EnumerableSet.UintSet;

    // Used for internal ID tracking
    EnumerableSet.UintSet private idSet;
    bool public isSudoMirror;
    address public sudoPoolAddress;

    /// @inheritdoc LSSVMPair
    function _sendAnyNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256 numNFTs
    ) internal override {
        // Send NFTs to recipient
        // We're missing enumerable, so we also update the pair's own ID set
        // NOTE: We start from last index to first index to save on gas
        require(_nft == nft());
        uint256 lastIndex = idSet.length() - 1;
        for (uint256 i; i < numNFTs; ) {
            uint256 nftId = idSet.at(lastIndex);
            uint256[] memory nftIds;
            nftIds[0] = nftId;
            if (isSudoMirror) {
                // TODO: move this out of the loop
                LSSVMPairMissingEnumerable(sudoPoolAddress).withdrawERC721(_nft, nftIds);
                _nft.safeTransferFrom(address(this), nftRecipient, nftId);
            } else {
                require(nft().ownerOf(nftIds[i]) == owner(), "NFT not owned by pool owner");
                ILSSVMPairFactoryLike(address(factory())).requestNFTTransferFrom(_nft, owner(), nftRecipient, nftId);
            }
            
            idSet.remove(nftId);
            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function _sendSpecificNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256[] calldata nftIds
    ) internal override {
        // Send NFTs to caller
        // If missing enumerable, update pool's own ID set
        require(_nft == nft());
        if (isSudoMirror) LSSVMPairMissingEnumerable(sudoPoolAddress).withdrawERC721(_nft, nftIds);
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            require(idSet.contains(nftIds[i]), "NFT not permitted!");
            if (isSudoMirror) {
                _nft.safeTransferFrom(
                    address(this),
                    nftRecipient,
                    nftIds[i]
                );
            } else {
                require(nft().ownerOf(nftIds[i]) == owner(), "NFT not owned by pool owner");
                ILSSVMPairFactoryLike(address(factory())).requestNFTTransferFrom(_nft, owner(), nftRecipient, nftIds[i]);
            }
            
            // Remove from id set
            idSet.remove(nftIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function changeDelta(uint128 newDelta) external override onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(
            _bondingCurve.validateDelta(newDelta),
            "Invalid delta for curve"
        );
        if (delta != newDelta) {
            delta = newDelta;
            emit DeltaUpdate(newDelta);
        }
        if (isSudoMirror) LSSVMPairMissingEnumerable(sudoPoolAddress).changeDelta(newDelta);
    }

    function changeSpotPrice(uint128 newSpotPrice) external override onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(
            _bondingCurve.validateSpotPrice(newSpotPrice),
            "Invalid new spot price for curve"
        );
        if (spotPrice != newSpotPrice) {
            spotPrice = newSpotPrice;
            emit SpotPriceUpdate(newSpotPrice);
        }
        if (isSudoMirror) return LSSVMPairMissingEnumerable(sudoPoolAddress).changeSpotPrice(newSpotPrice);
    }

    /// @inheritdoc LSSVMPair
    function getAllHeldIds() external view override returns (uint256[] memory) {
        if (isSudoMirror) return LSSVMPairMissingEnumerable(sudoPoolAddress).getAllHeldIds();
        uint256 numNFTs = idSet.length();
        uint256[] memory ids = new uint256[](numNFTs);
        uint256 y = 0;
        for (uint256 i; i < numNFTs; ) {
            if (
                nft().isApprovedForAll(
                    owner(),
                    address(factory())
                ) && nft().ownerOf(idSet.at(i)) == owner()
            ) {
                ids[y] = idSet.at(i);
                unchecked {
                    ++y;
                }
            }
            unchecked {
                ++i;
            }
        }
        uint256[] memory idsCopy = new uint256[](y);
        for (uint256 i; i < y; ) {
            idsCopy[i] = ids[i];
            unchecked {
                ++i;
            }
        }
        return idsCopy;
    }

    function addNFTToPool(uint256[] calldata ids) external nonReentrant {
        for (uint256 i; i < ids.length; i++) {
            // if(nft().isApprovedForAll(nftOwner, address(this)) && nftOwner == msg.sender) {
            idSet.add(ids[i]);
            if (isSudoMirror) {
              ILSSVMPairFactoryLike(address(factory())).requestNFTTransferFrom(nft(), owner(), address(this), ids[i]);
            }
            
            // emit event
        }
        if (isSudoMirror) {
            ILSSVMPairFactoryLike(ILSSVMPairFactoryLike(address(factory())).sisterFactory()).depositNFTs(nft(), ids, sudoPoolAddress);
        }
    }

    function removeNFTFromPool(uint256[] calldata ids) external onlyOwner {
        if (isSudoMirror) LSSVMPairMissingEnumerable(sudoPoolAddress).withdrawERC721(nft(), ids);
        for (uint256 i; i < ids.length; i++) {
            // address nftOwner = nft().ownerOf(ids[i]);
            // if (nftOwner == msg.sender) {
            idSet.remove(ids[i]);
            if (isSudoMirror) {
              nft().safeTransferFrom(address(this), owner(), ids[i]);
            }
            // }
            // emit event
            emit NFTWithdrawal();
        }
    }

    function createSudoPool(
      address factoryAddress,
        address payable _assetRecipient) external payable returns (address){
          require(msg.sender == address(factory()));
          require(sudoPoolAddress == address(0), "Sudo Pool Already Initialized");
          uint256[] memory arr;
          isSudoMirror = true;
          sudoPoolAddress = address(ILSSVMPairFactoryLike(factoryAddress).createPairETH{value: msg.value}(address(nft()), address(bondingCurve()), _assetRecipient, uint8(poolType()), delta, fee, spotPrice, arr));
          nft().setApprovalForAll(ILSSVMPairFactoryLike(address(factory())).sisterFactory(), true);
        return sudoPoolAddress;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // function removeStaleNFTs() public {
    //     uint256 numNFTs = idSet.length();
    //     for (uint256 i; i < numNFTs; ) {
    //         if (
    //             !nft().isApprovedForAll(
    //                 permissionedIds[idSet.at(i)],
    //                 address(this)
    //             ) || nft().ownerOf(idSet.at(i)) != permissionedIds[idSet.at(i)]
    //         ) {
    //             idSet.remove(idSet.at(i));
    //             permissionedIds[idSet.at(i)] = address(0);
    //         }
    //     }
    //     // emit event
        
    // }

    /// @inheritdoc LSSVMPair
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds)
        external
        override
        onlyOwner
    {
        IERC721 _nft = nft();
        require(a != _nft);
        uint256 numNFTs = nftIds.length;
        
        // If it's not the pair's NFT, just withdraw normally
        if (a != _nft) {
            for (uint256 i; i < numNFTs; ) {
                a.safeTransferFrom(address(this), msg.sender, nftIds[i]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    function withdrawERC721Sudo(IERC721 a, uint256[] calldata nftIds)
        external
        onlyOwner
    {
        IERC721 _nft = nft();
        require(a != _nft);
        uint256 numNFTs = nftIds.length;
        
        // If it's not the pair's NFT, just withdraw normally
        if (a != _nft) {
            if (isSudoMirror) LSSVMPairMissingEnumerable(sudoPoolAddress).withdrawERC721(a, nftIds);
            for (uint256 i; i < numNFTs; ) {
                a.safeTransferFrom(address(this), msg.sender, nftIds[i]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    function token_() public pure returns (ERC20 _token) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _token := shr(
                0x60,
                calldataload(add(sub(calldatasize(), paramsLength), 61))
            )
        }
    }

    /// @inheritdoc LSSVMPair
    function withdrawERC20(ERC20 a, uint256 amount)
        external
        override
        onlyOwner
    {
        a.safeTransfer(msg.sender, amount);

        if (a == token_()) {
            // emit event since it is the pair token
            emit TokenWithdrawal(amount);
        }
    }

    function withdrawERC20Sudo(ERC20 a, uint256 amount)
        external
        onlyOwner
    {
        if (isSudoMirror) LSSVMPairMissingEnumerable(sudoPoolAddress).withdrawERC20(a, amount);
        a.safeTransfer(msg.sender, amount);

        if (a == token_()) {
            // emit event since it is the pair token
            emit TokenWithdrawal(amount);
        }
    }

    function withdrawERC1155(
        IERC1155 a,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external override onlyOwner {
      a.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }

    function withdrawERC1155Sudo(
        IERC1155 a,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
      if (isSudoMirror) LSSVMPairMissingEnumerable(sudoPoolAddress).withdrawERC1155(a, ids, amounts);
        a.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }
}