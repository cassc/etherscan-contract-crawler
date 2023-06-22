// SPDX-License-Identifier: MIT


/*
██████╗░
██╔══██╗
██████╔╝
██╔═══╝░
██║░░░░░
╚═╝░░░░░
*/


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

                                                                                    

contract P is ERC721, Ownable {


    bool public claimIsActive = false;
	uint public maxSupply = 1000;
	
	mapping(address => uint) public addressClaimed;
	
	
	

    using Counters for Counters.Counter;
    Counters.Counter private pSupply;

    constructor() ERC721("P", "P") {}


    function totalSupply() public view returns (uint256 supply) {
        return pSupply.current();
    }

    function setClaimState(bool newState) public onlyOwner {
        claimIsActive = newState;
    }
	
	
    function claim() external {
        require(claimIsActive, "Claim is inactive.");
        require(pSupply.current() + 1 <= maxSupply, "No more supply.");
		require(addressClaimed[msg.sender] < 1, "One per wallet.");
		addressClaimed[msg.sender] += 1;
        for(uint i = 0; i < 1; i++) {
		  uint256 _tokenId = pSupply.current() + 1;
            _safeMint(msg.sender, _tokenId);
            pSupply.increment();
        }
    }

	
	
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
	
        string memory image = string(abi.encodePacked('<svg width="128" height="128" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g><path d="M121,0.11H6.99c-3.78,0-6.87,3.1-6.87,6.88v114.01c0,3.78,3.09,6.88,6.87,6.88H121 c3.78,0,6.88-3.09,6.88-6.88V7C127.88,3.21,124.78,0.11,121,0.11z" style="fill:#006CA2;"/><path d="M71.63,15.96h-34.5c-0.13,0-0.25,0.06-0.37,0.08h-5.91c-1.13,0-2.04,0.92-2.04,2.05v92.01 c0,1.13,0.91,2.04,2.04,2.04H50.8c1.13,0,2.04-0.91,2.04-2.04V80.85h18.79c18.07,0,32.77-14.55,32.77-32.44 C104.4,30.52,89.7,15.96,71.63,15.96z M70.05,61.73c-0.32,0.02-0.64,0.05-0.95,0.05H53.18c0,0-0.08-0.04-0.11-0.05 c-0.09-0.02-0.16-0.04-0.23-0.09c-0.1-0.1-0.19-0.23-0.19-0.39V35.57c0-0.16,0.09-0.29,0.19-0.39c0.06-0.05,0.13-0.06,0.2-0.08 c0.06-0.02,0.1-0.06,0.14-0.06H69.1c0.38,0,0.75,0.02,1.13,0.06C76.81,35.69,82,41.43,82,48.4C82,55.45,76.71,61.22,70.05,61.73z" style="fill:#FFFFFF;"/></g></svg>'));
        string memory output = string(abi.encodePacked(image));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "P #', toString(tokenId),'","attributes": [ { "trait_type": "Not ', unicode"🅿️" ,'", "value": "','False','" }]',', "description": "Certified ', unicode"🅿️", ' - ', toString(tokenId),'/1000','", "image": "data:image/svg+xml;base64,',Base64.encode(bytes(output)),'"}'))));
		output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
	
	
	
	
	 /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

            for {
                let i := 0
            } lt(i, len) {

            } {
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
}