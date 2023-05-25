// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

interface IAlienFrensIncubator {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function burnIncubatorForAddress(address burnTokenAddress) external;
}

contract AlienFrensEvolution is
    Ownable,
    PaymentSplitter,
    ERC721A,
    ReentrancyGuard
{
    // Supply
    uint256 public constant RARES = 6; // 6 1of1s
    uint256 public constant HOLDERS = 6913; // from snapshot
    uint256 public constant INCUBATORS = 10000; // 1 Incubator per fren
    uint256 public constant MAX_TOKENS = INCUBATORS + HOLDERS + RARES; // Incubators + total holders + rares

    uint256 public PRICE = 0.25 ether;

    uint256 public maxMint = 1; // only 1 mint during pre or pub sale

    // counters
    mapping(address => uint8) public _preSaleListCounter;
    mapping(address => uint8) public _pubSaleListCounter;

    uint256 public nonIncubatorMints = 0; // used to check (pre + pub) mints <= HOLDERS

    // Contract Data
    string public _baseTokenURI;

    // Sale Switches
    bool public IncubatorMintActive = false;
    bool public preMintActive = false;
    bool public pubMintActive = false;

    // Addresses
    address public IncubatorContract;
    uint256 public IncubatorId = 0;

    // Merkle Root
    bytes32 public preRoot;
    bytes32 public pubRoot;

    constructor(address[] memory payees, uint256[] memory shares)
        ERC721A("Alien Frens Evolution", "AFE", maxMint, MAX_TOKENS)
        PaymentSplitter(payees, shares)
    {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /* Sale Switches */
    function setIncubatorMint(bool state) public onlyOwner {
        IncubatorMintActive = state;
    }

    function setPreMint(bool state) public onlyOwner {
        preMintActive = state;
    }

    function setPubMint(bool state) public onlyOwner {
        pubMintActive = state;
    }

    /* Setters */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setIncubatorContract(address _IncubatorContract) public onlyOwner {
        IncubatorContract = _IncubatorContract;
    }

    function setPreRoot(bytes32 _preRoot) public onlyOwner {
        preRoot = _preRoot;
    }

    function setPubRoot(bytes32 _pubRoot) public onlyOwner {
        pubRoot = _pubRoot;
    }

    /* Getters */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* Minting */

    // @dev rareMint() airdrops rare tokens to a single address
    function rareMint(address to) external onlyOwner {
        require(
            totalSupply() + 1 <= RARES,
            "Minting would exceed rares supply"
        );
        _safeMint(to, 1);
    }

    // @dev IncubatorMint() only mints 1 token in exchange for a Incubator token
    function IncubatorMint() external nonReentrant callerIsUser {
        // activation check
        require(IncubatorMintActive, "Incubator minting is not active");
        // overflow check
        require(
            totalSupply() + 1 <= MAX_TOKENS,
            "Incubator minting would exceed max supply"
        );
        // must have atleast 1 Incubator
        require(
            IAlienFrensIncubator(IncubatorContract).balanceOf(
                msg.sender,
                IncubatorId
            ) > 0,
            "You do not have enough Incubator"
        );

        // burn Incubator
        IAlienFrensIncubator(IncubatorContract).burnIncubatorForAddress(
            msg.sender
        );

        // mint v2
        _safeMint(msg.sender, 1);
    }

    // @dev preSale() only mints max 1 token to holder
    function preMint(bytes32[] calldata proof)
        external
        payable
        nonReentrant
        callerIsUser
    {
        // activation check
        require(preMintActive, "Pre minting is not active");
        require(
            nonIncubatorMints + 1 <= HOLDERS,
            "Mint would exceed max supply"
        );
        require(
            _preSaleListCounter[msg.sender] + 1 <= maxMint,
            "Only 1 mint per wallet"
        );
        require(PRICE * 1 == msg.value, "Incorrect funds");

        // check proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, preRoot, leaf),
            "Invalid MerkleProof"
        );

        // mint
        _safeMint(msg.sender, 1);

        // increment counters
        _preSaleListCounter[msg.sender] = _preSaleListCounter[msg.sender] + 1;
        nonIncubatorMints += 1;
    }

    // @dev preSale() only mints max 1 token to holder
    function publicMint(bytes32[] calldata proof)
        external
        payable
        nonReentrant
        callerIsUser
    {
        // activation check
        require(pubMintActive, "Public minting is not active");
        require(
            nonIncubatorMints + 1 <= HOLDERS,
            "Mint would exceed holder supply"
        );
        require(
            _pubSaleListCounter[msg.sender] + 1 <= maxMint,
            "Only 1 mint per wallet"
        );
        require(PRICE * 1 == msg.value, "Incorrect funds");

        // check proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, pubRoot, leaf),
            "Invalid MerkleProof"
        );

        // mint
        _safeMint(msg.sender, 1);

        // increment counters
        _pubSaleListCounter[msg.sender] = _pubSaleListCounter[msg.sender] + 1;
        nonIncubatorMints += 1;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}