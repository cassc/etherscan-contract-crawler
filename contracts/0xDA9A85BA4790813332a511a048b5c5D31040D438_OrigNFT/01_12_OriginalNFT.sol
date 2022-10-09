// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "ERC721Enumerable.sol";
import "Strings.sol";


contract OrigNFT is ERC721Enumerable {
    using Strings for uint256;
    using Strings for uint160;
    
    string  internal baseurl;
    uint256 public lastNFTId;
    
    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseurl
    ) 
        ERC721(name_, symbol_)  
    {
        baseurl = string(
            abi.encodePacked(
                _baseurl,
                block.chainid.toString(),
                "/",
                uint160(address(this)).toHexString(),
                "/"
            )
        );
    }

    function mint(address _to) external {
        lastNFTId += 1;
        _mint(_to, lastNFTId);
    }
    
    function baseURI() external view  returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view  override returns (string memory) {
        return baseurl;
    }
}