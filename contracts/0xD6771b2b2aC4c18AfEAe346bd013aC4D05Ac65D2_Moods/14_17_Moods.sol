//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Moods is ERC721, Ownable, DefaultOperatorFilterer {
    using Counters for Counters.Counter;

    // Core constants.
    string public constant NAME = "Moods by Ranxdeer";
    string public constant SYMBOL = "MOODS";
    address public constant WITHDRAW_ADDRESS_1 = 0x4A76a9E69d5d402780Dc2462275354C354856d16;
    address public constant WITHDRAW_ADDRESS_2 = 0xB07952A55bF9c45C268F37C3631823Df50ac721a;
    address public constant WITHDRAW_ADDRESS_3 = 0x0e59BB432ddD24311cF164aF729fEf0232e1B8C3;
    address public constant WITHDRAW_ADDRESS_4 = 0x6907495b99FF6270B6de708c04f3DaCAedD40A40;

    // Minting constants.
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant MAX_WL_SUPPLY = 1000;
    uint256 public constant MAX_AMOUNT_PER_WALLET = 10;

    // Core variables.
    Counters.Counter public _nextTokenId;
    string public baseURI;
    uint256 public price = 0.011 ether;
    bool public isMintEventActive = false;
    uint256 public mintStartTime;

    bytes32 public wlMerkleRoot;
    Counters.Counter public wlMintedAmount;
    mapping(address => bool) public wlUsed;

    // Events.
    event Mint(uint256 fromTokenId, uint256 amount, address owner);

    // Constructor.
    constructor(
        string memory _baseUri,
        bytes32 _wlMerkleRoot,
        uint256 _mintStartTime
    ) ERC721(NAME, SYMBOL) {
        _nextTokenId.increment();
        setBaseURI(_baseUri);
        setWlMerkleRoot(_wlMerkleRoot);
        setMintStartTime(_mintStartTime);
    }

    // OpenSea creator fee support.
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Base URI. Overrides _baseURI in ERC721.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Mint.
    function publicMint(uint256 mintAmount) public payable {
        uint256 totalSupplyPreMint = totalSupply();

        require(isMintEventActive, "Mint event is not currently active");
        require(block.timestamp >= mintStartTime, "Mint is not currently active");
        require((balanceOf(msg.sender) + mintAmount) <= MAX_AMOUNT_PER_WALLET, "Mint would exceed maximum token amount per wallet");
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
        require(block.timestamp >= mintStartTime, "Mint is not currently active");
        require(MerkleProof.verify(merkleProof, wlMerkleRoot, merkleLeaf), "Invalid whitelist merkle proof");
        require((balanceOf(msg.sender) + mintAmount) <= MAX_AMOUNT_PER_WALLET, "Mint would exceed maximum token amount per wallet");
        require((totalSupplyPreMint + mintAmount) <= MAX_SUPPLY, "Mint would exceed maximum supply");
        require((wlMintedAmount.current() + mintAmount) <= MAX_WL_SUPPLY, "Mint would exceed maximum WL supply");
        require(!wlUsed[msg.sender], "Whitelist mint allocation is already used");

        uint i;
        for (i = 0; i < mintAmount; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
            wlMintedAmount.increment();
        }

        emit Mint(totalSupplyPreMint, mintAmount, msg.sender);

        wlUsed[msg.sender] = true;
    }

    // Total supply.
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
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
    function setMintStartTime(uint256 _time) public onlyOwner {
        mintStartTime = _time;
    }

    // Whitelist merkle tree root.
    function setWlMerkleRoot(bytes32 _wlMerkleRoot) public onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    // Withdraw.
    function withdraw() public onlyOwner {
        uint256 balanceOneTenthPercent = address(this).balance / 1000;
        payable(WITHDRAW_ADDRESS_1).transfer(balanceOneTenthPercent * 500);
        payable(WITHDRAW_ADDRESS_2).transfer(balanceOneTenthPercent * 200);
        payable(WITHDRAW_ADDRESS_3).transfer(balanceOneTenthPercent * 225);
        payable(WITHDRAW_ADDRESS_4).transfer(balanceOneTenthPercent * 75);
    }
}