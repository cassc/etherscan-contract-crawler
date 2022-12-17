// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721, ERC721, ERC721Enumerable} from "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {toWadUnsafe, toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {LibGOO} from "goo-issuance/LibGOO.sol";

/// @dev An enum for representing whether to
/// increase or decrease a user's goo balance.
enum GooBalanceUpdateType {
    INCREASE,
    DECREASE
}

/// @notice Struct holding data relevant to each user's account.
struct UserData {
    // User's goo balance at time of last checkpointing.
    uint128 lastBalance;
    // Timestamp of the last goo balance checkpoint.
    uint64 lastTimestamp;
}

contract OwnedEnumerableNFT is ERC721Enumerable, Ownable {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable() {}

    function mint(address recipient) public virtual onlyOwner returns (uint256 id) {
        id = totalSupply();
        _safeMint(recipient, id);
    }

    function burn(uint256 id) public onlyOwner {
        _burn(id);
    }
}

// SPY NFT will produce Goo
contract SpyNFT is OwnedEnumerableNFT {
    /*//////////////////////////////////////////////////////////////
                            Variables
    //////////////////////////////////////////////////////////////*/

    /// Random emission multiple to massage the curve into place
    uint256 public constant EMISSION_MULTIPLE = 69;

    /// Keeps track of virtual GOO Balance
    mapping(address => UserData) public getUserData;

    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);

    /*//////////////////////////////////////////////////////////////
                            Errors
    //////////////////////////////////////////////////////////////*/

    error TooEarly();

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() OwnedEnumerableNFT("Spy", "SPIES") {}

    /*//////////////////////////////////////////////////////////////
                      Goo Functionality (Read only)
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate a user's virtual goo balance.
    /// @param user The user to query balance for.
    function gooBalance(address user) public view returns (uint256) {
        // Compute the user's virtual goo balance using LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            EMISSION_MULTIPLE * balanceOf(user),
            getUserData[user].lastBalance,
            uint256(toDaysWadUnsafe(block.timestamp - getUserData[user].lastTimestamp))
        );
    }

    /*//////////////////////////////////////////////////////////////
                      Goo Functionality (Permissioned)
    //////////////////////////////////////////////////////////////*/

    /// @notice Update a user's virtual goo balance.
    /// @param user The user whose virtual goo balance we should update.
    /// @param gooAmount The amount of goo to update the user's virtual balance by.
    /// @param updateType Whether to increase or decrease the user's balance by gooAmount.
    function updateUserGooBalance(address user, uint256 gooAmount, GooBalanceUpdateType updateType) public onlyOwner {
        // Will revert due to underflow if we're decreasing by more than the user's current balance.
        // Don't need to do checked addition in the increase case, but we do it anyway for convenience.
        uint256 updatedBalance =
            updateType == GooBalanceUpdateType.INCREASE ? gooBalance(user) + gooAmount : gooBalance(user) - gooAmount;

        // Snapshot the user's new goo balance with the current timestamp.
        getUserData[user].lastBalance = uint128(updatedBalance);
        getUserData[user].lastTimestamp = uint64(block.timestamp);

        emit GooBalanceUpdated(user, updatedBalance);
    }

    /// @notice Superuser transferFrom
    function sudoTransferFrom(address from, address to, uint256 tokenId) public onlyOwner {
        // if (getUserData[from].lastTimestamp == 0) {
        //     getUserData[from].lastTimestamp = uint64(block.timestamp);
        // }
        // if (getUserData[to].lastTimestamp == 0) {
        //     getUserData[to].lastTimestamp = uint64(block.timestamp);
        // }

        unchecked {
            // We update their last balance before updating their emission multiple to avoid
            // penalizing them by retroactively applying their new (lower) balanceOf
            getUserData[from].lastBalance = uint128(gooBalance(from));
            getUserData[from].lastTimestamp = uint64(block.timestamp);

            // We update their last balance before updating their emission multiple to avoid
            // overpaying them by retroactively applying their new (higher) balanceOf
            getUserData[to].lastBalance = uint128(gooBalance(to));
            getUserData[to].lastTimestamp = uint64(block.timestamp);
        }

        // State changes happen *after* gooBalance is update
        _transfer(from, to, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 Functionality
    //////////////////////////////////////////////////////////////*/

    function mint(address recipient, uint256 timestamp) public onlyOwner returns (uint256 id) {
        // Prevent bugs
        if (timestamp < block.timestamp) {
            revert TooEarly();
        }

        // If we can't get the gooBalance, then minting hasn't start yet
        // If we can get the gooBal then we good
        try this.gooBalance(recipient) returns (uint256 existingGooBal) {
            getUserData[recipient].lastBalance = uint128(existingGooBal);
        } catch {}
        getUserData[recipient].lastTimestamp = uint64(timestamp);

        id = totalSupply();
        _safeMint(recipient, id);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        if (getUserData[from].lastTimestamp == 0) {
            getUserData[from].lastTimestamp = uint64(block.timestamp);
        }
        if (getUserData[to].lastTimestamp == 0) {
            getUserData[to].lastTimestamp = uint64(block.timestamp);
        }

        unchecked {
            // We update their last balance before updating their emission multiple to avoid
            // penalizing them by retroactively applying their new (lower) balanceOf
            getUserData[from].lastBalance = uint128(gooBalance(from));
            getUserData[from].lastTimestamp = uint64(block.timestamp);

            // We update their last balance before updating their emission multiple to avoid
            // overpaying them by retroactively applying their new (higher) balanceOf
            getUserData[to].lastBalance = uint128(gooBalance(to));
            getUserData[to].lastTimestamp = uint64(block.timestamp);
        }

        // State changes happen *after* gooBalance is update
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override (ERC721, IERC721)
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        unchecked {
            // We update their last balance before updating their emission multiple to avoid
            // penalizing them by retroactively applying their new (lower) balanceOf
            getUserData[from].lastBalance = uint128(gooBalance(from));
            getUserData[from].lastTimestamp = uint64(block.timestamp);

            // We update their last balance before updating their emission multiple to avoid
            // overpaying them by retroactively applying their new (higher) balanceOf
            getUserData[to].lastBalance = uint128(gooBalance(to));
            getUserData[to].lastTimestamp = uint64(block.timestamp);
        }

        _safeTransfer(from, to, tokenId, data);
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        string[4] memory parts;

        parts[0] =
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = "SPY #";

        parts[2] = SVGUtils.toString(tokenId);

        parts[3] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Spy #',
                        SVGUtils.toString(tokenId),
                        '", "description": "A Spy in the Knife Game Universe.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }
}

contract KnifeNFT is OwnedEnumerableNFT {
    constructor() OwnedEnumerableNFT("Knife", "KNIVES") {}

    function sudoTransferFrom(address from, address to, uint256 tokenId) public onlyOwner {
        _transfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        string[4] memory parts;

        parts[0] =
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = "Knife #";

        parts[2] = SVGUtils.toString(tokenId);

        parts[3] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Knife #',
                        SVGUtils.toString(tokenId),
                        '", "description": "A Knife the Knife Game Universe.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for { let i := 0 } lt(i, len) {} {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

library SVGUtils {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}