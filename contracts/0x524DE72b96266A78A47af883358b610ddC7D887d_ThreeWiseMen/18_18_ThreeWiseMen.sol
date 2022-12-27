// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

error ThreeWiseMen__TransferFailed();

contract ThreeWiseMen is
    ERC721,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;

    uint256 public constant MAX_SUPPLY = 333;

    string public baseURI;
    string public notRevealedUri =
        "ipfs://QmYUuwLoiRb8woXwJCCsr1gvbr8E21KuxRtmVBmnH1tZz7/hidden.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;
    bool public ownerM = false;

    uint256 public presaleAmountLimit = 1;
    uint256 public publicAmountLimit = 3;

    mapping(address => uint256) public _presaleClaimed;

    uint256 public _preSalePrice = 3000000000000000; // 0.0030 ETH
    uint256 public _ownerPrice = 0;
    uint256 public _publicPrice = 3300000000000000; // 0.0033 ETH

    Counters.Counter private _tokenIds;

    constructor(
        string memory uri,
        bytes32 merkleroot
    ) ERC721("ThreeWiseMen", "TWM") ReentrancyGuard() {
        root = merkleroot;

        setBaseURI(uri);
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMerkleRoot(bytes32 merkleroot) public onlyOwner {
        root = merkleroot;
    }

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
        require(
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ) == true,
            "Not allowed origin"
        );
        _;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function toggleownerSale() public onlyOwner {
        ownerM = !ownerM;
    }

    function presaleMint(
        address account,
        uint256 _amount,
        bytes32[] calldata _proof
    ) external payable isValidMerkleProof(_proof) onlyAccounts nonReentrant{
        require(msg.sender == account, "Not allowed");
        require(presaleM, "Presale is OFF");
        require(!paused, "PreSale is paused");
        require(_amount <= presaleAmountLimit, "Maximum mints exceeded");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,
            "You can't mint so much tokens"
        );

          uint current = _tokenIds.current();
          
          require(
            current + _amount <= MAX_SUPPLY,
            "Sold Out"
        );

        require(_preSalePrice * _amount <= msg.value, "Not enough ethers sent");

        _presaleClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) external payable onlyAccounts nonReentrant {
        require(publicM, "PublicSale is OFF");
        require(!paused, "PublicSale is paused");
        require(_amount > 0, "zero amount");

        require(_publicPrice * _amount <= msg.value, "Not enough ethers sent");

           uint current = _tokenIds.current();
           require(
            current + _amount <= MAX_SUPPLY,
            "Sold out"
        );

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function ownerMint(uint256 _amount) external payable onlyOwner {
        require(ownerM, "You're not the owner");
        require(_amount > 0, "zero amount");

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
   
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(
        string memory _newBaseExtension
    ) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert ThreeWiseMen__TransferFailed();
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}