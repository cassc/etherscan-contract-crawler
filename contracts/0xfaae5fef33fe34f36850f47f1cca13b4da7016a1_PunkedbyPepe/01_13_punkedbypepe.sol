// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";


contract PunkedbyPepe is ERC721A, Ownable {

    using Strings for uint256;

    string public uriPrefix;
    string public uriSuffix = ".json";

    uint256 public price = 0.0025 ether;

    uint256 public maxPerTx = 20;

    uint256 public maxFreePerWallet = 2;

    uint256 public totalFree = 4269;

    uint256 public maxSupply = 4269;

    bool public mintEnabled = false;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("Punked by Pepe", "PbP") {
        _safeMint(msg.sender, 10);
        setUriPrefix("ipfs://QmR6Q9kGGcs8G3k7YbzApAnmnMHPVi9kuAEXnA9TJewGUT/");
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
    }

    // Start Token
    
    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
    }

    function mint(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalSupply() + count < totalFree + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= maxFreePerWallet));

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < maxSupply + 1, "No more");
        require(mintEnabled, "Minting is not live yet");
        require(count < maxPerTx + 1, "Max per TX reached.");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token.");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
    : "";
    }

    // BaseURI
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
    }
  }