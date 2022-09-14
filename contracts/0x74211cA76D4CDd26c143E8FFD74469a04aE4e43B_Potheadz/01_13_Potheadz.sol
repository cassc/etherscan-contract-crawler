//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract Potheadz is ERC721, Ownable {
    using Counters for Counters.Counter;

    // Core constants.
    string public constant NAME = "Potheadz by Satoshis Mom";
    string public constant SYMBOL = "POTHEADZ";
    address public constant WITHDRAW_ADDRESS_1 = 0x3049112397E7B9948f4Ba6618601B7298319eF5f;
    address public constant WITHDRAW_ADDRESS_2 = 0x6907495b99FF6270B6de708c04f3DaCAedD40A40;
    address public constant WITHDRAW_ADDRESS_3 = 0x0e59BB432ddD24311cF164aF729fEf0232e1B8C3;

    // Minting constants.
    uint256 public constant MAX_SUPPLY = 6969;
    uint256 public constant MAX_PUBLIC_MINT_AMOUNT = 20;

    // Core variables.
    Counters.Counter public _nextTokenId;
    string public baseURI;
    uint256 public price = 0.0269 ether;
    bool public isMintEventActive = false;
    uint256 public wlMintStartTime;
    uint256 public publicMintStartTime;
    bytes32 public wlMerkleRoot;
    mapping(address => bool) public wlUsed;

    // Provenance.
    string public provenanceHash;

    // Events.
    event Mint(uint256 fromTokenId, uint256 amount, address owner);

    // Constructor.
    constructor(
        string memory _baseUri,
        bytes32 _wlMerkleRoot,
        uint256 _wlMintStartTime,
        uint256 _publicMintStartTime
    ) ERC721(NAME, SYMBOL) {
        _nextTokenId.increment();
        setBaseURI(_baseUri);
        setWlMerkleRoot(_wlMerkleRoot);
        setWlMintStartTime(_wlMintStartTime);
        setPublicMintStartTime(_publicMintStartTime);
    }

    // Base URI. Overrides _baseURI in ERC721.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Mint.
    function publicMint(uint256 mintAmount) public payable {
        uint256 totalSupplyPreMint = totalSupply();

        require(isMintEventActive, "Mint event is not currently active");
        require(block.timestamp >= publicMintStartTime, "Public mint is not currently active");
        require(mintAmount <= MAX_PUBLIC_MINT_AMOUNT, "Mint would exceed maximum token amount per mint");
        require((totalSupplyPreMint + mintAmount) <= MAX_SUPPLY, "Mint would exceed maximum supply");
        require(msg.value >= (mintAmount * price), "ETH value sent is not correct");

        uint i;
        for (i = 0; i < mintAmount; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }

        emit Mint(totalSupplyPreMint, mintAmount, msg.sender);
    }

    function wlMint(uint mintAmount, bytes32[] calldata merkleProof) public payable {
        uint256 totalSupplyPreMint = totalSupply();
        bytes32 merkleLeaf = keccak256(abi.encodePacked(msg.sender, mintAmount));

        require(isMintEventActive, "Mint event is not currently active");
        require(block.timestamp >= wlMintStartTime && block.timestamp < publicMintStartTime, "Whitelist mint is not currently active");
        require(MerkleProof.verify(merkleProof, wlMerkleRoot, merkleLeaf), "Invalid whitelist merkle proof");
        require(!wlUsed[msg.sender], "Whitelist mint allocation is already used");
        require((totalSupplyPreMint + mintAmount) <= MAX_SUPPLY, "Mint would exceed maximum supply");

        uint i;
        for (i = 0; i < mintAmount; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }

        emit Mint(totalSupplyPreMint, mintAmount, msg.sender);

        wlUsed[msg.sender] = true;
    }

    // Total supply.
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // Provenance.
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    // Price.
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // Base URI.
    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    // Mint event status.
    function setMintEventActive(bool _isActive) public onlyOwner {
        isMintEventActive = _isActive;
    }

    // Mint time checks.
    function setWlMintStartTime(uint256 _time) public onlyOwner {
        wlMintStartTime = _time;
    }

    function setPublicMintStartTime(uint256 _time) public onlyOwner {
        publicMintStartTime = _time;
    }

    // Whitelist merkle tree root.
    function setWlMerkleRoot(bytes32 _wlMerkleRoot) public onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    // Withdraw.
    function withdraw() public onlyOwner {
        uint256 balanceOneTenthPercent = address(this).balance / 1000;
        payable(WITHDRAW_ADDRESS_1).transfer(balanceOneTenthPercent * 650);
        payable(WITHDRAW_ADDRESS_2).transfer(balanceOneTenthPercent * 175);
        payable(WITHDRAW_ADDRESS_3).transfer(balanceOneTenthPercent * 175);
    }
}