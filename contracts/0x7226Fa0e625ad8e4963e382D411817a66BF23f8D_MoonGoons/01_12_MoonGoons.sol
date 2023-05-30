// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract MoonGoons is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public mintPrice = 0 ether;
    uint256 public maxSupply = 5000;
    uint256 public maxPerWallet = 3;
    uint256 public maxPerTransaction = 3;
    uint256 public currentSupply;
    bool public isSalePublic = false;
    string public baseURI = "ipfs://QmW9NmdqXYZJVFfWzMLYjtgza3qfki6qseVLmhxHcp4qiG/";
    mapping(address => uint256) public walletMints;

    constructor() payable ERC721A("Moon Goons", "MOONGOONS") {}

    //////// Internal Functions

    // Override start token id to set to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //////// External Functions
    function mint(uint256 _quantity) external payable publicSaleActive {
        require(tx.origin == msg.sender, "No contract minting");
        require(_quantity <= maxPerTransaction, "Too many mints per transaction");
        require(currentSupply + _quantity <= maxSupply, "Max supply reached");

        uint256 userMintsTotal = _numberMinted(msg.sender);
        require(userMintsTotal + _quantity <= maxPerWallet, "max per wallet reached");

        uint256 price = mintPrice;
        checkValue(price * _quantity);
        currentSupply += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    //////// Public Functions
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json")) : "";
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

            currentTokenId++;
        }
        return ownedTokenIds;
    }

    //////// Owner Functions
    function mintTo(uint256 _quantity, address _user) external onlyOwner {
        require(currentSupply + _quantity <= maxSupply, "Max supply reached");
        
        currentSupply += _quantity;

        _safeMint(_user, _quantity);
    }

    function setBaseTokenUri(string calldata _baseTokenUri) external onlyOwner {
        baseURI = _baseTokenUri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ,) = payable(msg.sender).call{
            value: balance
        }("");
        require(succ, "Transfer failed");
    }

    function setIsSalePublic(bool _isSalePublic) external onlyOwner {
        isSalePublic = _isSalePublic;
    }

    //////// Private Functions
    function checkValue(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{value: (msg.value - price)}("");
            require(succ, "Transfer Failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    // Modifiers
    modifier publicSaleActive() {
        require(isSalePublic, "public sale not active");
        _;
    }
}