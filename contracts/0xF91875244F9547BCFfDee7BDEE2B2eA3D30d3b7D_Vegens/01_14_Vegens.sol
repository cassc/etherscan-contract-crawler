// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Vegens is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    bytes32 public merkleRoot =
        0x80984a5fe1656e9d3e9281b115de689ccf331d0462ecf46449785af830045560;

    uint256 public tokenPrice = 0.015 ether;

    uint256 public maxPerWallet = 5;

    uint256 public maxSupply = 1500;

    bool public saleIsActive = false;
    bool public isPresale = true;

    uint256 public tokenReserve = 100;

    string private newBaseURI;

    mapping(address => bool) public whitelistClaimed;

    constructor() ERC721("Vegens NFT", "VEGENS") {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function reserveTokens(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        uint256 supply = _totalSupply();
        require(
            _reserveAmount > 0 && _reserveAmount <= tokenReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            _tokenIdTracker.increment();
            _safeMint(_to, supply + i);
        }
        tokenReserve = tokenReserve.sub(_reserveAmount);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        newBaseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return newBaseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        isPresale = !isPresale;
    }

    function mintToken(uint256 numberOfTokens, bytes32[] calldata merkleProof)
        public
        payable
    {
        require(saleIsActive, "Sale not active");
        // if (isPresale) {
        //     require(isWhiteListed(msg.sender), "Not whitelisted");
        // }
        require(!whitelistClaimed[msg.sender], "Address has already claimed.");
        require(
            _totalSupply().add(numberOfTokens) <= maxSupply,
            "Exceed max supply of Tokens"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );
        require(
            balanceOf(msg.sender).add(numberOfTokens) <= maxPerWallet,
            "Over Max Mint per Address"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid proof."
        );
        whitelistClaimed[msg.sender] = true;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _totalSupply();
            if (_totalSupply() < maxSupply) {
                _tokenIdTracker.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function setTokenPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setTokenReserve(uint256 _tokenReserve) public onlyOwner {
        tokenReserve = _tokenReserve;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
}