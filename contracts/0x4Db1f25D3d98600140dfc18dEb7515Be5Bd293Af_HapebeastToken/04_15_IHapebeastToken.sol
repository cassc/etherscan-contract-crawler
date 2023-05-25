// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract IHapebeastToken is ERC721 {
    function setProvenanceHash(string memory _provenanceHash) virtual external;
    function setStartingIndex() virtual external;
    function mint(uint256 _count, address _recipient) virtual external;
    function totalSupply() virtual external returns (uint256);
    function updateMinter(address _minter) virtual external;
    function lockMinter() virtual external;
}