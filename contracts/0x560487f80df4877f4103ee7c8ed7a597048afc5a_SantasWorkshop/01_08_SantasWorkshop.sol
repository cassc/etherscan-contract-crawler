// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

contract SantasWorkshop is ERC721A, Ownable {
    address public signer;

    string public baseUri = "ipfs://";

    uint public WL_OPEN_TIME = 1671908400;
    uint public PUBLIC_OPEN_TIME = 1671910200;

    uint public WL_COST = 0.008 ether;
    uint public PUBLIC_COST = 0.009 ether;

    uint public MAX_SUPPLY = 333;
    uint public MAX_PER_WALLET = 2;

    mapping(address => uint) public mintedAmount;

    constructor() ERC721A("SantasWorkshop", "ELF") {
        signer = msg.sender;
        _mint(msg.sender, 1);
    }

    modifier canMint(uint _quantity) {
        require(MAX_SUPPLY >= totalSupply() + _quantity, "Sold out");
        require(mintedAmount[msg.sender] + _quantity <= MAX_PER_WALLET, "Already minted max");
        require(tx.origin == msg.sender, "Caller cannot be a contract");
        _;
    }

    modifier verifyWL(bytes memory signature) {
        bytes32 hash = keccak256(abi.encodePacked("Santa", msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address recoveredSigner = ECDSA.recover(message, signature);
        require(recoveredSigner == signer, "WL signature not valid");
        _;
    }

    function mintWL(uint _quantity, bytes memory signature) external payable canMint(_quantity) verifyWL(signature) {
        require(block.timestamp >= WL_OPEN_TIME, "WL sale is not active yet");
        require(msg.value >= WL_COST * _quantity, "Not enough Eth");
        mintedAmount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function mintPublic(uint _quantity) external payable canMint(_quantity)  {
        require(block.timestamp >= PUBLIC_OPEN_TIME, "Public sale is not active yet");
        require(msg.value >= PUBLIC_COST * _quantity, "Not enough Eth");
        mintedAmount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function setOpenTimes(uint _wlOpenTime, uint _publicOpenTime) external onlyOwner {
        WL_OPEN_TIME = _wlOpenTime;
        PUBLIC_OPEN_TIME = _publicOpenTime;
    }

    function setCosts(uint _wlCost, uint _publicCost) external onlyOwner {
        WL_COST = _wlCost;
        PUBLIC_COST = _publicCost;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseUri = baseURI;
    }

    function tokenURI(uint tokenId) public view virtual override returns(string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId + 1), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseUri;
    }

    function withdraw() external onlyOwner {
		(bool os,) = payable(owner()).call{value: address(this).balance}("");
		require(os);
	}
}