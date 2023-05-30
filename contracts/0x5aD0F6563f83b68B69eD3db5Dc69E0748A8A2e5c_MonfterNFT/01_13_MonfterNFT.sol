// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MonfterNFT is ERC721, AccessControl {
    using Counters for Counters.Counter;

    // the image file containing all the monfters
    string public imageHash =
        "062f48fb4279f4e5258a50bf1b72f30a569986c761f6e43f4dfc9ef39e60f621";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    // max token
    uint256 public _maxSupply = 8000;

    // base URI
    string public _URI;

    constructor() ERC721("Monfters Club", "Monfter") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view override returns (string memory) {
        return _URI;
    }

    /**
     * @dev public function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _URI = uri;
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < _maxSupply, "MonfterNFT: mint invalid");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /*
     * @dev totalSupply
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}