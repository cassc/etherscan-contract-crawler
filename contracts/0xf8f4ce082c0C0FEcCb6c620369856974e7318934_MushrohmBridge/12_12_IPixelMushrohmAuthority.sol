// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

interface IPixelMushrohmAuthority {
    /* ========== EVENTS ========== */

    event OwnerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event OwnerPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    event Paused(address by);
    event Unpaused(address by);

    /* ========== VIEW ========== */

    function owner() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);

    function paused() external view returns (bool);
}