// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./IVaccine.sol";

struct SourceTokensData {
    uint256 chapter1TokenId;
    uint256 chapter2TokenId;
    bool isMutated;
}

contract Pork1984ChapterIII is ERC721A, Ownable, Pausable {
    IERC721 private _chapter1Contract;
    IERC721 private _chapter2Contract;
    IVaccine private _vaccinesContract;

    mapping(uint256 => uint256) private _chapter1TokenIdToChapter3TokenId;
    mapping(uint256 => uint256) private _chapter2TokenIdToChapter3TokenId;
    mapping(uint256 => SourceTokensData) private _chapter3TokenIdToSourceTokensData;

    string private __baseURI;

    constructor() ERC721A("Pork1984 Chapter III", "PORK1984-C3") {
        _chapter1Contract = IERC721(0x14A2dFF3b2FB4dFfa35b2006e84BF1CBB0Ac4bBA);
        _chapter2Contract = IERC721(0x66B1dd8B17849E270075229b901ba9Ef5dC3A8DC);
        _vaccinesContract = IVaccine(0xEBc651F4A8C898b5C45FBEEEC9CF125bB8b452E1);

        _pause();
        __baseURI = 'https://api.pork1984.io/api/chapter3/token/';
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        __baseURI = baseURI;
    }

    function _setSourceTokensData(uint256 chapter1TokenId, uint256 chapter2TokenId, uint256 chapter3TokenId) internal {
        _chapter1TokenIdToChapter3TokenId[chapter1TokenId] = chapter3TokenId;
        _chapter2TokenIdToChapter3TokenId[chapter2TokenId] = chapter3TokenId;
        _chapter3TokenIdToSourceTokensData[chapter3TokenId] = SourceTokensData(chapter1TokenId, chapter2TokenId, isVaccinated(chapter1TokenId));
    }

    function mint(uint256[] calldata chapter1TokenIds, uint256[] calldata chapter2TokenIds) external whenNotPaused {
        _mintManyTo(chapter1TokenIds, chapter2TokenIds, _msgSender());
    }

    function mintTo(uint256[] calldata chapter1TokenIds, uint256[] calldata chapter2TokenIds, address to) external onlyOwner {
        _mintManyTo(chapter1TokenIds, chapter2TokenIds, to);
    }

    function _mintManyTo(uint256[] calldata chapter1TokenIds, uint256[] calldata chapter2TokenIds, address to) internal {
        uint256 quantity = chapter1TokenIds.length;
        require(quantity == chapter2TokenIds.length, "both lists must have equal length");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 chapter1TokenId = chapter1TokenIds[i];
            uint256 chapter2TokenId = chapter2TokenIds[i];

            require(!isChapter1TokenAlreadyUsed(chapter1TokenId), "Chapter I token is already used");
            require(!isChapter2TokenAlreadyUsed(chapter2TokenId), "Chapter II token is already used");

            require(_chapter1Contract.ownerOf(chapter1TokenId) == to, "target address is not an owner of the given chapter 1 token");
            require(_chapter2Contract.ownerOf(chapter2TokenId) == to, "target address is not an owner of the given chapter 2 token");

            _setSourceTokensData(chapter1TokenId, chapter2TokenId, _nextTokenId() + i);
        }

        _mint(to, quantity);
    }

    function canMintForChapter1Token(uint256 tokenId) public view returns(bool) {
        return !isChapter1TokenAlreadyUsed(tokenId) && _chapter1Contract.ownerOf(tokenId) == _msgSender();
    }

    function canMintForChapter2Token(uint256 tokenId) public view returns(bool) {
        return !isChapter2TokenAlreadyUsed(tokenId) && _chapter2Contract.ownerOf(tokenId) == _msgSender();
    }

    function getChapter1TokenId(uint256 chapter3TokenId) public view returns(uint256) {
        return _chapter3TokenIdToSourceTokensData[chapter3TokenId].chapter1TokenId;
    }

    function getChapter2TokenId(uint256 chapter3TokenId) public view returns(uint256) {
        return _chapter3TokenIdToSourceTokensData[chapter3TokenId].chapter2TokenId;
    }

    function isMutated(uint256 chapter3TokenId) public view returns(bool) {
        return _chapter3TokenIdToSourceTokensData[chapter3TokenId].isMutated;
    }

    function getSourceTokensData(uint256 chapter3TokenId) public view returns(SourceTokensData memory) {
        return _chapter3TokenIdToSourceTokensData[chapter3TokenId];
    }

    function getChapter3TokenIdByChapter1TokenId(uint256 chapter1TokenId) public view returns(uint256) {
        return _chapter1TokenIdToChapter3TokenId[chapter1TokenId];
    }

    function getChapter3TokenIdByChapter2TokenId(uint256 chapter2TokenId) public view returns(uint256) {
        return _chapter2TokenIdToChapter3TokenId[chapter2TokenId];
    }

    function isVaccinated(uint256 chapter1TokenId) public view returns(bool) {
        return _vaccinesContract.isFullyVaccinated(chapter1TokenId);
    }

    function isChapter1TokenAlreadyUsed(uint256 chapter1TokenId) public view returns(bool) {
        return getChapter3TokenIdByChapter1TokenId(chapter1TokenId) != 0;
    }

    function isChapter2TokenAlreadyUsed(uint256 chapter2TokenId) public view returns(bool) {
        return getChapter3TokenIdByChapter2TokenId(chapter2TokenId) != 0;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}