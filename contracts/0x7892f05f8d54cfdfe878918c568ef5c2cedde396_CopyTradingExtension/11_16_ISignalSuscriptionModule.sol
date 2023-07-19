/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
import {IJasperVault} from "./IJasperVault.sol";

interface ISignalSuscriptionModule {
    function subscribe(IJasperVault _jasperVault, address target) external;

    function unsubscribe(IJasperVault _jasperVault, address target) external;

    function unsubscribeByMaster(address target) external;

    function exectueFollowStart(address _jasperVault) external;
    function exectueFollowEnd(address _jasperVault) external;
    
    function isExectueFollow(address _jasperVault) external view returns (bool);
  
    function warningLine() external view returns(uint256);

    function unsubscribeLine() external view returns(uint256);

    function handleFee(IJasperVault _jasperVault) external;

    function handleResetFee(IJasperVault _target,IJasperVault _jasperVault,address _token,uint256 _amount) external;

    function mirrorToken() external view returns(address);

    function udpate_allowedCopytrading(
        IJasperVault _jasperVault, 
        bool can_copy_trading
    ) external;

    function get_followers(address target)
        external
        view
        returns (address[] memory);

    function get_signal_provider(IJasperVault _jasperVault)
        external
        view
        returns (address);
}