// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC721BaseV2.sol";

/**
 * @title RefinableERC721Token
 * @dev anyone can mint token.
 */
contract RefinableERC721TokenV2 is ERC721BaseV2 {
    using ECDSA for bytes32;

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
    ) public {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender))
                .toEthSignedMessageHash()
                .recover(_signature)
            ),
            "invalid signer"
        );
        _mint(msg.sender, _tokenId, _royaltyShares, _uri, _royaltyBps, _royaltyStrategy);
    }
}