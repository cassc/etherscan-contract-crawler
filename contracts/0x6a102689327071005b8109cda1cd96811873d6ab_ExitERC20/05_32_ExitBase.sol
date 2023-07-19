// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IExitBase.sol";

abstract contract ExitBase is Module, IExitBase, IERC165 {
    // @notice Mapping of denied tokens defined by the avatar
    mapping(address => bool) public deniedTokens;

    function getExitAmount(uint256 supply, bytes memory params)
        internal
        view
        virtual
        returns (uint256);

    // @dev Execute the share of assets and the transfer of designated tokens
    // @param tokens Array of tokens to claim, ordered lowest to highest
    // @param params used to calculate the exit amount per token
    // @notice Will revert if tokens[] is not ordered highest to lowest, contains duplicates, or includes denied tokens
    function _exit(address[] memory tokens, bytes memory params) internal {
        if (avatar.balance > 0) {
            transferNativeAsset(
                msg.sender,
                getExitAmount(avatar.balance, params)
            );
        }

        address previousToken;
        uint256 avatarTokenBalance;
        for (uint8 i = 0; i < tokens.length; i++) {
            require(!deniedTokens[tokens[i]], "Denied token");
            require(
                tokens[i] > previousToken,
                "tokens[] is out of order or contains a duplicate"
            );
            avatarTokenBalance = ERC20(tokens[i]).balanceOf(avatar);
            transferToken(
                tokens[i],
                msg.sender,
                getExitAmount(avatarTokenBalance, params)
            );
            previousToken = tokens[i];
        }

        emit ExitSuccessful(msg.sender);
    }

    // @dev Execute a token transfer through the avatar
    // @param token address of token to transfer
    // @param to address that will receive the transfer
    // @param amount to transfer
    function transferToken(
        address token,
        address to,
        uint256 amount
    ) private {
        // 0xa9059cbb - bytes4(keccak256("transfer(address,uint256)"))
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, to, amount);
        require(
            exec(token, 0, data, Enum.Operation.Call),
            "Error on token transfer"
        );
    }

    // @dev Execute a token transfer through the avatar
    // @param to address that will receive the transfer
    // @param amount to transfer
    function transferNativeAsset(address to, uint256 amount) private {
        require(
            exec(to, amount, bytes("0x"), Enum.Operation.Call),
            "Error on native asset transfer"
        );
    }

    // @dev Add a batch of token addresses to denied tokens list
    // @param tokens Batch of addresses to add into the denied token list
    // @notice Can not add duplicate token address or it will throw
    // @notice Can only be modified by owner
    function addToDenyList(address[] calldata tokens) external onlyOwner {
        for (uint8 i; i < tokens.length; i++) {
            require(!deniedTokens[tokens[i]], "Token already denied");
            deniedTokens[tokens[i]] = true;
        }
    }

    // @dev Remove a batch of token addresses from denied tokens list
    // @param tokens Batch of addresses to be removed from the denied token list
    // @notice If a non-denied token address is passed, the function will throw
    // @notice Can only be modified by owner
    function removeFromDenyList(address[] calldata tokens) external onlyOwner {
        for (uint8 i; i < tokens.length; i++) {
            require(deniedTokens[tokens[i]], "Token not denied");
            deniedTokens[tokens[i]] = false;
        }
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        override
        returns (bool)
    {
        return interfaceID == 0x01ffc9a7 || interfaceID == 0xaf20af8a;
    }
}