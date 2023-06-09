// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/DefaultOperatorFilterer.sol";

contract MoonsheepOrdinals is
    Ownable,
    DefaultOperatorFilterer,
    ERC2981,
    ERC721A
{
    event ClaimMoonsheep(uint256 indexed tokenId, address indexed claimee, string btcAddress);

    string constant InvalidMoonsheep = "Invalid Moonsheep tokenId";
    string constant ErrNotSheepOwner = "Not Moonsheep's owner";
    string constant MoonsheepAlreadyClaimed = "Moonsheep already claimed";
    string baseURI = 'https://thesadtimes.com/api/metadata/moonsheep';
    bool public isClaimingEnabled = false;

    constructor(
        address _owner,
        uint96 feeBasisPoints
    ) ERC721A("TheSadTimesMoonsheepOrdinals", "STMSO") {
        _transferOwnership(_owner);
        _setDefaultRoyalty(_owner, feeBasisPoints);
        _mint(_owner, 111);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function enableClaiming() external onlyOwner {
        isClaimingEnabled = true;
    }

    function disableClaiming() external onlyOwner {
        isClaimingEnabled = false;
    }

    function updateRoyalty(uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(owner(), feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return ERC2981.supportsInterface(interfaceId) ||
          super.supportsInterface(interfaceId);
    }

    function _claimAndBurn(uint256 tokenId, string calldata btcAddress)
        internal
    {
        require(isClaimingEnabled, 'Claiming is not enabled.');
        require(tokenId > 0 && tokenId < 112, InvalidMoonsheep);
        require(_exists(tokenId), MoonsheepAlreadyClaimed);
        require(msg.sender == ownerOf(tokenId), ErrNotSheepOwner);
        _burn(tokenId);
        emit ClaimMoonsheep(tokenId, msg.sender, btcAddress);
    }


    function claimAndBurn(uint256 tokenId, string calldata btcAddress)
        external
    {
        _claimAndBurn(tokenId, btcAddress);
    }

    function claimAndBurnMultiple(uint256[] calldata tokenIds, string[] calldata btcAddresses)
        external
    {
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i = 0; i < tokenIdsLength; ++i) {
          _claimAndBurn(tokenIds[i], btcAddresses[i]);
        }
    }

    function updateBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId)));
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}