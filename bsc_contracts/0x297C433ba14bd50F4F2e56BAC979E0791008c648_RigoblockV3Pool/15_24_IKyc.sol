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

/// @title KycFace - allows interaction with a Kyc provider.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IKyc {
    /// @notice Returns whether an address has been whitelisted.
    /// @param user The address to verify.
    /// @return Bool the user is whitelisted.
    function isWhitelistedUser(address user) external view returns (bool);
}