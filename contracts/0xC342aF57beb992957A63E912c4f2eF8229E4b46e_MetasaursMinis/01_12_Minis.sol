// SPDX-License-Identifier: MIT

// ERC721A with premint

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetasaursMinis is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 9999;
    string public  baseTokenUri;


    constructor(string memory _uri
    ) ERC721A("MetasaursMinis", "MTSM") {
        setBaseURI(_uri);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(baseTokenUri, _tokenId.toString(), ".json"));
	}

    function setBaseURI(string memory _uri) public onlyOwner {
        baseTokenUri = _uri;
    }

    /**
     * @dev Minting a batch of NFTs to an array of addresses
     */

    function adminMint(uint256 _amount)external onlyOwner{
        require(totalSupply()+_amount <= MAX_SUPPLY);
        _safeMint(msg.sender, _amount);
    }

    function airdrop(address[] memory _to, uint256[] memory _ids)
        external
        onlyOwner
    {
        require(
            _to.length == _ids.length,
            "The number of addresses must equal to th enumber of ids"
        );
        for (uint256 i; i < _to.length; i++) {
            safeTransferFrom(msg.sender, _to[i], _ids[i]);
        }
    }

    /**
     * @dev Shows ids of tokens belonging to a checked address.
     */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

}