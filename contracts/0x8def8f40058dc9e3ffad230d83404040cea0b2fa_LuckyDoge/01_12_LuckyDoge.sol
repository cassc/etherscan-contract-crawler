// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0 < 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface OtherHolder {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract LuckyDoge is ERC721, Ownable, Pausable {
    using Strings for uint;
    string private baseURI = 'https://gateway.pinata.cloud/ipfs/QmfL3cX1M6iLA46oXbtnXo9hBhrnJJ99k1yjvfmAgTpQQ8/';
    uint private maxSupply = 10000;
    uint private maxGrant = 600;
    uint private mintedSupply = 0;
    uint256 private grantMintedNum = 0;
    uint private basePrice;

    address[] otherHolderAddress;

    uint private grantNums;
    mapping(address => bool) private grants;

    constructor() ERC721("LuckyDoge", "LuckyDoge") {
        // 0.01 ETH
        basePrice = 10000000000000000;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setBasePrice(uint _basePrice) external onlyOwner {
        basePrice = _basePrice;
    }

    function getBasePrice() public view returns (string memory) {
        return basePrice.toString();
    }

    function setMaxGrant(uint _maxGrant) external onlyOwner {
        maxGrant = _maxGrant;
    }

    function setHolderOwner(address[] memory _address) external onlyOwner {
        otherHolderAddress = _address;
    }

    function mintDoges(uint _amount) public payable whenNotPaused {
        require(msg.value >= basePrice * _amount, "Not enough ETH sent");
        require(mintedSupply < maxSupply, "Max supply reached");
        require(mintedSupply + _amount <= maxSupply, "Exceeds max supply");

        for (uint i = 0; i < _amount; i++) {
            mint();
        }
    }

    function mintWithGrant() public payable whenNotPaused {
        require(allowGrant(), "You have no chance [1]");
        require(grantMintedNum < maxGrant, "You have no chance [2]");
        mint();
        grantMintedNum++;
        grants[msg.sender] = true;
    }

    function mint() internal {
        _safeMint(msg.sender, mintedSupply);
        mintedSupply++;
    }

    function getBalanceOf(address _address, uint target) public view returns (uint256) {
        return OtherHolder(otherHolderAddress[target]).balanceOf(_address);
    }

    function allowGrant() public view returns (bool) {
        if (grants[msg.sender]) {
            return false;
        }

        for (uint i = 0; i < otherHolderAddress.length; i++) {
            if (getBalanceOf(msg.sender, i) > 0) {
                return true;
            }
        }

        return false;
    }

    function mintedLength() public view returns (uint[] memory) {
        uint[] memory arr = new uint[](2);
        arr[0] = mintedSupply;
        arr[1] = grantMintedNum;
        return arr;
    }
}