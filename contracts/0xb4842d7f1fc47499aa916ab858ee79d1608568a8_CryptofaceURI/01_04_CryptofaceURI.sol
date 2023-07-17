// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";

contract CryptofaceURI {
    
    address public cryptoface = 0x66dab8a88B7cA020A89F45380cC61692Fe62E7ed;

    string public baseURI = "ipfs://QmNw4FAbRNeT9A7Ab4JaVCMWK4NjEvBjZWnVhfXNHLAEde/";

    function getURI(uint256 token) external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(token), ".json"));
    }
}