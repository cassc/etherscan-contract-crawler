// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC721Base.sol";
import "../../roles/SignerRole.sol";
import "../../libs/Ownable.sol";

/**
 * @title RefinableERC721Token
 * @dev anyone can mint token.
 */
contract RefinableERC721Token is
    IERC721,
    IERC721Metadata,
    ERC721Burnable,
    ERC721Base,
    SignerRole,
    Ownable
{
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
    ) public ERC721Base(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
        _registerInterface(bytes4(keccak256("MINT_WITH_ADDRESS")));
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        Fee[] memory _fees,
        string memory _tokenURI
    ) public {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(_signature)
            ),
            "invalid signer"
        );
        _mint(msg.sender, _tokenId, _fees);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        _setContractURI(_contractURI);
    }
}