// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.16;

import "./orderUtils.sol";
import "./eip1271.sol";
import "./utils.sol";

abstract contract Signing
{
    /**
     * @dev Name of contract.
     */
    string private constant CONTRACT_NAME = "Rook Swap";

    /**
     * @dev Version of contract.
     */
    string private constant CONTRACT_VERSION = "0.1.0";

    /**
     * @dev The EIP-712 typehash for the contract's domain.
     */
    bytes32 private constant TYPEHASH_DOMAIN = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /**
     * @dev The EIP-712 typehash for the Order struct.
     */
    bytes32 private constant TYPEHASH_ORDER = keccak256("Order(address maker,address makerToken,address takerToken,uint256 makerAmount,uint256 takerAmountMin,uint256 takerAmountDecayRate,uint256 data)");

    /**
     * @dev Storage indicating whether or not an orderHash has been pre signed
     */
    mapping(bytes32 => bool) public preSign;

    /**
     * @dev Event that is emitted when an account either pre-signs an order or revokes an existing pre-signature.
     */
    event PreSign(
        bytes32 orderHash,
        bool signed
    );

    /**
     * @dev The length of any signature from an externally owned account.
     */
    uint256 private constant ECDSA_SIGNATURE_LENGTH = 65;

    /**
     * @dev Domain separator.
     */
    bytes32 immutable domainSeparator;

    /**
     * @dev A mapping from a maker address to EOAs which are registered to sign on behalf of the maker address
     * The Maker address can be a smart contract or an EOA. This mapping enables EOAs to sign orders on behalf of
     * smart contracts or other EOAs.
     */
    mapping(address => mapping(address => bool)) orderSignerRegistry;

    /**
     * @dev Event emitted when a new signer is added (or modified) to orderSignerRegistry.
     */
    event OrderSignerRegistered(
        address maker,
        address signer,
        bool allowed
    );

    constructor()
    {
        domainSeparator = keccak256(
            abi.encode(
                TYPEHASH_DOMAIN,
                keccak256(bytes(CONTRACT_NAME)),
                keccak256(bytes(CONTRACT_VERSION)),
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Gets the chainId.
     */
    function _getChainId(
    )
        private
        view
        returns (uint256 chainId)
    {
        assembly
        {
            chainId := chainid()
        }
    }

    /**
     * @dev Calculates orderHash from Order struct
     */
    function getOrderHash(
        OrderUtils.Order calldata order
    )
        public
        view
        returns (bytes32 orderHash)
    {
        orderHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(abi.encode(
                    TYPEHASH_ORDER,
                    order.maker,
                    order.makerToken,
                    order.takerToken,
                    order.makerAmount,
                    order.takerAmountMin,
                    order.takerAmountDecayRate,
                    order.data)
                )
            )
        );
    }

    /**
     * @dev Recovers an order's signer from the specified order and signature.
     * @param orderHash The orderHash to recover the signer for.
     * @param signingScheme The signing scheme (EIP-191, EIP-712, EIP-1271 or PreSign).
     * @param encodedSignature The signature bytes.
     * @return signer The recovered signer address from the specified signature,
     * or address(0) if signature is invalid (EIP-1271 and PreSign only).
     * We are not reverting if signer == address(0) in this function, that responsibility is on the function caller
     */
    function _recoverOrderSignerFromOrderHash(
        bytes32 orderHash,
        LibSignatures.Scheme signingScheme,
        bytes calldata encodedSignature
    )
        internal
        view
        returns (address signer)
    {
        if (signingScheme == LibSignatures.Scheme.Eip712)
        {
            signer = _ecdsaRecover(orderHash, encodedSignature);
        }
        else if (signingScheme == LibSignatures.Scheme.EthSign)
        {
            // The signed message is encoded as:
            // `"\x19Ethereum Signed Message:\n" || length || data`, where
            // the length is a constant (32 bytes) and the data is defined as:
            // `orderHash`.
            signer = _ecdsaRecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        orderHash
                    )
                ),
                encodedSignature);
        }
        else if (signingScheme == LibSignatures.Scheme.Eip1271)
        {
            // Use assembly to read the verifier address from the encoded
            // signature bytes.
            // solhint-disable-next-line no-inline-assembly
            assembly
            {
                // signer = address(encodedSignature[0:20])
                signer := shr(96, calldataload(encodedSignature.offset))
            }

            bytes calldata _signature = encodedSignature[20:];

            // Set signer to address(0) instead of reverting if isValidSignature fails.
            // We have to use a try/catch here in case the verifier's implementation of isValidSignature reverts when false
            // But we cannot rely only on that, because it may return a with a non 1271 magic number instead of reverting.
            try EIP1271Verifier(signer).isValidSignature(orderHash, _signature) returns (bytes4 magicValue)
            {
                // Check if isValidSignature return matches the 1271 magic value spec
                bool isValid = (magicValue == LibERC1271.MAGICVALUE);

                // If not, set signer to address(0)
                assembly
                {
                    let mask := mul(isValid, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    signer := and(signer, mask)
                }
            }
            catch
            {
                signer = address(0);
            }
        }
        else // signingScheme == Scheme.PreSign
        {
            assembly
            {
                // signer = address(encodedSignature[0:20])
                signer := shr(96, calldataload(encodedSignature.offset))
            }

            bool isValid = preSign[orderHash];

            assembly
            {
                let mask := mul(isValid, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                signer := and(signer, mask)
            }
        }
        return signer;
    }

    /**
     * @dev Perform an ECDSA recover for the specified message and calldata
     * signature.
     * The signature is encoded by tighyly packing the following struct:
     * ```
     * struct EncodedSignature {
     *     bytes32 r;
     *     bytes32 s;
     *     uint8 v;
     * }
     * ```
     * @param message The signed message.
     * @param encodedSignature The encoded signature.
     * @return signer The recovered address from the specified signature.
     */
    function _ecdsaRecover(
        bytes32 message,
        bytes calldata encodedSignature
    )
        internal
        pure
        returns (address signer)
    {
        require(
            encodedSignature.length == ECDSA_SIGNATURE_LENGTH,
            "RS:E8"
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        // NOTE: Use assembly to efficiently decode signature data.
        // solhint-disable-next-line no-inline-assembly
        assembly
        {
            // r = uint256(encodedSignature[0:32])
            r := calldataload(encodedSignature.offset)
            // s = uint256(encodedSignature[32:64])
            s := calldataload(add(encodedSignature.offset, 32))
            // v = uint8(encodedSignature[64])
            v := shr(248, calldataload(add(encodedSignature.offset, 64)))
        }

        signer = ecrecover(message, v, r, s);
    }

    /**
     * @dev Sets presign signatures for a batch of specified orders.
     * @param orders The order data of the orders to pre-sign.
     * @param signed Boolean indicating whether to pre-sign or cancel pre-signature.
     */
    function setPreSigns_weQh(
        OrderUtils.Order[] calldata orders,
        bool signed
    )
        external
    {
        for (uint256 i; i < orders.length;)
        {
            // Must be either the order's maker or the maker's valid signer
            require(
                (orders[i].maker == msg.sender) || isValidOrderSigner(orders[i].maker, msg.sender),
                "RS:E16"
            );

            bytes32 orderHash = getOrderHash(orders[i]);

            preSign[orderHash] = signed;
            emit PreSign(orderHash, signed);

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Checks if a given address is registered to sign on behalf of a maker address.
     * @param maker The maker address encoded in an order (can be a contract).
     * @param signer The address that is providing a signature.
     */
    function isValidOrderSigner(
        address maker,
        address signer
    )
        public
        view
        returns (bool isValid)
    {
        isValid = orderSignerRegistry[maker][signer];
    }

    /**
     * @dev Register a signer to sign on behalf of msg.sender (msg.sender can be a contract or EOA).
     * @param signer The address from which you plan to generate signatures.
     * @param allowed True to register, false to unregister.
     */
    function registerAllowedOrderSigner(
        address signer,
        bool allowed
    )
        external
    {
        require(
            signer != address(0),
            "RS:E1"
        );

        orderSignerRegistry[msg.sender][signer] = allowed;

        emit OrderSignerRegistered(msg.sender, signer, allowed);
    }
}