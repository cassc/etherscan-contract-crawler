// SPDX-License-Identifier: MIT

//   _ _ _                            _                            _                     _ ____
//  | (_) |                          | |                          | |                   | |  _ \
//  | |_| |__  _ __ __ _ _ __ _   _  | |     __ _ _   _ _ __   ___| |__  _ __   __ _  __| | |_) |_   _ _   _
//  | | | '_ \| '__/ _` | '__| | | | | |    / _` | | | | '_ \ / __| '_ \| '_ \ / _` |/ _` |  _ <| | | | | | |
//  | | | |_) | | | (_| | |  | |_| | | |___| (_| | |_| | | | | (__| | | | |_) | (_| | (_| | |_) | |_| | |_| |
//  |_|_|_.__/|_|  \__,_|_|   \__, | |______\__,_|\__,_|_| |_|\___|_| |_| .__/ \__,_|\__,_|____/ \__,_|\__, |
//                             __/ |                                    | |                             __/ |
//                            |___/                                     |_|                            |___/

pragma solidity ^0.8.16;

import "../data/DataType.sol";
import "../enum/LaunchpadProxyEnums.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LaunchpadBuy {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    function processBuy(
        DataType.Launchpad storage lpad,
        DataType.AccountRoundsStats storage accountStats,
        uint256 roundsIdx,
        address sender,
        uint256 whiteListBuyNum,
        uint256 quantity,
        bytes memory signature,
        address signer
    ) public returns (uint256) {
        string memory ret = checkLaunchpadBuy(
            lpad,
            accountStats,
            roundsIdx,
            sender,
            quantity,
            whiteListBuyNum,
            signer,
            signature,
            sender
        );

        if (keccak256(bytes(ret)) != keccak256(bytes(LaunchpadProxyEnums.OK))) {
            revert(ret);
        }
        uint256 shouldPay = lpad.roundss[roundsIdx].price * quantity;
        uint256 nftType = lpad.nftType;
        address sourceAddress = lpad.sourceAddress;
        if (lpad.roundss[roundsIdx].price > 0) {
            transferIncomes(
                lpad,
                sender,
                lpad.roundss[roundsIdx].buyToken,
                shouldPay
            );
        }
        {
            uint32 totalBuyQty = accountStats.totalBuyQty;
            accountStats.totalBuyQty = totalBuyQty + uint32(quantity);
            accountStats.lastBuyTime = uint32(block.timestamp);

            if (
                roundsIdx != 0 &&
                lpad.roundss[roundsIdx - 1].saleQuantity !=
                lpad.roundss[roundsIdx - 1].maxSupply
            ) {
                lpad.roundss[roundsIdx].startTokenId =
                    lpad.roundss[roundsIdx - 1].saleQuantity +
                    lpad.roundss[roundsIdx - 1].startTokenId;
                lpad.roundss[roundsIdx].maxSupply =
                    lpad.roundss[roundsIdx].maxSupply +
                    lpad.roundss[roundsIdx - 1].maxSupply -
                    lpad.roundss[roundsIdx - 1].saleQuantity;
                lpad.roundss[roundsIdx - 1].maxSupply = lpad
                    .roundss[roundsIdx - 1]
                    .saleQuantity;
            }
        }
        transitCall(nftType, lpad, roundsIdx, sender, quantity, sourceAddress);
        return shouldPay;
    }

    function transitCall(
        uint256 nftType,
        DataType.Launchpad storage lpad,
        uint256 roundsIdx,
        address sender,
        uint256 quantity,
        address sourceAddress
    ) public {
        if (nftType == 0) {
            uint256 saleQuantity = lpad.roundss[roundsIdx].saleQuantity;
            DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[
                roundsIdx
            ];
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = lpadRounds.startTokenId + saleQuantity;
                callLaunchpadBuy(
                    lpad,
                    sender,
                    quantity,
                    sourceAddress,
                    tokenId
                );
                saleQuantity = saleQuantity + 1;
            }
            lpad.roundss[roundsIdx].saleQuantity = uint32(saleQuantity);
        } else {
            uint256 saleQuantity = lpad.roundss[roundsIdx].saleQuantity;
            DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[
                roundsIdx
            ];
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = lpadRounds.startTokenId + saleQuantity;
                uint256 perIdQuantity = lpad.roundss[roundsIdx].perIdQuantity;
                callLaunchpadBuy(
                    lpad,
                    sender,
                    perIdQuantity,
                    sourceAddress,
                    tokenId
                );
                saleQuantity = saleQuantity + 1;
            }
            lpad.roundss[roundsIdx].saleQuantity = uint32(saleQuantity);
        }
    }

    function callLaunchpadBuy(
        DataType.Launchpad storage lpad,
        address sender,
        uint256 quantity,
        address sourceAddress,
        uint256 tokenId
    ) public {
        // example bytes4(keccak256("safeMint(address,uint256)")),
        bytes4 selector = lpad.abiSelectorAndParam[
            DataType.ABI_IDX_BUY_SELECTOR
        ];
        bytes4 paramTable = lpad.abiSelectorAndParam[
            DataType.ABI_IDX_BUY_PARAM_TABLE
        ];
        bytes memory proxyCallData;
        if (paramTable == bytes4(0x00000000)) {
            proxyCallData = abi.encodeWithSelector(selector, sender, tokenId);
        } else if (paramTable == bytes4(0x00000001)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sender,
                tokenId,
                quantity
            );
        } else if (paramTable == bytes4(0x00000002)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sourceAddress,
                sender,
                tokenId
            );
        } else if (paramTable == bytes4(0x00000003)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sourceAddress,
                sender,
                tokenId,
                quantity
            );
        }
        require(
            proxyCallData.length > 0,
            LaunchpadProxyEnums.LPD_ROUNDS_ABI_NOT_FOUND
        );
        (bool didSucceed, bytes memory returnData) = lpad.targetContract.call(
            proxyCallData
        );
        if (!didSucceed) {
            revert(
                string(
                    abi.encodePacked(
                        LaunchpadProxyEnums.LPD_ROUNDS_CALL_BUY_CONTRACT_FAILED,
                        LaunchpadProxyEnums.LPD_SEPARATOR,
                        returnData
                    )
                )
            );
        }
    }

    function checkLaunchpadBuy(
        DataType.Launchpad memory lpad,
        DataType.AccountRoundsStats memory accStats,
        uint256 roundsIdx,
        address sender,
        uint256 quantity,
        uint256 wlMaxBuyQuantity,
        address signer,
        bytes memory signature,
        address msgSender
    ) public returns (string memory) {
        if (lpad.id == 0) return LaunchpadProxyEnums.LPD_INVALID_ID;
        if (!lpad.enable) return LaunchpadProxyEnums.LPD_NOT_ENABLE;
        if (roundsIdx >= lpad.roundss.length)
            return LaunchpadProxyEnums.LPD_ROUNDS_IDX_INVALID;
        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];
        if (isContract(sender))
            return LaunchpadProxyEnums.LPD_ROUNDS_BUY_FROM_CONTRACT_NOT_ALLOWED;
        if ((quantity + lpadRounds.saleQuantity) > lpadRounds.maxSupply)
            return LaunchpadProxyEnums.LPD_ROUNDS_QTY_NOT_ENOUGH_TO_BUY;
        if (lpadRounds.price > 0) {
            uint256 paymentNeeded = quantity * lpadRounds.price;
            if (lpadRounds.buyToken != address(0)) {
                if (
                    paymentNeeded >
                    IERC20(lpadRounds.buyToken).balanceOf(sender)
                ) return LaunchpadProxyEnums.LPD_ROUNDS_ERC20_BLC_NOT_ENOUGH;
                if (
                    paymentNeeded >
                    IERC20(lpadRounds.buyToken).allowance(sender, address(this))
                )
                    return
                        LaunchpadProxyEnums
                            .LPD_ROUNDS_PAYMENT_ALLOWANCE_NOT_ENOUGH;
                if (msg.value > 0)
                    return LaunchpadProxyEnums.LPD_ROUNDS_PAY_VALUE_NOT_NEED;
            } else {
                if (paymentNeeded > (sender.balance + msg.value))
                    return LaunchpadProxyEnums.LPD_ROUNDS_PAYMENT_NOT_ENOUGH;
                if (paymentNeeded > msg.value)
                    return LaunchpadProxyEnums.LPD_ROUNDS_PAY_VALUE_NOT_ENOUGH;
                if (msg.value > paymentNeeded)
                    return LaunchpadProxyEnums.LPD_ROUNDS_PAY_VALUE_UPPER_NEED;
            }
        }
        if (quantity > lpadRounds.maxBuyNumOnce)
            return LaunchpadProxyEnums.LPD_ROUNDS_MAX_BUY_QTY_PER_TX_LIMIT;
        if ((quantity + accStats.totalBuyQty) > lpadRounds.maxBuyQtyPerAccount)
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_MAX_BUY_LIMIT;
        if (block.timestamp - accStats.lastBuyTime < lpadRounds.buyInterval)
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_BUY_INTERVAL_LIMIT;
        if (lpadRounds.saleEnd > 0 && block.timestamp > lpadRounds.saleEnd)
            return LaunchpadProxyEnums.LPD_ROUNDS_SALE_END;
        if (lpadRounds.whiteListModel != DataType.WhiteListModel.NONE) {
            return
                checkWhitelistBuy(
                    lpad,
                    roundsIdx,
                    quantity,
                    accStats.totalBuyQty,
                    wlMaxBuyQuantity,
                    signer,
                    signature,
                    msgSender
                );
        } else {
            if (block.timestamp < lpadRounds.saleStart)
                return LaunchpadProxyEnums.LPD_ROUNDS_SALE_NOT_START;
        }
        return LaunchpadProxyEnums.OK;
    }

    function transferIncomes(
        DataType.Launchpad memory lpad,
        address sender,
        address buyToken,
        uint256 shouldPay
    ) public {
        if (shouldPay == 0) {
            return;
        }
        if (buyToken == address(0)) {
            payable(lpad.receipts).transfer(shouldPay);
        } else {
            IERC20 token = IERC20(buyToken);
            token.safeTransferFrom(sender, lpad.receipts, shouldPay);
        }
    }

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    //                     [whitelist sale]                  [public sale]
    //  | whiteListSaleStart ---------- saleStart | saleStart ---------- saleEnd |
    function checkWhitelistBuy(
        DataType.Launchpad memory lpad,
        uint256 roundsIdx,
        uint256 quantity,
        uint256 alreadyBuy,
        uint256 maxWhitelistBuy,
        address signer,
        bytes memory signature,
        address msgSender
    ) public view returns (string memory) {
        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];
        if (lpadRounds.whiteListSaleStart != 0) {
            if (lpadRounds.saleStart < block.timestamp) {
                return LaunchpadProxyEnums.OK;
            }
            if (block.timestamp < lpadRounds.whiteListSaleStart)
                return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_SALE_NOT_START;
        } else {
            if (block.timestamp < lpadRounds.saleStart)
                return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_SALE_NOT_START;
        }
        if (!signVerify(lpad.id, roundsIdx, signer, signature, msgSender))
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_NOT_IN_WHITELIST;
        if (maxWhitelistBuy == 0)
            return LaunchpadProxyEnums.LPD_ROUNDS_MAX_WHITELIST_BUY_ZERO;
        if ((quantity + alreadyBuy) > maxWhitelistBuy)
            return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_BUY_NUM_LIMIT;
        return LaunchpadProxyEnums.OK;
    }

    // sign verify
    function signVerify(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address signer,
        bytes memory signature,
        address msgSender
    ) public pure returns (bool) {
        bytes32 shash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msgSender, launchpadId, roundsIdx))
            )
        );
        return signer == shash.recover(signature);
    }
}