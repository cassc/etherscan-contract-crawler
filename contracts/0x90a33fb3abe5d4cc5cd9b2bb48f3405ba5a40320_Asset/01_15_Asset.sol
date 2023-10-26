// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Mintable.sol";

contract Asset is ERC721, Mintable {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}

    function _mintFor(
        address user,
        uint256 id,
        bytes calldata blueprint
    ) internal override {
        _safeMint(user, id);
    }

//    function mintFor(
//        address user,
//        uint256 quantity,
//        bytes calldata mintingBlob
//    ) external override onlyOwnerOrIMX {
//        require(quantity == 1, "Mintable: invalid quantity");
//        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
//        _mintFor(user, id, blueprint);
//        blueprints[id] = blueprint;
//        emit AssetMinted(user, id, blueprint);
//    }
}