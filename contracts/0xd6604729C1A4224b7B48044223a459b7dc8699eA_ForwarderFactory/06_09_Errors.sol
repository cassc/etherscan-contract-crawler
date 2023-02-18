// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

error Unauthorised();
error AlreadyIntialised();
error SinkZeroAddress();
error OwnerZeroAddress();
error ForwarderNativeZeroBalance();
error ForwarderERC20ZeroBalance(address erc20TokenContract);