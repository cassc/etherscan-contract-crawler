/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IConduitController.sol";
import "./interfaces/ISeaport.sol";
import "./interfaces/ITransferSelectorNFT.sol";
import "./interfaces/ILooksRare.sol";
import "./interfaces/IX2y2.sol";
import "./IThirdExchangeCheckerFeature.sol";


contract ThirdExchangeCheckerFeature is IThirdExchangeCheckerFeature {

    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public immutable LOOKS_RARE;
    address public immutable X2Y2;
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    constructor(address looksRare, address x2y2) {
        LOOKS_RARE = looksRare;
        X2Y2 = x2y2;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        public
        override
        view
        returns (SeaportCheckInfo memory info)
    {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (itemType == 0) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        }

        try ISeaport(SEAPORT).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;
        } catch {}
        return info;
    }

    function getSeaportCheckInfo(address account, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        override
        view
        returns (SeaportCheckInfo memory info)
    {
        uint8 itemType = 255;
        if (supportsERC721(nft)) {
            itemType = 0;
        } else if (supportsERC721(nft)) {
            itemType = 1;
        }
        return getSeaportCheckInfoEx(account, itemType, nft, tokenId, conduitKey, orderHash);
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getLooksRareCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, uint256 accountNonce)
        public
        override
        view
        returns (LooksRareCheckInfo memory info)
    {
        try ILooksRare(LOOKS_RARE).transferSelectorNFT() returns (ITransferSelectorNFT transferSelector) {
            try transferSelector.checkTransferManagerForToken(nft) returns (address transferManager) {
                info.transferManager = transferManager;
            } catch {}
        } catch {}

        try ILooksRare(LOOKS_RARE).isUserOrderNonceExecutedOrCancelled(account, accountNonce) returns (bool isExecutedOrCancelled) {
            info.isExecutedOrCancelled = isExecutedOrCancelled;
        } catch {}

        if (itemType == 0) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.transferManager);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.transferManager);
        }
        return info;
    }

    function getLooksRareCheckInfo(address account, address nft, uint256 tokenId, uint256 accountNonce)
        external
        override
        view
        returns (LooksRareCheckInfo memory info)
    {
        uint8 itemType = 255;
        if (supportsERC721(nft)) {
            itemType = 0;
        } else if (supportsERC721(nft)) {
            itemType = 1;
        }
        return getLooksRareCheckInfoEx(account, itemType, nft, tokenId, accountNonce);
    }

    function getX2y2CheckInfo(address account, address nft, uint256 tokenId, bytes32 orderHash, address executionDelegate)
        external
        override
        view
        returns (X2y2CheckInfo memory info)
    {
        if (X2Y2 == address(0)) {
            return info;
        }

        try IX2y2(X2Y2).inventoryStatus(orderHash) returns (IX2y2.InvStatus status) {
            info.status = status;
        } catch {}

        info.erc721Owner = ownerOf(nft, tokenId);
        info.erc721ApprovedAccount = getApproved(nft, tokenId);
        info.isApprovedForAll = isApprovedForAll(nft, account, executionDelegate);
        return info;
    }

    function getConduit(bytes32 conduitKey) public view returns (address conduit, bool exists) {
        try ISeaport(SEAPORT).information() returns (string memory, bytes32, address conduitController) {
            try IConduitController(conduitController).getConduit(conduitKey) returns (address _conduit, bool _exists) {
                conduit = _conduit;
                exists = _exists;
            } catch {
            }
        } catch {
        }
        return (conduit, exists);
    }

    function supportsERC721(address nft) internal view returns (bool) {
        try IERC165(nft).supportsInterface(INTERFACE_ID_ERC721) returns (bool support) {
            return support;
        } catch {
        }
        return false;
    }

    function supportsERC1155(address nft) internal view returns (bool) {
        try IERC165(nft).supportsInterface(INTERFACE_ID_ERC1155) returns (bool support) {
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

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try IERC1155(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}