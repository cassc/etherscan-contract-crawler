// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract WAGTI is ERC721A, Ownable
{
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant INITIAL_SUPPLY = 600;
    uint256 public constant WHITELIST_SUPPLY = 45;
    uint256 public constant RESERVE_SUPPLY = 24;
    uint256 public constant SUPPLY_TO_RELEASE_BY_EPOCH = 50;
    uint256 public constant MAX_PER_WALLET = 4;
    uint256 public constant EPOCH_DURATION = 15780000; // 6 months
    uint256 public constant ONE_DAY = 86400;

    string public baseTokenURI;

    bytes32 public merkleRoot;
    bytes32 public wlMerkleRoot;
    uint256 public mintPrice;

    // Tight Variable Packing
    uint128 public mintStartTimestamp;
    uint64 public nextReleaseTimestamp;
    bool public reserveMinted;
    bool public paused;

    event Withdraw(uint256 amount);

    modifier notPaused() {
        require(!paused, "CONTRACT_PAUSED");
        _;
    }

    constructor(string memory _baseTokenURI) ERC721A("wagti.corp", "wagti") {
        baseTokenURI = _baseTokenURI;
    }

    // public mint automatically starts 1 day after whitelist mint
    function mint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable notPaused {
        uint128 _mintStartTimestamp = mintStartTimestamp;

        require(_mintStartTimestamp > 0 && _mintStartTimestamp + ONE_DAY <= block.timestamp, "MINT_NOT_STARTED");
        require(totalSupply() + _quantity <= INITIAL_SUPPLY - WHITELIST_SUPPLY, "NO_MORE_SUPPLY");
        require(balanceOf(msg.sender) + _quantity <= MAX_PER_WALLET, "CANNOT_MINT_MORE");
        require(msg.value >= mintPrice * _quantity, "NOT_ENOUGH_ETHER");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "INVALID_PROOF");

        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] calldata _merkleProof) external payable notPaused {
        require(mintStartTimestamp > 0, "MINT_NOT_STARTED");
        require(totalSupply() + 1 <= INITIAL_SUPPLY, "NO_MORE_SUPPLY");
        require(_numberMinted(msg.sender) == 0, "CANNOT_MINT_MORE");
        require(msg.value >= mintPrice, "NOT_ENOUGH_ETHER");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf), "INVALID_PROOF");

        _safeMint(msg.sender, 1);
    }

    function reserveMint() external onlyOwner {
        require(!reserveMinted, "RESERVE_ALREADY_MINTED");

        reserveMinted = true;
        _safeMint(msg.sender, RESERVE_SUPPLY);
    }

    function release() external onlyOwner {
        require(block.timestamp >= nextReleaseTimestamp, "EPOCH_NOT_ENDED");

        nextReleaseTimestamp += uint64(EPOCH_DURATION);
        _safeMint(msg.sender, SUPPLY_TO_RELEASE_BY_EPOCH);
    }

    function startMint(uint256 _mintPrice, bytes32 _merkleRoot, bytes32 _wlMerkleRoot) external onlyOwner {
        mintPrice = _mintPrice;

        mintStartTimestamp = uint128(block.timestamp);
        nextReleaseTimestamp = uint64(block.timestamp + EPOCH_DURATION);

        merkleRoot = _merkleRoot;
        wlMerkleRoot = _wlMerkleRoot;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    // start a new session in order to include new accounts in the merkle root
    function startSession(uint256 _mintPrice, bytes32 _merkleRoot) external onlyOwner {
        if (_mintPrice > 0) {
            mintPrice = _mintPrice;
        }

        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "NO_ETHER");

        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "WITHDRAW_FAILED");

        emit Withdraw(balance);
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}