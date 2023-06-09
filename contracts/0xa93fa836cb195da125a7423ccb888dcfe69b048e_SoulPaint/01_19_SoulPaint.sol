// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721psi/contracts/ERC721Psi.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SoulPaint is ERC721Psi, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";

    //tokenURI
    mapping(uint256 => string) private _tokenURIs;

    //funds
    address funds;

    constructor(
        string memory _initBaseURI,
        address _receiver,
        uint96 feeNumerator
    ) ERC721Psi("SoulPaint", "SP") {
        setBaseURI(_initBaseURI);
        setDefaultRoyalty(_receiver, feeNumerator);
    }

    //modifier
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "caller is not EOA");
        _;
    }

    function mint_Owner(uint256 tokenQuantity)
        public
        payable
        nonReentrant
        onlyOwner
        onlyEOA
    {
        _safeMint(msg.sender, tokenQuantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw() external onlyOwner nonReentrant {
        payable(funds).transfer(address(this).balance);
    }

    function setfunds(address funds_) external onlyOwner {
        funds = funds_;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Psi, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}