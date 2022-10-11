// SPDX-License-Identifier: MIT
// ENVELOP protocol for NFT
pragma solidity 0.8.10;

import "Ownable.sol";
import "ERC721Enumerable.sol";
import "Strings.sol";

//v0.0.1
contract EnvelopERC721 is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for uint160;
    
    address public wrapperMinter;
    string  internal baseurl;
    
    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseurl
    ) 
        ERC721(name_, symbol_)  
    {
        wrapperMinter = msg.sender;
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

    function mint(address _to, uint256 _tokenId) external {
        require(wrapperMinter == msg.sender, "Trusted address only");
        _mint(_to, _tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function setMinter(address _minter) external onlyOwner {
        wrapperMinter = _minter;
    }

    function setBaseUrl(string calldata _baseurl) external onlyOwner {
        baseurl = _baseurl;
    }

    
    function baseURI() external view  returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view  override returns (string memory) {
        return baseurl;
    }

}