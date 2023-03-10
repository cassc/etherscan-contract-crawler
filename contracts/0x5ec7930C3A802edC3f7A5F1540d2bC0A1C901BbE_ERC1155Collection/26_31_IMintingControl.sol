// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

interface IMintingControl {
    function isPublic() external returns (bool);

    function isMinter(address account) external view returns (bool);
}