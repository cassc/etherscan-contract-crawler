// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IBaseERC721Extendable} from "./IBaseERC721Extendable.sol";

/**
 * @dev Custom extension that is used for public minting by a signature. This extension ist implemented to handle payments by papers.xyz
 */
contract ERC721SignatureExtension is AccessControlEnumerable, ReentrancyGuard {
    bytes32 public constant FEE_OPERATOR_ROLE = keccak256("FEE_OPERATOR_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    address payable private feeCustodian;


    struct BatchMintPayableHashParams {
        address baseContract; // erc721 contract where the extension will connect
        address[] tos; // list of receiver for the tokens
        uint256[] tokenIds; // list of token ids that should be minted
        string[] tokenUris; // list of token uris of the tokens
        uint256[] prices; // list of prices of the tokens
        uint256 expiresAt; // block time when the mint offer expires
        address[] payees; // payees addresses that receives the the eth that was send with minting
        uint256[] shareBps; // shares of the payees, amount less then or equal to 10000 is allowed.
        uint256 feeShareBps; // difference between 10000 and share bps. Control parameter to avoid human errors.
    }

    struct BatchMintPayableParams {
        address baseContract; // erc721 contract where the extension will connect
        address[] tos; // list of receiver for the tokens
        uint256[] tokenIds; // list of token ids that should be minted
        string[] tokenUris; // list of token uris of the tokens
        uint256[] prices; // list of prices of the tokens
        uint256 expiresAt; // block time when the mint offer expires
        address[] payees; // payees addresses that receives the the eth that was send with minting
        uint256[] shareBps; // shares of the payees, amount less then or equal to 10000 is allowed.
        uint256 feeShareBps; // Difference between 10000 and share bps. Control parameter to avoid human errors.
        address signer; // address that signed the mint message (must be a admin of the contract) ??? should me minter right?
        bytes sig; // signed hash that was computed with 'batchMintPayableHash'
    }

    event FeesReleased(uint256 balance);
    event FeeCustodianSet(address custodian);

    error ZeroAddressNotAllowed();
    error ZeroShareNotAllowed();
    error SharesMustSumUpTo10000();
    error InputArraysAreNotEqualInSize();
    error MissingPayees();
    error RefundingOfExcessEtherFailed();
    error SendOfPaymentToPayeeFailed();
    error InvalidSignature();
    error InsufficientFundsSentForMinting(uint256 send, uint256 required);
    error MintingRequestExpired(uint256 expiresAt, uint256 blockTimeStamp);

    /**
     * @dev constructor with default admin of extension as parameter
     */
    constructor(
        address admin_,
        address signer_,
        address feeOperator_,
        address payable feeCustodian_
    ) payable {
        if (feeCustodian_ == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        if (signer_ == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        feeCustodian = feeCustodian_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(SIGNER_ROLE, admin_);
        _grantRole(SIGNER_ROLE, signer_);
        _grantRole(FEE_OPERATOR_ROLE, feeOperator_);
    }

    /**
     * @dev Mint function that can be used by an external source if the used request data can be verified
     * @param _params struct that contains all data to verify the given mint request
     */
    function batchMintPayable(
        BatchMintPayableParams calldata _params
    ) public payable nonReentrant {
        if (
            _params.tos.length != _params.tokenIds.length ||
            (_params.tokenUris.length > 0 &&
                _params.tos.length != _params.tokenUris.length) ||
            _params.tos.length != _params.prices.length
        ) {
            revert InputArraysAreNotEqualInSize();
        }

        if (_params.payees.length != _params.shareBps.length) {
            revert InputArraysAreNotEqualInSize();
        }

        if (_params.payees.length == 0) {
            revert MissingPayees();
        }

        if (_params.expiresAt <= block.timestamp) {
            revert MintingRequestExpired(_params.expiresAt, block.timestamp);
        }

        if (_params.signer == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        _checkRole(SIGNER_ROLE, _params.signer);
        uint256 shareSum = _params.feeShareBps;
        for (uint256 i; i < _params.payees.length; ++i) {
            if (_params.payees[i] == address(0)) {
                revert ZeroAddressNotAllowed();
            }
            if (_params.shareBps[i] == 0) {
                revert ZeroShareNotAllowed();
            }
            shareSum += _params.shareBps[i];
        }

        if (shareSum != 10000) {
            revert SharesMustSumUpTo10000();
        }

        uint256 priceSum = 0;
        uint256 len = _params.prices.length;
        for (uint256 i; i < len; ++i) {
            priceSum += _params.prices[i];
        }

        if (msg.value < priceSum) {
            revert InsufficientFundsSentForMinting(msg.value, priceSum);
        }

        bytes32 hash = batchMintPayableHash(
            BatchMintPayableHashParams(
                _params.baseContract,
                _params.tos,
                _params.tokenIds,
                _params.tokenUris,
                _params.prices,
                _params.expiresAt,
                _params.payees,
                _params.shareBps,
                _params.feeShareBps
            )
        );

        if (validateSignature(hash, _params.sig, _params.signer) == false) {
            revert InvalidSignature();
        }

        IBaseERC721Extendable(_params.baseContract).batchMintExtension(
            _params.tos,
            _params.tokenIds,
            _params.tokenUris
        );

        // if buyer sends too much money, we will refund the difference
        if (msg.value > priceSum) {
            unchecked {
                uint256 change = msg.value - priceSum;
                address payable refundAddress = payable(msg.sender);
                (bool refundSent, ) = refundAddress.call{value: change}("");
                if (!refundSent) {
                revert RefundingOfExcessEtherFailed();
                }
            }
        }

        for (uint256 i; i < _params.payees.length; ++i) {
            address payable payeeAddress = payable(_params.payees[i]);
            (bool payeeSent, ) = payeeAddress.call{
                value: (priceSum * _params.shareBps[i]) / 10000
            }("");
            if (!payeeSent) {
                revert SendOfPaymentToPayeeFailed();
            }
        }
    }

    /**
     * @dev Support function that can be called by an external provider to validate if minting of the given tokens is possible
     * @param baseContract erc721 contract where the extension is registered and where the token check should be executed
     * @param tokenIds that should be checked. If at least one token is minted a information will be returned
     * @param expiresAt timestamp that will compared to current block time.
     */
    function checkClaimEligibility(
        address baseContract,
        uint256[] calldata tokenIds,
        uint256 expiresAt
    ) external view returns (string memory) {
        if (block.timestamp >= expiresAt) {
            return "minting request expired";
        }

        uint256 len = tokenIds.length;
        for (uint256 i; i < len; ++i) {
            try IERC721(baseContract).ownerOf(tokenIds[i]) returns (address) {
                return "At least one token was already minted.";
            } catch {}
        }
        return "";
    }

    /**
     * @dev Mint function that takes all input parameters to create a hash of them. This hash can the be signed by an admin account and used for minting
     */
    function batchMintPayableHash(
        BatchMintPayableHashParams memory _params
    ) public pure returns (bytes32) {
        bytes memory encodedParams = abi.encode(
            _params.baseContract,
            _params.tos,
            _params.tokenIds,
            _params.tokenUris,
            _params.prices,
            _params.expiresAt,
            _params.payees,
            _params.shareBps,
            _params.feeShareBps
        );
        return keccak256(encodedParams);
    }

    /**
     * @dev Updates the uris of the given tokens. The extension must be the creator of the token
     * @param _baseContract;    erc721 contract where the extension will connect
     * @param _tokenIds;        list of token ids that should be updated
     * @param _tokenUris;       list of token uris that should be set
     */
    function batchUpdateTokenUri(
        address _baseContract,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris,
        bool _emitBatchMetadataUpdatedEvent
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IBaseERC721Extendable(_baseContract).batchUpdateTokenUriExtension(
            _tokenIds,
            _tokenUris,
            _emitBatchMetadataUpdatedEvent
        );
    }

    /**
     * @dev Updates the base uri in the contract of the extension
     * @param _baseContract;    erc721 contract where the extension will connect
     * @param _baseURI;         base uri that should be updated
     */
    function updateBaseURI(
        address _baseContract,
        string memory _baseURI,
        bool _emitBatchMetadataUpdatedEvent
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IBaseERC721Extendable(_baseContract).updateBaseURIExtension(
            _baseURI,
            _emitBatchMetadataUpdatedEvent
        );
    }

    /**
     * @dev Validates this given signature data
     * @param _hash;            Hash value that should be validated
     * @param _sig;             signature of the hash that should be validated
     * @param _expectedSigner   expected signer of the hash
     */
    function validateSignature(
        bytes32 _hash,
        bytes memory _sig,
        address _expectedSigner
    ) public pure returns (bool) {
        bytes32 ethSignedHash = ECDSA.toEthSignedMessageHash(_hash);
        return ECDSA.recover(ethSignedHash, _sig) == _expectedSigner;
    }

    function releaseToFeeCustodian() public onlyRole(FEE_OPERATOR_ROLE) {
        emit FeesReleased(address(this).balance);
        feeCustodian.call{value: address(this).balance}("");
    }

    function getFeeCustodian() public view returns (address) {
        return feeCustodian;
    }

    function setFeeCustodian(
        address payable _feeCustodian
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_feeCustodian == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        feeCustodian = _feeCustodian;
        emit FeeCustodianSet(_feeCustodian);
    }

    function getRoleMembers(
        bytes32 _role
    ) public view returns (address[] memory) {
        uint256 roleCount = getRoleMemberCount(_role);
        address[] memory members = new address[](roleCount);
        for (uint256 i; i < roleCount; ++i) {
            members[i] = getRoleMember(_role, i);
        }
        return members;
    }
}