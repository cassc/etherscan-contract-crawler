// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IERC721Mintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ERC721MinterProxy is ERC1967Proxy, Ownable {
    constructor(address implementation) ERC1967Proxy(implementation, "") {}
}