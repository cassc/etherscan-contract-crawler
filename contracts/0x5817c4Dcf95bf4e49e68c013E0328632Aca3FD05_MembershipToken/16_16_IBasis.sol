// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBasis is IERC721 {
    function setBaseURI(string memory _baseUri) external;

    function setContractURI(string memory _contractURI) external;

    function totalSupply()
    external
    view
    returns (uint256);
}