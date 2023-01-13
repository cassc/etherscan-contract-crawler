// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SaunoaMembership NFT
 */
contract SaunoaMemberMe is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;
    string public baseTokenURI;

    /**
     * @dev Constractor of SaunoaMembership contract.
     * @param _baseTokenURI Initial setting of base token URI.
     */
    constructor(string memory _baseTokenURI) ERC721("SaunoaMemberMe", "SAUNOA") {
        setBaseTokenURI(_baseTokenURI);
    }

    /**
     * @dev Setter of base token URI.
     * @param _baseTokenURI base token URI
     */
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @dev Getter of base token URI. Override ERC721.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Getter of tokenURI. Override ERC721.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    /**
     * @dev Getter of current total mint count.
     */
    function totalMint() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Mint SaunoaMembership NFT. Transfer it to the specified address.
     */
    function mint(address _to) public onlyOwner {
        _tokenIds.increment();
        uint256 nextTokenId = _tokenIds.current();
        _safeMint(_to, nextTokenId);
    }

    /**
     * @dev Burn SaunoaMembership NFT.
     */
    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }
    
    /**
     * @notice Override ERC721.
     * @dev Transfer is not allowed.
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal pure override {
        require(_from == address(0) || _to == address(0), "Transfer is not allowed.");
    }
}