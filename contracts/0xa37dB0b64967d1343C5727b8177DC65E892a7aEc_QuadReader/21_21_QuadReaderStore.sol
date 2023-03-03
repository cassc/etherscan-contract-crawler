//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IQuadPassport.sol";
import "../interfaces/IQuadGovernance.sol";

import "./QuadConstant.sol";

contract QuadReaderStore is QuadConstant{
    IQuadGovernance public governance;
    IQuadPassport public passport;
}