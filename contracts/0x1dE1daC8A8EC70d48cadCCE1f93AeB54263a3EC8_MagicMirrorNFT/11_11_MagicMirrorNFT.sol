// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MagicMirrorNFT
 * @notice MagicMirrorNFT is a contract for mirroring NFTs on other networks. MagicMirror is meant
 *         to be used in conjunction with a trusted MagicMirror backend. It's possible to use the
 *         same backend to serve NFTs for multiple different networks by specifying a chain ID.
 */
contract MagicMirrorNFT is ERC721, Ownable {
    /**
     * @notice URI for the MagicMirror backend server.
     */
    string public api;

    /**
     * @notice Chain ID for the chain to mirror NFTs on.
     */
    uint256 public immutable chain;

    /**
     * @param _api   URI for the MagicMirror backend server.
     * @param _chain Chain ID for the chain to mirror NFTs on.
     */
    constructor(
        address _owner,
        string memory _api,
        uint256 _chain
    ) ERC721("Magic Mirror NFT", "MMNFT") {
        api = _api;
        chain = _chain;
        _transferOwnership(_owner);
    }

    /**
     * @notice Mints a new MagicMirror NFT.
     */
    function mint() public {
        _mint(msg.sender, uint256(uint160(msg.sender)));
    }

    /**
     * @notice Retrieves the URI for a given token.
     *
     * @param _tokenId ID of the token to retrieve a URI for.
     *
     * @return URI for the given token.
     */
    function tokenURI(
        uint256 _tokenId
    )
        public
        override
        view
        returns (
            string memory
        )
    {
        return string(
            abi.encodePacked(
                api,
                Strings.toString(chain),
                "/",
                Strings.toHexString(uint160(_tokenId))
            )
        );
    }

    /**
     * @notice Allows the owner to set the API URL.
     *
     * @param _api API for the MagicMirror backend server.
     */
    function setAPI(
        string memory _api
    ) public onlyOwner {
        api = _api;
    }

    /**
     * @notice Transfers are blocked.
     */
    function _transfer(
        address,
        address,
        uint256
    )
        internal
        override
        pure
    {
        revert("MagicMirrorNFT: mirrored NFTs cannot be transferred");
    }
}