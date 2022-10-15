// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KhaleejiNFT is ERC721, Ownable {
    using Strings for uint256;

    string private baseURI;
    string private baseExt = ".json";

    mapping(address => bool) allowedMinters;

    constructor(string memory _initBaseURI) ERC721("KhaleejiNFT", "KLJ") {
        setBaseURI(_initBaseURI);
        allowedMinters[msg.sender] = true;
    }

    /**
     * Allows to add new minter for collection
     */
    function addMinter(address minter) external onlyOwner {
        allowedMinters[minter] = true;
    }

    /**
     * Allows to remove minter for collection
     */
    function removeMinter(address minter) external onlyOwner {
        allowedMinters[minter] = false;
    }

    /*
     * Mints tokenId to specific to address
     */
    function mint(address to, uint256 tokenId) external {
        require(allowedMinters[msg.sender], "KhaleejiNFT: address not allowed to mint");
        _safeMint(to, tokenId);
    }

    /**
     * Mints tokenIds to specific to address
     */
    function mintMany(address to, uint256[] memory tokenIds) external {
        require(allowedMinters[msg.sender], "KhaleejiNFT: address not allowed to mint");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i]);
        }
    }

    // Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
    * Allows to set base URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // Get metadata URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExt
                    )
                )
                : "";
    }
}