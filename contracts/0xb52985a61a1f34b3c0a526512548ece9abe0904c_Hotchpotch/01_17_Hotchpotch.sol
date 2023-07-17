// SPDX-License-Identifier: MIT

// ┏┓┏┓╋┏┓╋╋┏┓╋╋╋╋┏┓╋╋┏┓
// ┃┗┛┣━┫┗┳━┫┗┳━┳━┫┗┳━┫┗┓
// ┃┏┓┃╋┃┏┫━┫┃┃╋┃╋┃┏┫━┫┃┃
// ┗┛┗┻━┻━┻━┻┻┫┏┻━┻━┻━┻┻┛
// ╋╋╋╋╋╋╋╋╋╋╋┗┛
//
// m1nm1n & Co.
// https://m1nm1n.com/

pragma solidity ^0.8.9;

import "./tokens/ERC1155Base.sol";

contract Hotchpotch is ERC1155Base {
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseMetadataURI
  ) ERC1155Base(_name, _symbol, _baseMetadataURI) {}
}