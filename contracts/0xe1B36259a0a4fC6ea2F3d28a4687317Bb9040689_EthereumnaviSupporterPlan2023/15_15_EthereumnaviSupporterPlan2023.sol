// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract EthereumnaviSupporterPlan2023 is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public _imageUrl = "https://ipfs.io/ipfs/Qmao9Q11ZqLez1BrGk33BXR9TiPLVLNJMQpeG7B3EAi1uv";
    uint256 public constant MINT_PRICE = 0.25 ether;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("EthereumnaviSupporterPlan2023", "ESP2023") {}

    function setImageUrl(string memory _url) public onlyOwner {
        _imageUrl = _url;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint() public payable whenNotPaused{
        require(msg.value == MINT_PRICE, "Error: Invalid value");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
                tokenId.toString(),
            '"},',
            '{"trait_type": "name", "value": "',
                "Ethereumnavi Supporter Plan 2023",
            '"}'
        );

        bytes memory description = 'This SBT is a collection for Ethereumnavi supporter plans; it will serve as an access path to the discord during 2023.';
        bytes memory metadata =
            abi.encodePacked(
                '{"name": "Ethereumnavi Supporter Plan 2023 #',
                tokenId.toString(),
                '", "description": "',
                description,
                '", "image": "',
                _imageUrl,
                '", "attributes": [',
                attributes,
                ']}'
            );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        require(from == address(0), "Err: token is SOUL BOUND");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function renounceOwnership() public override onlyOwner {}   
}