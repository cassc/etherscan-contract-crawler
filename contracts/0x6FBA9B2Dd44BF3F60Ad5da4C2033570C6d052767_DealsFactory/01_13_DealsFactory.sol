// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

//import 'hardhat/console.sol';

import './IDealsController.sol';
import './plugins/erc20/IErc20DealPointsController.sol';
import './plugins/ether/IEtherDealPointsController.sol';
import './plugins/erc721/erc721item/IErc721ItemDealPointsController.sol';
import './plugins/erc721/erc721count/IErc721CountDealPointsController.sol';

struct EtherPointCreationData {
    address from;
    address to;
    uint256 count;
}
struct Erc20PointCreationData {
    address from;
    address to;
    address token;
    uint256 count;
}
struct Erc721ItemPointCreationData {
    address from;
    address to;
    address token;
    uint256 tokenId;
}
struct Erc721CountPointCreationData {
    address from;
    address to;
    address token;
    uint256 count;
}
struct DealCreationData {
    address owner2; // another owner or zero if open swap
    EtherPointCreationData[] eth; // tyoe id 1
    Erc20PointCreationData[] erc20; // type id 2
    Erc721ItemPointCreationData[] erc721Item; // type id 3
    Erc721CountPointCreationData[] erc721Count; // type id 4
}

contract DealsFactory {
    IDealsController public dealsController;
    IEtherDealPointsController public eth;
    IErc20DealPointsController public erc20;
    IErc721ItemDealPointsController public erc721Item;
    IErc721CountDealPointsController public erc721Count;

    constructor(
        IDealsController dealsController_,
        IEtherDealPointsController eth_,
        IErc20DealPointsController erc20_,
        IErc721ItemDealPointsController erc721Item_,
        IErc721CountDealPointsController erc721Count_
    ) {
        dealsController = dealsController_;
        erc20 = erc20_;
        eth = eth_;
        erc721Item = erc721Item_;
        erc721Count = erc721Count_;
    }

    function createDeal(DealCreationData calldata data) external {
        // limitation
        uint256 dealPointsCount = data.erc20.length +
            data.erc721Item.length +
            data.eth.length;
        require(dealPointsCount > 1, 'at least 2 deal points required');
        // create deal
        uint256 dealId = dealsController.createDeal(msg.sender, data.owner2);
        // create points
        for (uint256 i = 0; i < data.eth.length; ++i) {
            checkPoindAddresses(data.eth[i].from, data.eth[i].to, data.owner2);
            eth.createPoint(
                dealId,
                data.eth[i].from,
                data.eth[i].to,
                data.eth[i].count
            );
        }
        for (uint256 i = 0; i < data.erc20.length; ++i) {
            checkPoindAddresses(
                data.erc20[i].from,
                data.erc20[i].to,
                data.owner2
            );
            erc20.createPoint(
                dealId,
                data.erc20[i].from,
                data.erc20[i].to,
                data.erc20[i].token,
                data.erc20[i].count
            );
        }
        for (uint256 i = 0; i < data.erc721Item.length; ++i) {
            checkPoindAddresses(
                data.erc721Item[i].from,
                data.erc721Item[i].to,
                data.owner2
            );
            erc721Item.createPoint(
                dealId,
                data.erc721Item[i].from,
                data.erc721Item[i].to,
                data.erc721Item[i].token,
                data.erc721Item[i].tokenId
            );
        }
        for (uint256 i = 0; i < data.erc721Count.length; ++i) {
            checkPoindAddresses(
                data.erc721Count[i].from,
                data.erc721Count[i].to,
                data.owner2
            );
            erc721Count.createPoint(
                dealId,
                data.erc721Count[i].from,
                data.erc721Count[i].to,
                data.erc721Count[i].token,
                data.erc721Count[i].count
            );
        }

        // stop deal editing
        dealsController.stopDealEditing(dealId);
    }

    function checkPoindAddresses(
        address from,
        address to,
        address owner2
    ) private view {
        require(from != to, 'from equals to address');
        require(
            !(from == address(0) && to == address(0)),
            'from ant to booth equals zero address'
        );
        require(
            from == msg.sender || from == owner2,
            'from must be msg.sender address or owner2 address'
        );
        require(
            to == msg.sender || to == owner2,
            'to must be msg.sender address or owner2 address'
        );
    }
}