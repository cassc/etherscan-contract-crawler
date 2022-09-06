//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMinter.sol";

contract LACPlatinum is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 4444;

    address public administratorAddress;
    address public minterAddress;

    bool public operational = true;

    uint256 public burnedTokenCount = 0;

    constructor(
        string memory baseURI_
    ) ERC721("LACPlatinum", "LACPlatinum") {
        _baseTokenURI = baseURI_;
    }

    function devMint(uint256 _mintQty) external onlyOwner {
        uint256 supply = totalSupply();

        require(burnedTokenCount + supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");
        
        for (uint256 i = 1; i <= _mintQty; i++) {
            _safeMint(msg.sender, burnedTokenCount + supply + i);
        }
    }

    function mint(address _to) external {
        uint256 supply = totalSupply();
        require(msg.sender == administratorAddress, "You are not authorized to execute this method");
        require(operational, "Operation is paused");
        require(burnedTokenCount + supply + 1 <= MAX_SUPPLY, "Exceeds maximum token supply");

        _safeMint(_to, burnedTokenCount + supply + 1);
    }

    function upgrade(uint256[2] calldata tokenIds) external {
        IMinter minter = IMinter(minterAddress);
        bool canUpgrade = false;

        for (uint256 i = 0; i < 2; i++) {
            address owner = ERC721.ownerOf(tokenIds[i]);
            if (msg.sender == owner) {
                canUpgrade = true;
            } else {
                canUpgrade = false;
            }
        }

        if (canUpgrade) {
            for (uint256 i = 0; i < 2; i++) {
                _burn(tokenIds[i]);
            }

            burnedTokenCount += 2;
            minter.mint(msg.sender);
        }
    }

    function setAdministrator(address _administratorAddress) external onlyOwner {
        administratorAddress = _administratorAddress;
    }

    function setMinter(address _minterAddress) external onlyOwner {
        minterAddress = _minterAddress;
    }

    function toggleOperational() external onlyOwner {
        operational = !operational;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}