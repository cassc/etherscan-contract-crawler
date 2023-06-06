// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title  OwnerPermissionedTokenRegistry
 * @author James Wenzel (emo.eth)
 * @notice Interface for a generic registry of tokens, where the owner of a token contract (as specified by the Ownable
 *         interface) is allowed to register the token as part of the registry and configure addresses allowed to call
 *         into subclass methods, as permissioned by the onlyTokenOrAllowedUpdater modifier.
 *
 *         This base registry interface includes methods to see if a token is registered, and the allowedUpdaters,
 *         if any, for registered tokens.
 */
interface OwnerPermissionedTokenRegistryInterface {
    error TokenNotRegistered(address tokenAddress);
    error TokenAlreadyRegistered(address tokenAddress);
    error NotAllowedUpdater();
    error NotTokenOrOwner(address token, address actualOwner);

    event TokenRegistered(address indexed tokenAddress);

    function registerToken(address tokenAddress) external;

    function addAllowedUpdater(address tokenAddress, address newAllowedUpdater)
        external;

    function removeAllowedUpdater(
        address tokenAddress,
        address allowedUpdaterToRemove
    ) external;

    function getAllowedUpdaters(address tokenAddress)
        external
        returns (address[] memory);

    function isAllowedUpdater(address tokenAddress, address updater)
        external
        returns (bool);

    function isTokenRegistered(address tokenAddress)
        external
        returns (bool isRegistered);
}