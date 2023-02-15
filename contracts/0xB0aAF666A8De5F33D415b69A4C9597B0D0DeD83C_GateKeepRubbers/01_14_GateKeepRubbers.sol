// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GateKeepRubbers is ERC1155, Ownable, ReentrancyGuard { 
    using SafeMath for uint256;
    using Strings for uint256;

    string public name = "GateKeep Rubbers";
    string public symbol = "RUBBERS";
    string public baseURI = "";

    uint256 public price = 0.018 ether;
    uint256 public supply = 100000;
    uint256 public mintedCount = 0;
    uint256 public maxMint = 10;

    uint256 public goldenCount = 0;

    address public deployer = 0x21096E97E9fA7c2d283E8C4356e2d9e1fE903dE7;

    bool public saleActive = false;

    constructor() ERC1155("https://api.gatekeep.xyz/api/rubbers/") { }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "no eth");
        (bool succcess,) = deployer.call{value: address(this).balance}("");
        require(succcess, "Error withdrawing.");
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function saleSwitch() external onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        require(_supply > mintedCount, "updated supply must be greater than minted supply.");
        supply = _supply;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function mint(uint256 quantity) external payable {
        require(saleActive, "sale not live");
        require(mintedCount.add(quantity) <= supply, "Not enough supply for this mint amount");
        require(quantity <= maxMint, "max mint 10" );
        require(msg.value >= price.mul(quantity), "Not enough ether sent");

        mintedCount += quantity;

        _mint(msg.sender, 1, quantity, "");
        return;
    }

    function summonGolden() external nonReentrant {
        require((balanceOf(msg.sender, 1) >= 8), "you dont own enough to summon");

        _burn(msg.sender, 1, 8);

        goldenCount += 1;

        _mint(msg.sender, 2, 1, "");
    }

    function airdrop(address[] calldata chosenOnes, uint256[] calldata heldCount) external onlyOwner {
       for (uint256 i; i < chosenOnes.length; ) {
            _mint(chosenOnes[i], 2, heldCount[i], "");
            unchecked {
                ++i;
            }
        }
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }
}