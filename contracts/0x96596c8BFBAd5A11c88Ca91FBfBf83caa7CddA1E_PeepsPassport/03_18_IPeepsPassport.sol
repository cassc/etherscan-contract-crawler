// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Peeps Passport Interface
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://peeps.club

interface IPeepsPassport {
    function burn(address addr, uint32 amount) external;
}