// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Detailed} from "./../interfaces/IERC20Detailed.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC20DetailedStorage {
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;
    using ERC20DetailedStorage for ERC20DetailedStorage.Layout;

    struct Layout {
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimals;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.token.ERC20.ERC20Detailed.storage")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.core.token.ERC20.ERC20Detailed.phase")) - 1);

    /// @notice Initializes the storage with the token details (immutable version).
    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Detailed.
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @param tokenName The token name.
    /// @param tokenSymbol The token symbol.
    /// @param tokenDecimals The token decimals.
    function constructorInit(Layout storage s, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) internal {
        s.tokenName = tokenName;
        s.tokenSymbol = tokenSymbol;
        s.tokenDecimals = tokenDecimals;
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Detailed).interfaceId, true);
    }

    /// @notice Initializes the storage with the token details (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Detailed.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @param tokenName The token name.
    /// @param tokenSymbol The token symbol.
    /// @param tokenDecimals The token decimals.
    function proxyInit(Layout storage s, string calldata tokenName, string calldata tokenSymbol, uint8 tokenDecimals) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.tokenName = tokenName;
        s.tokenSymbol = tokenSymbol;
        s.tokenDecimals = tokenDecimals;
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Detailed).interfaceId, true);
    }

    /// @notice Gets the name of the token. E.g. "My Token".
    /// @return tokenName The name of the token.
    function name(Layout storage s) internal view returns (string memory tokenName) {
        return s.tokenName;
    }

    /// @notice Gets the symbol of the token. E.g. "TOK".
    /// @return tokenSymbol The symbol of the token.
    function symbol(Layout storage s) internal view returns (string memory tokenSymbol) {
        return s.tokenSymbol;
    }

    /// @notice Gets the number of decimals used to display the balances.
    /// @notice For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5,05` (`505 / 10 ** 2`).
    /// @notice Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei.
    /// @dev Note: This information is only used for display purposes: it does  not impact the arithmetic of the contract.
    /// @return nbDecimals The number of decimals used to display the balances.
    function decimals(Layout storage s) internal view returns (uint8 nbDecimals) {
        return s.tokenDecimals;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}