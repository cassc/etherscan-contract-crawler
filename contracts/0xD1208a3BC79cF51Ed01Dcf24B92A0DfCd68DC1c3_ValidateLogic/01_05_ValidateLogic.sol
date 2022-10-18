/**************************
  ___  ____  ____  ____   ___   ___  ____    ___    
|_  ||_  _||_  _||_  _|.'   `.|_  ||_  _| .'   `.  
  | |_/ /    \ \  / / /  .-.  \ | |_/ /  /  .-.  \ 
  |  __'.     \ \/ /  | |   | | |  __'.  | |   | | 
 _| |  \ \_   _|  |_  \  `-'  /_| |  \ \_\  `-'  / 
|____||____| |______|  `.___.'|____||____|`.___.'  

 **************************/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../interface.sol";
import { Errors } from "./Errors.sol";

library ValidateLogic {
    function checkDepositPara(
        address game,
        uint[] memory toolIds,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle
    ) public view {
        require(
            IERC721Upgradeable(game).supportsInterface(0x80ac58cd) &&
            totalAmount > (amountPerDay * cycle / 1 days) &&
            totalAmount > minPay &&
            (cycle > 0 && cycle <= 365 days) &&
            toolIds.length > 0 &&
            amountPerDay > 0 &&
            totalAmount > 0 &&
            minPay > 0,
            Errors.VL_DEPOSIT_PARAM_INVALID
        );
    }

    function checkEditPara(
        address editor,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle,
        uint internalId,
        mapping(uint => ICCAL.DepositAsset) storage assetMap
    ) external view {
        ICCAL.DepositAsset memory asset = assetMap[internalId];
        require(
            totalAmount > (amountPerDay * cycle / 1 days) &&
            totalAmount > minPay &&
            (cycle > 0 && cycle <= 365 days) &&
            amountPerDay > 0 &&
            totalAmount > 0 &&
            minPay > 0,
            Errors.VL_EDIT_PARAM_INVALID
        );

        require(
            block.timestamp < asset.depositTime + asset.cycle &&
            asset.status == ICCAL.AssetStatus.INITIAL &&
            asset.holder == editor,
            Errors.VL_EDIT_CONDITION_NOT_MATCH
        );
    }

    function checkBorrowPara(
        uint internalId,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle,
        mapping(uint => ICCAL.DepositAsset) storage assetMap
    ) public view returns(bool) {
        ICCAL.DepositAsset memory asset = assetMap[internalId];
        if (
            asset.depositTime + asset.cycle <= block.timestamp ||
            asset.status != ICCAL.AssetStatus.INITIAL ||
            asset.internalId != internalId
        ) {
            return false;
        }
        // prevent depositor change data before borrower freeze token
        if (asset.amountPerDay != amountPerDay || asset.totalAmount != totalAmount || asset.minPay != minPay || asset.cycle != cycle) {
            return false;
        }
        return true;
    }

    function checkWithdrawTokenPara(
        address user,
        uint16 chainId,
        uint internalId,
        uint borrowIdx,
        mapping(address => ICCAL.InterestInfo[]) storage pendingWithdraw
    ) public view returns(bool, uint) {
        ICCAL.InterestInfo[] memory list = pendingWithdraw[user];
        uint len = list.length;
        if (len < 1) {
            return (false, 0);
        }

        for (uint i = 0; i < len;) {
            if (
                list[i].borrowIndex == borrowIdx &&
                list[i].chainId == chainId &&
                list[i].internalId == internalId 
            ) {
                return (true, i);
            }
            unchecked {
                ++i;
            }
        }

        return (false, 0);
    }

    function calcCost(uint amountPerDay, uint time, uint min, uint max) external pure returns(uint) {
        uint cost = time * amountPerDay / 1 days;
        if (cost <= min) {
            return min;
        } else {
            return cost > max ? max : cost;
        }
    }
}