// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SuperbowlNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for string;

    // Storage Game Variables
    mapping(address => uint8) private percentageDistribution;

    address[] private distributionList;

    //NFT Variables
    uint256 public MintPrice = 0 ether;
    uint256 public LockedSupply = 10;

    string private _baseTokenURI;

    uint public constant HardCap = 1;
    bool public SaleIsActive = false;
    bool public forceIsActive = false;
    

    mapping(address => uint256[]) public owners;

    constructor(
        string memory uri,
        uint initialSupply,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        _baseTokenURI = uri;
        LockedSupply = initialSupply;
    }

    function changeShareOf(address addr, uint8 share) public onlyOwner {
        percentageDistribution[addr] = share;
        if(share > 0) {
            distributionList.push(addr);
        }
    }

    function flipSaleState() public onlyOwner {
        SaleIsActive = !SaleIsActive;
    }
    
    function increaseLockedSupplyBy(uint256 amount) public onlyOwner {
        LockedSupply += amount;
    }

    function flipForce() public onlyOwner {
        forceIsActive = !forceIsActive;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        MintPrice = _newPrice;
    }

    function increaseSupply(uint256 increment) public onlyOwner {
        LockedSupply += increment;
    }


    function withdrawAll() public payable onlyOwner {

        uint256 balance = address(this).balance;
        for(uint8 i = 0; i< distributionList.length ; i++)
        {
            address target = distributionList[i];
            require(payable(distributionList[i]).send(balance.mul(percentageDistribution[target]).div(100)));
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function mintRabbits(uint numberOfTokens) public payable {
        require(SaleIsActive, "Sale must be active to mint Superbowl");
        require(numberOfTokens <= HardCap,"Maximum mints per transaction exceeded");
        require(totalSupply() + numberOfTokens <= LockedSupply,"Purchase would exceed max supply of Superbowl");
        require(MintPrice * numberOfTokens == msg.value,"Ether value sent is not correct");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            owners[msg.sender].push(mintIndex);
            if (totalSupply() < LockedSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // function _afterTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     uint256 batchSize
    // ) internal virtual override {
    //     uint256[] memory fromTokens = owners[from];

    //     if (from != address(0)) {
    //         // Avoiding minting
    //         unchecked {
    //             for (uint256 i = 0; i < fromTokens.length; i++) {
    //                 if (fromTokens[i] == tokenId) {
    //                     uint256 element = fromTokens[fromTokens.length - 1];
    //                     fromTokens[fromTokens.length - 1] = fromTokens[i];
    //                     fromTokens[i] = element;
    //                     delete fromTokens[fromTokens.length - 1];
    //                 }
    //             }
    //             owners[to].push(tokenId);
    //         }
    //     }
    // }

    function getMyNFTS() public view returns (uint256[] memory) {
        return owners[msg.sender];
    }

    // function jediForce() public {
    //     require(SaleIsActive, "Sale must be active to mint Kaido");
    //     require(forceIsActive,"Only authorized wallets can use this jedi function");
    //     require(totalSupply().add(1) <= LockedSupply,"Purchase would exceed max supply of Kaido");
    //     uint mintIndex = totalSupply();
    //     if (totalSupply() < LockedSupply) {
    //         _safeMint(msg.sender, mintIndex);
    //     }
    // }
}