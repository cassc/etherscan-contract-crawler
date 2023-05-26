// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "openzeppelin-contracts-v4.6.0/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./SorareProxy.sol";

contract GatewayMinterProxy is ERC721Holder, SorareProxy {}