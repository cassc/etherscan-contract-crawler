// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ThugDogs is ERC721Enumerable, Ownable {
    uint256 maxTotalSupply = 10_000;
    string private _baseUri;
    string public contractURI;

    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    constructor(string memory baseUri, string memory contractUri)
        ERC721("Thug Dogs In Doggyland", "TDD")
        Ownable()
    {
        _baseUri = baseUri;
        contractURI = contractUri;
    }

    modifier _isEnoughTokens(uint256 amount) {
        require(
            _tokenIds.current() + amount <= maxTotalSupply,
            "ThugDogs: more than possible minted amount"
        );
        _;
    }

    modifier _checkAmount(uint256 amount) {
        require(amount >= 1, "ThugDogs: amount should be positive");
        _;
    }

    function setContractURI(string memory _contractUri) public onlyOwner {
        contractURI = _contractUri;
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, _tokenId.toString(), ".json"));
    }

    function mintTokens(address _to, uint256 amount) public onlyOwner {
        _mintTokens(_to, amount);
    }

    function _mintTokens(address _to, uint256 amount)
        internal
        _isEnoughTokens(amount)
        _checkAmount(amount)
    {
        for (uint16 i = 0; i < amount; i++) {
            _tokenIds.increment();
            _safeMint(_to, _tokenIds.current());
        }
    }

    function getTokensOfOwner(address _owner)
        external
        view
        returns (uint16[] memory _tokensIDs)
    {
        uint16 _tokenCount = uint16(balanceOf(_owner));
        if (_tokenCount == 0) {
            return new uint16[](0);
        }

        _tokensIDs = new uint16[](_tokenCount);
        for (uint16 _index; _index < _tokenCount; _index++) {
            _tokensIDs[_index] = uint16(tokenOfOwnerByIndex(_owner, _index));
        }
    }

    // to protect
    function renounceOwnership() public override onlyOwner {}
}