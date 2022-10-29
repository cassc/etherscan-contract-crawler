// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

DegenheimRenderer.sol

Written by: mousedev.eth

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DegenheimRenderer is Ownable {
    string public baseURI =
        "ipfs://QmRn7cDx8gon5esi6xp6QvCDLAsQ9mawfbwmQRUQjK1sJV/";
    string public baseURIEXT = ".json";

    uint256 public shiftAmount =
        82908126085295501332510496606049286525447947558910115637646280171574109755608;

    address public degenheimAddress;

    function setBaseURIEXT(string memory _baseURIEXT) public onlyOwner {
        baseURIEXT = _baseURIEXT;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        uint256 _newTokenId = (_tokenId + shiftAmount) % 7777;
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_newTokenId),
                    baseURIEXT
                )
            );
    }
}