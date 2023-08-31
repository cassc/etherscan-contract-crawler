/**
 * Y2K / 千禧少女
 * ~ 再び2000年に戻る ~
 *
 * Twitter: https://twitter.com/y2k_eth
 * Website: https://y2k.city
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Y2K is ERC721A, Ownable {
    constructor() ERC721A("Y2K", "Y2K") {
        config = Config(7777, 7, 0, 0);
    }

    string public revealUrl;
    uint public revealSeed;
    Config public config;

    struct Config {
        uint256 maxSupply;
        uint256 maxMint;
        uint256 price;
        uint256 phase;
    }

    mapping(address => bool) FREE_MINTED;

    // public mint
    function backTo2000(uint256 count) external payable {
        require(config.phase == 1, "Invalid phase.");
        
        _mint(count);
    }

    function _mint(uint256 count) private {
        uint256 pay = count * config.price;

        if (!FREE_MINTED[msg.sender]) {
            pay -= config.price;
        }

        FREE_MINTED[msg.sender] = true;
        require(pay <= msg.value, "No enough Ether.");
        require(totalSupply() + count <= config.maxSupply, "Exceed maxmiumn.");
        require(
            _numberMinted(msg.sender) + count <= config.maxMint,
            "Cant mint more."
        );

        _safeMint(msg.sender, count);
    }

    function devMint(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= config.maxSupply, "");
        _safeMint(msg.sender, _quantity);
    }

    function tokenURI(uint256 _id)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_id > 0 && _id <= totalSupply(), "Invalid token ID.");

        return string(abi.encodePacked(revealUrl, revealId(_id)));
    }

    function revealId(uint256 _id) private view returns (string memory) {
        uint256 maxSupply = config.maxSupply;
        uint256[] memory temp = new uint256[](maxSupply + 1);

        for (uint256 i = 1; i <= maxSupply; i += 1) {
            temp[i] = i;
        }

        for (uint256 i = 1; i <= maxSupply; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(revealSeed, i))) %
                (maxSupply)) + 1;

            (temp[i], temp[j]) = (temp[j], temp[i]);
        }

        return Strings.toString(temp[_id]);
    }

    function numberMinted(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }

    function tokensOfOwner(address owner)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function setRevealSeed(uint seed) external onlyOwner {
        require(revealSeed == 0, "seed exist");
        revealSeed = seed;
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        require(max <= config.maxSupply, "invalid.");
        config.maxSupply = max;
    }

    function setRevealUrl(string calldata url) external onlyOwner {
        revealUrl = url;
    }

    function setMaxMint(uint256 max) external onlyOwner {
        config.maxMint = max;
    }

    function setPrice(uint256 price) external onlyOwner {
        config.price = price;
    }

    function setPhase(uint256 phase) external onlyOwner {
        config.phase = phase;
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "error.");
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "");
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
}