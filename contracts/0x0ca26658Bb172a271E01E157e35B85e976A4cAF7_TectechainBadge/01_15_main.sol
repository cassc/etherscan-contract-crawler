// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract TectechainBadge is ERC721, ERC721Enumerable, Ownable, ERC721Burnable   {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // token
    uint256 private constant MAX_PER_MINT = 20;
    string private baseURI_ = "ipfs://bafybeiclkzxxwdneknav63wf7h4ulwcjzplxro6h5qw5mjqbkjuwt2hrfy/";
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Tectechain E-Badge", "Badge")  {}

    function setURI(string calldata newURI) external {
       baseURI_  = newURI;
    }

    /**
        @notice get the total supply including burned token
    */
    function tokenIdCurrent() external view returns(uint256) {
        return _tokenIdCounter.current();
    }

    function _safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /**
        @notice air drop tokens to recievers
        @param recievers each account will receive one token
    */
    function airDrop(address[] calldata recievers) external onlyOwner {
        require(recievers.length <= MAX_PER_MINT, "High Quntity");

        for (uint256 i = 0; i < recievers.length; i++) {
            _safeMint(recievers[i]);
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString(), ".json")) : "";
    }

    function _burn(uint256 tokenId) internal override (ERC721){
        super._burn(tokenId);
    }

}