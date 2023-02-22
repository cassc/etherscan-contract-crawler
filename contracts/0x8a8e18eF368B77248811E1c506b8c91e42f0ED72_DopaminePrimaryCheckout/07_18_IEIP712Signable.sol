pragma solidity ^0.8.18;

import {IEIP712SignableErrors} from "./IEIP712SignableErrors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title EIP-712 Signable Interface
interface IEIP712Signable is IEIP712SignableErrors {

    /// @notice Returns all EIP-712 metadata pertaining to the contract.
    function EIP712Data() external view returns (
        string memory name,
        string memory version,
        address verifyingContract,
        bytes32 domainSeparator
    );

}