pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IEIP712SignableErrors} from "./IEIP712SignableErrors.sol";

/// @title EIP-712 Signable Interface
interface IEIP712Signable is IEIP712SignableErrors {

    function EIP712Data() external view returns (
        string memory name,
        string memory version,
        address verifyingContract,
        bytes32 domainSeparator
    );

}