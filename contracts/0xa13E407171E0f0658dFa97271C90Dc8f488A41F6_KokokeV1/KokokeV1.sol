/**
 *Submitted for verification at Etherscan.io on 2023-05-13
*/

// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface
pragma solidity ^0.8.0;

/**
 * @title Kokoke - A Smart Contract for an NFT game based on the proximity of addresses
 * @dev Right now there are no transfer functions and this is just a proof of concept to get people
 * excited about it and put it out there. Let's see how low we can go!
 */
contract KokokeV1 {
    mapping(address => uint256) public kofe;

    int256 private _minDifference;

    address private _currentClosest;

    uint64 private _lastStolen;
    uint16 private _timesStolen;

    /**
 
     * @notice Transfer event to log NFT transfers
     * @param from The address from which the NFT is being transferred
     * @param to The address to which the NFT is being transferred
     * @param tokenId The ID of the NFT being transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Message(string indexed message);

    /**
     * @notice Initializes the contract, sending to ACK and emitting a Transfer/Message event
     */
    constructor() {
        address ack = 0x03ee832367E29a5CD001f65093283eabB5382B62;

        _minDifference = int256(uint256(uint160(ack))) - int256(uint256(uint160(address(this))));
        _currentClosest = ack;
        emit Transfer(address(0), ack, 1);
        emit Message("initialize!");
    }

    /**
     * @notice Allows a user to steal the NFT if their address is closer to the contract's address
     */
    function eAihue(string memory message) external {
        int256 difference = int256(uint256(uint160(msg.sender))) -
            int256(uint256(uint160(address(this))));
        require(
            (difference < 0 ? -difference : difference) <
                (_minDifference < 0 ? -_minDifference : _minDifference),
            "Address isn't closer!"
        );

        ++_timesStolen;
        _lastStolen = uint64(block.timestamp); // solhint-disable-line not-rely-on-time
        _minDifference = difference;
        emit Transfer(_currentClosest, msg.sender, 1);
        emit Message(message);
        _currentClosest = msg.sender;
    }

    /**
     * @notice Donate some coffee! It'll be repaid... somehow... someday....
     */
    function haawiKofe() external payable {
        payable(0xB3F3c86928F5D5592635859f60b152D98b3D8C88).transfer(address(this).balance);
        // solhint-disable-next-line reentrancy
        kofe[msg.sender] += msg.value;
    }

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address to query the balance of
     * @return uint256 The balance of the specified address
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == _currentClosest) {
            return 1;
        } else {
            return 0;
        }
    }

    /**
     * @notice Gets the owner of the specified token ID
     * @param tokenId The token ID to query the owner of
     * @return address The owner of the specified token ID
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        require(tokenId == 1, "ERC721: invalid token ID");
        return _currentClosest;
    }

    /**
     * @notice Gets the name of the token
     * @return string The token name
     */
    function name() public view virtual returns (string memory) {
        return "Kokoke V1";
    }

    /**
     * @notice Gets the symbol of the token
     * @return string The token symbol
     */
    function symbol() public view virtual returns (string memory) {
        return "KOKO";
    }

    /**
     * @notice Gets the token URI of the specified token ID
     * @param id The token ID to query the token URI of
     * @return string The token URI of the specified token ID
     */
    function tokenURI(uint256 id) public view returns (string memory) {
        require(id == 1, "ERC721: invalid token ID");
        // solhint-disable quotes, max-line-length
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"Kokoke V1","description":"E hele kokoke loa e lanakila.","image":"ipfs://QmcprQ1VHrpK2Qidngs8aEU8r9LdjSxMMYwzZK9NyqqvvD","attributes":[{"display_type":"date","trait_type":"Last Stolen","value":',
                    _toString(int64(_lastStolen)),
                    '},{"display_type":"boost_number","trait_type":"Times Stolen","value":',
                    _toString(int16(_timesStolen)),
                    '},{"display_type": "boost_percentage","trait_type":"~Distance Away","value":',
                    _toString((_minDifference * 100) / int256(uint256(uint160(address(this))))),
                    "}]}"
                )
            );
        // solhint-enable quotes, max-line-length
    }

    /**
     * @dev borrowed Openzeppelin's _log10 function to take log10 of a value
     * @param value to take the log10 of :)
     * @return uint256 the log10 of that value!
     */
    // solhint-disable-next-line code-complexity
    function _log10(uint256 value) private pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev borrowed Openzeppelin's _toString function to convert ints to strings
     * their version is uint but since we have the potential to have negative numbers...
     * @param value to convert to string :)
     * @return string the string of that value!
     */
    function _toString(int256 value) private pure returns (string memory) {
        // solhint-disable no-inline-assembly
        unchecked {
            bytes16 symbols = "0123456789abcdef";
            bool negative = value < 0;
            int256 uvalue = negative ? -value : value;
            uint256 length = negative ? _log10(uint256(uvalue)) + 2 : _log10(uint256(uvalue)) + 1;
            string memory buffer = new string(length);
            uint256 ptr;

            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                assembly {
                    mstore8(ptr, byte(mod(uvalue, 10), symbols))
                }
                uvalue /= 10;
                if (uvalue == 0) break;
            }
            if (negative) {
                buffer = string.concat("-", buffer);
            }
            return buffer;
        }
        // solhint-enable no-inline-assembly
    }
}