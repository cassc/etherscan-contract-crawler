// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import '../utils/IGovernable.sol';
import '../utils/ICollectableDust.sol';
import '../utils/IPausable.sol';

interface IUtilsReady is IGovernable, ICollectableDust, IPausable {
}