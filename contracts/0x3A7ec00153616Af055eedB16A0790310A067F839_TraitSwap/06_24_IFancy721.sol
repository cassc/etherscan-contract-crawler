// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract IFancy721 is IERC721Enumerable {

    mapping(string => bool) public categoryValidation;
    uint256 public categoryPointer;
    string[] public categories;

    function safeMint(address _to, uint256[] calldata _apeTokenIds) public virtual;
    function tokensInWallet(address _owner) public virtual returns(uint256[] memory);
    function getCategories() public virtual returns (string[] memory);

}