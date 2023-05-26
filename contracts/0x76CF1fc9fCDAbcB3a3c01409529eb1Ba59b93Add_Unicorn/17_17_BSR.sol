// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Unicorn is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    event Stopped(uint256 timestamp);

    bool public isStopped = false; // Once true, the minting is stopped forever
    address minter = 0x4034937e6fF8de6da40992f2F184CccBE06Ec93a;

    string private _uri;
    uint public constant MAX_SUPPLY = 150;

    Counters.Counter private _tokenIdCounter;

    mapping (bytes32 => uint256) public transactionIDToTokenID;

    constructor() ERC721("Balmain x Space Runners Unicorn", "Unicorn") {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _pause();
    }

    // be careful once you call this function, you can't mint anymore, forever
    function stop() public onlyOwner {
        require(!isStopped, "Minting is already stopped");
        isStopped = true;
        emit Stopped(block.timestamp);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, bytes32[] memory transactionIDs) public {
        require(minter == msg.sender, "MinterRole: caller does not have the Minter role");
        require(!isStopped, "Minting is stopped");
        require(MAX_SUPPLY >= _tokenIdCounter.current() + transactionIDs.length, "Exceeds max supply");

        for (uint i = 0; i < transactionIDs.length; i++) {
            require(transactionIDToTokenID[transactionIDs[i]] == 0, "Token already minted");

            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            transactionIDToTokenID[transactionIDs[i]] = tokenId;
            _safeMint(to, tokenId);
        }
    }

    function lastMintId() public view returns(uint256) {
        return _tokenIdCounter.current();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _baseURI() internal override(ERC721) view returns(string memory) {
        return _uri;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _uri = uri;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}