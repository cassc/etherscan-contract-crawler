// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../../../../interfaces/markets/tokens/IERC20.sol";
import "../../../../../interfaces/markets/tokens/IERC1155.sol";
import "../../../../../interfaces/markets/tokens/IERC721.sol";

interface INFTXVault {
    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);

    function redeemTo(
        uint256 amount,
        uint256[] memory specificIds,
        address to
    ) external returns (uint256[] memory);

    function swapTo(
        uint256[] memory tokenIds,
        uint256[] memory amounts, /* ignored for ERC721 vaults */
        uint256[] memory specificIds,
        address to
    ) external returns (uint256[] memory);
}

interface ICryptoPunks {
    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;
}

contract NftxV2Market {
    struct NFTXBuy {
        address vault;
        uint256 amount;
        uint256[] specificIds;
    }

    function _approve(
        address _operator,
        address _token,
        uint256[] memory _tokenIds
    ) internal {
        // in case of kitties
        if (_token == 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IERC721(_token).approve(_operator, _tokenIds[i]);
            }
        }
        // in case of cryptopunks
        else if (_token == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                ICryptoPunks(_token).offerPunkForSaleToAddress(
                    _tokenIds[i],
                    0,
                    _operator
                );
            }
        }
        // default
        else if (!IERC721(_token).isApprovedForAll(address(this), _operator)) {
            IERC721(_token).setApprovalForAll(_operator, true);
        }
    }

    function sellERC721ForERC20Equivalent(
        address fromERC721,
        address vault,
        uint256[] memory tokenIds
    ) external {
        _approve(vault, fromERC721, tokenIds);
        INFTXVault(vault).mint(tokenIds, tokenIds);
    }

    function sellERC1155BatchForERC20Equivalent(
        address fromERC1155,
        address vault,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external {
        _approve(vault, fromERC1155, tokenIds);
        INFTXVault(vault).mint(tokenIds, amounts);
    }

    function buyAssetsForErc20(
        NFTXBuy[] memory nftxBuys,
        address recipient,
        bool revertIfTrxFails
    ) external {
        uint256 length = nftxBuys.length;
        bool success;

        for (uint256 i; i < length; ) {
            (success, ) = nftxBuys[i].vault.call(
                abi.encodeWithSelector(
                    INFTXVault.redeemTo.selector,
                    nftxBuys[i].amount,
                    nftxBuys[i].specificIds,
                    recipient
                )
            );

            if (!success && revertIfTrxFails) {
                // Copy revert reason from call
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            unchecked {
                i++;
            }
        }
    }

    function swapErc721(
        address fromERC721,
        address vault,
        uint256[] memory fromTokenIds,
        uint256[] memory toTokenIds,
        address recipient
    ) external {
        // approve token to NFTX vault
        _approve(vault, fromERC721, fromTokenIds);
        // swap tokens and send back to the recipient
        uint256[] memory amounts;
        INFTXVault(vault).swapTo(fromTokenIds, amounts, toTokenIds, recipient);
    }

    function swapErc1155(
        address fromERC1155,
        address vault,
        uint256[] memory fromTokenIds,
        uint256[] memory fromAmounts,
        uint256[] memory toTokenIds,
        address recipient
    ) external {
        // approve token to NFTX vault
        _approve(vault, fromERC1155, fromTokenIds);
        // swap tokens and send back to the recipient
        INFTXVault(vault).swapTo(
            fromTokenIds,
            fromAmounts,
            toTokenIds,
            recipient
        );
    }
}