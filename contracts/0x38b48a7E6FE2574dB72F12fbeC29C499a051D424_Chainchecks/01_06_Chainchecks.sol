// This is an on-chain derivative of the Checks collection by Jack Butcher

/*************************************************************************
    __  __ __   ____  ____  ____     __  __ __    ___    __  __  _  _____
   /  ]|  |  | /    ||    ||    \   /  ]|  |  |  /  _]  /  ]|  |/ ]/ ___/
  /  / |  |  ||  o  | |  | |  _  | /  / |  |  | /  [_  /  / |  ' /(   \_ 
 /  /  |  _  ||     | |  | |  |  |/  /  |  _  ||    _]/  /  |    \ \__  |
/   \_ |  |  ||  _  | |  | |  |  /   \_ |  |  ||   [_/   \_ |     \/  \ |
\     ||  |  ||  |  | |  | |  |  \     ||  |  ||     \     ||  .  |\    |
 \____||__|__||__|__||____||__|__|\____||__|__||_____|\____||__|\_| \___|

*************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Chainchecks is ERC721A, Ownable {
    bool public mintActive = false;
    uint public price = 1000000000000000; // 0.001 eth
    constructor() ERC721A("Chainchecks", "CHX") {}

    function mint(uint256 quantity) external payable {
        require(msg.value >= price * quantity, "Insufficient fee");
        require(mintActive, "Mint is closed");
        _mint(msg.sender, quantity);
    }

    function startMint() external onlyOwner {
        mintActive = true;
    }

    function stopMint() external onlyOwner {
        mintActive = false;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory name = string(abi.encodePacked("Chainchecks #", uint2str(tokenId)));
        string memory json = string(abi.encodePacked(
            '{"name": "',
            name,
            '", "description": "This artwork may or may not be on chain.", "attributes":[{"trait_type": "number", "value": ',
            uint2str(tokenId),
            '}], "image": "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHByZXNlcnZlQXNwZWN0UmF0aW89InhNaW5ZTWluIG1lZXQiIHdpZHRoPSI2MDAiIGhlaWdodD0iNjAwIiB2aWV3Qm94PSIwIDAgMzcgMzciIGZpbGw9Im5vbmUiPgo8cmVjdCB3aWR0aD0iMzciIGhlaWdodD0iMzciIGZpbGw9IiNFQkVCRUIiLz4KPHJlY3QgeD0iMTAiIHk9IjgiIHdpZHRoPSIxNyIgaGVpZ2h0PSIyMSIgZmlsbD0id2hpdGUiLz4KPHJlY3QgeD0iMTEiIHk9IjkiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNEQjM5NUUiLz4KPHJlY3QgeD0iMTEiIHk9IjExIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjMkU2NjhCIi8+CjxyZWN0IHg9IjExIiB5PSIxMyIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0YwQTMzQSIvPgo8cmVjdCB4PSIxMSIgeT0iMTUiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM1MjVFQTkiLz4KPHJlY3QgeD0iMTEiIHk9IjE3IiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjMzM3NThDIi8+CjxyZWN0IHg9IjExIiB5PSIxOSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0VBN0IzMCIvPgo8cmVjdCB4PSIxMSIgeT0iMjEiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM5Njc5MzEiLz4KPHJlY3QgeD0iMTEiIHk9IjIzIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjNDA2OEMwIi8+CjxyZWN0IHg9IjExIiB5PSIyNSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0Y3RDk0QSIvPgo8cmVjdCB4PSIxMSIgeT0iMjciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiMzMjJGOTAiLz4KPHJlY3QgeD0iMTMiIHk9IjkiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM2MDIyNjMiLz4KPHJlY3QgeD0iMTMiIHk9IjExIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRjZDQkE2Ii8+CjxyZWN0IHg9IjEzIiB5PSIxMyIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iIzVBQkFEMyIvPgo8cmVjdCB4PSIxMyIgeT0iMTUiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNFQzczNjgiLz4KPHJlY3QgeD0iMTMiIHk9IjE3IiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRjA5ODM3Ii8+CjxyZWN0IHg9IjEzIiB5PSIxOSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iIzNFOEJBMyIvPgo8cmVjdCB4PSIxMyIgeT0iMjEiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNENTMzMkYiLz4KPHJlY3QgeD0iMTMiIHk9IjIzIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRjlEQTREIi8+CjxyZWN0IHg9IjEzIiB5PSIyNSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0M3RURGMiIvPgo8cmVjdCB4PSIxMyIgeT0iMjciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNFODQyNEUiLz4KPHJlY3QgeD0iMTUiIHk9IjkiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM1QzgzQ0IiLz4KPHJlY3QgeD0iMTUiIHk9IjExIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjREEzMzIxIi8+CjxyZWN0IHg9IjE1IiB5PSIxMyIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0Q2RjRFMSIvPgo8cmVjdCB4PSIxNSIgeT0iMTUiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNGQkVBNUIiLz4KPHJlY3QgeD0iMTUiIHk9IjE3IiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjOUFEOUZCIi8+CjxyZWN0IHg9IjE1IiB5PSIxOSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0YwQTBDQSIvPgo8cmVjdCB4PSIxNSIgeT0iMjEiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNFNzNFNTMiLz4KPHJlY3QgeD0iMTUiIHk9IjIzIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjNzdEM0RFIi8+CjxyZWN0IHg9IjE1IiB5PSIyNSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0YyQjM0MSIvPgo8cmVjdCB4PSIxNSIgeT0iMjciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiMyRTQ5ODUiLz4KPHJlY3QgeD0iMTciIHk9IjkiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNCMUVGQzkiLz4KPHJlY3QgeD0iMTciIHk9IjExIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjMkQ1MzUyIi8+CjxyZWN0IHg9IjE3IiB5PSIxMyIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0QxREY0RiIvPgo8cmVjdCB4PSIxNyIgeT0iMTUiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM5M0NGOTgiLz4KPHJlY3QgeD0iMTciIHk9IjE3IiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRjdERDlCIi8+CjxyZWN0IHg9IjE3IiB5PSIxOSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iIzREMzY1OCIvPgo8cmVjdCB4PSIxNyIgeT0iMjEiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiMyRjIyNDMiLz4KPHJlY3QgeD0iMTciIHk9IjIzIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjNkE1NTJBIi8+CjxyZWN0IHg9IjE3IiB5PSIyNSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0VBNUIzMyIvPgo8cmVjdCB4PSIxNyIgeT0iMjciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM1RkM5QkYiLz4KPHJlY3QgeD0iMTkiIHk9IjkiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiMyNTQzOEMiLz4KPHJlY3QgeD0iMTkiIHk9IjExIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjNUZDRDhDIi8+CjxyZWN0IHg9IjE5IiB5PSIxMyIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0E0QzhFRSIvPgo8cmVjdCB4PSIxOSIgeT0iMTUiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNFQjVBMkEiLz4KPHJlY3QgeD0iMTkiIHk9IjE3IiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRkFFNjYzIi8+CjxyZWN0IHg9IjE5IiB5PSIxOSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iIzgxRDFFQyIvPgo8cmVjdCB4PSIxOSIgeT0iMjEiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNEQjRENTgiLz4KPHJlY3QgeD0iMTkiIHk9IjIzIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjOEEyMjM1Ii8+CjxyZWN0IHg9IjE5IiB5PSIyNSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0Q5N0QyRSIvPgo8cmVjdCB4PSIxOSIgeT0iMjciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNGOURCNDkiLz4KPHJlY3QgeD0iMjEiIHk9IjkiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM3QTI1MjAiLz4KPHJlY3QgeD0iMjEiIHk9IjExIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjNDI5MUE4Ii8+CjxyZWN0IHg9IjIxIiB5PSIxMyIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0VGODkzMyIvPgo8cmVjdCB4PSIyMSIgeT0iMTUiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNCODJDMzYiLz4KPHJlY3QgeD0iMjEiIHk9IjE3IiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRjRCREJFIi8+CjxyZWN0IHg9IjIxIiB5PSIxOSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iIzNCMkYzOSIvPgo8cmVjdCB4PSIyMSIgeT0iMjEiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNGMkE5M0MiLz4KPHJlY3QgeD0iMjEiIHk9IjIzIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRkFFMjcyIi8+CjxyZWN0IHg9IjIxIiB5PSIyNSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0FCREQ0NSIvPgo8cmVjdCB4PSIyMSIgeT0iMjciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM0QUEzOTIiLz4KPHJlY3QgeD0iMjMiIHk9IjkiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM4NUMzM0MiLz4KPHJlY3QgeD0iMjMiIHk9IjExIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRUY4QzM3Ii8+CjxyZWN0IHg9IjIzIiB5PSIxMyIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0E3RERGOSIvPgo8cmVjdCB4PSIyMyIgeT0iMTUiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNFQTNBMkQiLz4KPHJlY3QgeD0iMjMiIHk9IjE3IiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRjdDQTU3Ii8+CjxyZWN0IHg9IjIzIiB5PSIxOSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0YyQTkzQiIvPgo8cmVjdCB4PSIyMyIgeT0iMjEiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM1QTlGM0UiLz4KPHJlY3QgeD0iMjMiIHk9IjIzIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRUI0NDI5Ii8+CjxyZWN0IHg9IjIzIiB5PSIyNSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0YyQTg0MCIvPgo8cmVjdCB4PSIyMyIgeT0iMjciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNERTMyMzciLz4KPHJlY3QgeD0iMjUiIHk9IjkiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNDMjM1MzIiLz4KPHJlY3QgeD0iMjUiIHk9IjExIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjNTM1Njg3Ii8+CjxyZWN0IHg9IjI1IiB5PSIxMyIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iIzlERUZCRiIvPgo8cmVjdCB4PSIyNSIgeT0iMTUiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiNGNkNCNDUiLz4KPHJlY3QgeD0iMjUiIHk9IjE3IiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRUU4MzdEIi8+CjxyZWN0IHg9IjI1IiB5PSIxOSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iIzYwQjFGNCIvPgo8cmVjdCB4PSIyNSIgeT0iMjEiIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM2RDJGMjIiLz4KPHJlY3QgeD0iMjUiIHk9IjIzIiB3aWR0aD0iMSIgaGVpZ2h0PSIxIiBmaWxsPSIjRTBDOTYzIi8+CjxyZWN0IHg9IjI1IiB5PSIyNSIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0iI0VFODI4RiIvPgo8cmVjdCB4PSIyNSIgeT0iMjciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiIGZpbGw9IiM3QTVBQjQiLz4KPC9zdmc+Cg=="}'
        ));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}