// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// HEXAPOD INDUSTRIES

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract HexapodIndustries is ERC721, ERC721Burnable, Ownable {

    string public baseURI = 'https://hexapod.industries/api/holo/';
    uint256 counter;

    mapping(address => mapping(uint256 => bool)) public MintPerAddress;
    mapping(uint256 => uint256) public tokenIdToGroupId;

    struct Holo {
        uint256 price;
        uint16 size;
        uint16 reserve;
        uint16 minted;
        uint16 burned;
    }

    Holo[] public holos;

    constructor() ERC721("Hexapod Industries", "HOLO") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner() {
        baseURI = _uri;
    }

    function contractURI() public pure returns (string memory) {
        return "https://hexapod.industries/api/contract-metadata";
    }

    function createHolo(
            uint256 _price,
            uint16 _size,
            uint16 _reserve
    ) public onlyOwner() {
        holos.push(Holo({
            price: _price,
            size: _size,
            reserve: _reserve,
            minted: 0,
            burned: 0
        }));
    }

    function updateHolo(
        uint16 _index,
        uint16 _size, 
        uint16 _reserve, 
        uint256 _price
    ) public onlyOwner() {
        Holo storage h = holos[_index];
        h.size = _size;
        h.reserve = _reserve;
        h.price = _price;
    }

    function recoverSigner(
        address _address,
        bytes memory _signature,
        uint256 _hId
    ) public pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_address, _hId))
            )
        );
        return ECDSA.recover(messageDigest, _signature);
    }

    function mintWithSignature(
        uint256 hId,
        bytes memory signature
    ) external payable {
        require(recoverSigner(msg.sender, signature, hId) == owner(), "ACCESS DENIED");
        require((holos[hId].minted - holos[hId].burned) < (holos[hId].size - holos[hId].reserve), "MAX");
        require(MintPerAddress[msg.sender][hId] != true, "OTO");
        require(msg.value >= holos[hId].price, "BELOW PRICE");

        holos[hId].minted++;
        MintPerAddress[msg.sender][hId] = true;
        tokenIdToGroupId[counter] = hId;
        _mint( msg.sender, counter++);
    }

    function burnHolo(uint256 tokenId) public {
        uint256 hId = tokenIdToGroupId[tokenId];
        bool reserve = (uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp
            ))) % 10) == 0;
        holos[hId].burned++;
        if(reserve) holos[hId].reserve++;
        _burn(tokenId);
    }

    function releaseReserve(uint256 hId) public onlyOwner() {
        require(holos[hId].minted >= (holos[hId].size - holos[hId].reserve), "DENIED");

        for (uint256 i = 0; i < holos[hId].reserve; i++) {
            tokenIdToGroupId[counter] = hId;
            _mint( msg.sender, counter++);   
        }
        holos[hId].minted += holos[hId].reserve;
        holos[hId].reserve = 0;
    }

    function withdraw() public onlyOwner() {
        uint256 balance = address(this).balance;
        (bool success, ) = (msg.sender).call{ value: balance }("");
        require(success, "FAILED WITHDRAW");
    }
}