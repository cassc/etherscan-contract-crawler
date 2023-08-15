// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface RuleChecker {
    /// @param forwarder - receiving address/contract
    /// @param value - amount of coins
    /// @param dest - destination address, where coins will be sent
    /// @return address - destination address, where coins will be sent
    /// @dev You can return different address, than the one passed as a parameter to override destination address
    /// @return uint256 - amount of coins, that will be sent
    /// @dev You can return different amount of coins, than the one passed as a parameter to override amount of coins that will be sent
    function exec(address forwarder, uint256 value, address dest) external view returns (address, uint256);

    /// @notice Used to validate ERC20 tokens forwarding
    /// @param forwarder - receiving address/contract
    /// @param token - address of ER20 tokens smart contract
    /// @param value - amount of tokens
    /// @param dest - destination address, where tokens will be sent
    /// @return address - destination address, where tokens will be sent
    /// @dev You can return different address, than the one passed as a parameter to override destination address
    /// @return uint256 - amount of tokens, that will be sent
    /// @dev You can return different amount of tokens, than the one passed as a parameter to override amount of coins that will be sent
    function execERC20(address forwarder, address token, uint256 value, address dest)
        external
        view
        returns (address, uint256);

    /// @notice Used to validate ERC721 tokens forwarding
    /// @param forwarder - receiving address/contract
    /// @param token - address of ERC721 tokens smart contract
    /// @param id - token id
    /// @param dest - destination address, where token will be sent
    /// @return address - destination address, where coins will be sent
    /// @dev you can return different address, than the one passed as a parameter to override destination address
    function execERC721(address forwarder, address token, uint256 id, address dest) external view returns (address);

    /// @notice Used to validate ERC1155 tokens forwarding
    /// @param forwarder - receiving address/contract
    /// @param token - address of ERC1155 tokens smart contract
    /// @param id - token id
    /// @param value - amount of tokens
    /// @param dest - destination address, where token will be sent
    /// @return address - destination address, where coins will be sent
    /// @dev you can return different address, than the one passed as a parameter to override destination address
    /// @return uint256 - amount of tokens, that will be sent
    /// @dev You can return different amount of tokens, than the one passed as a parameter to override amount of coins that will be sent
    function execERC1155(address forwarder, address token, uint256 id, uint256 value, address dest)
        external
        view
        returns (address, uint256);
}