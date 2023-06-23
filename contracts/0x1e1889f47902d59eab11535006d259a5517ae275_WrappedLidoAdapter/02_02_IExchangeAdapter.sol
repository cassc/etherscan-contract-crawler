/*

    Copyright 2022 31Third B.V.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface IExchangeAdapter {
  /**
   * Returns the address to which from tokens for trading have to be approved.
   */
  function getSpender() external view returns (address);

  /**
   * Returns calldata handler, send value, calldata.
   * Verifies calldata against passed trade infos.
   *
   * @param  _from         Address of the token to sell
   * @param  _fromAmount   Amount of the token to sell
   * @param  _to           Address of the token that will be received
   * @param  _minToReceive Minimal amount to receive
   * @param  _taker        Taker of the received value
   * @param  _value        ETH value for this trade
   * @param  _data         Arbitrary call data which is sent to the exchange
   *
   * @return address       Calldata handler contract address
   * @return uint256       Call value
   * @return bytes         Trade calldata
   */
  function getTradeCalldata(
    address _from,
    uint256 _fromAmount,
    address _to,
    uint256 _minToReceive,
    address _taker,
    uint256 _value,
    bytes memory _data
  ) external view returns (address, uint256, bytes memory);
}