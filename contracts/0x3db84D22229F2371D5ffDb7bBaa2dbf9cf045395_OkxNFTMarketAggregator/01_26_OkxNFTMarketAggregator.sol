// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../tools/SecurityBaseFor8.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./markets/MarketRegistry.sol";
import "./interfaces/markets/IOkxNFTMarketAggregator.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../Adapters/libs/OKXSeaportLib.sol";
import "../Adapters/libs/SeaportLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {TradeType} from "../Adapters/libs/TradeType.sol";
import "../common/TokenTransferrerConstants.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "hardhat/console.sol";

library MyTools {
    function getSlice(
        uint256 begin,
        uint256 end,
        bytes memory text
    ) internal pure returns (bytes memory) {
        uint256 length = end - begin;
        bytes memory a = new bytes(length + 1);
        for (uint256 i = 0; i <= length; i++) {
            a[i] = text[i + begin - 1];
        }
        return a;
    }

    function bytesToAddress(bytes memory bys)
        internal
        view
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function bytesToBytes4(bytes memory bys)
        internal
        view
        returns (bytes4 addr)
    {
        assembly {
            addr := mload(add(bys, 32))
        }
    }
}

contract OkxNFTMarketAggregator is
    IOkxNFTMarketAggregator,
    SecurityBaseFor8,
    ReentrancyGuard,
    ERC721Holder,
    ERC1155Holder
{
    bool private _initialized;
    MarketRegistry public marketRegistry;

    bytes4 private constant _SEAPORT_ADAPTER_SEAPORTBUY = 0xb30f2249;
    bytes4 private constant _SEAPORT_ADAPTER_SEAACCEPT = 0x13a6f9b9;
    bytes4 private constant _SEAPORT_ADAPTER_SEAPORTBUY_ETH = 0x3f4a7fd1;
    uint256 private constant _SEAPORT_LIB = 7;
    uint256 private constant _OKX_SEAPORT_LIB = 8;

    uint256 private constant _SEAPORT_BUY_ETH = 1;
    uint256 private constant _SEAPORT_BUY_ERC20 = 2;
    uint256 private constant _SEAPORT_ACCEPT = 3;

    using SafeERC20 for IERC20;

    error NFT_RESERVED();
    error ERC20_RESERVED();

    event MatchOrderResults(bytes32[] orderHashes, bool[] results);

    struct AggregatorParam {
        uint256 actionType;
        uint256 payAmount;
        address payToken;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 tradeType;
    }

    function init(address newOwner) external {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _transferOwnership(newOwner);
    }

    receive() external payable {

    }

    // 配置erc20给别的市场的授权
    function approveERC20(
        IERC20 token,
        address operator,
        uint256 amount
    ) external onlyOwner {
        token.approve(operator, amount);
    }

    function setMarketRegistry(address _marketRegistry) external onlyOwner {
        marketRegistry = MarketRegistry(_marketRegistry);
    }

    //compatibleOldVersion
    function trade(MarketRegistry.TradeDetails[] memory tradeDetails)
        external
        payable
        nonReentrant
    {
        uint256 length = tradeDetails.length;
        bytes32[] memory orderHashes = new bytes32[](length);
        bool[] memory results = new bool[](length);
        uint256 giveBackValue;

        for (uint256 i = 0; i < length; i++) {
            (address proxy, bool isLib, bool isActive) = marketRegistry.markets(
                tradeDetails[i].marketId
            );

            if (!isActive) {
                continue;
            }

            bytes memory tradeData = tradeDetails[i].tradeData;
            uint256 ethValue = tradeDetails[i].value;

            //okc wyvern
            if (
                tradeDetails[i].marketId ==
                uint256(MarketInfo.OKEXCHANGE_ERC20_ADAPTER)
            ) {
                bytes memory tempAddr = MyTools.getSlice(49, 68, tradeData);
                address orderToAddress = MyTools.bytesToAddress(tempAddr);
                require(
                    orderToAddress == msg.sender,
                    "OKExchange orderToAddress error!"
                );
            } else if (
                tradeDetails[i].marketId ==
                uint256(MarketInfo.LOOKSRARE_ADAPTER)
            ) {
                //looksrare
                bytes memory tempAddr = MyTools.getSlice(81, 100, tradeData);
                address orderToAddress = MyTools.bytesToAddress(tempAddr);
                require(
                    orderToAddress == msg.sender,
                    "Loosrare orderToAddress error!"
                );
            } else if (
                tradeDetails[i].marketId ==
                uint256(MarketInfo.OPENSEA_SEAPORT_ADAPTER)
            ) {
                //opensea seaport
                bytes memory tempSelector = MyTools.getSlice(1, 4, tradeData);
                bytes4 functionSelector = MyTools.bytesToBytes4(tempSelector);
                if (
                    functionSelector == _SEAPORT_ADAPTER_SEAPORTBUY ||
                    functionSelector == _SEAPORT_ADAPTER_SEAPORTBUY_ETH
                ) {
                    bytes memory tempAddr = MyTools.getSlice(49, 68, tradeData);
                    address orderToAddress = MyTools.bytesToAddress(tempAddr);
                    require(
                        orderToAddress == msg.sender,
                        "Opensea Seaport Buy orderToAddress error!"
                    );
                } else if (functionSelector == _SEAPORT_ADAPTER_SEAACCEPT) {
                    bytes memory tempAddr = MyTools.getSlice(
                        81,
                        100,
                        tradeData
                    );
                    address orderToAddress = MyTools.bytesToAddress(tempAddr);
                    require(
                        orderToAddress == msg.sender,
                        "Opensea Seaport Accept orderToAddress error!"
                    );
                } else {
                    revert("seaport adapter function error");
                }
            }

            (bool success, ) = isLib
                ? proxy.delegatecall(tradeData)
                : proxy.call{value: ethValue}(tradeData);

            orderHashes[i] = tradeDetails[i].orderHash;
            results[i] = success;

            if (!success) {
                giveBackValue += ethValue;
            }
        }

        if (giveBackValue > 0) {
            (bool transfered, bytes memory reason) = msg.sender.call{
                value: giveBackValue - 1
            }("");
            require(transfered, string(reason));
        }

        emit MatchOrderResults(orderHashes, results);
    }

    function trade(
        MarketRegistry.TradeDetails[] memory tradeDetails,
        bool isFailed
    ) external payable nonReentrant {
        uint256 length = tradeDetails.length;
        bytes32[] memory orderHashes = new bytes32[](length);
        bool[] memory results = new bool[](length);
        uint256 giveBackValue;

        for (uint256 i = 0; i < length; i++) {
            (address proxy, bool isLib, bool isActive) = marketRegistry.markets(
                tradeDetails[i].marketId
            );

            if (!isActive) {
                continue;
            }

            bytes memory tradeData = tradeDetails[i].tradeData;
            uint256 ethValue = tradeDetails[i].value;

            //okc wyvern
            if (tradeDetails[i].marketId == 4) {
                bytes memory tempAddr = MyTools.getSlice(49, 68, tradeData);
                address orderToAddress = MyTools.bytesToAddress(tempAddr);
                require(orderToAddress == msg.sender, "orderToAddress error!");
            } else if (tradeDetails[i].marketId == 2) {
                //looksrare
                bytes memory tempAddr = MyTools.getSlice(81, 100, tradeData);
                address orderToAddress = MyTools.bytesToAddress(tempAddr);
                require(orderToAddress == msg.sender, "orderToAddress error!");
            } else if (tradeDetails[i].marketId == 3) {
                //opensea seaport
                bytes memory tempSelector = MyTools.getSlice(1, 4, tradeData);
                bytes4 functionSelector = MyTools.bytesToBytes4(tempSelector);
                if (
                    functionSelector == _SEAPORT_ADAPTER_SEAPORTBUY ||
                    functionSelector == _SEAPORT_ADAPTER_SEAPORTBUY_ETH
                ) {
                    bytes memory tempAddr = MyTools.getSlice(49, 68, tradeData);
                    address orderToAddress = MyTools.bytesToAddress(tempAddr);
                    require(
                        orderToAddress == msg.sender,
                        "orderToAddress error!"
                    );
                } else if (functionSelector == _SEAPORT_ADAPTER_SEAACCEPT) {
                    bytes memory tempAddr = MyTools.getSlice(
                        81,
                        100,
                        tradeData
                    );
                    address orderToAddress = MyTools.bytesToAddress(tempAddr);
                    require(
                        orderToAddress == msg.sender,
                        "orderToAddress error!"
                    );
                } else {
                    revert("seaport adapter function error");
                }
            }

            (bool success, ) = isLib
                ? proxy.delegatecall(tradeData)
                : proxy.call{value: ethValue}(tradeData);
            if (isFailed && !success) {
                revert("Transaction Failed!");
            }
            orderHashes[i] = tradeDetails[i].orderHash;
            results[i] = success;

            if (!success) {
                giveBackValue += ethValue;
            }
        }

        if (giveBackValue > 0) {
            (bool transfered, bytes memory reason) = msg.sender.call{
                value: giveBackValue - 1
            }("");
            require(transfered, string(reason));
        }

        emit MatchOrderResults(orderHashes, results);
    }

    //TODO
    function tradeV2(
        MarketRegistry.TradeDetails[] calldata tradeDetails,
        AggregatorParam[] calldata aggregatorParam,
        bool isAtomic
    ) external payable {
        //uint256 length = tradeDetails.length;
        bytes32[] memory orderHashes = new bytes32[](tradeDetails.length);
        bool[] memory results = new bool[](tradeDetails.length);
        uint256 giveBackValue;

        for (uint256 i = 0; i < tradeDetails.length; ) {
            bool success = true;

            // 除飞龙协议以外，marketId 0-6 使用 trade 接口
            if(tradeDetails[i].marketId != 0 && tradeDetails[i].marketId !=4 && tradeDetails[i].marketId < 7) {
                unchecked {
                    ++i;
                }
                continue;
            }

            if (
                tradeDetails[i].marketId == _SEAPORT_LIB||tradeDetails[i].marketId == _OKX_SEAPORT_LIB
            ) {
                uint256 length = tradeDetails[i].tradeData.length;
                bytes calldata tradeData = tradeDetails[i].tradeData;
                uint256 ethValue = tradeDetails[i].value;

                
                address CONDUIT = 0x1E0049783F008A0085193E00003D00cd54003c71;
                address SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
                if ( _OKX_SEAPORT_LIB  == tradeDetails[i].marketId) {
                    CONDUIT = 0x97cf28FfEcBACC60E2b6983d3508d4F3c9A3207d;
                    SEAPORT = 0x90A77DD8AE0525e08b1C2930eb2Eb650E78c6725;               
                }

                //before process
                if (aggregatorParam[i].actionType != _SEAPORT_BUY_ETH) {
                    success = beforeExecute(aggregatorParam[i],CONDUIT);
                    ethValue = 0;
                }

                if(success){
                    assembly {
                        let len := length
                        let start := tradeData.offset
                        let ptr := mload(0x40) // free memory pointer
                        calldatacopy(ptr, start, len)
                        if iszero(call(gas(), SEAPORT, ethValue, ptr, len, 0, 0)) {
                            success := false
                        }
                    }
                }

               if (success && (aggregatorParam[i].actionType != _SEAPORT_BUY_ETH)) {
                    success = afterExecute(aggregatorParam[i], CONDUIT);
               }

            } else {
                (address proxy, bool isLib, bool isActive) = marketRegistry.markets(tradeDetails[i].marketId);
                if(isActive == false){
                    unchecked {
                        ++i;
                    }
                    continue;
                }

                if (tradeDetails[i].marketId == 4) {
                    if (!verifyWyvern(tradeDetails[i])) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                (success, ) = isLib
                ? proxy.delegatecall(tradeDetails[i].tradeData)
                : proxy.call{value: tradeDetails[i].value}(
                    tradeDetails[i].tradeData
                );

            }


            if (!success) {
                if(isAtomic) {
                    revert("Transaction Failed!");
                }

                if(aggregatorParam[i].actionType == _SEAPORT_BUY_ETH){
                    giveBackValue += tradeDetails[i].value;
                }else if(aggregatorParam[i].actionType == _SEAPORT_BUY_ERC20){
                    //errorProcess erc20
                    safeERC20Transfer(aggregatorParam[i].payToken,
                        msg.sender,
                        aggregatorParam[i].payAmount);

                }else if(aggregatorParam[i].actionType == _SEAPORT_ACCEPT){
                    // errorProcess Take
                    if(TradeType.ERC1155 == TradeType(aggregatorParam[i].tradeType)){
                        _performERC1155Transfer(aggregatorParam[i].tokenAddress, address(this) ,msg.sender,
                            aggregatorParam[i].tokenId,
                            aggregatorParam[i].amount);
                    }else if(TradeType.ERC721 == TradeType(aggregatorParam[i].tradeType)){
                        _performERC721Transfer(aggregatorParam[i].tokenAddress, address(this) ,msg.sender,
                            aggregatorParam[i].tokenId);
                    }
                }
            }

            orderHashes[i] = tradeDetails[i].orderHash;
            results[i] = success;

            unchecked {
                ++i;
            }
        }

        if (giveBackValue > 0) {
            (bool transfered, bytes memory reason) = msg.sender.call{
                value: giveBackValue - 1
            }("");
            require(transfered, string(reason));
        }

        emit MatchOrderResults(orderHashes, results);
    }

    function verifyWyvern(MarketRegistry.TradeDetails calldata tradeDetail) internal returns (bool) {
        bytes memory tempAddr = MyTools.getSlice(49, 68,  tradeDetail.tradeData);
        address orderToAddress = MyTools.bytesToAddress(tempAddr);
        if(orderToAddress != msg.sender) {
            return false;
        }
        return true;
    }

    function beforeExecute(AggregatorParam calldata aggregatorParam,address CONDUIT) internal returns (bool success) {
        if (aggregatorParam.actionType == _SEAPORT_BUY_ERC20) {
            success = safeERC20TransferFrom(
                ERC20(aggregatorParam.payToken),
                msg.sender,
                address(this),
                aggregatorParam.payAmount);
        } else if (aggregatorParam.actionType == _SEAPORT_ACCEPT) {

            // TODO: check isApproved
            success = setApprovalForAll(aggregatorParam.tokenAddress, CONDUIT, true);
            if(!success){
                return false;
            }

            if (TradeType.ERC1155 == TradeType(aggregatorParam.tradeType)) {

                success = _performERC1155Transfer(aggregatorParam.tokenAddress, msg.sender,
                    address(this),
                    aggregatorParam.tokenId,
                    aggregatorParam.amount);
            }else if (TradeType.ERC721 == TradeType(aggregatorParam.tradeType)) {

                success = _performERC721Transfer(aggregatorParam.tokenAddress,msg.sender,
                    address(this),
                    aggregatorParam.tokenId);
            } else {
                success = false;
            }
        }
    }

    function afterExecute(AggregatorParam calldata aggregatorParam,address CONDUIT) internal returns (bool success) {

       if (aggregatorParam.actionType == _SEAPORT_ACCEPT) {
            //take offer
            success = safeERC20Transfer(
                aggregatorParam.payToken,
                msg.sender,
                    IERC20(aggregatorParam.payToken).balanceOf(address(this)));
        }
    }



    function _performERC1155Transfer(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    ) internal returns (bool) {

        bool success;

        // Utilize assembly to perform an optimized ERC1155 token transfer.
        assembly {
        // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

        // The following memory slots will be used when populating call data
        // for the transfer; read the values and restore them later.
            let memPointer := mload(FreeMemoryPointerSlot)
            let slot0x80 := mload(Slot0x80)
            let slot0xA0 := mload(Slot0xA0)
            let slot0xC0 := mload(Slot0xC0)

        // Write call data into memory, beginning with function selector.
            mstore(
            ERC1155_safeTransferFrom_sig_ptr,
            ERC1155_safeTransferFrom_signature
            )
            mstore(ERC1155_safeTransferFrom_from_ptr, from)
            mstore(ERC1155_safeTransferFrom_to_ptr, to)
            mstore(ERC1155_safeTransferFrom_id_ptr, identifier)
            mstore(ERC1155_safeTransferFrom_amount_ptr, amount)
            mstore(
            ERC1155_safeTransferFrom_data_offset_ptr,
            ERC1155_safeTransferFrom_data_length_offset
            )
            mstore(ERC1155_safeTransferFrom_data_length_ptr, 0)

        // Perform the call, ignoring return data.
            success := call(
            gas(),
            token,
            0,
            ERC1155_safeTransferFrom_sig_ptr,
            ERC1155_safeTransferFrom_length,
            0,
            0
            )

            mstore(Slot0x80, slot0x80) // Restore slot 0x80.
            mstore(Slot0xA0, slot0xA0) // Restore slot 0xA0.
            mstore(Slot0xC0, slot0xC0) // Restore slot 0xC0.

        // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

        // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }

        return success;
    }

    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 identifier
    ) internal returns (bool) {

        bool success;

        // Utilize assembly to perform an optimized ERC721 token transfer.
        assembly {
        // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

        // The free memory pointer memory slot will be used when populating
        // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

        // Write call data to memory starting with function selector.
            mstore(ERC721_transferFrom_sig_ptr, ERC721_transferFrom_signature)
            mstore(ERC721_transferFrom_from_ptr, from)
            mstore(ERC721_transferFrom_to_ptr, to)
            mstore(ERC721_transferFrom_id_ptr, identifier)

        // Perform the call, ignoring return data.
            success := call(
            gas(),
            token,
            0,
            ERC721_transferFrom_sig_ptr,
            ERC721_transferFrom_length,
            0,
            0
            )

        // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

        // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }

        return success;
    }

    //IERC20(payToken).approve(address,uint256);
    function safeERC20Approve(address token, address operator, uint256 amount) internal returns (bool success) {
        //success = false;
        assembly {
            // If the token has no code, false.
           // if not(iszero(extcodesize(token))) {
            if gt(extcodesize(token), 0){
                // The free memory pointer memory slot will be used when populating
                // call data for the transfer; read the value and restore it later.
                let memPointer := mload(FreeMemoryPointerSlot)

                mstore(ERC20_safeApprove_sig_ptr, ERC20_safeApprove_signature)
                mstore(ERC20_setApprove_operator_ptr, operator)
                mstore(ERC20_setApprove_amount_ptr, amount)
                
                // Perform the call, ignoring return data.
                success := call(
                    gas(),
                    token,
                    0,
                    ERC20_safeApprove_sig_ptr,
                    ERC20_setApprove_length,
                    0,
                    OneWord
                )
                // Check for  success. 
                // We accept 0-length return data as success, or at
                // least 32 bytes that starts with a 32-byte boolean true.
                success := and(
                    success,                             // call itself succeeded
                    or(
                        iszero(returndatasize()),                  // no return data, or
                        and(
                            iszero(lt(returndatasize(), 32)),      // at least 32 bytes
                            eq(mload(0), 1)                       // starts with uint256(1)
                        )
                    )
                )
                // Restore the original free memory pointer.
                mstore(FreeMemoryPointerSlot, memPointer)
            }
            
        }
    }


    //IERC721(payToken).setApprovalForAll(address,false);
    function setApprovalForAll(address token, address operator, bool isApprove)  internal returns (bool success) {
        //success = false;
        assembly {
            // If the token has no code, false.
            //if not(iszero(extcodesize(token))) {
            if gt(extcodesize(token), 0){
                // The free memory pointer memory slot will be used when populating
                // call data for the transfer; read the value and restore it later.
                let memPointer := mload(FreeMemoryPointerSlot)

                mstore(ERC721_setApprovalForAll_sig_ptr, ERC721_setApprovalForAll_signature)
                mstore(ERC721_setApprovalForAll_operator_ptr, operator)
                mstore(ERC721_setApprovalForAll_isApprove_ptr, isApprove)
                
                // Perform the call, ignoring return data.
                success := call(
                    gas(),
                    token,
                    0,
                    ERC721_setApprovalForAll_sig_ptr,
                    ERC721_setApprovalForAll_length,
                    0,
                    0
                )
                // Check for  success. 
                // We accept 0-length return data as success, or at
                // least 32 bytes that starts with a 32-byte boolean true.
                success := and(
                    success,                             // call itself succeeded
                    or(
                        iszero(returndatasize()),                  // no return data, or
                        and(
                            iszero(lt(returndatasize(), 32)),      // at least 32 bytes
                            eq(mload(0), 1)                       // starts with uint256(1)
                        )
                    )
                )
                // Restore the original free memory pointer.
                mstore(FreeMemoryPointerSlot, memPointer)
            }
        }
    }


    //IERC20(payToken).safeERC20Transfer(type(uint256).max);
    function safeERC20Transfer(address token, address to, uint256 amount) internal returns (bool success) {
        assembly {
            // If the token has no code, revert.
            //if not(iszero(extcodesize(token))) {
            if gt(extcodesize(token), 0){
                // The free memory pointer memory slot will be used when populating
                // call data for the transfer; read the value and restore it later.
                let memPointer := mload(FreeMemoryPointerSlot)

                mstore(ERC20_safeTransfer_sig_ptr, ERC20_safeTransfer_signature)
                mstore(ERC20_safeTransfer_operator_ptr, to)
                mstore(ERC20_safeTransfer_amount_ptr, amount)
                
                // Perform the call, ignoring return data.
                success := call(
                    gas(),
                    token,
                    0,
                    ERC20_safeTransfer_sig_ptr,
                    ERC20_safeTransfer_length,
                    0,
                    OneWord
                )
                // Check for  success. 
                // We accept 0-length return data as success, or at
                // least 32 bytes that starts with a 32-byte boolean true.
                success := and(
                    success,                             // call itself succeeded
                    or(
                        iszero(returndatasize()),                  // no return data, or
                        and(
                            iszero(lt(returndatasize(), 32)),      // at least 32 bytes
                            eq(mload(0), 1)                       // starts with uint256(1)
                        )
                    )
                )
                // Restore the original free memory pointer.
                mstore(FreeMemoryPointerSlot, memPointer)
            }
        }
    }

    function safeERC20TransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal returns (bool success)  {

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }
    }


}