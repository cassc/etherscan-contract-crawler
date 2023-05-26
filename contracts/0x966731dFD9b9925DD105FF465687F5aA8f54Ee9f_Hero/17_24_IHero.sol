// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRaidERC721.sol";
import "./IHeroURIHandler.sol";
import "./ISeeder.sol";

interface IHero is IRaidERC721 {
    event HandlerUpdated(address indexed caller, address indexed handler);

    function setHandler(IHeroURIHandler handler) external;

    function getHandler() external view returns (address);

    function getSeeder() external view returns (address);
}