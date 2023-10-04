// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../../../DataTypesPeerToPeer.sol";

interface IERC721Wrapper {
    event ERC721WrapperCreated(
        address indexed newErc20Addr,
        address indexed minter,
        uint256 numTokensCreated,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] wrappedTokensInfo
    );

    /**
     * @notice Allows user to wrap (multiple) ERC721 into one ERC20
     * @param minter Address of the minter
     * @param tokensToBeWrapped Array of WrappedERC721TokenInfo
     * @param name Name of the new wrapper token
     * @param symbol Symbol of the new wrapper token
     */
    function createWrappedToken(
        address minter,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped,
        string calldata name,
        string calldata symbol
    ) external returns (address);

    /**
     * @notice Returns address registry
     * @return address registry
     */
    function addressRegistry() external view returns (address);

    /**
     * @notice Returns implementation contract address
     * @return implementation contract address
     */
    function wrappedErc721Impl() external view returns (address);

    /**
     * @notice Returns array of tokens created
     * @return array of tokens created
     */
    function allTokensCreated() external view returns (address[] memory);

    /**
     * @notice Returns the address of a token created by index
     * @param idx the index of the token
     * @return address of the token created
     */
    function tokensCreated(uint256 idx) external view returns (address);

    /**
     * @notice Returns number of tokens created
     * @return number of tokens created
     */
    function numTokensCreated() external view returns (uint256);
}