// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "./MimeticMetadataBase.sol";

error RequiredNFTHolder();
error NonExistentToken();
error NotTokenOwner();

contract EndGame is Ownable, Pausable, ReentrancyGuard, MimeticMetadataBase, ERC721A, ERC2981 {
    uint256 public constant PUBLIC_MAX_LIMIT = 3;
    uint256 public constant MINT_TIME = 2 days;
    uint256 public constant TOTAL_SUPPLY = 15000;
    uint96 public constant ROYALTY_FEE = 1000;

    uint256 public startTimestamp;
    bytes32[3] public merkleRoots;

    mapping(address => bool) public isWLMinted;
    mapping(address => uint256) public publicMintTrack;

    struct MerkleNode {
        uint256 group;
        uint256 quantity;
        bytes32[] proofs;
    }

    event Mint(address indexed user, uint256 indexed group, uint256 startIndex, uint256 amount);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller not a user");
        _;
    }

    constructor(
        uint256 _startTimestamp,
        string memory _initialBaseUri,
        address payable _royaltyReceiver
    ) MimeticMetadataBase(_initialBaseUri) ERC721A("LOOK LABS End Game", "EG") {
        require(_startTimestamp >= 0, "Invalid start timestamp");
        startTimestamp = _startTimestamp;

        // Use ERC2981 to set royalty receiver and fee
        _setDefaultRoyalty(_royaltyReceiver, ROYALTY_FEE);

        // Pause
        _pause();
    }

    function whitelistMint(MerkleNode[] calldata _data) external whenNotPaused callerIsUser nonReentrant {
        require(block.timestamp > startTimestamp, "Mint not started yet");
        require(block.timestamp <= startTimestamp + MINT_TIME, "Mint ended");
        require(isWLMinted[msg.sender] == false, "Already minted");
        require(_data.length > 0 && _data.length <= 3, "Too many nodes");

        uint256 _quantity = 0;
        uint256 _startIndex = _currentIndex;
        uint256[3] memory groups;

        for (uint256 index = 0; index < _data.length; index++) {
            MerkleNode memory node = _data[index];
            require(node.group >= 0 && node.group < 3, "Invalid group");
            require(merkleRoots[node.group] != 0, "Merkle root not set");

            // Check if the same group is sent multiple times
            for (uint256 i = 0; i < index; i++) {
                // node.group + 1: elevate the values by 1, because they start from 0
                if (groups[i] == node.group + 1) revert("Cheat is not allowed");
            }
            groups[index] = node.group + 1;

            // Verify the proof
            bytes32 merkleNode = keccak256(abi.encodePacked(msg.sender, node.quantity));
            require(MerkleProof.verify(node.proofs, merkleRoots[node.group], merkleNode), "Invalid amount");

            // Emit event and prepare for the next node
            emit Mint(msg.sender, node.group, _startIndex, node.quantity);

            _quantity += node.quantity;
            _startIndex += node.quantity;
        }

        isWLMinted[msg.sender] = true;
        mint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external whenNotPaused callerIsUser nonReentrant {
        require(block.timestamp > startTimestamp + MINT_TIME, "Mint not allowed");
        require(_quantity == 1 && publicMintTrack[msg.sender] + _quantity <= PUBLIC_MAX_LIMIT, "Max reached");

        // Record how many tokens the user has minted
        publicMintTrack[msg.sender] += _quantity;

        emit Mint(msg.sender, 3, _currentIndex, _quantity);
        mint(msg.sender, _quantity);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert NonExistentToken();

        return _tokenURI(_tokenId);
    }

    function evolve(uint256 _tokenId) external whenNotPaused {
        if (!_exists(_tokenId)) revert NonExistentToken();
        if (ownerOf(_tokenId) != msg.sender) revert NotTokenOwner();

        _evolve(_tokenId);
    }

    // Owner functions
    // There are also owner functions from `MimeticMetadataBase` contract
    function ownerMint(uint256 _quantity) external onlyOwner {
        // Emit mint event
        emit Mint(msg.sender, 4, _currentIndex, _quantity);

        mint(owner(), _quantity);
    }

    function setMerkleRoots(bytes32[3] calldata _roots) external onlyOwner {
        require(_roots.length == 3, "Invalid number of roots");

        merkleRoots = _roots;
    }

    function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        require(_startTimestamp > 0, "Invalid timestamp");
        startTimestamp = _startTimestamp;
    }

    function setRoyaltyInfo(address _receiver, uint96 _feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeBasisPoints);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Internal functions
    function mint(address _to, uint256 _quantity) private {
        require(_quantity >= 0 && _totalMinted() + _quantity <= TOTAL_SUPPLY, "Reached supply");

        _mint(_to, _quantity, "", false);
    }
}