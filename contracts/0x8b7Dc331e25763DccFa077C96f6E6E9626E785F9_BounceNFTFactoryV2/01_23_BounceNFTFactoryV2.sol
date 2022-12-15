// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./BounceERC721V2.sol";
import "./BounceERC1155V2.sol";

contract BounceNFTFactoryV2 {

    event Brand721Created(address indexed user, address nft);
    event Brand1155Created(address indexed user, address nft);

    mapping(address => address) public brands;

    function createBrand721(bytes calldata creationCode, string calldata _uri, string calldata _name, string calldata _symbol, uint _mode) external {
        bytes memory bytecode = abi.encodePacked(creationCode, abi.encode(_name, _symbol, _mode));
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number, _name, _symbol, _mode));
        address nft = Create2.deploy(0, salt, bytecode);
        BounceERC721V2(nft).setBaseURI(string(abi.encodePacked(_uri, addressToString(nft), "/")));
        BounceERC721V2(nft).transferOwnership(msg.sender);
        emit Brand721Created(msg.sender, nft);
    }

    function createBrand1155(bytes calldata creationCode, string calldata _uri, uint _mode) external {
        bytes memory bytecode = abi.encodePacked(creationCode, abi.encode(_uri, _mode));
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number, _uri, _mode));
        address nft = Create2.deploy(0, salt, bytecode);
        BounceERC1155V2(nft).transferOwnership(msg.sender);
        emit Brand1155Created(msg.sender, nft);
    }

    function addressToString(address account) public pure returns(string memory) {
        return toStringRaw(abi.encodePacked(account));
    }

    function toStringRaw(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}