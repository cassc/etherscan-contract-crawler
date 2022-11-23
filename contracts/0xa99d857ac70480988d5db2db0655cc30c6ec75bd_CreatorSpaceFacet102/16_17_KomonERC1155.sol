// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155Base, ERC1155BaseInternal} from "ERC1155Base.sol";
import {ERC1155Enumerable} from "ERC1155Enumerable.sol";
import {ERC1155EnumerableInternal} from "ERC1155EnumerableInternal.sol";
import {IKomonERC1155} from "IKomonERC1155.sol";
import {AddressUtils} from "AddressUtils.sol";
import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";

/**
 * @title Komon ERC1155 implementation
 */
abstract contract KomonERC1155 is
    IKomonERC1155,
    ERC1155Base,
    ERC1155Enumerable
{
    /**
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function distributeMintingCuts(uint256 tokenId, uint256 totalCost)
        internal
    {
        uint256 creatorCut = calculateCreatorCut(tokenId, totalCost);
        uint256 komonCut = totalCost - creatorCut;

        address komonExchangeAccount = KomonAccessControlBaseStorage
            .layout()
            ._komonExchangeAccount;
        address creatorAccount = creatorTokenOwner(tokenId);

        AddressUtils.sendValue(payable(komonExchangeAccount), komonCut);
        AddressUtils.sendValue(payable(creatorAccount), creatorCut);
        _safeMint(msg.sender, tokenId, 1, "");
    }
}
