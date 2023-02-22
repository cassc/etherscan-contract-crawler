// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./token/ERC20/IERC20.sol";
import "./token/Address.sol";
import "./token/ERC20/SafeER20.sol";
import "./interface/bebop_aggregation_contract.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract BebopAggregationContract is IBebopAggregationContract {

    bytes4 constant internal EIP1271_MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    using SafeERC20 for IERC20;

    function getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    uint256 chainId = getChainID();
    address verifyingContract = address(this);
    string private constant EIP712_DOMAIN =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(abi.encodePacked(EIP712_DOMAIN));

    string constant AGGREGATED_ORDER_TYPE =
        "AggregateOrder(uint256 expiry,address taker_address,address[] maker_addresses,uint256[] maker_nonces,address[][] taker_tokens,address[][] maker_tokens,uint256[][] taker_amounts,uint256[][] maker_amounts,address receiver)";
    bytes32 constant AGGREGATED_ORDER_TYPE_HASH = keccak256(abi.encodePacked(AGGREGATED_ORDER_TYPE));

    string constant PARTIAL_AGGREGATED_ORDER_TYPE =
        "PartialOrder(uint256 expiry,address taker_address,address maker_address,uint256 maker_nonce,address[] taker_tokens,address[] maker_tokens,uint256[] taker_amounts,uint256[] maker_amounts,address receiver)";
    bytes32 constant PARTIAL_AGGREGATED_ORDER_TYPE_HASH = keccak256(abi.encodePacked(PARTIAL_AGGREGATED_ORDER_TYPE));

    bytes32 private DOMAIN_SEPARATOR;

    uint256 private constant ETH_SIGN_HASH_PREFIX = 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;

    mapping(address => mapping(uint256 => uint256)) private maker_validator;
    mapping(address => mapping(address => bool)) orderSignerRegistry;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("BebopAggregationContract"),
                keccak256("1"),
                chainId,
                verifyingContract
            )
        );
    }

    function getRsv(bytes memory sig) internal pure returns (bytes32, bytes32, uint8)
    {
        require(sig.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid sig value S");
        require(v == 27 || v == 28, "Invalid sig value V");
        return (r, s, v);
    }

    function encodeTightlyPackedNestedInt(uint256[][] memory _nested_array) internal pure returns(bytes memory encoded) {
        uint nested_array_length = _nested_array.length;
        for (uint i = 0; i < nested_array_length; i++) {
            encoded = abi.encodePacked(
                encoded,
                keccak256(abi.encodePacked(_nested_array[i]))
            );
        }
        return encoded;
    }

    function encodeTightlyPackedNested(address[][] memory _nested_array) internal pure returns(bytes memory encoded) {
        uint nested_array_length = _nested_array.length;
        for (uint i = 0; i < nested_array_length; i++) {
            encoded = abi.encodePacked(
                encoded,
                keccak256(abi.encodePacked(_nested_array[i]))
            );
        }
        return encoded;
    }

    function registerAllowedOrderSigner(address signer, bool allowed) external override {
        orderSignerRegistry[msg.sender][signer] = allowed;
        emit OrderSignerRegistered(msg.sender, signer, allowed);
    }

    function hashAggregateOrder(AggregateOrder memory order) public view override returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        AGGREGATED_ORDER_TYPE_HASH,
                        order.expiry,
                        order.taker_address,
                        keccak256(abi.encodePacked(order.maker_addresses)),
                        keccak256(abi.encodePacked(order.maker_nonces)),
                        keccak256(encodeTightlyPackedNested(order.taker_tokens)),
                        keccak256(encodeTightlyPackedNested(order.maker_tokens)),
                        keccak256(encodeTightlyPackedNestedInt(order.taker_amounts)),
                        keccak256(encodeTightlyPackedNestedInt(order.maker_amounts)),
                        order.receiver
                    )
                )
            )
        );
    }

    function hashPartialOrder(PartialOrder memory order) public view override returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PARTIAL_AGGREGATED_ORDER_TYPE_HASH,
                            order.expiry,
                            order.taker_address,
                            order.maker_address,
                            order.maker_nonce,
                            keccak256(abi.encodePacked(order.taker_tokens)),
                            keccak256(abi.encodePacked(order.maker_tokens)),
                            keccak256(abi.encodePacked(order.taker_amounts)),
                            keccak256(abi.encodePacked(order.maker_amounts)),
                            order.receiver
                        )
                    )
                )
            );
    }

    function invalidateOrder(address maker, uint256 nonce) private {
        require(nonce != 0, "Nonce must be non-zero");
        uint256 invalidatorSlot = uint64(nonce) >> 8;
        uint256 invalidatorBit = 1 << uint8(nonce);
        mapping(uint256 => uint256) storage invalidatorStorage = maker_validator[maker];
        uint256 invalidator = invalidatorStorage[invalidatorSlot];
        require(invalidator & invalidatorBit == 0, "Invalid maker order (nonce)");
        invalidatorStorage[invalidatorSlot] = invalidator | invalidatorBit;
    }

    function validateMakerSignature(
        address maker_address,
        bytes32 hash,
        Signature memory signature
    ) public view override {
        if (signature.signatureType == SignatureType.EIP712) {
            // Signed using EIP712
            (bytes32 r, bytes32 s, uint8 v) = getRsv(signature.signatureBytes);
            address signer = ecrecover(hash, v, r, s);
            require(signer != address(0), "Invalid signer");
            if (signer != maker_address && !orderSignerRegistry[maker_address][signer]) {
                revert("Invalid maker signature");
            }
        } else if (signature.signatureType == SignatureType.EIP1271) {
            require(IERC1271(maker_address).isValidSignature(hash, signature.signatureBytes) == EIP1271_MAGICVALUE, "Invalid Maker EIP 1271 Signature");
        } else if (signature.signatureType == SignatureType.ETHSIGN) {
            bytes32 ethSignHash;
            assembly {
                mstore(0, ETH_SIGN_HASH_PREFIX) // length of 28 bytes
                mstore(28, hash) // length of 32 bytes
                ethSignHash := keccak256(0, 60)
            }
            (bytes32 r, bytes32 s, uint8 v) = getRsv(signature.signatureBytes);
            address signer = ecrecover(ethSignHash, v, r, s);
            require(signer != address(0), "Invalid signer");
            if (signer != maker_address && !orderSignerRegistry[maker_address][signer]) {
                revert("Invalid maker signature");
            }
        } else {
            revert("Invalid Signature Type");
        }
    }

    function assertAndInvalidateMakerOrders(
        AggregateOrder memory order,
        Signature[] memory makerSigs
    ) private {
        // number of columns = number of sigs otherwise unwarranted columns can be injected by sender.
        require(order.taker_tokens.length == makerSigs.length, "Taker tokens length mismatch");
        require(order.maker_tokens.length == makerSigs.length, "Maker tokens length mismatch");
        require(order.taker_amounts.length == makerSigs.length, "Taker amounts length mismatch");
        require(order.maker_amounts.length == makerSigs.length, "Maker amounts length mismatch");
        require(order.maker_nonces.length == makerSigs.length, "Maker nonces length mismatch");
        require(order.maker_addresses.length == makerSigs.length, "Maker addresses length mismatch");
        uint numMakerSigs = makerSigs.length;
        for (uint256 i = 0; i < numMakerSigs; i++) {
            // validate the partially signed orders.
            address maker_address = order.maker_addresses[i];
            require(order.maker_tokens[i].length == order.maker_amounts[i].length, "Maker tokens and amounts length mismatch");
            require(order.taker_tokens[i].length == order.taker_amounts[i].length, "Taker tokens and amounts length mismatch");
            PartialOrder memory partial_order = PartialOrder(
                 order.expiry,
                 order.taker_address,
                 maker_address,
                 order.maker_nonces[i],
                 order.taker_tokens[i],
                 order.maker_tokens[i],
                 order.taker_amounts[i],
                 order.maker_amounts[i],
                 order.receiver
            );
            bytes32 partial_hash = hashPartialOrder(partial_order);
            Signature memory makerSig = makerSigs[i];
            validateMakerSignature(maker_address, partial_hash, makerSig);
            invalidateOrder(maker_address, order.maker_nonces[i]);
        }
    }

    // Construct partial orders from aggregated orders
    function assertAndInvalidateAggregateOrder(
        AggregateOrder memory order,
        bytes memory takerSig,
        Signature[] memory makerSigs
    ) internal returns (bytes32) {
        bytes32 h = hashAggregateOrder(order);
        (bytes32 R, bytes32 S, uint8 V) = getRsv(takerSig);
        address taker = ecrecover(h, V, R, S);
        require(taker == order.taker_address, "Invalid taker signature");

        // construct and validate maker partial orders
        assertAndInvalidateMakerOrders(order, makerSigs);

        require(order.expiry > block.timestamp, "Signature expired");
        return h;
    }

    function makerTransferFunds(
        address from,
        address to,
        uint256 quantity,
        address token
    ) private returns (bool) {
        IERC20(token).safeTransferFrom(from, to, quantity);
        return true;
    }

    function SettleAggregateOrder(
        AggregateOrder memory order,
        bytes memory takerSig,
        Signature[] memory makerSigs
    ) public payable override returns (bool) {
        bytes32 h = assertAndInvalidateAggregateOrder(
            order,
            takerSig,
            makerSigs
        );

        // for each distinct maker
        uint numMakerSigs = makerSigs.length;
        for (uint256 i = 0; i < numMakerSigs; i++) {
            // for each of that maker's tokens
            uint makerTokensLength = order.maker_tokens[i].length;
            uint takerTokensLength = order.taker_tokens[i].length;
            for (uint256 j = 0; j < makerTokensLength; j++) {
                require(
                    // transfer those tokens to the receiver
                    makerTransferFunds(
                        order.maker_addresses[i],
                        order.receiver,
                        order.maker_amounts[i][j],
                        order.maker_tokens[i][j]
                    )
                );
            }

            // for each of the takers tokens (corresponding to each maker)
            for (uint k = 0; k < takerTokensLength; k++){
                // transfer each of those tokens to the corresponding maker
                IERC20(address(order.taker_tokens[i][k])).safeTransferFrom(
                    order.taker_address,
                    order.maker_addresses[i],
                    order.taker_amounts[i][k]
                );
            }
        }

        emit AggregateOrderExecuted(
            h
        );

        return true;
    }
}