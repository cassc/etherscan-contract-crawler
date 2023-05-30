//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "ERC721A/ERC721A.sol";

/*
 * @title ERC1155 token for NFT 2048
 * @author WayneHong @ Norika
 */

error CallFromContract();
error ExceedMaxSupply(uint256 maxSupply);
error ExceedMintLimit(uint256 mintLimit);
error MintNotStart();
error MintEnd();
error InvalidSignature();

contract Onitama is Ownable, ERC721A {
    using ECDSA for bytes32;
    using Strings for uint256;

    address public signerAddress;
    address public teamAddress;
    mapping(address => uint256) public addressWhitelistMintedCount;
    mapping(address => uint256) public addressMintedCount;

    string public notRevealedUri;
    string private _baseTokenURI = "";

    uint256 public maxSupply = 3333;
    uint256 public maxBatchSize = 1;
    uint256 public publicMintStartAt;
    uint256 public whitelistMintStartAt;

    constructor(
        address _signerAddress,
        address _teamAddress,
        uint256 _maxBatchSize,
        uint256 _whitelistMintStartAt,
        uint256 _publicMintStartAt,
        string memory _notRevealedUri
    ) ERC721A("Onitama", "ONI") {
        signerAddress = _signerAddress;
        teamAddress = _teamAddress;
        maxBatchSize = _maxBatchSize;
        whitelistMintStartAt = _whitelistMintStartAt;
        publicMintStartAt = _publicMintStartAt;
        notRevealedUri = _notRevealedUri;
        // _mint(teamAddress, 250);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : notRevealedUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    modifier checkValidMint(uint256 quantity) {
        if (tx.origin != msg.sender) revert CallFromContract();
        if (totalSupply() + quantity > maxSupply)
            revert ExceedMaxSupply(maxSupply);

        _;
    }

    function whitelistMint(
        uint256 quantity,
        uint256 mintLimit,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable checkValidMint(quantity) {
        if (block.timestamp < whitelistMintStartAt) revert MintNotStart();
        if (block.timestamp >= publicMintStartAt) revert MintEnd();
        if (addressWhitelistMintedCount[msg.sender] + quantity > mintLimit)
            revert ExceedMintLimit(mintLimit);
        if (!isAuthorized(msg.sender, mintLimit, v, r, s))
            revert InvalidSignature();

        addressWhitelistMintedCount[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity)
        external
        payable
        checkValidMint(quantity)
    {
        if (block.timestamp < publicMintStartAt) revert MintNotStart();
        if (addressMintedCount[msg.sender] + quantity > maxBatchSize)
            revert ExceedMintLimit(maxBatchSize);

        addressMintedCount[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function mintForAirdrop(address[] memory addresses, uint256 quantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], quantity);
        }
    }

    function isAuthorized(
        address sender,
        uint256 mintLimit,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, mintLimit));
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return signerAddress == ecrecover(signedHash, v, r, s);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}