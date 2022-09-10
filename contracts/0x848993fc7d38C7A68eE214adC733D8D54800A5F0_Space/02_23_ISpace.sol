// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@chainlink/contracts/src/v0.8/vendor/Strings.sol";


interface ISpace is IERC1155, IERC1155MetadataURI {

    event SpaceCreated(string name, string uri, address indexed owner);

    event AttributeMinted(address indexed to, uint256 indexed attributeId);

    event AttributeAdded(uint256 indexed attributeId, string name, uint256 cost, uint256 supply);

    event AttributeEndorsed(address indexed from, address indexed to, uint256 indexed attributeId);

    event AttributeLinked(address indexed to, uint256 indexed attributeId);

    function mint(uint256 attributeId) external payable;

    function endorse(uint256 attributeId, address to) external;

    function link(uint256 attributeId) external;

    function isLinked(address account, uint256 id) external view returns (bool);

    function addAttribute(string memory name, uint256 cost, uint256 supply) external;

    function getAttribute(uint256 attributeId) external view returns (string memory name, uint256 cost, uint256 supply);

    function getSpaceName() external view returns (string memory);

}