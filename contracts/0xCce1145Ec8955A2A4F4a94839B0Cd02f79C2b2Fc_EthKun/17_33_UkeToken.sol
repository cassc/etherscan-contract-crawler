// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";
//import 'base64-sol/base64.sol';


contract UkeToken is ERC20, Ownable {

    uint256 public constant START_TOKEN_SUPPLY = 420;

    constructor() ERC20 ("UkeToken", "UKE") {
      _mint(msg.sender, START_TOKEN_SUPPLY);
    }

    function decimals() public view virtual override returns (uint8) {
      return 16;
    }

    function mintAdmin(address to, uint256 tokenCount) external onlyOwner {
        _mint(to, tokenCount);
    }
}