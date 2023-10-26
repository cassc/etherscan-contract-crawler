// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract TMI is ERC1155PresetMinterPauser {

    string public baseURI;

    constructor(string memory _baseURI) ERC1155PresetMinterPauser(string.concat(_baseURI, "{id}")) {
        baseURI = _baseURI;
    }

    function contractURI() public view returns (string memory) {
        return string.concat(baseURI, "contract");
    }

    function setBaseURI(string memory newBaseURI) public {
        baseURI = newBaseURI;
        _setURI(string.concat(newBaseURI, "{id}"));
    }

    function mint(address account, uint256 id, uint256, bytes memory) public override {
        require(hasRole(MINTER_ROLE, msg.sender) && balanceOf(account, id) == 0);
        _mint(account, id, 1, "");
    }
}