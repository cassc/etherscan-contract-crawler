//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721Slim.sol";

contract MetaPredator is ERC721Slim, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PURCHASE_PER_TX = 10;
    uint256 public constant MAX_PURCHASE_PER_WALLET = 10;

    mapping(address => uint8) public _minters;
    string public _baseUri;
    bool public _saleStarted;

    constructor() ERC721Slim("MetaPredator", "MP") {
        _baseUri = "https://www.metapredator.io/assets/";
        _saleStarted = false;
    }

    modifier maxSupplyCheck(uint8 amount) {
        require(amount + totalMinted() <= MAX_SUPPLY, "MetaPredator: exceed maximum supply");
        _;
    }

    function purchase(uint8 amount) external maxSupplyCheck(amount) {
        require(tx.origin == msg.sender, "MetaPredator: are you botting??");
        require(_saleStarted, "MetaPredator: sale is not started");
        require(amount <= MAX_PURCHASE_PER_TX, "MetaPredator: exceed maximum amount per tx");
        require(
            _minters[msg.sender] + amount <= MAX_PURCHASE_PER_WALLET,
            "MetaPredator: exceed maximum amount per wallet"
        );

        _minters[msg.sender] += amount;
        _safeBatchMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "MetaPredator: URI query for nonexistent token");
        return string(abi.encodePacked(_baseUri, tokenId.toString(), ".json"));
    }

    // ========== Admin operations ===========

    function setSaleState(bool newState) external onlyOwner {
        _saleStarted = newState;
    }

    function setBaseUri(string memory baseUri) external onlyOwner {
        _baseUri = baseUri;
    }

    function devMint(uint8 amount, address to) external onlyOwner maxSupplyCheck(amount) {
        _safeBatchMint(to, amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = (address(this).balance * 90) / 100;

        Address.sendValue(payable(0xCE4c3478E82Aea54e62Db24465ad7BfAec753D08), (balance * 100) / 1000);
        Address.sendValue(payable(0x601Bd113546bd7dA62D785396c4126d249b1fb33), (balance * 200) / 1000);
        Address.sendValue(payable(0x176C0387CE0c140A755240471604010FCa59fbF1), (balance * 100) / 1000);
        Address.sendValue(payable(0xf12AE22C236d13a3BeC51BA4a4C5Fa907EAD11ed), (balance * 100) / 1000);
        Address.sendValue(payable(0xD347b09be433A55FC19bBE1D6A1Cb89b7B04D1B0), (balance * 100) / 1000);
        Address.sendValue(payable(0x32c0fBdE13005eBC8cE3F237bF047C8D97DF02dc), (balance * 100) / 1000);
        Address.sendValue(payable(0x01aBf92800a224bb69a03c0396D8fBF892747f6D), (balance * 100) / 1000);
        Address.sendValue(payable(0xC2E2C81DC7C6fE6b332fa05854D3b1e92839C5a2), (balance * 40) / 1000);
        Address.sendValue(payable(0xBd7A7cC8Ed95c6Bc18c29865398982c0C47c60A3), (balance * 15) / 1000);
        Address.sendValue(payable(0x514d97D3F5ff3C8dcc1e19983E01b3f0Cd7A6eb7), (balance * 15) / 1000);
        Address.sendValue(payable(0x9aF86d53186A4C96a03cdb8f4fbFE0d2256C809c), (balance * 15) / 1000);
        Address.sendValue(payable(0x2A9C6c066AD731b1E26Fdc6F428Ac9ED8733485f), (balance * 15) / 1000);

        Address.sendValue(payable(msg.sender), address(this).balance);
    }
}