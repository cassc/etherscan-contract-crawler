// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC721BaseV2.sol";
/**
 * @title RefinableERC721TokenWhiteListed
 * @dev only minters can mint token.

 */
contract RefinableERC721WhiteListedTokenV2 is ERC721BaseV2 {
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
    ) public ERC721BaseV2(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy
    ) public onlyMinter {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(_signature)
            ),
            "invalid signer"
        );
        RoyaltyLibrary.RoyaltyShareDetails[] memory newRoyaltyShares;

        //add the default royalties if the contract has set
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0) {
            newRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](_royaltyShares.length + 1);
            for (uint256 i = 0; i < _royaltyShares.length; i++) {
                newRoyaltyShares[i] = _royaltyShares[i];
            }
            newRoyaltyShares[_royaltyShares.length] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });
        } else {
            newRoyaltyShares = _royaltyShares;
        }

        _mint(msg.sender, _tokenId, newRoyaltyShares, _uri, _royaltyBps, _royaltyStrategy);
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10**4, "ERC721: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}