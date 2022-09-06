//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//
/**
 * @title ABErrors
 * @author Anotherblock Technical Team
 * @notice AnotherblockV1 Custom Errors contract
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ABErrors {
    /**
    @notice Error returned if `royaltySharePerToken` is smaller or equal to 0
    **/
    error InsufficientRoyalties();

    /**
    @notice Error returned if `maxAmountPerAddress` is smaller or equal to 0
    **/
    error InsufficientMaxAmountPerAddress();

    /**
    @notice Error returned if `supply` is smaller or equal to 0
    **/
    error InsufficientSupply();

    /**
    @notice Error returned if `owner` address is the zero address
    **/
    error ZeroAddress();

    /**
    @notice Error returned if the amount deposited is equal to 0
    **/
    error EmptyDeposit();

    /**
    @notice Error returned if attempting to deposit reward for an inexistant drop
    **/
    error DropNotFound();

    /**
    @notice Error returned if the sum of the _amounts in deposit is different than the ETH sent
    **/
    error IncorrectDeposit();

    /**
    @notice Error returned if there is nothing to claim
    **/
    error NothingToClaim();

    /**
    @notice Error returned if an unauthorized address attempt to update the drop details
    **/
    error UnauthorizedUpdate();

    /**
    @notice Error returned if the contract passed as parameters does not implement the expected interface
    **/
    error IncorrectInterface();
}