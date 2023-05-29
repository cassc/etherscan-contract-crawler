// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "../../tokens/ERC20/IERC20.sol";

/// @title Rigo Token Interface - Allows interaction with the Rigo token.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoToken is IERC20 {
    /// @notice Emitted when new tokens have been minted.
    /// @param recipient Address receiving the new tokens.
    /// @param amount Number of minted units.
    event TokenMinted(address indexed recipient, uint256 amount);

    /// @notice Returns the address of the minter.
    /// @return Address of the minter.
    function minter() external view returns (address);

    /// @notice Returns the address of the Rigoblock Dao.
    /// @return Address of the Dao.
    function rigoblock() external view returns (address);

    /// @notice Allows minter to create new tokens.
    /// @dev Mint method is reserved for minter module.
    /// @param recipient Address receiving the new tokens.
    /// @param amount Number of minted tokens.
    function mintToken(address recipient, uint256 amount) external;

    /// @notice Allows Rigoblock Dao to update minter.
    /// @param newAddress Address of the new minter.
    function changeMintingAddress(address newAddress) external;

    /// @notice Allows Rigoblock Dao to update its address.
    /// @param newAddress Address of the new Dao.
    function changeRigoblockAddress(address newAddress) external;
}