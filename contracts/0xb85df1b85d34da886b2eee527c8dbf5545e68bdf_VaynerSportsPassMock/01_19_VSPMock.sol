// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';

contract VaynerSportsPassMock is ERC721Enumerable, ERC721Royalty, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 15555;
    uint256 public constant MAX_PUBLIC_MINT = 100;
    uint256 public constant MAX_RESERVE_SUPPLY = 15555;

    string private _baseURIextended = "https://minting-pipeline-vayner.herokuapp.com/";
    uint256 public reserveSupply;

    constructor() ERC721("VaynerSports Pass Mock", "VSP Mock") {
    }

    /**
     * @dev checks to see if amount of tokens to be minted would exceed the maximum supply allowed
     */
    modifier ableToMint(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        _;
    }

    ////////////////
    // admin
    ////////////////
    /**
     * @dev reserves a number of tokens
     */
    function devMint(uint256 numberOfTokens, address _to) external ableToMint(numberOfTokens) nonReentrant {
        require(reserveSupply + numberOfTokens <= MAX_RESERVE_SUPPLY, 'Number would exceed max reserve supply');
        uint256 ts = totalSupply();

        reserveSupply += numberOfTokens;
        for (uint256 index = 0; index < numberOfTokens; index++) {
            _safeMint(_to, ts + index);
        }
    }

    function mintToken(uint256 tokenId) external nonReentrant {
        require(!_exists(tokenId), "Token ID already exists");
        _mint(msg.sender, tokenId);
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @dev sets the base uri for {_baseURI}
     */
    function setBaseURI(string memory baseURI_) external {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721Enumerable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}