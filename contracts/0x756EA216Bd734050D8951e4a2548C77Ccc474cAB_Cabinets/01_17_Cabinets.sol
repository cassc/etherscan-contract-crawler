// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./CabinetsSVG.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Cabinets is CabinetsSVG, ERC721Royalty, Ownable {
    address payable constant dev =
        payable(0x39596955f9111e12aF0B96A96160C5f7211B20EF);

    uint256 private _price;
    address private _signer;
    mapping(bytes32 => uint256) private _minted;
    bytes[] private _dnas;
    bool private _open;

    constructor(uint256 price, address signer) ERC721("Cabinets", "CBNTS") {
        _signer = signer;
        _price = price;
        _setDefaultRoyalty(msg.sender, 500);
    }

    function openShop() public onlyOwner {
        _open = true;
    }

    function closeShop() public onlyOwner {
        _open = false;
    }

    function isShopOpen() public view returns (bool) {
        return _open;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function safeMint(
        address to,
        bytes memory dna,
        bytes memory signature
    ) public payable {
        bytes32 hash = keccak256(dna);
        // Put this first so if you try to mint but it already sold out you waste a bit less gas.
        require(_dnas.length < 123, "Cabinets: sold out");
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) ==
                _signer,
            "Cabinets: invalid signature"
        );
        require(_minted[hash] == 0, "Cabinets: already minted");
        _dnas.push(dna);
        _minted[hash] = _dnas.length;

        address payable owner = payable(owner());

        if (_msgSender() == owner) {
            require(msg.value == 0, "Cabinets: wrong amount");
        } else {
            require(_open, "Cabinets: closed");
            require(msg.value == _price, "Cabinets: wrong amount");
            (bool success, ) = owner.call{value: (_price * 80) / 100}("");
            require(success, "Cabinets: unable transfer to A");
            (success, ) = dev.call{value: (_price * 20) / 100}("");
            require(success, "Cabinets: unable transfer to B");
        }

        _safeMint(to, _dnas.length);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(_generateJSON(tokenId, _dnas[tokenId - 1]));
    }

    function totalMinted() public view returns (uint256) {
        return _dnas.length;
    }

    function dnaToTokenId(bytes memory dna) public view returns (uint256) {
        bytes32 hash = keccak256(dna);
        return _minted[hash];
    }

    function generateSVG(bytes memory dna) public view returns (string memory) {
        require(msg.sender == tx.origin, "Cabinets: nope");
        return string(_generateSVG(dna));
    }
}