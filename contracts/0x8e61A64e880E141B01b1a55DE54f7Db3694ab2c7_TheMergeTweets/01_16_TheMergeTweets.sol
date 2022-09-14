// SPDX-License-Identifier: MIT

//  ooooooooooooo oooo                      ooo        ooooo
//  8'   888   `8 `888                      `88.       .888'
//       888       888 .oo.    .ooooo.       888b     d'888   .ooooo.  oooo d8b  .oooooooo  .ooooo.
//       888       888P"Y88b  d88' `88b      8 Y88. .P  888  d88' `88b `888""8P 888' `88b  d88' `88b
//       888       888   888  888ooo888      8  `888'   888  888ooo888  888     888   888  888ooo888
//       888       888   888  888    .o      8    Y     888  888    .o  888     `88bod8P'  888    .o
//      o888o     o888o o888o `Y8bod8P'     o8o        o888o `Y8bod8P' d888b    `8oooooo.  `Y8bod8P'
//                                                                              d"     YD
//                                                                              "Y88888P'
//
//               ooooooooooooo                                          .
//               8'   888   `8                                        .o8
//                    888      oooo oooo    ooo  .ooooo.   .ooooo.  .o888oo  .oooo.o
//                    888       `88. `88.  .8'  d88' `88b d88' `88b   888   d88(  "8
//                    888        `88..]88..8'   888ooo888 888ooo888   888   `"Y88b.
//                    888         `888'`888'    888    .o 888    .o   888 . o.  )88b
//                   o888o         `8'  `8'     `Y8bod8P' `Y8bod8P'   "888" 8""888P'

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TheMergeTweets is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    uint256 public price = 0.003 ether;
    uint256 public maxPerTx = 20;
    uint256 public maxPerFree = 1;
    uint256 public totalFree = 10000;
    uint256 public maxSupply = 10000;
    bool public merged;
    uint256 public totalFreeMinted = 0;

    mapping(address => uint256) public _mintedFreeAmount;

    constructor() ERC721A("TheMergeTweets", "TMT") {}

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function mint(uint256 count) external payable {
        require(
            block.difficulty >= 58750000000000000000000 || merged,
            "Mint starts at TTD 58750000000000000000000"
        );

        uint256 cost = price;
        bool isFree = ((totalFreeMinted + count < totalFree + 1) &&
            (_mintedFreeAmount[msg.sender] < maxPerFree));

        if (isFree) {
            require(totalSupply() + count <= maxSupply, "No more");
            require(count <= maxPerTx, "Max per TX reached.");
            if (count >= (maxPerFree - _mintedFreeAmount[msg.sender])) {
                require(
                    msg.value >=
                        (count * cost) -
                            ((maxPerFree - _mintedFreeAmount[msg.sender]) *
                                cost),
                    "Please send the exact ETH amount"
                );
                _mintedFreeAmount[msg.sender] = maxPerFree;
                totalFreeMinted += maxPerFree;
            } else if (count < (maxPerFree - _mintedFreeAmount[msg.sender])) {
                require(msg.value >= 0, "Please send the exact ETH amount");
                _mintedFreeAmount[msg.sender] += count;
                totalFreeMinted += count;
            }
        } else {
            require(
                msg.value >= count * cost,
                "Please send the exact ETH amount"
            );
            require(totalSupply() + count <= maxSupply, "No more");
            require(count <= maxPerTx, "Max per TX reached.");
        }

        _safeMint(msg.sender, count);
    }

    function costCheck() public view returns (uint256) {
        return price;
    }

    function mergeCheck() public view returns (bool) {
        return block.difficulty >= 58750000000000000000000 || merged;
    }

    function maxFreePerWallet() public view returns (uint256) {
        return maxPerFree;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory baseuri_) public onlyOwner {
        baseURI = baseuri_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxTotalFree(uint256 MaxTotalFree_) external onlyOwner {
        totalFree = MaxTotalFree_;
    }

    function setMaxPerFree(uint256 MaxPerFree_) external onlyOwner {
        maxPerFree = MaxPerFree_;
    }

    function ownerMintMultiAirdrop(address[] calldata addresses)
        external
        onlyOwner
    {
        require(
            totalSupply() + addresses.length < maxSupply + 1,
            "Exceeds max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(address(addresses[i]), 1);
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function ownerMintAirdrop(address to, uint256 count) external onlyOwner {
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");
        _safeMint(to, count);
    }

    function toggleMinting() external onlyOwner {
        merged = !merged;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}