// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IERC1155Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC721 {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev totalSupply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract NFTsBatchReader {
    constructor() {}

    function erc721BalancesOf(address nft, address[] calldata owners) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            balances[i] = IERC721(nft).balanceOf(owners[i]);
        }
        return balances;
    }

    function erc1155BalancesOf(
        address nft,
        uint256 tokenId,
        address[] calldata owners
    ) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            balances[i] = IERC1155(nft).balanceOf(owners[i], tokenId);
        }
        return balances;
    }

    function erc721OwnersOf(address nft, uint256[] calldata tokenIds) external view returns (address[] memory) {
        address[] memory owners = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            try IERC721(nft).ownerOf(tokenIds[i]) returns (address owner) {
                owners[i] = owner;
            } catch Error(
                string memory /*reason*/
            ) {
                owners[i] = address(0);
            }
        }
        return owners;
    }

    function tokenURIs(address nft, uint256[] calldata tokenIds) external view returns (string[] memory) {
        string[] memory res = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isERC721(nft)) {
                try IERC721(nft).tokenURI(tokenIds[i]) returns (string memory uri) {
                    res[i] = uri;
                } catch Error(
                    string memory /*reason*/
                ) {
                    res[i] = "";
                }
            } else if (isERC1155(nft)) {
                try IERC1155(nft).uri(tokenIds[i]) returns (string memory uri) {
                    res[i] = uri;
                } catch Error(
                    string memory /*reason*/
                ) {
                    res[i] = "";
                }
            }
        }
        return res;
    }

    function tokensURIs(address[] calldata nfts, uint256[] calldata tokenIds) external view returns (string[] memory) {
        string[] memory res = new string[](nfts.length);
        for (uint256 i = 0; i < nfts.length; i++) {
            if (isERC721(nfts[i])) {
                try IERC721(nfts[i]).tokenURI(tokenIds[i]) returns (string memory uri) {
                    res[i] = uri;
                } catch Error(
                    string memory /*reason*/
                ) {
                    res[i] = "";
                }
            } else if (isERC1155(nfts[i])) {
                try IERC1155(nfts[i]).uri(tokenIds[i]) returns (string memory uri) {
                    res[i] = uri;
                } catch Error(
                    string memory /*reason*/
                ) {
                    res[i] = "";
                }
            }
        }
        return res;
    }

    function isERC721(address nft) public view returns (bool) {
        return IERC165Upgradeable(nft).supportsInterface(0x80ac58cd);
    }

    function isERC1155(address nft) public view returns (bool) {
        return IERC165Upgradeable(nft).supportsInterface(type(IERC1155Upgradeable).interfaceId);
    }

    function erc721TotalSupplies(address[] calldata nfts) external view returns (uint256[] memory) {
        uint256[] memory supplies = new uint256[](nfts.length);
        for (uint256 i = 0; i < nfts.length; i++) {
            supplies[i] = IERC721(nfts[i]).totalSupply();
        }
        return supplies;
    }
}