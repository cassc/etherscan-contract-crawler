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
 ______     ______     __    __     __     __   __     ______  
/\  ___\   /\  __ \   /\ "-./  \   /\ \   /\ "-.\ \   /\__  _\ 
\ \ \__ \  \ \ \/\ \  \ \ \-./\ \  \ \ \  \ \ \-.  \  \/_/\ \/ 
 \ \_____\  \ \_____\  \ \_\ \ \_\  \ \_\  \ \_\\"\_\    \ \_\ 
  \/_____/   \/_____/   \/_/  \/_/   \/_/   \/_/ \/_/     \/_/ 

This smart-contract is powered by GOMINT.art

The smartest way to start your NFT project.
Build quality NFT projects with proper access lists, smart contracts and minting websites. Forget about hiring a developer; instead, focus on what is important to you.

Check GOMINT out here:
https://gomint.art
https://docs.gomint.art

Founded by:
https://twitter.com/poyo_eth
https://twitter.com/UniCapital_88

*/

contract LilBottles is Ownable, ERC721A, ERC2981, PaymentSplitter {
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

    uint256 public maxSupply = 3333;
    uint256 public price = 0.05 ether;
    uint256 public maxPerTransaction = 5;

    address public signer;
    string public baseTokenURI;
    mapping(address => EnumerableSet.UintSet) addressUsedNonces;

    uint256[] private _shares = [97, 3];
    address[] private _shareholders = [
        0xC0b73A77CbF7193a6B513de206e0d3595BD1ED91,
        0x5Cdf37A9FB779ceD217CEd8A67cc07A4d0e3aF0c
    ];

    constructor() ERC721A("LilBottles", "LilBottles") PaymentSplitter(_shareholders, _shares) {
        _setDefaultRoyalty(owner(), 600);
    }


    // Mint functions

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");
        _safeMint(_to, _amount);
    }

    function mintPublic(uint256 _amount) external payable {
        require(publicMint, "Public mint disabled");
        require(msg.value >= price.mul(_amount), "Not enough ETH");
        require(_amount <= maxPerTransaction, "Max per transaction");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");

        _safeMint(msg.sender, _amount);
    }

    function mintPrivate(MintRequest calldata _mintRequest, uint256 _amount, bytes calldata _signature) external payable {
        require(privateMint, "Private mint disabled");
        require(msg.sender == _mintRequest.to, "Invalid address");
        require(verify(_mintRequest, _signature), "Invalid request");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");
        require(_amount <= _mintRequest.amount, "Amount exceeds allowance");
        require(msg.value >= _mintRequest.price.mul(_amount), "Not enough ETH");
        require(!addressUsedNonces[msg.sender].contains(_mintRequest.nonce), "Signature was used");

        addressUsedNonces[msg.sender].add(_mintRequest.nonce);
        _safeMint(msg.sender, _amount);
    }

    
    // Signatures verification

    function verify(MintRequest memory mintRequest, bytes memory signature) public view returns (bool) {
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

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}