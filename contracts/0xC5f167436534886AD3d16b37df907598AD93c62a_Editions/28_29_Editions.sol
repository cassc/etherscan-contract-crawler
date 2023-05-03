// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████▓▀██████████████████████████████████████████████
// ██████████████████████████████████  ╙███████████████████████████████████████████
// ███████████████████████████████████    ╙████████████████████████████████████████
// ████████████████████████████████████      ╙▀████████████████████████████████████
// ████████████████████████████████████▌        ╙▀█████████████████████████████████
// ████████████████████████████████████▌           ╙███████████████████████████████
// ████████████████████████████████████▌            ███████████████████████████████
// ████████████████████████████████████▌         ▄█████████████████████████████████
// ████████████████████████████████████       ▄████████████████████████████████████
// ███████████████████████████████████▀   ,▄███████████████████████████████████████
// ██████████████████████████████████▀ ,▄██████████████████████████████████████████
// █████████████████████████████████▄▓█████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";

import {ERC721A} from "../tokens/ERC721A.sol";
import {AuthGuard} from "../core/AuthGuard.sol";
import {Payable} from "../core/Payable.sol";

contract Editions is ReentrancyGuard, AuthGuard, Payable {
    using ClonesWithImmutableArgs for address;

    ERC721A public implementation;

    mapping(uint64 => EditionsData) public editionsData;
    mapping(address => uint256) public fixedFees;
    uint256 public percentFee;
    uint256 internal constant BASIS_POINTS = 10000;

    bytes4 public constant SIGNER_ROLE = bytes4(keccak256("SIGNER_ROLE"));
    bytes4 public constant CREATE_ROLE = bytes4(keccak256("CREATE_ROLE"));
    bytes4 public constant UPDATE_ROLE = bytes4(keccak256("UPDATE_ROLE"));

    struct EditionsData {
        address paymentAddress;
        address paymentToken;
        ERC721A clone;
        uint64 startTime;
        uint64 endTime;
        uint64 maxEditions;
        uint32 minEditions;
        uint32 mintLimit;
        uint16 referralBasisPoints;
        uint pricePerEdition;
        bool closed;
    }

    event EditionCreated(uint indexed cid, EditionsData newEdition);
    event EditionUpdated(uint indexed cid, EditionsData updatedEdition);

    /**
     * @dev Constructor for the Editions contract.
     * @param _registry Address of the registry.
     * @param _implementation Address of the ERC721A implementation.
     * @param _nativeFixedFee Fixed fee for native token.
     * @param _percentFee Percentage fee for minting.
     */
    constructor(
        address _registry,
        ERC721A _implementation,
        uint256 _nativeFixedFee,
        uint256 _percentFee
    ) Payable(_registry) {
        require(_percentFee <= BASIS_POINTS, "Invalid percent fee");
        implementation = _implementation;
        fixedFees[address(0)] = _nativeFixedFee;
        percentFee = _percentFee;
    }

    struct CreateEditionParams {
        uint64 id;
        uint32 minEditions;
        uint64 maxEditions;
        uint64 startTime;
        uint64 endTime;
        uint pricePerEdition;
        uint32 mintLimit;
        address paymentToken;
        address paymentAddress;
        address formatter;
        uint16 referralBasisPoints;
        uint royaltyBPS;
    }

    /**
     * @dev Create a new edition.
     * @param params Parameters for the new edition.
     * @return clone Address of the new ERC721A clone.
     */
    function createEdition(
        CreateEditionParams memory params
    )
        external
        onlyAuthorizedById(params.id, CREATE_ROLE)
        returns (ERC721A clone)
    {
        // Ensure that minEditions is less than or equal to maxEditions (if maxEditions is set)
        require(
            params.maxEditions == 0 || params.minEditions <= params.maxEditions,
            "min must be lt or eq to max"
        );

        // Ensure that startTime is less than or equal to endTime (if endTime is set)
        require(
            params.endTime == 0 || params.startTime <= params.endTime,
            "start must be lt or eq to end"
        );

        bytes memory data = abi.encodePacked(params.id);
        clone = ERC721A(address(implementation).clone(data));
        clone.initialize(
            address(registry),
            getIdOwner(params.id),
            params.formatter,
            params.paymentAddress,
            params.royaltyBPS
        );

        EditionsData memory editionData = EditionsData({
            paymentAddress: params.paymentAddress,
            paymentToken: params.paymentToken,
            clone: clone,
            minEditions: params.minEditions,
            maxEditions: params.maxEditions,
            startTime: params.startTime,
            endTime: params.endTime,
            pricePerEdition: params.pricePerEdition,
            mintLimit: params.mintLimit,
            closed: false,
            referralBasisPoints: params.referralBasisPoints
        });
        editionsData[params.id] = editionData;
        connectPluginContract(params.id);
        emit EditionCreated(params.id, editionData);
    }

    /**
     * @dev Update an existing edition.
     * @param _id ID of the edition to update.
     * @param _startTime Updated start time.
     * @param _endTime Updated end time.
     * @param _minEditions Updated minimum editions.
     * @param _maxEditions Updated maximum editions.
     * @param _pricePerEdition Updated price per edition.
     * @param _mintLimit Updated mint limit.
     */
    function updateEdition(
        uint64 _id,
        uint64 _startTime,
        uint64 _endTime,
        uint32 _minEditions,
        uint64 _maxEditions,
        uint _pricePerEdition,
        uint32 _mintLimit,
        uint16 _referralBasisPoints
    ) external onlyAuthorizedById(_id, UPDATE_ROLE) {
        // TODO: unminted
        // Ensure that minEditions is less than or equal to maxEditions (if maxEditions is set)
        require(
            _maxEditions == 0 || _minEditions <= _maxEditions,
            "min must be lt or eq to max"
        );

        // Ensure that startTime is less than or equal to endTime (if endTime is set)
        require(
            _endTime == 0 || _startTime <= _endTime,
            "start must be lt or eq to end"
        );

        EditionsData storage editionData = editionsData[_id];
        editionData.startTime = _startTime;
        editionData.endTime = _endTime;
        editionData.minEditions = _minEditions;
        editionData.maxEditions = _maxEditions;
        editionData.pricePerEdition = _pricePerEdition;
        editionData.mintLimit = _mintLimit;
        editionData.referralBasisPoints = _referralBasisPoints;
        emit EditionUpdated(_id, editionData);
    }

    /**
     * @dev Mint a specific edition.
     * @param _id ID of the edition to mint.
     * @param _to Address to mint the edition to.
     * @param _quantity Quantity of editions to mint.
     */
    function mint(
        uint64 _id,
        address _to,
        uint _quantity,
        address _curator
    ) public payable {
        EditionsData storage editionData = editionsData[_id];

        require(!editionData.closed, "Edition is closed");

        uint totalMinted = editionData.clone.totalSupply();
        uint totalToMint = totalMinted + _quantity;

        // Ensure that the total number of editions to be minted does not exceed the maxEditions (if set)
        require(
            editionData.maxEditions == 0 ||
                totalToMint <= editionData.maxEditions,
            "Exceeds max editions"
        );

        // Ensure that the current block.timestamp is between the startTime and endTime (if set)
        require(
            (editionData.startTime == 0 ||
                block.timestamp >= editionData.startTime) &&
                (editionData.endTime == 0 ||
                    block.timestamp <= editionData.endTime),
            "Outside the minting window"
        );

        // Ensure that the total number of editions minted does not exceed the mintLimit (if set)
        require(
            editionData.mintLimit == 0 || _quantity <= editionData.mintLimit,
            "Exceeds mint limit"
        );

        if (_curator != address(0) && editionData.referralBasisPoints > 0) {
            if (editionData.paymentToken == address(0)) {
                _receiveNativeReferral(
                    msg.sender,
                    editionData.paymentAddress,
                    _curator,
                    editionData.pricePerEdition,
                    _quantity,
                    _id,
                    editionData.referralBasisPoints
                );
            } else {
                _receiveERC20Referral(
                    msg.sender,
                    editionData.paymentAddress,
                    _curator,
                    editionData.paymentToken,
                    editionData.pricePerEdition,
                    _quantity,
                    _id,
                    editionData.referralBasisPoints
                );
            }
        } else {
            if (editionData.paymentToken == address(0)) {
                _receiveNative(
                    msg.sender,
                    editionData.paymentAddress,
                    editionData.pricePerEdition,
                    _quantity,
                    _id
                );
            } else {
                _receiveERC20(
                    msg.sender,
                    editionData.paymentAddress,
                    editionData.paymentToken,
                    editionData.pricePerEdition,
                    _quantity,
                    _id
                );
            }
        }

        editionData.clone.mint(_to, _quantity);
    }

    /**
     * @dev Close an edition.
     * @param _id ID of the edition to close.
     */
    function close(uint64 _id) external onlyAuthorizedById(_id, UPDATE_ROLE) {
        EditionsData storage editionData = editionsData[_id];
        require(!editionData.closed, "Edition is already closed");
        editionData.closed = true;
    }

    /**
     * @dev Open a closed edition.
     * @param _id ID of the edition to open.
     */
    function open(uint64 _id) external onlyAuthorizedById(_id, UPDATE_ROLE) {
        EditionsData storage editionData = editionsData[_id];
        require(editionData.closed, "Edition is already open");
        editionData.closed = false;
    }

    struct SignatureMintParams {
        uint64 id;
        address to;
        address curator;
        uint quantity;
        uint32 maxEditions;
        uint64 startTime;
        uint64 endTime;
        uint pricePerEdition;
        uint32 mintLimit;
        bytes signature;
    }

    /**
     * @dev Mint an edition using a signature.
     * @param params Parameters for the signature mint.
     */
    function signatureMint(SignatureMintParams memory params) public payable {
        address signer = verifySignature(
            params.id,
            params.to,
            params.maxEditions,
            params.startTime,
            params.endTime,
            params.pricePerEdition,
            params.mintLimit,
            params.signature
        );

        require(
            isAuthorizedById(params.id, SIGNER_ROLE, signer),
            "UNAUTHORIZED"
        );

        EditionsData memory editionData = editionsData[params.id];

        require(!editionData.closed, "Edition is closed");

        uint totalMinted = editionData.clone.totalSupply();
        uint totalToMint = totalMinted + params.quantity;

        // Ensure that the total number of editions to be minted does not exceed the maxEditions (if set)
        require(
            params.maxEditions == 0 || totalToMint <= params.maxEditions,
            "Exceeds max editions"
        );

        // Ensure that the current block.timestamp is between the startTime and endTime (if set)
        require(
            (params.startTime == 0 || block.timestamp >= params.startTime) &&
                (params.endTime == 0 || block.timestamp <= params.endTime),
            "Outside the minting window"
        );

        // Ensure that the total number of editions minted does not exceed the mintLimit (if set)
        require(
            params.mintLimit == 0 || params.quantity <= params.mintLimit,
            "Exceeds mint limit"
        );

        if (
            params.curator != address(0) && editionData.referralBasisPoints > 0
        ) {
            if (editionData.paymentToken == address(0)) {
                _receiveNativeReferral(
                    msg.sender,
                    editionData.paymentAddress,
                    params.curator,
                    params.pricePerEdition,
                    params.quantity,
                    params.id,
                    editionData.referralBasisPoints
                );
            } else {
                _receiveERC20Referral(
                    msg.sender,
                    editionData.paymentAddress,
                    params.curator,
                    editionData.paymentToken,
                    params.pricePerEdition,
                    params.quantity,
                    params.id,
                    editionData.referralBasisPoints
                );
            }
        } else {
            if (editionData.paymentToken == address(0)) {
                _receiveNative(
                    msg.sender,
                    editionData.paymentAddress,
                    params.pricePerEdition,
                    params.quantity,
                    params.id
                );
            } else {
                _receiveERC20(
                    msg.sender,
                    editionData.paymentAddress,
                    editionData.paymentToken,
                    params.pricePerEdition,
                    params.quantity,
                    params.id
                );
            }
        }

        editionData.clone.mint(params.to, params.quantity);
    }

    /**
     * @dev Calculate the fee for a specific edition.
     * @param _unitPrice Unit price of the edition.
     * @param _quantity Quantity of editions to mint.
     * @param _token Address of the payment token.
     * @return fee Calculated fee.
     */
    function calculateFee(
        uint256 _unitPrice,
        uint256 _quantity,
        address _token
    ) public view override returns (uint256) {
        uint256 baseValue = _unitPrice * _quantity;
        uint256 fixedFeeTotal = fixedFees[_token] * _quantity;
        uint256 percentFeeTotal = (baseValue * percentFee) / BASIS_POINTS;
        return fixedFeeTotal + percentFeeTotal;
    }

    /**
     * @dev Update the fixed fee for a specific token.
     * @param _token Address of the token.
     * @param _newFixedFee New fixed fee for the token.
     */
    function updateFixedFee(
        address _token,
        uint256 _newFixedFee
    ) external onlyAdmin {
        fixedFees[_token] = _newFixedFee;
    }

    /**
     * @dev Update the percent fee.
     * @param _newPercentFee New percent fee for the token.
     */
    function updatePercentFee(uint256 _newPercentFee) external onlyAdmin {
        require(_newPercentFee <= BASIS_POINTS, "Invalid percent fee");
        percentFee = _newPercentFee;
    }

    function verifySignature(
        uint cid,
        address to,
        uint maxEditions,
        uint startTime,
        uint endTime,
        uint pricePerEdition,
        uint mintLimit,
        bytes memory signature
    ) public pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        bytes32 messageHash = getMessageHash(
            cid,
            to,
            maxEditions,
            startTime,
            endTime,
            pricePerEdition,
            mintLimit
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        // Recover the address that signed the message and check if it matches the calling address
        return recoverSigner(messageHash, v, r, s);
    }

    function getMessageHash(
        uint cid,
        address to,
        uint maxEditions,
        uint startTime,
        uint endTime,
        uint pricePerEdition,
        uint mintLimit
    ) public pure returns (bytes32) {
        // Hash the address using keccak256
        return
            keccak256(
                abi.encodePacked(
                    cid,
                    to,
                    maxEditions,
                    startTime,
                    endTime,
                    pricePerEdition,
                    mintLimit
                )
            );
    }

    function recoverSigner(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        // Add prefix to message hash as per EIP-191 standard
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        // Recover the address that signed the message using ecrecover
        return ecrecover(prefixedHash, v, r, s);
    }
}