// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Lilia is Ownable, ERC721URIStorage, ERC721Enumerable {
    using Counters for Counters.Counter;

    address public controller;
    Counters.Counter public counter;
    string public baseURI;

    event ControllerUpdated(
        address indexed oldController,
        address indexed newController
    );

    constructor() ERC721("Lilia", "Lilia") {}

    /**
     * @dev See {ERC721 - _beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    /**
     * @dev Set controller for minting
     */
    function setController(address newController) public onlyOwner {
        emit ControllerUpdated(controller, newController);

        controller = newController;
    }

    /**
     * @dev Mint NFT
     */
    function mint(
        address account,
        string memory _tokenURI,
        bytes memory data
    ) public {
        require(
            _msgSender() == controller || _msgSender() == owner(),
            "Lilia: only owner or controller"
        );

        // Increase current counter
        counter.increment();

        // Mint NFT to account
        _safeMint(account, counter.current(), data);

        // Set URI for NFT
        _setTokenURI(counter.current(), _tokenURI);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Set uri for a specific token id
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(tokenId, _tokenURI);
    }
}