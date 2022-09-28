// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import './ERC721A.sol';

contract PyramidsCollective is Ownable, ERC721A, ReentrancyGuard, EIP712 {

    uint16 public immutable MAX_TEAM_SUPPLY = 150;
    uint16 public teamCounter = 0;

    string private constant SIGNING_DOMAIN = "PYRAMIDSCOLLECTIVE";
    string private constant SIGNATURE_VERSION = "1";

    address private immutable CEO_ADDRESS = 0xc4d13342A2A57AFaA21197C2DceF4e0D2E505329;
    string public baseTokenURI;

    uint8 public saleStage; // 0: PAUSED | 1: PRESALE | 2: PUBLIC SALE | 3: SOLDOUT

    mapping (uint => bool) public whitelistIdUsed;

    constructor() ERC721A('Pyramids Collective', 'PC', 20, 5000) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        saleStage = 0;
    }

    // UPDATE SALESTAGE

    function setSaleStage(uint8 _saleStage) external onlyOwner {
        require(saleStage != 3, "Cannot update if already reached soldout stage.");
        saleStage = _saleStage;
    }

    // PRESALE MINT

    function presale(uint _quantity, uint256 _id, bytes memory _signature) external payable nonReentrant {
        require(saleStage == 1, "Presale is not active.");
        require(!whitelistIdUsed[_id], "Whitelist ID has already been used.");
        require(check(_id, _signature) == owner(), "Wallet is not in presale whitelist.");
        require(_quantity <= 2, "Max presale mint at once exceeded.");
        require(balanceOf(msg.sender) + _quantity <= 2, "Would reach max NFT per holder in presale.");
        require(msg.value >= 0.06 ether * _quantity, "Not enough ETH.");
        require(totalSupply() + _quantity + (MAX_TEAM_SUPPLY-teamCounter) <= collectionSize, "Mint would exceed max supply.");

        _safeMint(msg.sender, _quantity);

        if (totalSupply() + (MAX_TEAM_SUPPLY-teamCounter) == collectionSize) {
            saleStage = 3;
        }

        whitelistIdUsed[_id] = true;
    }

    function check(uint256 _id, bytes memory _signature) public view returns (address) {
        return _verify(_id, _signature);
    }

    function _verify(uint256 _id, bytes memory _signature) internal view returns (address) {
        bytes32 digest = _hash(_id);
        return ECDSA.recover(digest, _signature);
    }

    function _hash(uint256 _id) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Web3Struct(uint256 _id)"),
            _id
        )));
    }

    // PUBLIC MINT 

    function publicMint(uint _quantity) external payable nonReentrant {
        require(saleStage == 2, "Public sale is not active.");
        require(_quantity <= 10, "Max mint at once exceeded.");
        require(balanceOf(msg.sender) + _quantity <= 10, "Would reach max NFT per holder.");
        require(msg.value >= 0.08 ether * _quantity, "Not enough ETH.");
        require(totalSupply() + _quantity + (MAX_TEAM_SUPPLY-teamCounter) <= collectionSize, "Mint would exceed max supply.");

        _safeMint(msg.sender, _quantity);

        if (totalSupply() + (MAX_TEAM_SUPPLY-teamCounter) == collectionSize) {
            saleStage = 3;
        }
    }

    // TEAM MINT

    function teamMint(address _to, uint16 _quantity) external onlyOwner {
        require(teamCounter + _quantity <= MAX_TEAM_SUPPLY, "Would exceed max team supply.");
        _safeMint(_to, _quantity);
        teamCounter += _quantity;
    }
    
    // METADATA URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenUri(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexisting token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId), ".json")) : "https://gateway.pinata.cloud/ipfs/QmQ5MjPZVmGD31etVG337qDsE4dKUuKmsmxKsw9pt3geFg";
    }

    // WITHDRAW

    function withdraw() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(CEO_ADDRESS).transfer(ethBalance);
    }
}