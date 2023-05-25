// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.7.1;

import "./IMinter.sol";

// solhint-disable-next-line no-empty-blocks
interface IIQERC20 {
    function mint(address _addr, uint256 _amount) external;

    function burn(address _addr, uint256 _amount) external;

    function setMinter(IMinter _addr) external;

    function minter() external view returns (address);
}