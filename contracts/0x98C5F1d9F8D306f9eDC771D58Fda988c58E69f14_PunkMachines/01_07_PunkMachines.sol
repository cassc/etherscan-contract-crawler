// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&??#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5!!?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!!!!!!!?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5!!!!!!!!!?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B7!!!!!!!!!!!YBBBBB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GY7!!!!!!!!!!!!!!!!!!7JPB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGPJ?7!!!!!!!!!!!!!!!!!!!!!!!!!!7JGB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJ77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?JG&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@&BP?!!!!!!!!!!!!!!!!!!!!!GG7!!!!!!!!7!!!!!!!!!!!!!!!JG#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&5!!!!!!!!!!!7?P#&@5!!!!!!?&@@@[email protected]@@#[email protected]@@@@@@@@@@@&BP5YJY&
@@@@@@@@@@@@@@@@@@B?!!!!!!!!!!?P#@@@@[email protected]@@@&[email protected]@@@@@#P7!!!!!!!!!!!?5GGBBGP5J??7!!!!!?&
@@@@@@@@@@@@@@@@&[email protected]@@@@@#7!!!!!!!#@@@@@#[email protected]@@@@@@&G?!!!!!!!!!!!!!!!!!!!!!!7JPB#@@
@@@@@@@@@@@@@@@@Y!!!!!!!!!Y#@@@@@@@#[email protected]@@@@@@#7!!!!!!!Y&@@@@@@@&Y!!!!!!!!!!!!!!!!!!!JG&@@@@@@
@@@@@@@@@@@@@@#[email protected]@@@@@@@&[email protected]@@@@@@@[email protected]@&#[email protected]@@@@@@@@
@@@@@@@@@@@@@#7!!!!!!!!J#@@@@@@@@@[email protected]@@@@@@@@@@B7!!!!!!?J?7!!!!!!!!!!!!!!!!!!!7YG&@@@@@@@@@@@
@@@@@@@@@@@@@Y!!!!!!!!7&@@@@@@@@@#[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@@[email protected]@@@@@@@@&[email protected]@@@@@&#PYJ??!!!!!!!!!!!!!!!77?JP#@[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@[email protected]@@@@@@@@@G!!!!!!!?BBG5YJ?77!!!!!!!!!!!!!!!!?Y5G#&@@@@@#[email protected]@@@@@@@@@@@@@
@@@@@@@@@@#?!!!!!!!!7&@@@@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@
@@@@@@@@@@[email protected]@@@@&GYJJ?!!!!!!!!!!!!!!!!!!!!!7?JYY?!!!!!!!!7&@@@@@@@@[email protected]@@@@@@@@@@@@@
@@@@@@@@@@#[email protected]!!!!!!!!!!!!!!!!!7777YGBB#&@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@J!!!!!!!!J?!!!!!!!!!!!!!!!!!7JPB###&&@@@@@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@B!!!!!!!!!!!!!!!!!!!!!!!!!!5#@@@@@@@@@@@@@@@@@@@@[email protected]@@@@[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@&[email protected]@@@@@@@@@@@@@
@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@&?!!!!!!!J&@@&J!!!!!!!!7#@@@@@@@@@@@@@@
@@@@@#5?!!!!!!!!!!!!!7G&@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@
@&BY?7!!!!!77!!!!!!!!7&@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@
B!!!!!77?JYB&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@
&PPPPB#&@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J!!!!!!!!!!!!!!!J#@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@BJ!!!!!!!!!!!!!!!7&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&J!!!!!!!!!!!!J#@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@BY!!!!!!!!!!!!!7YGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@B57!!!!!!!!!!!!!!7?PGP#&@@@@@@@@@@@@@@@&##[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&Y!!!!!!!!!!!!!!!!!!77?555PGB##[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@Y!!!!?#@@B5J!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!?YPB&@PY7!!!!7#@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@#GPP5J??7!!!!!!!!!!!!!!!!!7J5G#@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@&#BBBBGPPPPPGGBBBB&@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y!!!7&@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@PJJ5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJJJ&@@@@@@@@@@@@@@@@@@
*/
contract PunkMachines is ERC721A, Ownable {
    using SafeMath for uint256;

    bytes32 public merkleRoot = 0x801a612b25769b33e25cfdf223e744315abb04662595f6252423b29ff781a9dd;

    bool public revealed = false;
    bool public mintActive = false;

    string public baseURI = '';
    string public nonRevealURI= 'https://punk-machines.nyc3.digitaloceanspaces.com/reveal/json/';

    uint256 public price = 0.0066 ether;
    uint256 public whitelistPrice = 0.0044 ether;
    uint256 public mintLimit = 10;
    uint256 public maxSupply = 888;

    constructor() ERC721A("Punk Machines", "PUM") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) {
            return bytes(nonRevealURI).length != 0 ? string(abi.encodePacked(nonRevealURI, _toString(tokenId), '.json')) : '';
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : '';
    }

    function mint(uint256 quantity) external payable {
        require(mintActive, "The mint is not live.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        require(_numberMinted(msg.sender).add(quantity) <= mintLimit, "The requested mint quantity exceeds the mint limit.");
        require(price.mul(quantity) <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        require(mintActive, "The mint is not live.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        require(_numberMinted(msg.sender).add(quantity) <= mintLimit, "The requested mint quantity exceeds the mint limit.");
        require(whitelistPrice.mul(quantity) <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function airdrop(address[] memory _addresses) external onlyOwner {
        require(totalSupply().add(_addresses.length) <= maxSupply, "The requested mint quantity exceeds the supply.");

        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    function mintTo(uint256 _quantity, address _receiver) external onlyOwner {
        require(totalSupply().add(_quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        _mint(_receiver, _quantity);
    }

    function fundsWithdraw() external onlyOwner {
        uint256 funds = address(this).balance;
        require(funds > 0, "Insufficient balance.");

        (bool status,) = payable(msg.sender).call{value : funds}("");
        require(status, "Transfer failed.");
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNonRevealUri(string memory _nonRevealURI) external onlyOwner {
        nonRevealURI = _nonRevealURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
}