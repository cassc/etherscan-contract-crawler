//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IAnomuraEquipment.sol";
import {IAnomuraErrors} from "./IAnomuraErrors.sol";

interface IAnomuraSeeder is IAnomuraErrors
{
    function requestSeed(uint256 _tokenId) external returns(uint256);
}