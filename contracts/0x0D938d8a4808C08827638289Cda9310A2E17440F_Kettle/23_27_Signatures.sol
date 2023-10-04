// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Fee, LoanOffer, BorrowOffer, OfferAuth, Collateral } from "./Structs.sol";
import { InvalidVParameter, InvalidSignature } from "./Errors.sol";
import { ISignatures } from "../interfaces/ISignatures.sol";

abstract contract Signatures is ISignatures {
    bytes32 private immutable _LOAN_OFFER_TYPEHASH;
    bytes32 private immutable _BORROW_OFFER_TYPEHASH;
    bytes32 private immutable _COLLATERAL_TYPEHASH;
    bytes32 private immutable _OFFER_AUTH_TYPEHASH;
    bytes32 private immutable _FEE_TYPEHASH;
    bytes32 private immutable _EIP_712_DOMAIN_TYPEHASH;

    string private constant _NAME = "Kettle";
    string private constant _VERSION = "1";

    mapping(address => uint256) public nonces;
    uint256[50] private _gap;

    constructor() {
        (
            _LOAN_OFFER_TYPEHASH,
            _BORROW_OFFER_TYPEHASH,
            _FEE_TYPEHASH,
            _COLLATERAL_TYPEHASH,
            _OFFER_AUTH_TYPEHASH,
            _EIP_712_DOMAIN_TYPEHASH
        ) = _createTypehashes();
    }

    function information()
        external
        view
        returns (string memory version, bytes32 domainSeparator)
    {
        version = _VERSION;
        domainSeparator = _hashDomain(
            _EIP_712_DOMAIN_TYPEHASH,
            keccak256(bytes(_NAME)),
            keccak256(bytes(_VERSION))
        );
    }

    function getLoanOfferHash(
        LoanOffer calldata offer
    ) external view returns (bytes32) {
        return _hashLoanOffer(offer);
    }

    function getBorrowOfferHash(
        BorrowOffer calldata offer
    ) external view returns (bytes32) {
        return _hashBorrowOffer(offer);
    }

    /**
     * @notice Generate all EIP712 Typehashes
     */
    function _createTypehashes()
        internal
        pure
        returns (
            bytes32 loanOfferTypehash,
            bytes32 borrowOfferTypehash,
            bytes32 feeTypehash,
            bytes32 collateralTypehash,
            bytes32 offerAuthTypehash,
            bytes32 eip712DomainTypehash
        )
    {
        eip712DomainTypehash = keccak256(
            bytes.concat(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

        bytes memory feeTypestring = bytes.concat(
            "Fee(",
            "uint16 rate,",
            "address recipient"
            ")"
        );

        feeTypehash = keccak256(feeTypestring);

        loanOfferTypehash = keccak256(
            bytes.concat(
                "LoanOffer(",
                "address collection,",
                "uint8 collateralType,",
                "uint256 collateralIdentifier,",
                "uint256 collateralAmount,",
                "address currency,",
                "uint256 totalAmount,",
                "uint256 minAmount,",
                "uint256 maxAmount,",
                "uint256 duration,",
                "uint256 rate,",
                "uint256 salt,",
                "uint256 expiration,",
                "uint256 nonce,",
                "Fee[] fees",
                ")",
                feeTypestring
            )
        );

        borrowOfferTypehash = keccak256(
            bytes.concat(
                "BorrowOffer(",
                "address collection,",
                "uint8 collateralType,",
                "uint256 collateralIdentifier,",
                "uint256 collateralAmount,",
                "address currency,",
                "uint256 loanAmount,",
                "uint256 duration,",
                "uint256 rate,",
                "uint256 salt,",
                "uint256 expiration,",
                "uint256 nonce,",
                "Fee[] fees",
                ")",
                feeTypestring
            )
        );

        collateralTypehash = keccak256(
            bytes.concat(
                "Collateral(",
                "uint8 collateralType,",
                "address collection,",
                "uint256 collateralId,",
                "uint256 collateralAmount"
                ")"
            )
        );

        offerAuthTypehash = keccak256(
            bytes.concat(
                "OfferAuth(",
                "bytes32 offerHash,",
                "address taker,"
                "uint256 expiration,",
                "bytes32 collateralHash",
                ")"
            )
        );
    }

    function _hashDomain(
        bytes32 eip712DomainTypehash,
        bytes32 nameHash,
        bytes32 versionHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    eip712DomainTypehash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _hashFee(Fee calldata fee) internal view returns (bytes32) {
        return keccak256(abi.encode(_FEE_TYPEHASH, fee.rate, fee.recipient));
    }

    function _packFees(Fee[] calldata fees) internal view returns (bytes32) {
        bytes32[] memory feeHashes = new bytes32[](fees.length);
        uint256 feesLength = fees.length;
        for (uint256 i; i < feesLength; ) {
            feeHashes[i] = _hashFee(fees[i]);
            unchecked {
                ++i;
            }
        }
        return keccak256(abi.encodePacked(feeHashes));
    }

    function _hashLoanOffer(
        LoanOffer calldata offer
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _LOAN_OFFER_TYPEHASH,
                    offer.collection,
                    offer.collateralType,
                    offer.collateralIdentifier,
                    offer.collateralAmount,
                    offer.currency,
                    offer.totalAmount,
                    offer.minAmount,
                    offer.maxAmount,
                    offer.duration,
                    offer.rate,
                    offer.salt,
                    offer.expiration,
                    nonces[offer.lender],
                    _packFees(offer.fees)
                )
            );
    }

    function _hashBorrowOffer(
        BorrowOffer calldata offer
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _BORROW_OFFER_TYPEHASH,
                    offer.collection,
                    offer.collateralType,
                    offer.collateralIdentifier,
                    offer.collateralAmount,
                    offer.currency,
                    offer.loanAmount,
                    offer.duration,
                    offer.rate,
                    offer.salt,
                    offer.expiration,
                    nonces[offer.borrower],
                    _packFees(offer.fees)
                )
            );
    }

    function _hashCollateral(
        uint8 collateralType,
        address collection,
        uint256 collateralId,
        uint256 collateralAmount
    ) internal view returns (bytes32) {
        return 
            keccak256(
                abi.encode(
                    _COLLATERAL_TYPEHASH, 
                    collateralType, 
                    collection,
                    collateralId,
                    collateralAmount
                )
            );
    }

    function _hashOfferAuth(
        OfferAuth calldata auth
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _OFFER_AUTH_TYPEHASH,
                    auth.offerHash,
                    auth.taker,
                    auth.expiration,
                    auth.collateralHash
                )
            );
    }

    function _hashToSign(bytes32 hash) internal view returns (bytes32) {
        bytes32 domain = _hashDomain(
            _EIP_712_DOMAIN_TYPEHASH,
            keccak256(bytes(_NAME)),
            keccak256(bytes(_VERSION))
        );

        return keccak256(abi.encodePacked(bytes2(0x1901), domain, hash));
    }

    /**
     * @notice Verify authorization of offer
     * @param offerHash Hash of offer struct
     * @param signer signer address
     * @param signature Packed offer signature
     */
    function _verifyOfferAuthorization(
        bytes32 offerHash,
        address signer,
        bytes calldata signature
    ) internal view {
        bytes32 hashToSign = _hashToSign(offerHash);
        bytes32 r;
        bytes32 s;
        uint8 v;

        // solhint-disable-next-line
        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 0x20))
            v := shr(248, calldataload(add(signature.offset, 0x40)))
        }
        _verify(signer, hashToSign, v, r, s);
    }
    

    /**
     * @notice Verify signature of digest
     * @param signer Address of expected signer
     * @param digest Signature digest
     * @param v v parameter
     * @param r r parameter
     * @param s s parameter
     */
    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure {
        if (v != 27 && v != 28) {
            revert InvalidVParameter();
        }

        address recoveredSigner = ecrecover(digest, v, r, s);
        if (recoveredSigner == address(0) || signer != recoveredSigner) {
            revert InvalidSignature();
        }
    }
}