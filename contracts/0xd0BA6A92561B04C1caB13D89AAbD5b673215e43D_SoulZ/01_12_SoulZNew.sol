// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC721A {
    function ownerOf(uint256 tokenId) external view returns (address);
}
contract SoulZ is ERC721, Ownable, Pausable {
    using Strings for uint256;
    IERC721A public oldCollection;
    string private _baseTokenURI =
        "https://ipfs.io/ipfs/QmPcp8s3mC3nZ6iojuThjSCaVQ4YejXSYhik5e7SBYM8Fk/";
    uint256 public totalSupply;

    constructor() ERC721("SoulZ Monogatari", "SLZM") {
        oldCollection = IERC721A(0xA5c807A62CD6774d6BF518dD2dEc0aE17446Ad8d);
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

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function claimNFT(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            totalSupply += 1;
            _mint(oldCollection.ownerOf(tokenId), tokenId);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdrawToSender() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdraw() external onlyOwner {
        address[8] memory addresses = [
            0x2bC46E31a324AB9a208B3B0Fb91958E390DC0797,
            0x897C456868d4888c258528f8660b932804Cb6948,
            0xc0524078b6ABC601158bFc328c9A2B64Ee376e23,
            0x8FE4A152939Ece65f1fC651e57b8aA84cFc137C2,
            0x29d54F704a4253B5c3a8aE6CBDFDb01472119713,
            0x896baBEE76dBdF3F6d3b7470ad1e47e8c2016BDB,
            0xE892C48B5CdD20F50dbFdF4A949c649Aee9F24Da,
            0x24e21ae83ccB58EbAE990Cf1e014e062F6bb7B19
        ];

        uint256[8] memory shares = [
            uint256(2),
            uint256(2),
            uint256(3),
            uint256(3),
            uint256(10),
            uint256(60),
            uint256(60),
            uint256(60)
        ];

        uint256 balance = address(this).balance;

        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 amount = i == addresses.length - 1
                ? address(this).balance
                : (balance * shares[i]) / 200;
            payable(addresses[i]).transfer(amount);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}