// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SaleOrder, MintRequest, BuyRequest, RentOrder, RentRequest, StakeRequest} from "../common/Structs.sol";
import {HashUtils} from "./HashUtils.sol";

library SignatureUtils {
    using HashUtils for bytes32;
    using HashUtils for SaleOrder;
    using HashUtils for MintRequest;
    using HashUtils for BuyRequest;
    using HashUtils for RentOrder;
    using HashUtils for RentRequest;
    using HashUtils for StakeRequest;



    /**
     * @dev Returns the result of comparision between the recovered address and the input address
     * @param _saleOrder the sale order item
     * @param _signature the signature of the sale order
     * @param _signer the input address
     * @return result true/false
     */
    function verifySaleOrder(
        SaleOrder memory _saleOrder,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 hash = _saleOrder.hashSaleOrder();
        bytes32 ethSignedHash = hash.getEthSignedHash();

        return ethSignedHash.recoverSigner(_signature) == _signer;
    }

    /**
     * @dev Returns the result of comparision between the recovered address and the input address
     * @param _rentOrder the rent order item
     * @param _signature the signature of the rent order
     * @param _signer the input address
     * @return result true/false
     */
    function verifyRentOrder(
        RentOrder memory _rentOrder,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 hash = _rentOrder.hashRentOrder();
        bytes32 ethSignedHash = hash.getEthSignedHash();

        return ethSignedHash.recoverSigner(_signature) == _signer;
    }
    /**
     * @dev Returns the result of comparision between the recovered address and the input address
     * @param _buyRequest the buy request item
     * @param _signature the signature of the buy request
     * @param _signer the input address
     * @return result true/false
     */
    function verifyBuyRequest(
        BuyRequest memory _buyRequest,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 hash = _buyRequest.hashBuyRequest();
        bytes32 ethSignedHash = hash.getEthSignedHash();

        return ethSignedHash.recoverSigner(_signature) == _signer;
    }

     /**
     * @dev Returns the result of comparision between the recovered address and the input address
     * @param _mintRequest the mint request item
     * @param _signature the signature of the mint request
     * @param _signer the input address
     * @return result true/false
     */
    function verifyMintRequest(
        MintRequest memory _mintRequest,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 hash = _mintRequest.hashMintRequest();
        bytes32 ethSignedHash = hash.getEthSignedHash();

        return ethSignedHash.recoverSigner(_signature) == _signer;
    }

    /**
     * @dev Returns the result of comparision between the recovered address and the input address
     * @param _rentRequest the rent request item
     * @param _signature the signature of the rent request
     * @param _signer the input address
     * @return result true/false
     */
    function verifyRentRequest(
        RentRequest memory _rentRequest,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 hash = _rentRequest.hashRentRequest();
        bytes32 ethSignedHash = hash.getEthSignedHash();

        return ethSignedHash.recoverSigner(_signature) == _signer;
    }

     /**
     * @dev Returns the result of comparision between the recovered address and the input address
     * @param _stakeRequest the stake request item
     * @param _signature the signature of the rent request
     * @param _signer the input address
     * @return result true/false
     */
    function verifyStakeRequest(
        StakeRequest memory _stakeRequest,
        bytes memory _signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 hash = _stakeRequest.hashStakeRequest();
        bytes32 ethSignedHash = hash.getEthSignedHash();

        return ethSignedHash.recoverSigner(_signature) == _signer;
    }
}