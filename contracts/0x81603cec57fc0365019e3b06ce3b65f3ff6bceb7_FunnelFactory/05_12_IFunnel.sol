// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC5827 } from "./IERC5827.sol";
import { IERC5827Payable } from "./IERC5827Payable.sol";
import { IERC5827Proxy } from "./IERC5827Proxy.sol";

/// @title Interface for Funnel contracts for ERC20
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IFunnel is IERC5827, IERC5827Proxy, IERC5827Payable {
    /// @dev Invalid selector returned
    error InvalidReturnSelector();

    /// @dev Error thrown when attempting to transfer to a non IERC1363Receiver
    error NotIERC1363Receiver();

    /// @dev Error thrown when attempting to transfer to a non IERC5827Spender
    error NotIERC5827Spender();

    /// @dev Error thrown if the Recovery Rate exceeds the max allowance
    error RecoveryRateExceeded();

    /// @notice Called when the contract is being initialised.
    /// @param _token contract address of the underlying ERC20 token
    /// @dev Sets the INITIAL_CHAIN_ID and INITIAL_DOMAIN_SEPARATOR that might be used in future permit calls
    function initialize(address _token) external;
}