// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RitoAsu is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string private baseURI;
    uint256 public _maxSupply;
    uint256 public _cost;

    constructor(
        string memory baseUri_,
        uint256 cost_,
        uint256 maxSupply_
    ) ERC721("Rito Asu", "RITO") {
        baseURI = baseUri_;
        _cost = cost_;
        _maxSupply = maxSupply_;
        _tokenIdCounter.reset();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory baseUri_) external onlyOwner {
        baseURI = baseUri_;
    }

    function _setParameters(
        uint256 cost_,
        uint256 maxSupply_
    ) external onlyOwner {
        _cost = cost_;
        _maxSupply = maxSupply_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function mint() public payable {
        require(totalSupply() + 1 <= _maxSupply, "Max supply reached");
        require(msg.sender == tx.origin, "Not allow contract mint");
        require(msg.value == _cost, "Sended value does not match mint price");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}