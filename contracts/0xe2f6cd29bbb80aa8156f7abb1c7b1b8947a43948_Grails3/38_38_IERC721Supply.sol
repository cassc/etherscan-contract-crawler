// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.10 <0.9.0;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IERC721Supply is IERC721 {
    function totalSupply() external view returns (uint256);
}