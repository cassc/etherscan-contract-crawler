// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMembershipToken is IERC721{
    function initialize(address _baseTokenAddress)
        external;

    function mint() external;

    function setContractURI(string memory _contractURI) external;

    function setBaseURI(string memory _baseUri) external;
}