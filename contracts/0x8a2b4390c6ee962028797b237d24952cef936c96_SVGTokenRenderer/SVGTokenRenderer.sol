/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

//SPDX-License-Identifier: MIT

// 🌞

// File: contracts/TokenRenderer.sol
pragma solidity ^0.8.4;

interface TokenRenderer {
    function getTokenURI(uint256 tokenId, string memory name)
        external
        view
        returns (string memory);
}

// File: contracts/Utils.sol
pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Utils {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function base64Encode(bytes memory data)
        internal
        pure
        returns (string memory)
    {
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

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }

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

    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/SVGTokenRenderer.sol
pragma solidity ^0.8.4;

// 🌞
contract SVGTokenRenderer is Ownable, TokenRenderer {
    uint256 private immutable _badgeLen = 5;

    constructor() {}

    function _getName(uint256 tokenId, string memory name)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(name, " #", _getBadgeNumber(tokenId)));
    }

    function _getBadgeNumber(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        uint256 maxNumber = 99_999;
        if (tokenId > maxNumber) {
            return "?????";
        }

        string memory tokenString = Utils.toString(tokenId);
        uint256 tokenLength = Utils.strlen(tokenString);
        bytes memory zero = abi.encodePacked("0");
        bytes memory badgeNumber = abi.encodePacked("");

        for (uint i = 0; i < _badgeLen - tokenLength; i++) {
            badgeNumber = abi.encodePacked(badgeNumber, zero);
        }

        badgeNumber = abi.encodePacked(badgeNumber, tokenString);
        return string(badgeNumber);
    }

    function _getSvg(uint256 tokenId) internal pure returns (bytes memory) {
        bytes
            memory s = '<svg viewBox="0 0 740 740" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><style>@import url(&#x27;https://fonts.googleapis.com/css2?family=Chivo:[email protected]&amp;display=swap&#x27;);</style></defs><path d="M740 0H0v740h740V0Z" fill="#2A2622"></path><path d="M170 446.77V119.21c0-16.96 13.43-30.71 30-30.71h340c16.57 0 30 13.75 30 30.71v327.56c0 113.07-89.54 204.73-200 204.73s-200-91.66-200-204.73Z" fill="#F9F4EA"></path><path d="M187 445.57V232.5c0-9.94 8.06-18 18-18h329c9.94 0 18 8.06 18 18v213.07c0 103.79-81.71 187.93-182.5 187.93S187 549.36 187 445.57ZM206.14 126.18h8.02c7.58 0 12.14 4.9 12.14 11.83 0 7.38-4.55 11.97-12.14 11.97h-8.02v-23.8Zm7.85 19.85c4.18 0 7.62-2.45 7.62-8.02 0-5.57-3.4-7.89-7.62-7.89h-3.33v15.91h3.33ZM235.21 126.18h5.68l8.5 23.8h-4.79l-1.67-4.69h-9.89l-1.63 4.69h-4.66l8.46-23.8Zm6.43 15.06-3.5-10.03h-.27l-3.5 10.03h7.28-.01ZM248.4 126.18h4.93l3.91 17.1h.27l4.15-17.1h5.58l4.15 17.1h.24l3.94-17.1h4.9l-6.15 23.8h-5.44l-4.32-17.41h-.24L260 149.98h-5.44l-6.15-23.8h-.01ZM282.98 126.18h4.93l10.2 16.28h.21v-16.28h4.38v23.8h-4.96l-10.13-16.28h-.21v16.28h-4.42v-23.8ZM315.72 126.18h9.01c4.55 0 7.96 3.09 7.96 7.68s-3.54 7.79-7.96 7.79h-4.49v8.33h-4.52v-23.8Zm8.53 11.59c2.28 0 3.81-1.6 3.81-3.91s-1.53-3.81-3.81-3.81h-4.01v7.72h4.01ZM339.96 126.18h5.68l8.5 23.8h-4.79l-1.67-4.69h-9.89l-1.63 4.69h-4.66l8.46-23.8Zm6.43 15.06-3.5-10.03h-.27l-3.5 10.03h7.28-.01ZM355.09 142.46h4.38c.03 2.14 1.8 3.81 4.79 3.81 2.55 0 4.18-1.09 4.18-2.89 0-5.44-12.65-1.05-12.65-10.78 0-3.77 2.99-6.87 8.23-6.87 4.52 0 8.36 2.38 8.5 7.34H368c-.03-1.97-1.43-3.3-3.98-3.3s-3.74 1.26-3.74 2.75c0 4.96 12.82.88 12.82 10.5 0 4.22-3.26 7.38-8.97 7.38-5.71 0-9.04-3.23-9.04-7.96v.02ZM374.88 142.46h4.38c.03 2.14 1.8 3.81 4.79 3.81 2.55 0 4.18-1.09 4.18-2.89 0-5.44-12.65-1.05-12.65-10.78 0-3.77 2.99-6.87 8.23-6.87 4.52 0 8.36 2.38 8.5 7.34h-4.52c-.03-1.97-1.43-3.3-3.98-3.3s-3.74 1.26-3.74 2.75c0 4.96 12.82.88 12.82 10.5 0 4.22-3.26 7.38-8.97 7.38-5.71 0-9.04-3.23-9.04-7.96v.02Z" fill="#2A2622"></path><path d="M507 131.71c-10.91 0-19.79 8.88-19.79 19.79v2.91h7.21v-2.91c0-6.94 5.65-12.58 12.58-12.58s12.58 5.65 12.58 12.58v2.91h7.21v-2.91c0-10.91-8.88-19.79-19.79-19.79Z" fill="#FF7C24"></path><path d="M507 138.91c-6.94 0-12.59 5.65-12.59 12.59v2.91h7.21v-2.91c0-2.96 2.41-5.38 5.38-5.38 2.97 0 5.38 2.41 5.38 5.38v2.91h7.21v-2.91c0-6.94-5.65-12.59-12.59-12.59Z" fill="#FF991F"></path><path d="M501.62 154.41v-2.91c0-2.96 2.41-5.38 5.38-5.38 2.97 0 5.38 2.41 5.38 5.38v2.91h-10.76Z" fill="#FFB624"></path><path d="M507 124.5c-14.88 0-26.99 12.1-27 26.98v.02c0 .98.05 1.95.16 2.91h7.05v-2.91c0-10.91 8.88-19.79 19.79-19.79 10.91 0 19.79 8.88 19.79 19.79v2.91h7.05c.1-.96.16-1.93.16-2.91v-.02c-.01-14.88-12.12-26.98-27-26.98Z" fill="#FF5622"></path><path d="M246.9 560.67h245.2a165.103 165.103 0 0 0 24.93-36.83H221.97c6.64 13.42 15.05 25.8 24.93 36.83Z" fill="#FF991F"></path><path d="M369.5 286.5C278.65 286.5 205 360.15 205 451h329c0-90.85-73.65-164.5-164.5-164.5Z" fill="#FF5622"></path><path d="M369.5 615.5c39.33 0 75.43-13.81 103.73-36.83H265.77c28.3 23.02 64.4 36.83 103.73 36.83Z" fill="#FFB624"></path><path d="M205.98 469a163.18 163.18 0 0 0 8.39 36.83h310.25c4.15-11.73 7-24.06 8.39-36.83H205.98Z" fill="#FF7C24"></path><text fill="#2A2622" xml:space="preserve" style="white-space:pre" font-family="Chivo,sans-serif" font-size="24"><tspan x="207" y="184.4">';
        s = abi.encodePacked(
            s,
            "#",
            _getBadgeNumber(tokenId),
            "</tspan></text></svg>"
        );

        return s;
    }

    // For tests
    // ---------

    function getBadgeLength() public pure returns (uint256) {
        return _badgeLen;
    }

    function getSVG(uint256 tokenId) public pure returns (string memory) {
        return string(_getSvg(tokenId));
    }

    function getBadgeNumber(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        return _getBadgeNumber(tokenId);
    }

    // For NFT
    // -------

    function getTokenURI(uint256 tokenId, string memory name)
        public
        pure
        override
        returns (string memory)
    {
        bytes memory json = abi.encodePacked(
            '{"name": "',
            _getName(tokenId, name),
            '", "description": "The Dawn Pass grants access to Daylight, where you can discover everything your wallet can do: mints, airdrops, votes, token gates, and more.\\n\\nThis NFT is soulbound and burnable. To burn it, send the NFT to the OpenSea burn address.", ',
            '"image": "data:image/svg+xml;base64,',
            Utils.base64Encode(_getSvg(tokenId)),
            '", "attributes": [{ "trait_type": "Badge Number", "value": ',
            Utils.toString(tokenId),
            " }]}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Utils.base64Encode(json)
                )
            );
    }
}