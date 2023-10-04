// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../../../DataTypesPeerToPeer.sol";

interface IWrappedERC20Impl {
    event Redeemed(address indexed redeemer, address recipient, uint256 amount);

    /**
     * @notice Initializes the ERC20 wrapper
     * @param minter Address of the minter
     * @param wrappedTokens Array of WrappedERC20TokenInfo
     * @param totalInitialSupply Total initial supply of the wrapped token basket
     * @param name Name of the new wrapper token
     * @param symbol Symbol of the new wrapper token
     */
    function initialize(
        address minter,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata wrappedTokens,
        uint256 totalInitialSupply,
        string calldata name,
        string calldata symbol
    ) external;

    /**
     * @notice Function to redeem wrapped token for underlying tokens
     * @param account Account that is redeeming wrapped tokens
     * @param recipient Account that is receiving underlying tokens
     * @param amount Amount of wrapped tokens to be redeemed
     */
    function redeem(
        address account,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Function to mint wrapped tokens for underlying token
     * @dev This function is only callable when the wrapped token has only one underlying token
     * @param recipient Account that is receiving the minted tokens
     * @param amount Amount of wrapped tokens to be minted
     * @param expectedTransferFee Expected transfer fee for the minted tokens (e.g. wrapping PAXG)
     */
    function mint(
        address recipient,
        uint256 amount,
        uint256 expectedTransferFee
    ) external;

    /**
     * @notice Returns wrapped token addresses
     * @return wrappedTokens array of wrapped token addresses
     */
    function getWrappedTokensInfo()
        external
        view
        returns (address[] calldata wrappedTokens);

    /**
     * @notice Returns whether wrapped token is IOU
     * @return boolean flag indicating whether wrapped token is IOU
     */
    function isIOU() external view returns (bool);
}