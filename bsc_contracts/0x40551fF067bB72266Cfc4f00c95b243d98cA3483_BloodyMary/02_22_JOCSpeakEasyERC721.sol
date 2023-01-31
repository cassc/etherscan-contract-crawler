/**
    ┌─────────────────────────────────────────────────────────────────┐
    |             --- DEVELOPED BY JackOnChain (JOC) ---              |
    |          Looking for help to create your own contract?          |
    |                    Telgegram: JackTripperz                      |
    |                      Discord: JackT#8310                        |
    └─────────────────────────────────────────────────────────────────┘                                               
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract JOCSpeakEasyERC721 is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    DefaultOperatorFilterer,
    ERC2981
{
    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIdCounter;
    address internal bankAddress = 0xce238AddA1C558f213469d442128739a876fBB3d;
    address internal staffAddress = 0x90849d08168D8D665cb45ae4BD3f9E6037C6E365;
    address internal ownerAddress;
    string internal ipfsString;
    
    address public speakEasyContractAddress;
    address public mintingContractAddress;

    constructor(string memory name, string memory shortname, string memory ipfs) ERC721(name, shortname) {
        ownerAddress = _msgSender();
        _setDefaultRoyalty(bankAddress, 500);
        ipfsString = ipfs;
    }

    modifier onlyTeam() {
        require(
            msg.sender == staffAddress ||
                msg.sender == speakEasyContractAddress ||
                msg.sender == mintingContractAddress ||
                msg.sender == ownerAddress
        );
        _;
    }

    function minted() public view returns(uint256 mintedNFTs) {
        return _tokenIdCounter.current();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function safeMintMultiple(address to, uint256 quantity) public onlyTeam {
        for (uint256 i = 0; i < quantity; i++) {
            safeMint(to);
        }
    }

    function safeMint(address to) public onlyTeam {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(
            tokenId,
            ipfsString
        );
    }

    function setSpeakEasyAddress(address adr) public onlyOwner {
        speakEasyContractAddress = adr;
    }

    function setMintingAddress(address adr) public onlyOwner {
        mintingContractAddress = adr;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}