// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/interfaces/IERC165.sol';

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC721Metadata.sol';
import '@openzeppelin/contracts/interfaces/IERC721Enumerable.sol';
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol';
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';
import "@openzeppelin/contracts/utils/Counters.sol";

import "../proxy/Proxy.sol";
import "../proxy/Delegate.sol";

//just import it in Layout and Interface contract if needed