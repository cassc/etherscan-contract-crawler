// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOevDataFeedServer.sol";
import "./IDapiServer.sol";

interface IOevDapiServer is IOevDataFeedServer, IDapiServer {}