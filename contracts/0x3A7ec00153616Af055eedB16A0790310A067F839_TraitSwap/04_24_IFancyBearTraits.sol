// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract IFancyBearTraits is IERC1155 {

    struct Trait {
        string name;
        string category;
        uint256 honeyConsumptionRequirement;
        bool set;
    }

    mapping(uint256 => Trait) public traits;

    mapping(string => bool) public categoryValidation;
    uint256 public categoryPointer;
    string[] public categories;
    function getTrait(uint256 _tokenId) public virtual returns (string memory, string memory, uint256);
    function getCategories() public virtual returns (string[] memory);
    function mint(address _account, uint256 _id, uint256 _amount, bytes memory _data) public virtual;
    function mintBatch(address _account, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) public virtual;
}