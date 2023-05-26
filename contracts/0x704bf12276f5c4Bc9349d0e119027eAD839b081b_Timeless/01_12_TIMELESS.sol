// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

library Commons {

    enum ExchangeType {
        founder,
        nftTree,
        none
    }

}

contract Timeless is ERC721, Ownable {
  using Strings for uint256;

    bool isLocked = false;

    event SetMinter(address minter, bool enabled);

    mapping(address => bool) public minters;

    string public baseURI;
    string public customTokenURI;

    constructor(string memory baseURI_) ERC721("Timeless", "TMLS") {
        setMinterAccess(msg.sender, true);
        baseURI = baseURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(!isLocked,"Base URI is locked");
        baseURI = baseURI_;
    }

    function lockBaseURI() external onlyOwner {
        isLocked = true;
    }

    function setCustomTokenURI(string memory customTokenURI_) external onlyOwner {
        customTokenURI = customTokenURI_;
    }

    function setMinterAccess(address minter, bool enabled) public onlyOwner {
        minters[minter] = enabled;
        emit SetMinter(minter, enabled);
    }

    function issueToken(address to, uint256 _tokenId, Commons.ExchangeType e) external {
        require(minters[msg.sender], "Not a minter");
        _issueToken(to, _tokenId, e);
    }

    function _issueToken(address to, uint256 _tokenId, Commons.ExchangeType e) internal {
        if (e == Commons.ExchangeType.founder) {
            _tokenId -= 1000000;
            require(_tokenId >= 1 && _tokenId <= 10420, "Cannot be minted: founder");
        } else if (e == Commons.ExchangeType.nftTree){
            _tokenId += 10420;
            require(_tokenId >= 10421 && _tokenId <= 10840, "Cannot be minted: nftTree");
        } else {
            require(_tokenId >= 1 && _tokenId <= 11111, "Cannot be minted: out of range");
        }

        _safeMint(to, _tokenId);
    }

    function mintBatch(address to, uint256 tokenIdRangeStart, uint256 tokenIdRangeEnd) external onlyOwner {
        require(tokenIdRangeStart >= 10841 && tokenIdRangeEnd <= 11111, "TokenId must be >=10841 and <=11111");
        while(tokenIdRangeStart <= tokenIdRangeEnd) {
            _safeMint(to, tokenIdRangeStart++);
        }
    }

    function issueBatch(address to, uint256[] memory tokenIds, Commons.ExchangeType[] memory es) external {
        require(minters[msg.sender], "Not a minter");
        require(tokenIds.length == es.length, "Length mismatch");

        for (uint256 index = 0; index < tokenIds.length; index++) {
            _issueToken(to, tokenIds[index], es[index]);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Not a token");

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    function customTokenUri(uint256 tokenId) external view virtual returns (string memory) {
        require(_exists(tokenId), "Not a token");

        return bytes(customTokenURI).length > 0
            ? string(abi.encodePacked(customTokenURI, tokenId.toString()))
            : '';
    }

}