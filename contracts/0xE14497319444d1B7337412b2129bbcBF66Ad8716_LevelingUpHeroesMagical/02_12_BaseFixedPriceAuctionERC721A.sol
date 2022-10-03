// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseFixedPriceAuctionERC721A is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    string public prefix = "Base Verification:";
    string private baseTokenURI = '';

    mapping(address => uint256) public _whitelistClaimed;
    mapping(address => uint256) public _publicListClaimed;

    uint256 public nonReservedMax;
    uint256 public reservedMax;
    uint256 public max;
    uint256 public nonReservedMinted;
    uint256 public reservedMinted;
    uint256 public price;
    uint256 public whitelistMaxMint;
    uint256 public publicListMaxMint;

    PaymentSplitter private _splitter;

    constructor(
        address[] memory payees, 
        uint256[] memory shares,
        string memory name,
        string memory symbol,
        uint256 _whitelistMaxMint, 
        uint256 _publicListMaxMint,
        uint256 _nonReservedMax,
        uint256 _reservedMax,
        uint256 _price
    )
        ERC721A(name, symbol)
    {
        whitelistMaxMint = _whitelistMaxMint;
        publicListMaxMint = _publicListMaxMint;
        nonReservedMax = _nonReservedMax;
        reservedMax = _reservedMax;
        max = nonReservedMax + reservedMax;
        nonReservedMinted = 0;
        reservedMinted = 0;
        _splitter = new PaymentSplitter(payees, shares);
        price = _price;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function release(address payable account) external {
        _splitter.release(account);
    }

    function _hash(address _address) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(prefix, _address));
    }

    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return (_recover(hash, signature) == owner());
    }

    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    return hash.recover(signature);
    }

    function setPrefix(string memory _prefix) public onlyOwner {
        prefix = _prefix;
    }

    function setWhitelistMaxMint(uint256 _whitelistMaxMint) external onlyOwner {
        whitelistMaxMint = _whitelistMaxMint;
    }

    function setPublicListMaxMint(uint256 _publicListMaxMint) external onlyOwner {
        publicListMaxMint = _publicListMaxMint;
    }

    function mintPublic(uint256 numberOfTokens) external payable {
        require(_publicListClaimed[msg.sender] + numberOfTokens <= publicListMaxMint, 'You cannot mint this many.');

        _nonReservedMintHelper(numberOfTokens);
        _publicListClaimed[msg.sender] += numberOfTokens;
    }
    
    function mintWhitelist(bytes32 hash, bytes calldata signature, uint256 numberOfTokens) external payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_hash(msg.sender) == hash, "The address hash does not match the signed hash.");
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= whitelistMaxMint, 'You cannot mint this many.');

        _whitelistClaimed[msg.sender] += numberOfTokens;
        _publicListClaimed[msg.sender] += numberOfTokens;
        _nonReservedMintHelper(numberOfTokens);
    }

    function _nonReservedMintHelper(uint256 numberOfTokens) internal {
        require(numberOfTokens * price == msg.value, "Invalid amount.");
        require(totalSupply() + numberOfTokens <= max, "Sold out.");

        _safeMint(msg.sender, numberOfTokens);
    }

    function splitPayments() public payable onlyOwner {
        (bool success, ) = payable(_splitter).call{value: address(this).balance}(
        ""
        );
        require(success);
    }

    function mintReserved(address receiver, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= reservedMax,
            "Sold out."
        );

        _safeMint(receiver, quantity);
    }

    function setBaseURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        virtual
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }
}