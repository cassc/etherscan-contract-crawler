// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";
import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC721Metadata} from "openzeppelin-contracts/interfaces/IERC721Metadata.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

contract ERC721WCHome is ERC721 {
    address payable public owner;

    string public BASE_URI;

    uint256 public immutable mintCost; // in wei
    uint256 public immutable maxWhitelistSupply;  // total number of NFTs in whitelist
    uint256 public immutable maxPublicSupply;  // total number of NFTs in public sale
    uint256 public immutable numInitialTeams;  // 32 for WC
    uint256 public immutable maxMintPerAddress;  // max amount each wallet can mint

    uint256 public numWhitelistMinted;  // number of items already publicly minted
    uint256 public numPublicMinted;  // number of items already publicly minted
    uint256 public numMinted;  // total number of items already minted
    mapping (address => uint256) public addressNumMinted;  // amount already minted in each wallet

    bool public mintEnded;  // cannot mint after teams are assigned

    bytes32 public immutable merkleRoot;  // mintlist
    mapping(address => bool) public claimed;

    event BaseURIUpdated();
    event OwnerChanged(address indexed newOwner);
    event MintEnded();

    error NotOwner();
    error NotHolder();
    error AlreadyClaimed();
    error InvalidProof();
    error IncorrectPayment(uint256 expected, uint256 amount);
    error InsufficientBalance(uint256 amount);
    error TransferFailed();
    error MintingEnded();
    error MaxSupplyReached();
    error MaxMintAmountReached();

    constructor(
        uint256 _mintCost,
        uint256 _numInitialTeams,
        uint256 _maxPublicSupply,
        uint256 _maxWhitelistSupply,
        uint256 _maxMintPerAddress,
        string memory _baseUri,
        bytes32 _merkleRoot
    ) ERC721(name, symbol) {
        owner = payable(msg.sender);

        BASE_URI = _baseUri;

        name = string("Hologram WC 2022 Home Jersey");
        symbol = string("HWCH");

        mintCost = _mintCost;
        maxPublicSupply = _maxPublicSupply;
        maxWhitelistSupply = _maxWhitelistSupply;
        numInitialTeams = _numInitialTeams;
        maxMintPerAddress = _maxMintPerAddress;

        merkleRoot = _merkleRoot;

        mintEnded = false;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function setOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    function updateBaseURI(string memory _baseUri) public onlyOwner {
        BASE_URI = _baseUri;
        emit BaseURIUpdated();
    }

    function endMinting() public onlyOwner {
        if (mintEnded) revert MintingEnded();
        mintEnded = true;
        emit MintEnded();
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return string.concat(BASE_URI, Strings.toString(_tokenId));
    }

    function getMintedAmount(address _addr) public view returns(uint256) {
        return addressNumMinted[_addr];
    }

    function checkInWhitelist(address _addr, uint256 amount, bytes32[] calldata merkleProof) public view returns(bool) {
        bytes32 node = keccak256(abi.encodePacked(_addr, amount));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    function claim(uint256 amount, bytes32[] calldata merkleProof) external {
        if (claimed[msg.sender]) revert AlreadyClaimed();
        if (numWhitelistMinted + amount > maxWhitelistSupply) revert MaxSupplyReached();

        // verify the merkle proof
        address to = msg.sender;
        if (!checkInWhitelist(to, amount, merkleProof)) revert InvalidProof();

        if (addressNumMinted[to] + amount > maxMintPerAddress) revert MaxMintAmountReached();

        for (uint256 i = numMinted; i < numMinted + amount; i ++) {
            _mint(to, i);
        }

        claimed[msg.sender] = true;
        addressNumMinted[to] += amount;
        numWhitelistMinted += amount;
        numMinted += amount;
    }

    function mint() public payable {
        if (mintEnded) revert MintingEnded();
        if (numPublicMinted == maxPublicSupply) revert MaxSupplyReached();
        if (msg.value != mintCost) revert IncorrectPayment(mintCost, msg.value);

        address to = msg.sender;
        if (addressNumMinted[to] == maxMintPerAddress) revert MaxMintAmountReached();
        
        _mint(to, numMinted);

        addressNumMinted[to] += 1;
        numPublicMinted += 1;
        numMinted += 1;
    }

    function batchMint(uint256 numToMint) public payable {
        if (mintEnded) revert MintingEnded();
        if (numPublicMinted + numToMint > maxPublicSupply) revert MaxSupplyReached();
        if (msg.value != mintCost * numToMint) revert IncorrectPayment(mintCost, msg.value);

        address to = msg.sender;
        if (addressNumMinted[to] + numToMint > maxMintPerAddress) revert MaxMintAmountReached();

        for (uint256 i = numMinted; i < numMinted + numToMint; i ++) {
            _mint(to, i);
        }

        addressNumMinted[to] += numToMint;
        numPublicMinted += numToMint;
        numMinted += numToMint;
    }
}