// SPDX-License-Identifier: MIT

pragma solidity >0.6.6;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// CakeToken with Governance.
contract MockERC1155 is ERC1155, Ownable {

    constructor (string memory _uri) ERC1155(_uri) {}

    function mint(address _account, uint _id, uint _amount) external onlyOwner {
        _mint(_account, _id, _amount, new bytes(0));
    }

}