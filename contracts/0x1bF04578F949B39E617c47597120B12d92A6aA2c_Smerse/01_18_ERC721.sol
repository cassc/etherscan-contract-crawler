//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/*
  /$$$$$$                                                       
 /$$__  $$                                                      
| $$  \__/ /$$$$$$/$$$$   /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$ 
|  $$$$$$ | $$_  $$_  $$ /$$__  $$ /$$__  $$ /$$_____/ /$$__  $$
 \____  $$| $$ \ $$ \ $$| $$$$$$$$| $$  \__/|  $$$$$$ | $$$$$$$$
 /$$  \ $$| $$ | $$ | $$| $$_____/| $$       \____  $$| $$_____/
|  $$$$$$/| $$ | $$ | $$|  $$$$$$$| $$       /$$$$$$$/|  $$$$$$$
 \______/ |__/ |__/ |__/ \_______/|__/      |_______/  \_______/

This smart-contract is powered by GOMINT for Smerse.
https://smerse.io
https://gomint.art
*/

contract Smerse is Ownable, ERC721A, ERC2981, PaymentSplitter {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct MintRequest {
        address to;
        uint256 nonce;
        uint256 price;
        uint256 amount;
    }

    bool public publicMint;
    bool public privateMint;

    address public signer;
    string public baseTokenURI;

    uint256 public maxSupply = 255;
    uint256 public price = 0.05 ether;
    uint256 public maxPerTransaction = 55;
    mapping(address => EnumerableSet.UintSet) addressUsedNonces;

    uint256[] private _shares = [90, 10];
    address[] private _shareholders = [
        0xD4D32A3e50eE7255dd8192A3df93C5e24Bc2fC4b,
        0xC84Ca3dD2cB86e3908dDEbE2374c70287fEf8C66
    ];

    constructor() ERC721A("Smerse", "Smerse") PaymentSplitter(_shareholders, _shares) {
        _setDefaultRoyalty(owner(), 750);
    }

    // Mint functions

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");
        _safeMint(_to, _amount);
    }

    function mintPublic(uint256 _amount) external payable {
        uint256 requiredPrice = price.mul(_amount);
        require(publicMint, "Public mint turned off");
        require(msg.value >= requiredPrice, "Not enough ETH");
        require(_amount <= maxPerTransaction, "Max per transaction");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");

        _safeMint(msg.sender, _amount);
    }

    function mintPrivate(MintRequest calldata _mintRequest, uint256 _amount, bytes calldata _signature) external payable {
        uint256 requiredPrice = _mintRequest.price.mul(_amount);
        require(privateMint, "Private mint turned off");
        require(msg.value >= requiredPrice, "Not enough ETH");
        require(msg.sender == _mintRequest.to, "Wrong address");
        require(verify(_mintRequest, _signature), "Invalid request");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");
        require(_amount <= _mintRequest.amount, "Amount exceeds allowance");
        require(!addressUsedNonces[msg.sender].contains(_mintRequest.nonce), "Signature was used");

        addressUsedNonces[msg.sender].add(_mintRequest.nonce);
        _safeMint(msg.sender, _amount);
    }

    // Signatures verification

    function verify(MintRequest memory mintRequest, bytes memory signature)
        public
        view
        returns (bool)
    {
        return
            keccak256(
                abi.encodePacked(
                    mintRequest.to,
                    mintRequest.nonce,
                    mintRequest.price,
                    mintRequest.amount
                )
            ).toEthSignedMessageHash().recover(signature) == signer;
    }

    // ETH withdrawal

    function withdraw() external onlyOwner {
        for (uint256 sh; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }

    // Setters

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setPublicMint(bool _publicMint) external onlyOwner {
        publicMint = _publicMint;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrivateMint(bool _privateMint) external onlyOwner {
        privateMint = _privateMint;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    function setRoyalty(address _receiver, uint96 _feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeBasisPoints);
    }

    // Overrides

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}