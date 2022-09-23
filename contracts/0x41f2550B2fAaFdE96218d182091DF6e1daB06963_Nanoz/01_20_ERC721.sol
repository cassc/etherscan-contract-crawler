//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { LicenseVersion, CantBeEvil } from "@a16z/contracts/licenses/CantBeEvil.sol";

/*

$$$$$$$$\ $$\                       $$\   $$\                                         
\__$$  __|$$ |                      $$$\  $$ |                                        
   $$ |   $$$$$$$\   $$$$$$\        $$$$\ $$ | $$$$$$\  $$$$$$$\   $$$$$$\  $$$$$$$$\ 
   $$ |   $$  __$$\ $$  __$$\       $$ $$\$$ | \____$$\ $$  __$$\ $$  __$$\ \____$$  |
   $$ |   $$ |  $$ |$$$$$$$$ |      $$ \$$$$ | $$$$$$$ |$$ |  $$ |$$ /  $$ |  $$$$ _/ 
   $$ |   $$ |  $$ |$$   ____|      $$ |\$$$ |$$  __$$ |$$ |  $$ |$$ |  $$ | $$  _/   
   $$ |   $$ |  $$ |\$$$$$$$\       $$ | \$$ |\$$$$$$$ |$$ |  $$ |\$$$$$$  |$$$$$$$$\ 
   \__|   \__|  \__| \_______|      \__|  \__| \_______|\__|  \__| \______/ \________|

This smart-contract is powered by GOMINT for The Nanoz.

https://www.thenanoz.com
https://gomint.art

*/

contract Nanoz is Ownable, ERC721A, ERC2981, PaymentSplitter, CantBeEvil {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public revenueFromFrance;
    uint256 public soldTokensInFrance;

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

    uint256 public maxSupply = 5555;
    uint256 public price = 0.02 ether;
    uint256 public maxPerTransaction = 55;
    mapping(address => EnumerableSet.UintSet) addressUsedNonces;
    
    uint256[] private _shares = [5, 95];
    address[] private _shareholders = [
        0x58477080D02D8EF9715Cb2381c904ad449887418,
        0xb258a2289B2BC76F997774757dE835547D320F7B
    ];
    

    constructor() ERC721A("Nanoz Universe", "NNZU") PaymentSplitter(_shareholders, _shares) CantBeEvil(LicenseVersion.CBE_NECR_HS) {
        _setDefaultRoyalty(owner(), 500);
    }

    // Mint functions

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");
        _safeMint(_to, _amount);
    }

    function mintPublic(uint256 _amount, bool _fromFrance, bool _notSanctioned) external payable {
        uint256 requiredPrice = price.mul(_amount);
        require(publicMint, "Public mint turned off");
        require(_notSanctioned, "Not allowed to mint");
        require(msg.value >= requiredPrice, "Not enough ETH");
        require(_amount <= maxPerTransaction, "Max per transaction");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");

        if (_fromFrance) {
            soldTokensInFrance += _amount;
            revenueFromFrance += requiredPrice;
        }
        _safeMint(msg.sender, _amount);
    }

    function mintPrivate(MintRequest calldata _mintRequest, uint256 _amount, bytes calldata _signature,bool _fromFrance, bool _notSanctioned) external payable {
        uint256 requiredPrice = _mintRequest.price.mul(_amount);

        require(_notSanctioned, "Not allowed to mint");
        require(privateMint, "Private mint turned off");
        require(msg.value >= requiredPrice, "Not enough ETH");
        require(msg.sender == _mintRequest.to, "Wrong address");
        require(verify(_mintRequest, _signature), "Invalid request");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");
        require(_amount <= _mintRequest.amount, "Amount exceeds allowance");
        require(!addressUsedNonces[msg.sender].contains(_mintRequest.nonce), "Signature was used");

        if (_fromFrance) {
            soldTokensInFrance += _amount;
            revenueFromFrance += requiredPrice;
        }

        addressUsedNonces[msg.sender].add(_mintRequest.nonce);
        _safeMint(msg.sender, _amount);
    }

    // Signatures verification

    function verify(MintRequest memory mintRequest, bytes memory signature) public view returns (bool) {
        return keccak256(abi.encodePacked(mintRequest.to,mintRequest.nonce,mintRequest.price,mintRequest.amount)).toEthSignedMessageHash().recover(signature) == signer;
    }

    // ETH withdrawal

    function withdraw() external onlyOwner {
        for (uint256 sh; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }

    // Setters

    function setPublicMint(bool _publicMint) external onlyOwner {
        publicMint = _publicMint;
    }

    function setPrivateMint(bool _privateMint) external onlyOwner {
        privateMint = _privateMint;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setRoyalty(address _receiver, uint96 _feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeBasisPoints);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // Overrides

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981, CantBeEvil) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}