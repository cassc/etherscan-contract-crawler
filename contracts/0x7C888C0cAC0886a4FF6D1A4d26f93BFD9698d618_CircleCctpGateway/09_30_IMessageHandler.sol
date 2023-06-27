// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity 0.8.19;

/**
 * @title IMessageHandler
 * @notice Handles messages on destination domain forwarded from
 * an IReceiver
 */
interface IMessageHandler {
    /**
     * @notice handles an incoming message from a Receiver
     * @param _sourceDomain the source domain of the message
     * @param _sender the sender of the message
     * @param _messageBody The message raw bytes
     * @return success bool, true if successful
     */
    function handleReceiveMessage(
        uint32 _sourceDomain,
        bytes32 _sender,
        bytes calldata _messageBody
    ) external returns (bool);
}