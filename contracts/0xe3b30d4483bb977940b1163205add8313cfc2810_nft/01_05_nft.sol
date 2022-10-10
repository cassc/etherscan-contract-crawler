// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract nft is ERC721A, Ownable {
    string public _contractBaseURI;

    uint256 public maxPerWalletPresale = 6;
    uint256 public maxPerTransaction = 10;
    bool public isActive;
    bytes32 public root;

    struct ImageData {
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 price;
    }

    ///@dev  imgId to ImageData : imgId range from 0 to 9
    mapping(uint256 => ImageData) public imageData;

    mapping(uint256 => uint256) public nftIdToImgId;
    ///@dev  message = eth volume (calculated offchain)
    mapping(uint256 => uint256) public nftIdToMessage;
    uint256 constant ONE_ETH = 1_000_000_000_000_000_000;

    constructor() ERC721A("Cryptoless", "Cryptoless") Ownable() {
        imageData[0] = ImageData(0, 1, 0);

        imageData[1] = ImageData(0, 10, (ONE_ETH * 4) / 10);
        imageData[2] = ImageData(0, 10, (ONE_ETH * 4) / 10);
        imageData[3] = ImageData(0, 10, (ONE_ETH * 4) / 10);
        imageData[4] = ImageData(0, 40, ONE_ETH / 10);
        imageData[5] = ImageData(0, 40, ONE_ETH / 10);
        imageData[6] = ImageData(0, 40, ONE_ETH / 10);
        imageData[7] = ImageData(0, 150, (ONE_ETH * 4) / 100);
        imageData[8] = ImageData(0, 150, (ONE_ETH * 4) / 100);
        imageData[9] = ImageData(0, 150, (ONE_ETH * 4) / 100);
    }

    ///@dev Function to mint new NFTs during the public sale
    ///@param _message = ETH volume
    /// @param _imgId = image category, from 0 to 9
    function mintNFT(uint256 _imgId, uint256 _message) external payable {
        require(isActive, "PublicSale is not active");
        require(
            (_imgId > 0 && _imgId <= 9) ||
                (_imgId == 0 && msg.sender == owner()),
            "invalid _imgId"
        );
        require(imageData[_imgId].price == msg.value, "incorrect eth value");
        require(
            imageData[_imgId].totalSupply + 1 <= imageData[_imgId].maxSupply,
            "max supply reached for this img"
        );

        uint256 nextTokenId = _nextTokenId();

        _safeMint(msg.sender, 1);

        nftIdToImgId[nextTokenId] = _imgId;
        nftIdToMessage[nextTokenId] = _message;
        imageData[_imgId].totalSupply++;
    }

    /// @dev Function to withdraw collected amount during minting by the owner

    function withdraw(address _to) public onlyOwner {
        require(address(this).balance > 0, "Balance should be more than zero");
        uint256 balance = address(this).balance;
        (bool sent1, ) = _to.call{value: balance}("");
        require(sent1, "Failed to send Ether");
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }

    ///@dev returns base_uri + imgId instead of base_uri + nftId
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 imgId = nftIdToImgId[tokenId];

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(imgId)))
                : "";
    }

    function setImageData(
        uint256 id,
        uint256 supply,
        uint256 price
    ) external onlyOwner {
        if (imageData[id].totalSupply > 0) {
            imageData[id] = ImageData(imageData[id].totalSupply, supply, price);
        } else {
            imageData[id] = ImageData(0, supply, price);
        }
    }

    /// @dev Function to set Base URI

    function setURI(string memory _URI) external onlyOwner {
        _contractBaseURI = _URI;
    }

    /// @dev Function toggleActive to activate/desactivate the smart contract
    function toggleActive() external onlyOwner {
        isActive = !isActive;
    }
}