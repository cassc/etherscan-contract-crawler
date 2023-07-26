// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libs/ERC4671.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/IMint.sol";

contract DecommBadge is ERC4671, Ownable, IMint {
  uint256 public mintableLimit; // when zero, it means unlimited

  constructor(
        string memory _name,
        string memory _symbol,
        uint256 _mintableLimit
    ) ERC4671(_name, _symbol) {
        mintableLimit = _mintableLimit;
    }

    function mint(address to) external override onlyOwner {
        uint256 newMintId = emittedCount();
        require(mintableLimit == 0 || newMintId < mintableLimit, "Already reached mint limit!");
        _mint(to);
    }

}