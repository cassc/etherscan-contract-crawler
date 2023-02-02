// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;
interface IPSM {
    function gemJoin() external view returns (address);
    function tin() external view returns (uint256);
    function tout() external view returns (uint256);
    function sellGem(address _to, uint256 _amount) external;
    function buyGem(address _to, uint256 _amount) external;
}