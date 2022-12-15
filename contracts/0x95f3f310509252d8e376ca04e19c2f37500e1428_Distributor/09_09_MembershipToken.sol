// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

import {Base64} from "./Base64.sol";

abstract contract MembershipToken is ERC721("", "") {
    /*********
     * Types *
     *********/

    struct Membership {
        address wallet;
        uint32 weight;
    }

    error NotAMember();
    error TokenDoesNotExist();

    /*************
     * Variables *
     *************/

    /// The total supply of membership tokens
    uint16 public totalSupply;

    /// Mapping to track weights per individual membership
    mapping(uint256 => uint32) public membershipWeight;

    /// The total number of weights across all tokens
    uint48 public totalWeights;

    /******************
     * Public functions
     ******************/

    /**
     * Get a token's proportional share of a specified total value.
     * @param tokenId ID of the membership token.
     * @param value The value we need to get a proportional share from.
     */
    function tokenShare(uint256 tokenId, uint224 value)
        public
        view
        returns (uint256)
    {
        return (uint256(value) * membershipWeight[tokenId]) / totalWeights;
    }

    /**
     * Generate SVG image asset for a membership token.
     * @param tokenId ID of the membership token.
     */
    function tokenImage(uint256 tokenId) public view returns (string memory) {
        if (tokenId >= totalSupply) revert TokenDoesNotExist();

        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80"><g><rect width="80" height="80" /><g stroke-width="16" fill="none"><circle stroke="white" r="15.9" cx="50%" cy="50%"/><circle stroke="hsl(',
                    Strings.toString(_prngInRange(tokenId, 360)),
                    ',100%,69%)" r="15.9" cx="50%" cy="50%" stroke-dasharray="',
                    Strings.toString(tokenShare(tokenId, 100)),
                    ' 100" stroke-dashoffset="0" transform="rotate(-90 40 40)" /></g><g font-family="monospace" text-anchor="middle" font-size="6" fill="white"><text x="50%" y="13%">',
                    name,
                    '</text><text x="50%" y="52%">#',
                    Strings.toString(tokenId),
                    '</text><text x="50%" y="92%">',
                    Strings.toString(membershipWeight[tokenId]),
                    "</text></g></g></svg>"
                )
            );
    }

    /**
     * Generate JSON metadata for a membership token.
     * @param tokenId ID of the membership token.
     */
    function tokenMetadata(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        if (tokenId >= totalSupply) revert TokenDoesNotExist();

        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    " #",
                    Strings.toString(tokenId),
                    '","image":"',
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(bytes(tokenImage(tokenId)))
                    ),
                    '","attributes":[{"trait_type":"Weight","value":',
                    Strings.toString(membershipWeight[tokenId]),
                    ',"max_value":',
                    Strings.toString(totalWeights),
                    "}]}"
                )
            );
    }

    /**
     * Generate base64-encoded metadata for a membership token.
     * @param tokenId ID of the membership token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (tokenId >= totalSupply) revert TokenDoesNotExist();
        string memory json = Base64.encode(bytes(tokenMetadata(tokenId)));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /*************
     * Internals *
     *************/

    /**
     * @dev Initialize the contract.
     * @param name_ Membership token name.
     * @param symbol_ Membership token symbol.
     * @param memberships Memberships to mint on initialization.
     */
    function _initialize(
        string memory name_,
        string memory symbol_,
        Membership[] memory memberships
    ) internal {
        name = name_;
        symbol = symbol_;
        _mintMemberships(memberships);
    }

    /**
     * @dev Mint a new membership token.
     * @param membership Information for the membership.
     */
    function _mintMembership(Membership memory membership) internal {
        uint256 tokenId = totalSupply;

        totalSupply += 1;
        totalWeights += membership.weight;
        membershipWeight[tokenId] = membership.weight;

        _mint(membership.wallet, tokenId);
    }

    /**
     * @dev Mint a batch of membership tokens.
     * @param memberships List of new memberships to mint.
     */
    function _mintMemberships(Membership[] memory memberships) internal {
        uint256 membershipCount = memberships.length;

        for (uint256 i = 0; i < membershipCount; i++) {
            _mintMembership(memberships[i]);
        }
    }

    /**
     * @dev Generate a randomish number in a range based on a token ID.
     * @param tokenId Token ID were using to generate the number.
     * @param range The range that the result needs to be in.
     */
    function _prngInRange(uint256 tokenId, uint256 range)
        internal
        view
        returns (uint256)
    {
        return
            uint256(keccak256(abi.encodePacked(name, symbol, tokenId))) % range;
    }

    /**
     * @dev Restrict function to be called by members only.
     */
    modifier memberOnly() {
        if (balanceOf(msg.sender) == 0) revert NotAMember();
        _;
    }
}