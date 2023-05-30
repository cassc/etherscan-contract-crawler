// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
              ________________       _,.......,_        
          .nNNNNNNNNNNNNNNNNP’  .nnNNNNNNNNNNNNnn..
         ANNC*’ 7NNNN|’’’’’’’ (NNN*’ 7NNNNN   `*NNNn.
        (NNNN.  dNNNN’        qNNN)  JNNNN*     `NNNn
         `*@*’  NNNNN         `*@*’  dNNNN’     ,ANNN)
               ,NNNN’  ..-^^^-..     NNNNN     ,NNNNN’
               dNNNN’ /    .    \   .NNNNP _..nNNNN*’
               NNNNN (    /|\    )  NNNNNnnNNNNN*’
              ,NNNN’ ‘   / | \   ’  NNNN*  \NNNNb
              dNNNN’  \  \'.'/  /  ,NNNN’   \NNNN.
              NNNNN    '  \|/  '   NNNNC     \NNNN.
            .JNNNNNL.   \  '  /  .JNNNNNL.    \NNNN.             .
          dNNNNNNNNNN|   ‘. .’ .NNNNNNNNNN|    `NNNNn.          ^\Nn
                           '                     `NNNNn.         .NND
                                                  `*NNNNNnnn....nnNP’
                                                     `*@NNNNNNNNN**’
I see you nerd! ⌐⊙_⊙
*/

contract TORAlbums is ERC1155, Ownable, ERC1155Supply {
    using ECDSA for bytes32;
    using Strings for uint256;

    IERC721 public vipPassContractInstance;

    IERC721 public torContractInstance;

    bool public mintingIsActive = false;

    // Used to validate albums
    address private _signerAddress = 0xB44b7e7988A225F8C479cB08a63C04e0039B53Ff;

    // Mapping from VIP pass token ID to whether it has been claimed or not
    mapping(uint256 => bool) public claimed;

    string public name = "TOR Albums";
    string public symbol = "TORALBUMS";
    string public baseURI;

    constructor(string memory baseURL, address vipPassContractAddress, address torContractAddress) ERC1155("") {
        vipPassContractInstance = IERC721(vipPassContractAddress);
        torContractInstance = IERC721(torContractAddress);
        baseURI = baseURL;
    }

    function hashAlbumId(uint256 torToken, uint256 id) public pure returns (bytes32) {
        return keccak256(abi.encode(
            torToken,
            id
        ));
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /*
    * Pause minting if active, make active if paused.
    */
    function flipMintingState() public onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    function setAddresses(address vipPassContractAddress, address torContractAddress, address newSignerAddress) public onlyOwner {
        vipPassContractInstance = IERC721(vipPassContractAddress);
        torContractInstance = IERC721(torContractAddress);
        _signerAddress = newSignerAddress;
    }

    function mintViaClaim(uint256 vipPassToken, uint256 torToken, uint256 id, bytes memory signature) public {
        require(mintingIsActive, 'Minting not live');
        require(vipPassContractInstance.ownerOf(vipPassToken) == msg.sender, 'Not owner of VIP');
        require(torContractInstance.ownerOf(torToken) == msg.sender, 'Not owner of TOR');
        require(! claimed[vipPassToken], 'Already claimed');
        require(_signerAddress == hashAlbumId(torToken, id).toEthSignedMessageHash().recover(signature), "Invalid signature");

        claimed[vipPassToken] = true;
        _mint(msg.sender, id, 1, "");
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function reserveMint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function reserveMintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}