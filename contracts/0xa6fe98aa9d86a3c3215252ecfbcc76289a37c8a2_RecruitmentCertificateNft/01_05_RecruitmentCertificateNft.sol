// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RecruitmentCertificateNft is ERC721A, Ownable {


    string private baseTokenURI;

    mapping(address => uint256[]) public tokenIdByAddress;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(string memory baseUri) ERC721A("RECRUITMENT CERTIFICATE by ZeroCorp", "ZRECRUITS") {
      baseTokenURI = baseUri;
    }

    function mint() external callerIsUser {
      tokenIdByAddress[msg.sender].push(_nextTokenId());
      _mint(msg.sender, 1);
    }

    function getOwnedTokens(address owner) external view returns(uint256[] memory) {
      return tokenIdByAddress[owner];
    }

    //URI to metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _newTokenURI) external onlyOwner {
        baseTokenURI = _newTokenURI;
    }

    function _startTokenId() internal view virtual override returns(uint256) {
      return 1;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A) returns (bool) {
      return ERC721A.supportsInterface(interfaceId);
    }
}