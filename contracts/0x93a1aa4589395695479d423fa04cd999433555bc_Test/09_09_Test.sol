// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "ERC721A/ERC721A.sol";

contract Test is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;
   
    uint256 constant COMIC_SUPPLY = 100;
    uint256 constant MINT_COST = 0.1 ether;
    uint256 constant MINT_PER_WALLET = 10; 

    bool public burningEnabled = false;

    string baseTokenURI;
    bytes32 public merkleRoot;

    enum Phase {
        PAUSED,
        AL,
        PUBLIC
    }

    Phase public mintingPhase = Phase.PAUSED;

    mapping(address => bool) public allowlistMintClaimed;

    // Errors
    error AlreadyClaimed();
    error BurningNotEnabled();
    error ComicSupplyExceeded();
    error IncorrectMintPhase();
    error MerkleProofInvalid();
    error MaxMintExceeded();
    error MintNotAuthorized();
    error NotComicOwner();
    error PaymentAmountInvalid();

    // Events
    event MintingPhaseStarted(Phase phase);
    event AllowlistClaimed(address wallet);

    modifier onlyIfMintingPhaseIsSetTo(Phase phase) {
        if (mintingPhase != phase) {
            revert IncorrectMintPhase();
        }
        _;
    }

    // @notice Requires burning if burning is enabled
    modifier onlyIfburningEnabled() {
        if (!burningEnabled) {
            revert BurningNotEnabled();
        }
        _;
    }

    // @notice Requires supply to be available
    modifier onlyIfSupplyAvailable() {
        if (_totalMinted() > COMIC_SUPPLY) {
            revert MaxMintExceeded();
        }
        _;
    }

    // @notice Requires a valid merkle proof for the specified merkle root.
    modifier onlyIfValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        if (!MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender)))) {
            revert MerkleProofInvalid();
        }
        _;
    }

    //@notice Requires msg.value to be equal to the mint price
    modifier onlyIfPaymentAmountValid(uint256 value) {
        if (msg.value != value) {
            revert PaymentAmountInvalid();
        }
        _;
    }

    // @notice Requires no earlier claims for the caller in the allowlist mint.
    modifier onlyIfNotAlreadyClaimedAllowlist() {
        if (allowlistMintClaimed[msg.sender]) {
            revert AlreadyClaimed();
        }
        _;
    }

    modifier onlyOwnerOf(uint256 tokenId) {
        if (msg.sender != ownerOf(tokenId)) {
            revert NotComicOwner();
        }
        _;
    }

    constructor(string memory _baseTokenURI, bytes32 _merkleRoot) ERC721A("testcomic", "testcomic") {
        baseTokenURI = _baseTokenURI;
        merkleRoot = _merkleRoot;
    }

    // @notice Mint allowlist function
    function mintAllowList(bytes32[] calldata proof)
        external
        payable
        onlyIfMintingPhaseIsSetTo(Phase.AL)
        onlyIfPaymentAmountValid(MINT_COST)
        onlyIfValidMerkleProof(merkleRoot, proof)
        onlyIfNotAlreadyClaimedAllowlist
        onlyIfSupplyAvailable
        nonReentrant
    {
        allowlistMintClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
        emit AllowlistClaimed(msg.sender);
    }

    // @notice Mint function
    function mint(uint256 amount, address to)
        external
        payable
        onlyIfPaymentAmountValid(MINT_COST * amount)
        onlyIfMintingPhaseIsSetTo(Phase.PUBLIC)
        onlyIfSupplyAvailable
    {
        if (tx.origin != msg.sender) {
            revert MintNotAuthorized();
        }

        if (amount > MINT_PER_WALLET) {
            revert MaxMintExceeded();
        }
        _safeMint(to, amount);
    }

    // @notice Allows the owner to change the minting phase
    function setPhase(Phase _phase) external onlyOwner {
        mintingPhase = _phase;
        emit MintingPhaseStarted(mintingPhase);
    }

    // @notice: Toggle Burning for physical redemption
    function toggleBurning() external onlyOwner {
        burningEnabled = !burningEnabled;
    }

    // @notice Allows users to check if their wallet has been allowlisted
    function allowListed(address _wallet, bytes32[] calldata _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_wallet)));
    }

    // @notice Updates merkleRoot of allowlist
    function updateAllowList(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    //@notice returns tokenURI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    // @notice: Set baseTokenURI
    function setbaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // @notice: Allows owner to burn the token
    function burn(uint256 tokenId) public virtual onlyOwnerOf(tokenId) onlyIfburningEnabled {
        _burn(tokenId);
    }

    // @notice: Overrides tokenId to start from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // @notice: Withdraw the preceeds
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}