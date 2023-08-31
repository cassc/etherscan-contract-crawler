// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenXNFT                     *
 ****************************************/

import "./GDXERC721Enumerable.sol";
import "./IERC721Batch.sol";

abstract contract GDXERC721Batch is GDXERC721Enumerable, IERC721Batch {
    function isOwnerOf(address account, uint256[] calldata tokenIds)
        external
        view
        override
        returns (bool)
    {
        for (uint256 i; i < tokenIds.length; ++i) {
            if (_owners[tokenIds[i]] != account) return false;
        }

        return true;
    }

    function transferBatch(
        address from,
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external override {
        for (uint256 i; i < tokenIds.length; ++i) {
            safeTransferFrom(from, to, tokenIds[i], data);
        }
    }

    function walletOfOwner(address account)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256 quantity = balanceOf(account);

        uint256 count;
        uint256[] memory wallet = new uint256[](quantity);
        for (uint256 i; i < _owners.length; ++i) {
            if (account == _owners[i]) {
                wallet[count++] = i;
                if (count == quantity) break;
            }
        }
        return wallet;
    }
}