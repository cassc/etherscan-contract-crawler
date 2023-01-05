// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {ERC1155} from "solmate/src/tokens/ERC1155.sol";

abstract contract HandleLSSVM {

    struct LSSVMSellNftStruct {
        address collection;
        uint256[] tokenIds;
        uint256 tokenStandards;
    }

    function handleLSSVMSell(
        address protocol,
        bytes memory data,
        address nftOwner,
        LSSVMSellNftStruct[] memory sellNfts
    ) internal returns (bool success, bytes memory output){

        // transfer NFT to this address
        for (uint256 j = 0; j < sellNfts.length; ) {
            LSSVMSellNftStruct memory sellNft = sellNfts[j];
            uint256[] memory tokenIds = sellNft.tokenIds;
            address token = sellNft.collection;
            uint256 tokenStandards = sellNft.tokenStandards;
            if (tokenStandards == 721) {
                for (uint256 i = 0; i < tokenIds.length; i++) {
                    uint256 tokenId = tokenIds[i];
                    ERC721(token).safeTransferFrom(
                        nftOwner,
                        address(this),
                        tokenId
                    );
                }
                ERC721(token).setApprovalForAll(protocol, true);
            } else {
                revert("TokenStandard Error");
            }

            unchecked{
                ++j;
            }
        }

        // call LSSVM router
        (success, output) = protocol.call(data);


        // if trade fail, transfer NFT back to user
        for (uint256 k = 0; k < sellNfts.length; ) {
            LSSVMSellNftStruct memory sellNft = sellNfts[k];
            uint256[] memory tokenIds = sellNft.tokenIds;
            address token = sellNft.collection;
            uint256 tokenStandards = sellNft.tokenStandards;
            if (tokenStandards == 721) {
                for (uint256 i = 0; i < tokenIds.length; i++) {
                    uint256 tokenId = tokenIds[i];
                    if (ERC721(token).ownerOf(tokenId) == address(this)) {
                        ERC721(token).safeTransferFrom(
                            address(this),
                            nftOwner,
                            tokenId
                        );
                    }
                }
            } else {
                revert("TokenStandard Error");
            }

            unchecked{
                ++k;
            }
        }


    }
}