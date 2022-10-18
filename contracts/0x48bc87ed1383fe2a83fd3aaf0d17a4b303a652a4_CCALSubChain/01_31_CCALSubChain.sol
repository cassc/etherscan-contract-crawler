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

import { ValidateLogic } from "./libs/ValidateLogic.sol";
import { Errors } from "./libs/Errors.sol";

import "./BaseContract.sol";

import "./interface.sol";

contract CCALSubChain is BaseContract {
    uint16 public mainChainId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {  
        _disableInitializers();  
    }

    function initialize(
        address _endpoint,
        uint16 _selfChainId,
        uint16 _mainChainId,
        address _currency,
        uint8 _currencyDecimal
    ) external initializer {
        mainChainId = _mainChainId;
        BaseContract.initialize(_endpoint, _selfChainId);
        toggleTokens(_currency, _currencyDecimal, true, true);
    }

    event LogRepayAsset(uint indexed internalId, uint interest, uint borrowIndex, uint time);
    function repayAsset(uint internalId) external payable {
        ICCAL.DepositAsset storage asset = nftMap[internalId];

        require(asset.status == ICCAL.AssetStatus.BORROW && asset.borrower == _msgSender(), Errors.VL_REPAY_CONDITION_NOT_MATCH);

        uint interest = ValidateLogic.calcCost(
            asset.amountPerDay,
            block.timestamp - asset.borrowTime,
            asset.minPay,
            asset.totalAmount
        );

        bytes memory payload = abi.encode(
            ICCAL.Operation.REPAY,
            abi.encode(
                asset.holder,
                internalId,
                selfChainId,
                interest,
                asset.borrowIndex
            )
        );

        // encode adapterParams to specify more gas for the destination
        bytes memory adapterParams = abi.encodePacked(VERSION, GAS_FOR_DEST_LZ_RECEIVE);

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint messageFee, ) = layerZeroEndpoint.estimateFees(mainChainId, address(this), payload, false, adapterParams);

        require(msg.value >= messageFee, Errors.LZ_GAS_TOO_LOW);

        asset.borrowTime = 0;
        asset.borrower = address(0);
        asset.status = ICCAL.AssetStatus.INITIAL;

        uint len = asset.toolIds.length;
        for (uint idx; idx < len;) {
            IERC721Upgradeable(asset.game).safeTransferFrom(_msgSender(), address(this), asset.toolIds[idx]);
            unchecked {
                ++idx;
            }
        }

        layerZeroEndpoint.send{value: msg.value}(
            mainChainId,                     //  destination chainId
            remotes[mainChainId],            //  destination address of nft contract
            payload,                     //  abi.encoded()'ed bytes
            payable(_msgSender()),                    //  refund address
            address(0x0),                      //  'zroPaymentAddress' unused for this
            adapterParams                      //  txParameters 
        );

        emit LogRepayAsset(internalId, interest, asset.borrowIndex, block.timestamp);
    }

    function estimateCrossChainRepayAssetFees(uint internalId) public view returns(uint) {
        ICCAL.DepositAsset storage asset = nftMap[internalId];

        uint interest = ValidateLogic.calcCost(
            asset.amountPerDay,
            block.timestamp - asset.borrowTime,
            asset.minPay,
            asset.totalAmount
        );

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint messageFee, ) = layerZeroEndpoint.estimateFees(
            mainChainId,
            address(this),
            abi.encode(
                ICCAL.Operation.REPAY,
                abi.encode(
                    asset.holder,
                    internalId,
                    selfChainId,
                    interest,
                    asset.borrowIndex
                )
            ),
            false,
            abi.encodePacked(VERSION, GAS_FOR_DEST_LZ_RECEIVE) // encode adapterParams to specify more gas for the destination
        );
        return messageFee;
    }

    event LogBorrowAsset(address indexed borrower, uint indexed internalId, uint borrowIndex, bool useCredit, uint time);
    function _borrow(address _borrower, uint internalId, bool _useCredit) internal {
        ICCAL.DepositAsset storage asset = nftMap[internalId];

        asset.borrowIndex += 1;
        asset.borrower = _borrower;
        asset.status = ICCAL.AssetStatus.BORROW;
        asset.borrowTime = block.timestamp;

        uint len = asset.toolIds.length;
        for (uint i = 0; i < len;) {
            IERC721Upgradeable(asset.game).safeTransferFrom(address(this), _borrower, asset.toolIds[i]);
            unchecked {
                ++i;
            }
        }

        emit LogBorrowAsset(_borrower, internalId, asset.borrowIndex, _useCredit, asset.borrowTime);
    }

    event LogWithdrawAsset(uint indexed internalId);
    function withdrawAsset(uint internalId) external payable whenNotPaused {
        ICCAL.DepositAsset memory asset = nftMap[internalId];

        require(
            (asset.status != ICCAL.AssetStatus.WITHDRAW) &&
            (asset.status != ICCAL.AssetStatus.LIQUIDATE) &&
            _msgSender() == asset.holder,
            Errors.VL_WITHDRAW_ASSET_CONDITION_NOT_MATCH
        );

        // if tool isn't borrow, depositor can withdraw
        if (asset.status == ICCAL.AssetStatus.INITIAL) {
            // if (msg.value > 0) {
            //     (bool success, ) = _msgSender().call{value: msg.value, gas: 30_000}(new bytes(0));
            //     require(success, Errors.LZ_BACK_FEE_FAILED);
            // }
            nftMap[internalId].status = ICCAL.AssetStatus.WITHDRAW;
            
            uint len = asset.toolIds.length;
            for (uint idx = 0; idx < len;) {
                IERC721Upgradeable(asset.game).safeTransferFrom(address(this), _msgSender(), asset.toolIds[idx]);
                unchecked {
                    ++idx;
                }
            }

            emit LogWithdrawAsset(internalId);
        } else {
            require(block.timestamp > asset.depositTime + asset.cycle, Errors.VL_LIQUIDATE_NOT_EXPIRED);
            liquidate(internalId);
        }
    }

    event LogLiquidation(uint internalId, uint time);
    function liquidate(uint internalId) internal {

        ICCAL.DepositAsset storage asset = nftMap[internalId];

        bytes memory payload = abi.encode(
            ICCAL.Operation.LIQUIDATE,
            abi.encode(
                asset.holder,
                selfChainId,
                internalId,
                asset.borrowIndex
            )
        );

        // encode adapterParams to specify more gas for the destination
        bytes memory adapterParams = abi.encodePacked(VERSION, GAS_FOR_DEST_LZ_RECEIVE);

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint messageFee, ) = layerZeroEndpoint.estimateFees(mainChainId, address(this), payload, false, adapterParams);

        require(msg.value >= messageFee, Errors.LZ_GAS_TOO_LOW);

        asset.status = ICCAL.AssetStatus.LIQUIDATE;

        layerZeroEndpoint.send{value: msg.value}(
            mainChainId,                     //  destination chainId
            remotes[mainChainId],            //  destination address of ccal contract
            payload,                          //  abi.encoded()'ed bytes
            payable(_msgSender()),                    //  refund address
            address(0x0),                      //  'zroPaymentAddress' unused for this
            adapterParams                      //  txParameters 
        );

        emit LogLiquidation(internalId, block.timestamp);
    }

    function estimateCrossChainLiquidateFees(uint internalId) public view returns(uint) {
        ICCAL.DepositAsset storage asset = nftMap[internalId];
        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint messageFee, ) = layerZeroEndpoint.estimateFees(
            mainChainId,
            address(this),
            abi.encode(
                ICCAL.Operation.LIQUIDATE,
                abi.encode(
                    asset.holder,
                    selfChainId,
                    internalId,
                    asset.borrowIndex
                )
            ),
            false,
            abi.encodePacked(VERSION, GAS_FOR_DEST_LZ_RECEIVE)
        );
        return messageFee;
    }

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        // boilerplate: only allow this endpiont to be the caller of lzReceive!
        require(msg.sender == address(layerZeroEndpoint), Errors.LZ_BAD_SENDER);
        // owner must have setRemote() to allow its remote contracts to send to this contract
        require(
            _srcAddress.length == remotes[_srcChainId].length && keccak256(_srcAddress) == keccak256(remotes[_srcChainId]),
            Errors.LZ_BAD_REMOTE_ADDR
        );

        try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function onLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public {
        // only internal transaction
        require(msg.sender == address(this), Errors.P_CALLER_MUST_BE_BRIDGE);

        // handle incoming message
        _LzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    event UnknownOp(bytes payload);
    function _LzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal {
        // decode
        (ICCAL.Operation op, bytes memory _other) = abi.decode(_payload, (ICCAL.Operation, bytes));
        if (op == ICCAL.Operation.BORROW) {
            handleBorrowAsset(_other);
        } else {
            emit UnknownOp(_payload);
        }
    }

    event BorrowFail(address indexed game, address indexed user, uint indexed id);
    function handleBorrowAsset(bytes memory _payload) internal {
        (address user, uint id, uint _dp, uint _total, uint _min, address _token, uint _c, bool _useCredit) = abi.decode(_payload, (address, uint, uint, uint, uint, address, uint, bool));
        ICCAL.DepositAsset memory asset = nftMap[id];
        bool canBorrow;
        // prevent depositor change data before borrower freeze token
        if (
            asset.depositTime + asset.cycle > block.timestamp &&
            asset.status == ICCAL.AssetStatus.INITIAL &&
            asset.totalAmount == _total &&
            asset.amountPerDay == _dp &&
            asset.internalId == id &&
            asset.minPay == _min &&
            asset.token == _token &&
            asset.cycle == _c
        ) {
            canBorrow = true;
        }
        if (!canBorrow) {
            emit BorrowFail(asset.game, user, id);
        } else {
            _borrow(user, id, _useCredit);
        }
    }

}