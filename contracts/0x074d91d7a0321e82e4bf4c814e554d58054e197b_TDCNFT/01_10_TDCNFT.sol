// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TDCNFT is Ownable, ReentrancyGuard, Pausable, ERC721AQueryable {
    enum Stage {
        NotStarted,
        AllowList,
        Public
    }
    /* ============ Constants ============ */
    uint256 public constant MAX_SUPPLY = 1888;
    uint256 public constant ALLOWLIST_MINT_NUM = 2;

    /* ============ State Variables ============ */
    string public baseURI;
    bytes32 public merkleRoot;
    Stage public currentStage;
    mapping(address => bool) public FilteredAddress;

    /* ============ Constructor ============ */
    constructor() ERC721A("3DCNFT", "3DC") {
        FilteredAddress[0x00000000000111AbE46ff893f3B2fdF1F759a8A8] = true; // Blur.io ExecutionDelegate
        FilteredAddress[0xF849de01B080aDC3A814FaBE1E2087475cF2E354] = true; // X2Y2 ERC721Delegate
        FilteredAddress[0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e] = true; // LooksRare TransferManagerERC721
    }

    /* ============ External Functions ============ */
    function allowlistMint(bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        onlyEOA
        whenNotPaused
    {
        require(currentStage == Stage.AllowList, "3DCNFT: not start");
        require(
            mintVerify(msg.sender, _merkleProof),
            "3DCNFT: Address is not in allow list"
        );
        require(
            _totalMinted() + ALLOWLIST_MINT_NUM <= MAX_SUPPLY,
            "3DCNFT: Over max supply"
        );
        require(
            _numberMinted(msg.sender) == 0,
            "3DCNFT: Over max mint per wallet"
        );

        _mint(msg.sender, ALLOWLIST_MINT_NUM);
    }

    function mint() external payable nonReentrant onlyEOA whenNotPaused {
        require(currentStage == Stage.Public, "3DCNFT: not start");
        require(_totalMinted() + 1 <= MAX_SUPPLY, "3DCNFT: Over max supply");
        require(
            _numberMinted(msg.sender) == 0,
            "3DCNFT: Over max mint per wallet"
        );

        _mint(msg.sender, 1);
    }

    // For marketing and airdrop etc.
    function devMint(uint256 _quantity) external onlyOwner {
        require(
            _totalMinted() + _quantity <= MAX_SUPPLY,
            "3DCNFT: too many already minted before dev mint"
        );
        require(
            _numberMinted(owner()) + _quantity <= 605,
            "3DCNFT: too many already minted"
        );

        _mint(owner(), _quantity);
    }

    /**
     * @notice Set the baseURI for tokenURI()
     * @param _newBaseURI The URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Set the merkle root
     * @param _newMerkleRoot The new merkle root
     */
    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    /**
     * @notice Set the stage
     * @param _newStage The new stage
     */
    function setCurrentStage(Stage _newStage) external onlyOwner {
        currentStage = _newStage;
    }

    function setFilteredAddress(address _address, bool _isFiltered)
        external
        onlyOwner
    {
        FilteredAddress[_address] = _isFiltered;
    }

    /**
     * @notice Pause the contract
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        require(
            !FilteredAddress[msg.sender],
            "3DCNFT: You are not allowed to transfer tokens"
        );
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /* ============ Internal Functions ============ */
    /**
     * @notice verify the merkle proof
     */
    function mintVerify(address addr, bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice override the start token id
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice override the base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /* ============ Modifiers ============ */
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyEOA() {
        require(
            tx.origin == msg.sender,
            "3DCNFT: The caller is another contract"
        );
        _;
    }

    /* ============ External Getter Functions ============ */
    /**
     * @notice Get the total number of tokens minted
     * @return The total number of tokens minted
     */
    function totalMinted(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }
}