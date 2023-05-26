// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC1155Base.sol";
import "../../roles/MinterRole.sol";

contract RefinableERC1155WhiteListedToken is ERC1155Base, MinterRole {

    using ECDSA for bytes32;

    string public name;
    string public symbol;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(string memory _name, string memory _symbol, address _signer, string memory _contractURI, string memory _tokenURIPrefix, string memory _uri) ERC1155Base(_contractURI, _tokenURIPrefix, _uri) public {
        name = _name;
        symbol = _symbol;

        addSigner(_msgSender());
        addSigner(_signer);
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    function mint(uint256 _tokenId, bytes memory _signature, Fee[] memory _fees, uint256 _supply, string memory _uri) public onlyMinter {
        require(
            hasRole(SIGNER_ROLE,
            keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
            .toEthSignedMessageHash()
            .recover(_signature)
            )
        ,"invalid signature"
        );
        _mint(_tokenId, _fees, _supply, _uri);
    }
}