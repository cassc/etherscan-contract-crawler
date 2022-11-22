//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@promos/contracts/Promos.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/*

This smart-contract is powered by GOMINT and Promos.
https://gomint.art
https://promos.wtf

*/

contract Destoria is ERC721A, Promos, Ownable {
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
    bool public promosMint;
    bool public privateMint;

    address public signer;
    string public baseTokenURI;

    uint256 public price = 0.09 ether;

    uint256 public maxSupply = 2250;
    uint256 public maxPerTransaction = 10;

    mapping(address => EnumerableSet.UintSet) addressUsedNonces;

    constructor()
        ERC721A("Destoria: Founder`s Pass", "DFP")
        Promos(100, promosProxyContractMainnet)
    {}

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

    function mintPrivate(
        MintRequest calldata _mintRequest,
        uint256 _amount,
        bytes calldata _signature
    ) external payable {
        uint256 requiredPrice = _mintRequest.price.mul(_amount);
        require(privateMint, "Private mint turned off");
        require(msg.value >= requiredPrice, "Not enough ETH");
        require(msg.sender == _mintRequest.to, "Wrong address");
        require(verify(_mintRequest, _signature), "Invalid request");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");
        require(_amount <= _mintRequest.amount, "Amount exceeds allowance");
        require(
            !addressUsedNonces[msg.sender].contains(_mintRequest.nonce),
            "Signature was used"
        );

        addressUsedNonces[msg.sender].add(_mintRequest.nonce);
        _safeMint(msg.sender, _amount);
    }

    function mintPromos(address _to, uint256 _amount)
        external
        payable
        override
        MintPromos(_to, _amount)
    {
        require(promosMint, "Promos mint turned off");
        require(totalSupply().add(_amount) <= maxSupply, "Out of supply");

        _safeMint(_to, _amount);
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

    function withdraw(address _receiver, uint256 _amount) external onlyOwner {
        payable(_receiver).transfer(_amount);
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

    function setPromosMint(bool _promosMint) external onlyOwner {
        promosMint = _promosMint;
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

    function setMaxPerTransaction(uint256 _maxPerTransaction)
        external
        onlyOwner
    {
        maxPerTransaction = _maxPerTransaction;
    }

    // Overrides

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, Promos)
        returns (bool)
    {
        return
            Promos.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    receive() external payable override {}
}