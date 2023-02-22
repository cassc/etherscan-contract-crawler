// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Mintable.sol";

contract Asset is ERC721URIStorage, Mintable {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}

    function _mintFor(
        address user,
        uint256 id,
        bytes memory blueprint
    ) internal override {
        _safeMint(user, id);
        _setTokenURI(id, string(blueprint));
    }

    function contractURI () public view returns (string memory) {
      return "https://metafight.mypinata.cloud/ipfs/QmbbAygiZ2DkCRVBscu1iCTs7TeSoX9MQfdaDgm2qrnyYT";
    }
}