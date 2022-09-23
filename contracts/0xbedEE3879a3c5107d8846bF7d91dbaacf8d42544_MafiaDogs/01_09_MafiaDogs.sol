// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC4907.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MafiaDogs is ERC4907, Ownable {

    string public baseTokenURI;

    bool public presaleIsActive;
    bool public publicSaleIsActive;

    uint256 public presalePrice;
    uint256 public publicSalePrice;

    uint256 public alMints;
    uint256 public ogMints;
    uint256 public maxMints;

    address private _signer;

    uint256 public constant MAX_SUPPLY = 7777;

    uint8 private constant _PUBLIC_MINT = 0;
    uint8 private constant _AL_MINT = 1;
    uint8 private constant _OG_MINT = 2;

    constructor(
        string memory _baseTokenURI,
        uint256 _presalePrice,
        uint256 _publicSalePrice,
        address signer_,
        uint256 _alMints,
        uint256 _ogMints,
        uint256 _maxMints
    ) ERC721A("MafiaDogs", "MD") {
        baseTokenURI = _baseTokenURI;
        presalePrice = _presalePrice;
        publicSalePrice = _publicSalePrice;
        _signer = signer_;

        setMaxMints(_alMints, _ogMints, _maxMints);
    }

    function adminMint(address recipient, uint256 quantity) external onlyOwner {
        require(recipient != address(0), "MafiaDogs: mint to the zero address");
        require(totalSupply() + quantity <= MAX_SUPPLY, "MafiaDogs: MAX_SUPPLY exceeded");
        _mint(recipient, quantity);
    }

    function mint(uint8 mintType, uint256 quantity, bytes memory signature) external payable {
        require(tx.origin == msg.sender, "MafiaDogs: externally-owned account only");
        require(_verifySignature(mintType, signature), "MafiaDogs: invalid signature");
        require(totalSupply() + quantity <= MAX_SUPPLY, "MafiaDogs: MAX_SUPPLY exceeded");

        uint256 costToMint;

        if (mintType == _AL_MINT) {
            require(presaleIsActive, "MafiaDogs: presale is not active");
            require(_numberMinted(msg.sender) + quantity <= alMints, "MafiaDogs: alMints exceeded");

            costToMint = quantity * presalePrice;
        } else if (mintType == _OG_MINT) {
            require(presaleIsActive, "MafiaDogs: presale is not active");
            require(_numberMinted(msg.sender) + quantity <= ogMints, "MafiaDogs: ogMints exceeded");

            costToMint = quantity * presalePrice;
        } else if (mintType == _PUBLIC_MINT) {
            require(publicSaleIsActive, "MafiaDogs: public sale is not active");
            require(_numberMinted(msg.sender) + quantity <= maxMints, "MafiaDogs: maxMints exceeded");

            costToMint = quantity * publicSalePrice;
        } else {
            revert("MafiaDogs: invalid mint type");
        }

        require(msg.value >= costToMint, "MafiaDogs: insufficient value");

        if (msg.value > costToMint) {
            payable(msg.sender).transfer(msg.value - costToMint);
        }

        _mint(msg.sender, quantity);
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setSigner(address signer_) external onlyOwner {
        _signer = signer_;
    }

    function setSaleState(bool _presaleIsActive, bool _publicSaleIsActive) external onlyOwner {
        presaleIsActive = _presaleIsActive;
        publicSaleIsActive = _publicSaleIsActive;
    }

    function setPrices(uint256 _presalePrice, uint256 _publicSalePrice) external onlyOwner {
        presalePrice = _presalePrice;
        publicSalePrice = _publicSalePrice;
    }

    function setMaxMints(uint256 _alMints, uint256 _ogMints, uint256 _maxMints) public onlyOwner {
        require(_alMints <= _ogMints && _ogMints <= _maxMints, "MafiaDogs: invalid arguments");
        alMints = _alMints;
        ogMints = _ogMints;
        maxMints = _maxMints;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function numberMinted(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _verifySignature(uint8 type_, bytes memory signature) private view returns (bool) {
        return (ECDSA.recover(keccak256(abi.encodePacked(type_, msg.sender)), signature) == _signer);
    }
}