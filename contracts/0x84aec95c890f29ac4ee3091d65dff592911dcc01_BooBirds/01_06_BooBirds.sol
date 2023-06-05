// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

contract BooBirds is ERC721A, Ownable {

    enum MintState {
        Closed,
        Open
    }

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public MAX_WL_SUPPLY = 1500;
    uint256 public WL_TOKEN_PRICE = 0.0033 ether;
    uint256 public PUBLIC_TOKEN_PRICE = 0.0066 ether;
    uint256 public MINT_LIMIT = 6;
    uint256 public totalWhitelistMint;

    MintState public mintState;
    bytes32 public merkleRoot;

    string public baseURI;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation
    ) ERC721A("BooBirds", "Boo") {
        if (allocation < MAX_SUPPLY && allocation != 0)
            _safeMint(recipient, allocation);

        baseURI = baseURI_;
    }

    // Overrides

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Modifiers

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    modifier onlyValidProof(bytes32[] calldata proof) {
        bool valid = MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
        require(valid, "Invalid proof");
        _;
    }

    // Token

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setWLPrice(uint256 _newPrice) public onlyOwner {
        WL_TOKEN_PRICE = _newPrice;
    }

    function setPublicPrice(uint256 _newPrice) public onlyOwner {
        PUBLIC_TOKEN_PRICE = _newPrice;
    }

    function setMintLimit(uint256 _newLimit) public onlyOwner {
        MINT_LIMIT = _newLimit;
    }

    // Sale

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setMintState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Open;
        else revert("Mint state does not exist");
    }

    function tokensRemainingForAddress(address who) public view returns (uint256) {
        if (mintState == MintState.Open)
            return MINT_LIMIT - _numberMinted(who);
        else revert("Mint state mismatch");
    }

    // Mint

    function publicMint(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Open, "Mint state mismatch");
        require(msg.value >= PUBLIC_TOKEN_PRICE * quantity, "Insufficient value");
        require(tokensRemainingForAddress(msg.sender) >= quantity, "Mint limit for user reached");

        _mint(msg.sender, quantity);
    }

    function whitelistMint(bytes32[] calldata proof, uint256 quantity)
        external
        payable
        onlyExternallyOwnedAccount
        onlyValidProof(proof)
    {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(quantity + totalWhitelistMint <= MAX_WL_SUPPLY, "Amount exceeds max whitelist supply");
        require(mintState == MintState.Open, "Mint state mismatch");
        require(msg.value >= WL_TOKEN_PRICE * quantity, "Insufficient value");
        require(tokensRemainingForAddress(msg.sender) >= quantity, "Mint limit for user reached");

        totalWhitelistMint += quantity;
        _mint(msg.sender, quantity);
    }

    function batchMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(recipients.length == quantities.length, "Arguments length mismatch");

        uint256 supply = this.totalSupply();

        for (uint256 i; i < recipients.length; i++) {
            supply += quantities[i];

            require(supply <= MAX_SUPPLY, "Batch mint exceeds max supply");

            _mint(recipients[i], quantities[i]);
        }
    }
    
    // Withdraw

    function withdrawToRecipients() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;

        address owner = 0x03D72513b47609601d588ee93c96Ef33348D5F2F;

        address(owner).call{value: balancePercentage * 100}("");
    }
}