// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "@thirdweb-dev/contracts/base/ERC721Base.sol";

import "@thirdweb-dev/contracts/extension/PrimarySale.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "./SignatureNameMintERC721.sol";

import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";
import {StringUtils} from "./libraries/StringUtils.sol";

contract NFTPersonalNameSignatureCollection17 is
    ERC721Base,
    PrimarySale,
    SignatureNameMintERC721
{
    /*//////////////////////////////////////////////////////////////
                           Name errors
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error AlreadyRegistered();

    /*//////////////////////////////////////////////////////////////
                           Name Registry & records
    //////////////////////////////////////////////////////////////*/

    // mapping for tokenid -> namehash
    mapping(uint256 => bytes32) public names;

    // nameHash -> address
    mapping(bytes32 => address) public domains;

    // nameHash -> records
    mapping(bytes32 => string) public records;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    ) ERC721Base(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        _setupPrimarySaleRecipient(_primarySaleRecipient);
    }

    /*//////////////////////////////////////////////////////////////
                        Signature minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice           Mints tokens according to the provided mint request.
     *
     *  @param _req       The payload / mint request.
     *  @param _signature The signature produced by an account signing the mint request.
     */
    function mintWithSignature(
        MintNameRequest calldata _req,
        bytes calldata _signature
    ) external payable virtual override returns (address signer) {
        require(_req.quantity == 1, "quantiy must be 1");

        uint256 tokenIdToMint = nextTokenIdToMint();

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        address receiver = _req.to;

        if (domains[_req.nameHash] != address(0)) revert AlreadyRegistered();

        require(domains[_req.nameHash] == address(0));

        // Collect price
        _collectPriceOnClaim(
            _req.primarySaleRecipient,
            _req.quantity,
            _req.currency,
            _req.pricePerToken
        );

        // Set royalties, if applicable.
        if (_req.royaltyRecipient != address(0) && _req.royaltyBps != 0) {
            _setupRoyaltyInfoForToken(
                tokenIdToMint,
                _req.royaltyRecipient,
                _req.royaltyBps
            );
        }

        // check name reservation here

        // Mint tokens.
        _setTokenURI(tokenIdToMint, _req.uri);
        _safeMint(receiver, _req.quantity);

        domains[_req.nameHash] = msg.sender;
        names[tokenIdToMint] = _req.nameHash;

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, _req);
    }

    /*//////////////////////////////////////////////////////////////
                            Name Registry functions
    //////////////////////////////////////////////////////////////*/

    // This will give us the domain owners' address
    function getAddress(string calldata nameHashStr) public view returns (address) {
        bytes32 nameHash =  bytes32(abi.encodePacked(nameHashStr));
        return domains[nameHash];
    }

    function valid(string calldata name) public pure returns (bool) {
        return StringUtils.strlen(name) >= 3;
    }

    function setRecord(string calldata nameHashStr, string calldata record) public {
        // Check that the owner is the transaction sender
        bytes32 nameHash =  bytes32(abi.encodePacked(nameHashStr));
        if (msg.sender != domains[nameHash]) revert Unauthorized();
        require(domains[nameHash] == msg.sender);
        records[nameHash] = record;
    }

    function getRecord(string calldata nameHashStr)
        public
        view
        returns (string memory)
    {
        bytes32 nameHash =  bytes32(abi.encodePacked(nameHashStr));
        return records[nameHash];
    }

    /*//////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _canSignMintRequest(address _signer)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return _signer == owner();
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner();
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == totalPrice, "Must send total price.");
        }

        address saleRecipient = _primarySaleRecipient == address(0)
            ? primarySaleRecipient()
            : _primarySaleRecipient;
        CurrencyTransferLib.transferCurrency(
            _currency,
            msg.sender,
            saleRecipient,
            totalPrice
        );
    }
}