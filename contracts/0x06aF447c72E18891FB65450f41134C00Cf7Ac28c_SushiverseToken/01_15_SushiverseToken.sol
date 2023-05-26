// // SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

pragma solidity ^0.7.0;
pragma abicoder v2;

contract SushiverseToken is ERC721, Ownable {
    using SafeMath for uint256;

    string public SUSHI_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN TOKENS ARE ALL SOLD OUT

    uint256 public constant tokenPrice = 59000000000000000; // 0.059 ETH
    uint256 public constant maxTokenPurchase = 5;
    uint256 public constant MAX_TOKENS = 10000;

    bool public saleIsActive = false;
    bool public presaleIsActive = false;

    mapping(address => bool) private _presaleList;
    mapping(address => uint256) private _presaleListClaimed;

    uint256 public presaleMaxMint = 3;
    uint256 public devReserve = 64;

    event SushiMinted(uint256 supply);

    constructor() ERC721("Sushiverse", "SV") {}

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function reserveTokens(address _to, uint256 _reserveAmount)
        external
        onlyOwner
    {
        require(
            _reserveAmount > 0 && _reserveAmount <= devReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            uint256 id = totalSupply();
            _safeMint(_to, id);
        }
        devReserve = devReserve.sub(_reserveAmount);
    }

    function setProvenanceHash(string memory provenanceHash)
        external
        onlyOwner
    {
        SUSHI_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function togglePresaleState() external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mintSushi(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Token");
        require(
            numberOfTokens > 0 && numberOfTokens <= maxTokenPurchase,
            "Can only mint one or more tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 id = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, id);
                emit SushiMinted(id);
            }
        }
    }

    function presaleSushi(uint256 numberOfTokens) external payable {
        require(presaleIsActive, "Presale is not active");
        require(_presaleList[msg.sender], "You are not on the Presale List");
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of token"
        );
        require(
            numberOfTokens > 0 && numberOfTokens <= presaleMaxMint,
            "Cannot purchase this many tokens"
        );
        require(
            _presaleListClaimed[msg.sender].add(numberOfTokens) <=
                presaleMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 id = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _presaleListClaimed[msg.sender] += 1;
                _safeMint(msg.sender, id);
                emit SushiMinted(id);
            }
        }
    }

    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = true;
        }
    }

    function removeFromPresaleList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = false;
        }
    }

    function setPresaleMaxMint(uint256 maxMint) external onlyOwner {
        presaleMaxMint = maxMint;
    }

    function onPreSaleList(address addr) external view returns (bool) {
        return _presaleList[addr];
    }
}