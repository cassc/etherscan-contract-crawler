// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "@franknft.eth/erc721-f/contracts/token/ERC721/ERC721FCOMMON.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title The Yearbook Club
 *
 * @dev Implementation of [ERC721F] with MerkleRoot validation for whitelisted accounts that can take part in the pre-sale
 */
contract YearbookClub is ERC721FCOMMON {
    uint256 public constant MAX_TOKENS = 5555;
    uint256 public constant MAX_PURCHASE = 6;
    uint256 public tokenPrice = 0.037 ether;
    bool public preSaleIsActive;
    bool public saleIsActive;
    bytes32 public root;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant TEAM = 0x467AEBE3369C5561dEb30a06B480Ac85F936334b;  
    address private constant WEB = 0x3Faa2705080657AfEDe5cD42F5011f2b6FdD4273;
    mapping(address => uint256) private mintAmount;

    constructor() ERC721FCOMMON("The Yearbook Club", "YBC") {
        setBaseTokenURI(
            "ipfs://QmaGXTPughLtEQZfztF5Zh7YZv87aDn4YTqQvGBtaXS6L8/"
        );
        _mint(FRANK, 0);     

    }

    /**
     * Mint Tokens to a wallet.
     */
    function airdrop(address to, uint256 numberOfTokens) public onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Reserve would exceed max supply of Tokens"
        );
        unchecked {
            for (uint256 i = 0; i < numberOfTokens; ) {
                _safeMint(to, supply + i);
                i++;
            }
        }
    }

    modifier validMintRequest(uint256 numberOfTokens) {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(
            tokenPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );
        _;
    }

    /**
     * @notice Assigns `_root` to `root`, this changes the whitelisted accounts that have access to mintPreSale
     * @param _root Calculated roothash of merkle tree
     * @dev A new roothash can be calculated using the `scripts\js\merkle_tree.js` file
     */
    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    /**
     * Changes the state of preSaleIsactive from true to false and false to true
     */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /**
     * Changes the state of saleIsActive from true to false and false to true
     * @dev If saleIsActive becomes `true` sets preSaleIsActive to `false`
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if (saleIsActive) {
            preSaleIsActive = false;
        }
    }

    /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 30
     */
    function mint(uint256 numberOfTokens)
        external
        payable
        validMintRequest(numberOfTokens)
    {
        require(msg.sender == tx.origin, "No Contracts allowed.");
        require(saleIsActive, "Sale NOT active yet");
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );

        unchecked {
            for (uint256 i; i < numberOfTokens; ) {
                _mint(msg.sender, supply + i); // no need to use safeMint as we don't allow contracts.
                i++;
            }
        }
        mintAmount[msg.sender] = mintAmount[msg.sender]+numberOfTokens;
    }

    /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 30
     * @param merkleProof Proof that an address is part of the whitelisted pre-sale addresses
     * @dev Uses MerkleProof to determine whether an address is allowed to mint during the pre-sale, non-mint name is due to hardhat being unable to handle function overloading
     */
    function mintPreSale(uint256 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        validMintRequest(numberOfTokens)
    {
        require(preSaleIsActive, "PreSale is not active yet");
        require(mintAmount[msg.sender]+numberOfTokens<MAX_PURCHASE,"Purchase would exceed max mint for walet");
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        require(checkValidity(merkleProof), "Invalid Merkle Proof");

        unchecked {
            for (uint256 i; i < numberOfTokens; ) {
                _safeMint(msg.sender, supply + i);
                i++;
            }
        }
        mintAmount[msg.sender] = mintAmount[msg.sender]+numberOfTokens;
    }

    function checkValidity(bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leafToCheck = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, root, leafToCheck);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        _withdraw(FRANK, balance/40);
        _withdraw(WEB, balance/20);
        _withdraw(TEAM, address(this).balance);
    }
}