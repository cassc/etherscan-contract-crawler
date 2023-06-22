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
 * @title ERC721ABErrors
 * @author Anotherblock Technical Team
 * @notice ERC721AB Custom Errors contract
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC721ABErrors {
    /**
    @notice Error returned if the drop is sold-out
    **/
    error DropSoldOut();

    /**
    @notice Error returned if the whitelist sale has not started yet
    **/
    error SaleNotStarted();

    /**
    @notice Error returned if user attempt to mint more than allowed by the drop
    **/
    error MaxMintPerAddress();

    /**
    @notice Error returned if the supply is sold out
    **/
    error NotEnoughTokensAvailable();

    /**
    @notice Error returned if user did not send the correct amount of ETH
    **/
    error IncorrectETHSent();

    /**
    @notice Error returned if non-whitelisted user attempts to mint prior to public sale  
    **/
    error NotInMerkle();

    /**
    @notice Error returned if the contract passed as parameters does not implement the expected interface  
    **/
    error IncorrectInterface();

    /**
    @notice Error returned if there are no ETH to withdraw from the contract
    **/
    error NothingToWithdraw();

    /**
    @notice Error returned if the caller is not authorized
    **/
    error Forbidden();

    /**
    @notice Error returned when a ETH transfer failed
    **/
    error TransferFailed();

    /**
    @notice Error returned when a ETH transfer failed
    **/
    error ZeroAddress();

    /**
    @notice Error returned if an uneligible user attempts to mint
    **/
    error NotEligible();

    /**
    @notice Error returned when the requested drop is incorrect
    **/
    error InvalidDrop();
}