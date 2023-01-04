// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Utils} from "./Utils.sol";
import {AssemblyUtils} from "./AssemblyUtils.sol";
import {SaleOrder, MintRequest, BuyRequest, RentOrder, RentRequest, StakeRequest} from "../common/Structs.sol";

library HashUtils {
    using Utils for MintRequest;
    using Utils for SaleOrder;
    using Utils for BuyRequest;
    using Utils for RentOrder;
    using Utils for RentRequest;
    using Utils for StakeRequest;
    using AssemblyUtils for uint256;


    /**
     * @dev Returns the hash of a mint request
     * @param _mintRequest the mint request item
     * @return hash the hash of mint request
     */
    function hashMintRequest(MintRequest memory _mintRequest)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256 size = _mintRequest.sizeOfMintRequest();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }

        index = index.writeUint256(_mintRequest.totalCopies);
        index = index.writeUint256(_mintRequest.amount);
        index = index.writeUint256(_mintRequest.priceConvert);
        index = index.writeAddress(_mintRequest.buyer);
        index = index.writeAddress(_mintRequest.tokenAddress);
        index = index.writeBytes(_mintRequest.nftId);
        index = index.writeBytes(_mintRequest.saleOrderSignature);
        index = index.writeBytes(_mintRequest.transactionId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    /**
     * @dev Returns the hash of a buy request
     * @param _buyRequest the buy request item
     * @return hash the hash of buy request
     */
    function hashBuyRequest(BuyRequest memory _buyRequest)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256 size = _buyRequest.sizeOfBuyRequest();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }
        index = index.writeUint256(_buyRequest.tokenId);
        index = index.writeUint256(_buyRequest.amount);
        index = index.writeUint256(_buyRequest.royaltyFee);
        index = index.writeAddress(_buyRequest.buyer);
        index = index.writeAddress(_buyRequest.tokenAddress);
        index = index.writeBytes(_buyRequest.saleOrderSignature);
        index = index.writeBytes(_buyRequest.transactionId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    /**
     * @dev Returns the hash of a rent request
     * @param _rentRequest the rent request item
     * @return hash the hash of rent request
     */
    function hashRentRequest(RentRequest memory _rentRequest)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256 size = _rentRequest.sizeOfRentRequest();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }
        index = index.writeUint256(_rentRequest.tokenId);
        index = index.writeUint256(_rentRequest.expDate);
        index = index.writeUint256(_rentRequest.totalPrice);
        index = index.writeUint256(_rentRequest.deadline);
        index = index.writeAddress(_rentRequest.renter);
        index = index.writeAddress(_rentRequest.tokenAddress);
        index = index.writeBytes(_rentRequest.transactionId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    /**
     * @dev Returns the hash of a rent order
     * @param _rentOrder the rent request item
     * @return hash the hash of rent order
     */
    function hashRentOrder(RentOrder memory _rentOrder)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256 size = _rentOrder.sizeOfRentOrder();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }
        index = index.writeUint256(_rentOrder.tokenId);
        index = index.writeUint256(_rentOrder.fee);
        index = index.writeUint256(_rentOrder.expirationDate);
        index = index.writeUint256(_rentOrder.deadline);
        index = index.writeAddress(_rentOrder.owner);
        index = index.writeAddress(_rentOrder.tokenAddress);
        index = index.writeBytes(_rentOrder.transactionId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }
    
    /**
     * @dev Returns the hash of a sale order
     * @param _saleOrder the mint request item
     * @return hash the hash of sale order
     */
    function hashSaleOrder(SaleOrder memory _saleOrder)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256 size = _saleOrder.sizeOfSaleOrder();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }

        index = index.writeUint256(_saleOrder.onSaleQuantity);
        index = index.writeUint256(_saleOrder.price);
        index = index.writeUint256(_saleOrder.tokenType);
        index = index.writeAddress(_saleOrder.seller);
        index = index.writeBytes(_saleOrder.saleOrderId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    /**
     * @dev Returns the hash of a rent request
     * @param _stakeRequest the rent request item
     * @return hash the hash of stake request
     */
    function hashStakeRequest(StakeRequest memory _stakeRequest)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256 size = _stakeRequest.sizeOfStakeRequest();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }
        index = index.writeUint256(_stakeRequest.tokenId);
        index = index.writeAddress(_stakeRequest.owner);
        index = index.writeBytes(_stakeRequest.poolId);
        index = index.writeBytes(_stakeRequest.internalTxId);


        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }


    /**
     * @dev Returns the eth-signed hash of the hash data
     * @param hash the input hash data
     * @return ethSignedHash the eth signed hash of the input hash data
     */
    function getEthSignedHash(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns the address which is recovered from the signature and the hash data
     * @param _hash the eth-signed hash data
     * @param _signature the signature which was signed by the admin
     * @return signer the address recovered from the signature and the hash data
     */
    function recoverSigner(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }
}