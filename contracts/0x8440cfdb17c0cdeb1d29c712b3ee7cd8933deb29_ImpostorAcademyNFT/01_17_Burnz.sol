// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@imtbl/imx-contracts/contracts/Mintable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@imtbl/imx-contracts/contracts/utils/Minting.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract ImpostorAcademyNFT is IMintable, ERC721, Ownable {

    string public baseURI;
    using SafeMath for uint;
    address public imx;
    
    event tokenMinted(address to, uint tokenID, bytes blueprint);
    mapping (uint => bytes) public minting;

    constructor(address _imx) ERC721('YagaSDK: Impostor Academy NFT', 'YIA') {
        imx = _imx;
    }

    function mintFor(address to, uint256 quantity, bytes calldata mintingBlob) external override {
        require(quantity == 1, "Not more than 1");
        (uint id, bytes memory blueprint) = Minting.split(mintingBlob);
        minting[id] = blueprint;
        tokenMint(to, id);
        emit tokenMinted(to, id, blueprint);
    }

    function tokenMint(address _to, uint tokenId) internal {
        /* checking will be done in the backend */
        _safeMint(_to, tokenId);
        // _setTokenURI(tokenId, uint2str(tokenId)); 
    }

    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
      require(_exists(tokenId), "ERC721Metadata: query for nonexistent token");
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    } 

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
}