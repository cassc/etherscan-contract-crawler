// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/utils/Counters.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "./IAvatar.sol";

/**
 * @title Grand Leisure Avatar
 * @author Poolsuite
 */
contract Avatar is IAvatar, ERC721, Ownable, Pausable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    /**
     * @dev Emitted when reservation is purchased by `to`
     */
    event ReserveAvatar(address indexed to);

    /**
     * @dev Event for setting baseURI
     */
    event SetBaseUri(string newBaseUri);

    /**
     * @dev Event for setting signature address
     */
    event SetSignatureAddress(address newSignatureAddress);

    /**
     * @dev Event for setting withdraw address
     */
    event SetWithdrawAddress(address newWithdrawAddress);

    /**
     * @dev Event for withdrawing
     */
    event Withdraw();

    address public signatureAddress;

    address payable public withdrawAddress;

    uint256 internal constant _MAX_SUPPLY = 10000;

    Counters.Counter internal _tokenIds;

    /**
     * @dev Mapping from token id to configuration bit mapping
     */
    mapping(uint256 => uint256) internal _tokenIdToConfiguration;

    /**
     * @dev Mapping from configuration bit mapping to token id
     */
    mapping(uint256 => uint256) internal _configurationToTokenId;

    /**
     * @dev Mapping from address to boolean indicating if avatar is reserved
     */
    mapping(address => bool) internal _reservations;

    /**
     * @dev Base URI for token metadata
     */
    string internal _baseURIExtended;

    constructor(
        address sigAddress,
        address payable withdrawAddress_,
        string memory baseURIExtended_
    ) ERC721("Grand Leisure", "GRANDLEISURE") {
        signatureAddress = sigAddress;
        emit SetSignatureAddress(signatureAddress);

        withdrawAddress = withdrawAddress_;
        emit SetWithdrawAddress(withdrawAddress);

        _baseURIExtended = baseURIExtended_;
        emit SetBaseUri(_baseURIExtended);
    }

    function ownerOf(uint256 avatarId)
        public
        view
        override(IAvatar, ERC721)
        returns (address)
    {
        return super.ownerOf(avatarId);
    }

    function mintAvatar(
        bytes memory signature,
        uint256 signatureExpiration,
        uint256 price,
        uint256 desiredConfiguration
    ) external payable whenNotPaused returns (uint256) {
        require(
            _verifySignature(
                keccak256(
                    abi.encodePacked(
                        "GrandLeisureMintApproval",
                        msg.sender,
                        signatureExpiration,
                        price,
                        desiredConfiguration,
                        block.chainid
                    )
                ),
                signature
            ),
            "The mint signature is invalid"
        );

        require(
            signatureExpiration > block.timestamp,
            "The signature is expired"
        );

        require(
            msg.value == price,
            "The avatar price does not match the amount paid"
        );

        require(
            _tokenIds.current() < _MAX_SUPPLY,
            "The avatar supply limit has been reached"
        );

        require(
            _configurationToTokenId[desiredConfiguration] == uint256(0),
            "An avatar already exists with this configuration"
        );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);

        if (_reservations[msg.sender]) {
            _reservations[msg.sender] = false;
        }
        _tokenIdToConfiguration[newItemId] = desiredConfiguration;
        _configurationToTokenId[desiredConfiguration] = newItemId;

        return newItemId;
    }

    function reserveAvatar(
        bytes memory signature,
        uint256 signatureExpiration,
        uint256 price
    ) external payable whenNotPaused returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "GrandLeisureReservationApproval",
                msg.sender,
                signatureExpiration,
                price,
                block.chainid
            )
        );

        require(
            _verifySignature(digest, signature),
            "The reservation signature is invalid"
        );

        require(
            signatureExpiration > block.timestamp,
            "The signature is expired"
        );

        require(
            msg.value == price,
            "The reservation price does not match the amount paid"
        );

        require(
            !_reservations[msg.sender],
            "You have already reserved an avatar"
        );

        require(
            _tokenIds.current() < (_MAX_SUPPLY),
            "The avatar supply limit has been reached"
        );

        _reservations[msg.sender] = true;
        emit ReserveAvatar(msg.sender);
        return true;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    function setBaseURI(string memory baseURI_)
        external
        onlyOwner
        returns (string memory)
    {
        _baseURIExtended = baseURI_;
        emit SetBaseUri(baseURI_);
        return _baseURIExtended;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function updateSignatureAddress(address newSignatureAddress)
        external
        onlyOwner
    {
        signatureAddress = newSignatureAddress;
        emit SetSignatureAddress(signatureAddress);
    }

    function _verifySignature(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 signedHash = hash.toEthSignedMessageHash();

        (address signedHashAddress, ECDSA.RecoverError error) = signedHash
            .tryRecover(signature);

        if (error == ECDSA.RecoverError.NoError) {
            return signedHashAddress == signatureAddress;
        } else {
            return false;
        }
    }

    function updateWithdrawAddress(address payable newWithdrawAddress)
        external
        onlyOwner
    {
        withdrawAddress = newWithdrawAddress;
        emit SetWithdrawAddress(withdrawAddress);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(withdrawAddress, address(this).balance);
        emit Withdraw();
    }

    function hasReservation(address _owner) external view returns (bool) {
        return _reservations[_owner];
    }

    function tokenByConfiguration(uint256 configuration)
        external
        view
        returns (uint256)
    {
        return _configurationToTokenId[configuration];
    }

    function configurationByToken(uint256 token)
        external
        view
        returns (uint256)
    {
        return _tokenIdToConfiguration[token];
    }

    function freeze() external onlyOwner {
        _pause();
    }

    function unfreeze() external onlyOwner {
        _unpause();
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }
}