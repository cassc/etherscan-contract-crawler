// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../../../DataTypesPeerToPeer.sol";

interface IWrappedERC721Impl {
    event Redeemed(address indexed redeemer, address recipient);

    event TransferFromWrappedTokenFailed(
        address indexed tokenAddr,
        uint256 indexed tokenId
    );

    event TokenSweepAttempted(address indexed tokenAddr, uint256[] tokenIds);

    /**
     * @notice Initializes the ERC20 wrapper
     * @param minter Address of the minter
     * @param tokensToBeWrapped Array of token info (address and ids array) for the tokens to be wrapped
     * @param name Name of the new wrapper token
     * @param symbol Symbol of the new wrapper token
     */
    function initialize(
        address minter,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped,
        string calldata name,
        string calldata symbol
    ) external;

    /**
     * @notice Transfers any stuck wrapped tokens to the redeemer
     * @param tokenAddr Address of the token to be swept
     * @param tokenIds Array of token ids to be swept
     */
    function sweepTokensLeftAfterRedeem(
        address tokenAddr,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @notice Function to redeem wrapped token for underlying tokens
     * @param account Account that is redeeming wrapped tokens
     * @param recipient Account that is receiving underlying tokens
     */
    function redeem(address account, address recipient) external;

    /**
     * @notice Function to remint wrapped token for underlying tokens
     * @param _wrappedTokensForRemint Array of token info (address and ids array) for the tokens to be reminted
     * @param recipient Account that is receiving the reminted ERC20 token
     */
    function remint(
        DataTypesPeerToPeer.WrappedERC721TokenInfo[]
            calldata _wrappedTokensForRemint,
        address recipient
    ) external;

    /**
     * @notice Function to sync the wrapper state with the underlying tokens
     * @dev This function is callable by anyone and can sync back up accounting.
     * e.g. in case of transfer occurring outside remint function directly to wrapped token address
     * @param tokenAddr Address of the token to be synced
     * @param tokenId Id of the token to be synced
     */
    function sync(address tokenAddr, uint256 tokenId) external;

    /**
     * @notice Returns wrapped token info
     * @return wrappedTokens array of struct containing information about wrapped tokens
     */
    function getWrappedTokensInfo()
        external
        view
        returns (
            DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata wrappedTokens
        );

    /**
     * @notice Returns the total and current number of tokens in the wrapper
     * @return Array of total and current number of tokens in the wrapper, respectively
     */
    function getTotalAndCurrentNumOfTokensInWrapper()
        external
        view
        returns (uint128[2] memory);

    /**
     * @notice Returns the address of the last redeemer
     * @return Address of the last redeemer
     */
    function lastRedeemer() external view returns (address);

    /**
     * @notice Returns stuck token status
     * @param tokenAddr Address of the token to be checked
     * @param tokenId Id of the token to be checked
     * @return Returns true if the token is stuck, false otherwise
     */
    function stuckTokens(
        address tokenAddr,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Returns token currently counted in wrapper status
     * @param tokenAddr Address of the token to be checked
     * @param tokenId Id of the token to be checked
     * @return Returns true if the token is currently counted in the wrapper, false otherwise
     */
    function isTokenCountedInWrapper(
        address tokenAddr,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Returns whether token is an underlying member of the wrapper
     * @param tokenAddr Address of the token to be checked
     * @param tokenId Id of the token to be checked
     * @return Returns true if the token is an underlying member of the wrapper, false otherwise
     */
    function isUnderlying(
        address tokenAddr,
        uint256 tokenId
    ) external view returns (bool);
}