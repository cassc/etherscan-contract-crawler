// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

contract OutlandishCreatures is ERC721A, Ownable {

    enum MintState {
        Closed,
        Whitelist,
        Public
    }

    uint256 public MAX_SUPPLY = 6666;
    uint256 public WL_TOKEN_PRICE = 0.005 ether;
    uint256 public PUBLIC_TOKEN_PRICE = 0.008 ether;
    uint256 public PUBLIC_MINT_LIMIT = 5;
    uint256 public WHITELIST_MINT_LIMIT = 2;

    MintState public mintState;
    bytes32 public merkleRoot;

    string public baseURI;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation
    ) ERC721A("OutlandishCreatures", "OC") {
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

    // Sale

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setSaleState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Whitelist;
        else if (newState == 2) mintState = MintState.Public;
        else revert("Mint state does not exist");
    }

    function tokensRemainingForAddress(address who) public view returns (uint256) {
        if (mintState == MintState.Whitelist)
            return WHITELIST_MINT_LIMIT - _numberMinted(who);
        else if (mintState == MintState.Public)
            return PUBLIC_MINT_LIMIT + _getAux(who) - _numberMinted(who);
        else revert("Mint state mismatch");
    }

    function mintPublic(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Public, "Mint state mismatch");
        require(msg.value >= PUBLIC_TOKEN_PRICE * quantity, "Insufficient value");
        require(tokensRemainingForAddress(msg.sender) >= quantity, "Mint limit for user reached");

        _mint(msg.sender, quantity);
    }

    function mintWhitelist(bytes32[] calldata proof, uint256 quantity)
        external
        payable
        onlyExternallyOwnedAccount
        onlyValidProof(proof)
    {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Whitelist, "Sale state mismatch");
        require(msg.value >= WL_TOKEN_PRICE * quantity, "Insufficient value");
        require(tokensRemainingForAddress(msg.sender) >= quantity, "Mint limit for user reached");

        _mint(msg.sender, quantity);

        _setAux(msg.sender, _getAux(msg.sender) + uint64(quantity));
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

    // Edit Mint

    function setWLPrice(uint256 _newPrice) public onlyOwner {
        WL_TOKEN_PRICE = _newPrice;
    }

    function setPublicPrice(uint256 _newPrice) public onlyOwner {
        PUBLIC_TOKEN_PRICE = _newPrice;
    }

    function setSupply(uint256 _newSupply) public onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setPublicLimit(uint256 _newLimit) public onlyOwner {
        PUBLIC_MINT_LIMIT = _newLimit;
    }

    function setWLLimit(uint256 _newLimit) public onlyOwner {
        WHITELIST_MINT_LIMIT = _newLimit;
    }

    // Withdraw
 
    function withdrawToRecipients() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;

        address owner           = 0x619298123929ff29870430Fd7bFd63d0c5BB36AF;
        address dev             = 0xbF5e7d8994E9f7C94E00Bc94a9249f511903EB3B;
        address marketingOne    = 0x6e82Ce36948f356Adcc9D110f7a7a0138272E5Ce;
        address marketingTwo    = 0x086B4bE6B51B208Db35d416f414Cc7282E84e5e4;

        address(owner          ).call{value: balancePercentage * 73}("");
        address(dev            ).call{value: balancePercentage * 10}("");
        address(marketingOne   ).call{value: balancePercentage * 10}("");
        address(marketingTwo   ).call{value: balancePercentage *  7}("");
    }
}