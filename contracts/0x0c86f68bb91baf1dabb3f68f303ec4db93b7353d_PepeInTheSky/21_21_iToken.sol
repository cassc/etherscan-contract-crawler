// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {iDescriptorMinimal} from "./iDescriptorMinimal.sol";
import {iSeeder} from "./iSeeder.sol";

interface iToken {
    event DescriptorUpdated(iDescriptorMinimal descriptor);
    event DescriptorLocked();
    event SeederUpdated(iSeeder seeder);
    error IncorrectPrice();
    error NotUser();
    error InvalidSaleState();
    error ZeroAddress();
    error LimitExceed();
    error SoldOut();
    error IncorrectSignature();
    error ReservedExceeded();
    error NotOpen();
    error NotOwner();
}