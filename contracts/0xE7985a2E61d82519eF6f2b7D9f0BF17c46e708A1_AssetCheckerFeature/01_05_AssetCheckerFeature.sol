/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


contract AssetCheckerFeature {

    bytes4 public constant INTERFACE_ID_ERC20 = 0x36372b07;
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct CheckResultInfo {
        uint8 itemType; // 0: ERC721, 1: ERC1155, 2: ERC20, 255: other
        uint256 allowance;
        uint256 balance;
        address erc721Owner;
        address erc721ApprovedAccount;
    }

    function checkAssets(address account, address operator, address[] calldata tokens, uint256[] calldata tokenIds) external view returns (CheckResultInfo[] memory infos) {
        require(tokens.length == tokenIds.length, "require(tokens.length == tokenIds.length)");

        infos = new CheckResultInfo[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenId = tokenIds[i];
            if (supportsInterface(token, INTERFACE_ID_ERC721)) {
                infos[i].itemType = 0;
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].erc721Owner = ownerOf(token, tokenId);
                infos[i].erc721ApprovedAccount = getApproved(token, tokenId);
                infos[i].balance = (infos[i].erc721Owner == account) ? 1 : 0;
                continue;
            }

            if (supportsInterface(token, INTERFACE_ID_ERC1155)) {
                infos[i].itemType = 1;
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].balance = balanceOf(token, account, tokenId);
                continue;
            }

            if (supportsInterface(token, INTERFACE_ID_ERC20)) {
                infos[i].itemType = 2;
                if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
                    infos[i].balance = account.balance;
                    infos[i].allowance = type(uint256).max;
                } else {
                    infos[i].balance = balanceOf(token, account);
                    infos[i].allowance = allowanceOf(token, account, operator);
                }
            } else {
                infos[i].itemType = 255;
            }
        }
        return infos;
    }

    function supportsInterface(address nft, bytes4 interfaceId) internal view returns (bool) {
        try IERC165(nft).supportsInterface(interfaceId) returns (bool support) {
            return support;
        } catch {
        }
        return false;
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try IERC721(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function getApproved(address nft, uint256 tokenId) internal view returns (address operator) {
        try IERC721(nft).getApproved(tokenId) returns (address approvedAccount) {
            operator = approvedAccount;
        } catch {
        }
        return operator;
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (operator != address(0)) {
            try IERC721(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        try IERC20(erc20).allowance(owner, spender) returns (uint256 _allowance) {
            allowance = _allowance;
        } catch {
        }
        return allowance;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try IERC1155(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}