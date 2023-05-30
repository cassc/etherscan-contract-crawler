//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../VarietyRepot.sol';
import '../IRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @title _512PrintRepot
/// @author Simon Fremaux (@dievardump)
contract _512PrintRepot is VarietyRepot {
    using Strings for uint256;

    IRenderer public renderer;

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param sower_ Sower contract
    /// @param renderer_ the renderer contract
    /// @param oldContract_ the oldContract for migration
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address sower_,
        address renderer_,
        address oldContract_
    )
        VarietyRepot(
            name_,
            symbol_,
            contractURI_,
            openseaProxyRegistry_,
            sower_,
            oldContract_
        )
    {
        renderer = IRenderer(renderer_);
    }

    /// @notice This function is a function that allows to update the current renderer
    ///         to a version where "rounded-stroke-gradient" misprints are fixed
    ///         this function will only be called in the case of a positive vote from 512Print holders
    function updateRenderer(address newRenderer) external onlyOwner {
        renderer = IRenderer(newRenderer);
    }

    /// @dev internal function to get the name. Should be overrode by actual Variety contract
    /// @param tokenId the token to get the name of
    /// @return seedlingName the token name
    function _getName(uint256 tokenId)
        internal
        view
        override
        returns (string memory seedlingName)
    {
        seedlingName = names[tokenId];
        if (bytes(seedlingName).length == 0) {
            seedlingName = string(
                abi.encodePacked('512Print.sol #', tokenId.toString())
            );
        }
    }

    /// @dev Rendering function; should be overrode by the actual seedling contract
    /// @param tokenId the tokenId
    /// @param seed the seed
    /// @return the json
    function _render(uint256 tokenId, bytes32 seed)
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return IRenderer(renderer).render(_getName(tokenId), tokenId, seed);
    }
}