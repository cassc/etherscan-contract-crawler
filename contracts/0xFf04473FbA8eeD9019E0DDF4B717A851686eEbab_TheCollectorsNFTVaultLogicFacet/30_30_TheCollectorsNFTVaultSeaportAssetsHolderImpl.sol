// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./Imports.sol";
import "./Interfaces.sol";
import "./LibDiamond.sol";
import {BasicOrderParameters, OrderComponents, Order, AdvancedOrder, CriteriaResolver} from "./SeaportStructs.sol";

interface INFTVault {
    function getVaultParticipants(uint64 vaultId) external view returns (LibDiamond.Participant[] memory);

    function validateSale(uint64 vaultId) external view returns (bool);
}

/*
    -______---______---______---______--______---______--______--
    /\--___\-/\--___\-/\--__-\-/\--==-\/\--__-\-/\--==-\/\__--_\-
    \-\___--\\-\--__\-\-\--__-\\-\--_-/\-\-\/\-\\-\--__<\/_/\-\/-
    -\/\_____\\-\_____\\-\_\-\_\\-\_\---\-\_____\\-\_\-\_\-\-\_\-
    --\/_____/-\/_____/-\/_/\/_/-\/_/----\/_____/-\/_/-/_/--\/_/-
    -______---______---______---______--______--______-----------
    /\--__-\-/\--___\-/\--___\-/\--___\/\__--_\/\--___\----------
    \-\--__-\\-\___--\\-\___--\\-\--__\\/_/\-\/\-\___--\---------
    -\-\_\-\_\\/\_____\\/\_____\\-\_____\-\-\_\-\/\_____\--------
    --\/_/\/_/-\/_____/-\/_____/-\/_____/--\/_/--\/_____/--------
    -__--__---______---__-------_____----______---______---------
    /\-\_\-\-/\--__-\-/\-\-----/\--__-.-/\--___\-/\--==-\--------
    \-\--__-\\-\-\/\-\\-\-\____\-\-\/\-\\-\--__\-\-\--__<--------
    -\-\_\-\_\\-\_____\\-\_____\\-\____--\-\_____\\-\_\-\_\------
    --\/_/\/_/-\/_____/-\/_____/-\/____/--\/_____/-\/_/-/_/------
    -------------------------------------------------------------
    @dev
    The business logic code of the asset holder.
    Working together with @TheCollectorsNFTVaultSeaportAssetsHolderProxy in a proxy/implementation design pattern.
    The reason why it is separated to proxy and implementation is to save gas when creating vaults.
    This contract is able to purchase and list NFTs on OpenSea's new protocol Seaport
*/
contract TheCollectorsNFTVaultSeaportAssetsHolderImpl is ERC721Holder, ERC1155Holder {

    /**
     *  @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_getAssetsHolderStorage().owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // Only the nft vault main contract can upgrade the implementation
    function upgrade(address impl) external onlyOwner {
        LibDiamond.AssetsHolderStorage storage ahs = _getAssetsHolderStorage();
        ahs.implementation = impl;
    }

    // ============================ BUY ============================

    /*
        @dev
        Buying the requested NFT on Seaport using an AdvancedOrder
    */
    function buyAdvancedNFTOnSeaport(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        uint256 price,
        address seaport
    ) external onlyOwner returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        require(IOpenseaSeaport(seaport).fulfillAdvancedOrder{value : price}(
                advancedOrder,
                criteriaResolvers,
                fulfillerConduitKey,
                address(0)
            ), "Order not fulfilled");
        return balanceBefore - address(this).balance;
    }

    /*
        @dev
        Buying the requested NFT on Seaport using an BasicOrder
    */
    function buyNFTOnSeaport(
        BasicOrderParameters calldata parameters,
        uint256 price,
        address seaport
    ) external onlyOwner returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        require(IOpenseaSeaport(seaport).fulfillBasicOrder{value : price}(parameters), "Order not fulfilled");
        return balanceBefore - address(this).balance;
    }

    /*
    @dev
        Buying the requested NFT on Seaport
    */
    function buyMatchedNFTOnSeaport(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments,
        uint256 price,
        address seaport
    ) external onlyOwner returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        Execution[] memory executions = IOpenseaSeaport(seaport).matchOrders{value : price}(
            orders, fulfillments
        );
        require(executions.length > 0, "Order not fulfilled");
        return balanceBefore - address(this).balance;
    }

    // ============================ ACCEPT OFFERS ============================

    function acceptNFTOfferOnSeaport(
        BasicOrderParameters calldata parameters,
        address seaport,
        address conduitAddress
    ) external onlyOwner {
        if (LibDiamond.WETH.allowance(address(this), conduitAddress) == 0) {
            LibDiamond.WETH.approve(conduitAddress, type(uint256).max);
        }
        if (!IApproveableNFT(parameters.considerationToken).isApprovedForAll(address(this), conduitAddress)) {
            IApproveableNFT(parameters.considerationToken).setApprovalForAll(conduitAddress, true);
        }
        require(IOpenseaSeaport(seaport).fulfillBasicOrder(parameters), "Order not fulfilled");
        _getAssetsHolderStorage().listed = false;
        LibDiamond.WETH.withdraw(LibDiamond.WETH.balanceOf(address(this)));
    }

    function acceptAdvancedNFTOfferOnSeaport(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address seaport,
        address conduitAddress,
        address considerationToken
    ) external onlyOwner {
        if (LibDiamond.WETH.allowance(address(this), conduitAddress) == 0) {
            LibDiamond.WETH.approve(conduitAddress, type(uint256).max);
        }
        if (!IApproveableNFT(considerationToken).isApprovedForAll(address(this), conduitAddress)) {
            IApproveableNFT(considerationToken).setApprovalForAll(conduitAddress, true);
        }
        require(IOpenseaSeaport(seaport).fulfillAdvancedOrder(
                advancedOrder,
                criteriaResolvers,
                fulfillerConduitKey,
                address(0)
            ), "Order not fulfilled");
        _getAssetsHolderStorage().listed = false;
        LibDiamond.WETH.withdraw(LibDiamond.WETH.balanceOf(address(this)));
    }

    // ============================ LISTING ============================

    /*
        @dev
        Making sure the collection is approved and then validating the order
        The FE will need to call Opensea's API to make sure the NFT listed on the website
        Using the @receive function to prevent buying in the next 4 blocks
    */
    function listNFTOnSeaport(
        Order memory order,
        address seaport,
        address conduitAddress
    ) external onlyOwner {
        if (!IApproveableNFT(order.parameters.offer[0].token).isApprovedForAll(address(this), conduitAddress)) {
            IApproveableNFT(order.parameters.offer[0].token).setApprovalForAll(conduitAddress, true);
        }
        require(IOpenseaSeaport(seaport).validate(_toOrders(order)), "Order not validated");
        _getAssetsHolderStorage().listed = true;
    }

    // ============================ CANCEL ============================

    /*
        @dev
        Cancelling sell orders of the requested NFT on Seaport
    */
    function cancelNFTListingOnSeaport(
        OrderComponents[] memory orders,
        address seaport
    ) external onlyOwner {
        _getAssetsHolderStorage().listed = false;
        require(IOpenseaSeaport(seaport).cancel(orders), "Order not cancelled");
    }

    /*
        @dev
        Transferring the assets to someone else, can only be called by the owner
    */
    function transferToken(bool isERC1155, address recipient, address collection, uint256 tokenId) external onlyOwner {
        if (isERC1155) {
            IERC1155(collection).safeTransferFrom(address(this), recipient, tokenId, 1, "");
        } else {
            IERC721(collection).safeTransferFrom(address(this), recipient, tokenId);
        }
    }

    /*
        @dev
        Transferring ETH to someone else, can only be called by the owner
    */
    function sendValue(address payable to, uint256 amount) external onlyOwner {
        Address.sendValue(to, amount);
    }

    /*
        @dev
        Confirming or executing a transaction just like a multisig contract
        Initially the contract did not contain this functionality, however, after reconsidering claiming and airdrop
        scenarios it was decided to add it.
        Please notice that a 100% consensus is needed to run a transaction and without any grace period.
    */
    function executeTransaction(address _target, bytes memory _data, uint256 _value) external {
        LibDiamond.AssetsHolderStorage storage ahs = _getAssetsHolderStorage();
        LibDiamond.Participant[] memory participants = INFTVault(ahs.owner).getVaultParticipants(
            ahs.vaultId
        );
        // Only a participant with ownership can confirm or execute transactions
        // Only after the nft vault has purchased the NFT the participants getting the ownership property filled
        require(_isParticipantExistsWithOwnership(participants, msg.sender), "E1");

        if (ahs.target == _target && keccak256(_data) == keccak256(ahs.data)
            && _value == ahs.value) {
            // Approving current transaction
            ahs.consensus[msg.sender] = true;
        } else {
            // New transaction and overriding previous transaction
            ahs.target = _target;
            ahs.data = _data;
            ahs.value = _value;
            for (uint256 i; i < participants.length;) {
                // Resetting all votes expect the sender
                ahs.consensus[participants[i].participant] = participants[i].participant == msg.sender;
                unchecked {
                    ++i;
                }
            }
        }

        bool passedConsensus = true;
        for (uint256 i; i < participants.length;) {
            // We need to check ownership > 0 because some participants can be in the vault but did not contribute
            // any funds (i.e were added by the vault creator)
            if (participants[i].ownership > 0 && !ahs.consensus[participants[i].participant]) {
                passedConsensus = false;
                break;
            }
            unchecked {
                ++i;
            }
        }

        if (passedConsensus) {
            if (Address.isContract(ahs.target)) {
                Address.functionCallWithValue(
                    ahs.target, ahs.data, ahs.value
                );
            } else {
                Address.sendValue(payable(ahs.target), ahs.value);
            }

            // Resetting votes and transaction
            for (uint256 i; i < participants.length;) {
                ahs.consensus[participants[i].participant] = false;
                unchecked {
                    ++i;
                }
            }
            ahs.target = address(0);
            ahs.data = "";
            ahs.value = 0;
        }
    }

    // ==================== Internals ====================

    function _toOrders(Order memory order) internal pure returns (Order[] memory) {
        Order[] memory orders = new Order[](1);
        orders[0] = order;
        return orders;
    }

    /*
        @dev
        A helper function to find out if a participant is part of a vault with ownership
    */
    function _isParticipantExistsWithOwnership(LibDiamond.Participant[] memory participants, address participant) internal pure returns (bool) {
        for (uint256 i; i < participants.length; i++) {
            if (participants[i].ownership > 0 && participants[i].participant == participant) {
                return true;
            }
        }
        return false;
    }

    function _getAssetsHolderStorage() internal pure returns (LibDiamond.AssetsHolderStorage storage ahs) {
        bytes32 position = LibDiamond.ASSETS_HOLDER_STORAGE_POSITION;
        assembly {
            ahs.slot := position
        }
    }

    /*
        @dev
        Since in current Seaport protocol there isn't any way to set up a static call to verify the sale after
        it happen, we are using the receive function to verify the sale.
        Since the vault is always selling only in ETH this will always work
    */
    receive() external payable {
        if (_getAssetsHolderStorage().listed) {
            require(INFTVault(_getAssetsHolderStorage().owner).validateSale(_getAssetsHolderStorage().vaultId), "Wait ~1 minute between list and sale");
        }
    }

}