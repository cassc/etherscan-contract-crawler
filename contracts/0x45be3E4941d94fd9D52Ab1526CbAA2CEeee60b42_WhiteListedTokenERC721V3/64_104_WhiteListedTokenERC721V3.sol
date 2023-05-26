// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../ERC721BaseV3.sol";
/**
 * @title RefinableERC721TokenWhiteListed
 * @dev only minters can mint token.

 */
contract WhiteListedTokenERC721V3 is ERC721BaseV3 {
    using ECDSA for bytes32;

    address payable public defaultRoyaltyReceiver = address(0);
    uint256 public defaultRoyaltyReceiverBps = 0;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _root address of admin account
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _baseURI ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _baseURI
    ) public ERC721BaseV3(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(_signature)
            ),
            "invalid signer"
        );

        RoyaltyLibrary.RoyaltyShareDetails[] memory defaultPrimaryRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](1);
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0)
            defaultPrimaryRoyaltyShares[0] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });
        _mint(msg.sender, _tokenId, _royaltyShares, _uri, _royaltyBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY, defaultPrimaryRoyaltyShares);
    }

    function mintSimilarBatch(
        uint256[] memory _tokenIds,
        bytes[] memory _signatures,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string[] memory _uris,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {

        require(_tokenIds.length < 101, "You can only batch mint 100 tokens");

        for(uint i = 0; i < _tokenIds.length; i++) {
            mint(_tokenIds[i], _signatures[i], _royaltyShares, _uris[i], _royaltyBps, _royaltyStrategy, _primaryRoyaltyShares);
        }
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10 ** 4, "ERC721: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}