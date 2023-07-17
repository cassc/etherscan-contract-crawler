// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ZKBridgeErc1155 is ERC1155URIStorage, Ownable {
    constructor() ERC1155("") {

    }

    function mint(address _to, uint256 _id, uint256 _amount, string calldata _uri) external onlyOwner {
        _mint(_to, _id, _amount, "");
        _setURI(_id, _uri);
    }

    function burn(address _from, uint256 _id, uint256 _amount) external onlyOwner {
        _burn(_from, _id, _amount);
    }
}