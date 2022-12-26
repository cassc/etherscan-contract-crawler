//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * >>> Join the Resistance <<<
 * >>>   https://nfa.gg/   <<<
 * @title   NonFungibleArcade Arcade Pass
 * @author  BowTiedPickle
 */
contract ArcadePass is ERC721, ERC721Burnable, ERC2981, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    string public baseURI;

    mapping(address => uint256) public claimed;

    Counters.Counter internal nextId;

    uint256 public mintPrice = 250e6;
    uint256 public maxPerWallet = 1;
    uint256 public maxSupply = 1000;
    bool public supplyLocked;

    uint128 public startTime_heroes;
    uint128 public startTime_arcade;
    uint128 public startTime_rebels;

    bytes32 public merkleRoot_heroes;
    bytes32 public merkleRoot_arcade;
    bytes32 public merkleRoot_rebels;

    IERC20 internal immutable USDC;

    /// @notice Total number of tokens in existence
    uint256 public totalSupply;

    /**
     * @param   _owner              Owner address
     * @param   _royaltyBPS         Royalty in basis points, max is 10% (1000 BPS)
     * @param   _merkleRoot_heroes  Merkle root for Heroes phase
     * @param   _merkleRoot_arcade  Merkle root for Arcade phase
     * @param   _merkleRoot_rebels  Merkle root for Rebels phase
     * @param   _USDC               Address of the USDC token proxy
     * @param   _startTime_heroes   Start time for Heroes phase
     * @param   _startTime_arcade   Start time for Arcade phase
     * @param   _startTime_rebels   Start time for Rebels phase
     */
    constructor(
        address _owner,
        uint96 _royaltyBPS,
        bytes32 _merkleRoot_heroes,
        bytes32 _merkleRoot_arcade,
        bytes32 _merkleRoot_rebels,
        address _USDC,
        uint128 _startTime_heroes,
        uint128 _startTime_arcade,
        uint128 _startTime_rebels
    ) ERC721("NonFungibleArcade Arcade Pass", "NFA-PASS") {
        require(_owner != address(0), "!addr");
        require(_royaltyBPS <= 1000, "!bps");

        _transferOwnership(_owner);
        _setDefaultRoyalty(owner(), _royaltyBPS);

        // Start at 1, not at 0
        nextId.increment();

        // Set the merkle roots
        merkleRoot_heroes = _merkleRoot_heroes;
        merkleRoot_arcade = _merkleRoot_arcade;
        merkleRoot_rebels = _merkleRoot_rebels;

        // Set timestamps
        startTime_heroes = _startTime_heroes;
        startTime_arcade = _startTime_arcade;
        startTime_rebels = _startTime_rebels;

        // Set the USDC deployment
        USDC = IERC20(_USDC);

        // Deploy in paused state
        _pause();
    }

    /**
     * @notice  Mint an arcade pass
     * @dev     User must have approved this contract for the required value already
     * @param   _qty    Quantity to mint
     * @param   _proof  Merkle whitelist proof
     */
    function mint(uint256 _qty, bytes32[] calldata _proof) external whenNotPaused {
        require(_qty > 0, "!zero");
        require(claimed[msg.sender] + _qty <= maxPerWallet, "!qty");
        require(nextId.current() + _qty <= maxSupply + 1, "Max supply");
        USDC.safeTransferFrom(msg.sender, address(this), mintPrice * _qty);

        // Verify
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bytes32 root = getActiveRoot();
        require(root != 0, "!phase");
        require(MerkleProof.verify(_proof, root, leaf), "!proof");
        claimed[msg.sender] += _qty;

        // Mint
        uint256 tokenId;
        for (uint256 i; i < _qty; i++) {
            tokenId = nextId.current();
            nextId.increment();
            _mint(msg.sender, tokenId);
        }
    }

    // ----- Admin Functions -----

    /**
     * @notice  Permissioned mint function
     * @dev     Respects max supply
     * @param   _to     Recipient address
     * @param   _qty    Quantity to mint
     */
    function adminMint(address _to, uint256 _qty) external onlyOwner {
        require(_qty > 0, "!zero");
        require(nextId.current() + _qty <= maxSupply + 1, "Max supply");
        uint256 tokenId;
        for (uint256 i; i < _qty; i++) {
            tokenId = nextId.current();
            nextId.increment();
            _mint(_to, tokenId);
        }
    }

    /**
     * @notice  Withdraw profits from the contract
     */
    function withdraw() external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        USDC.safeTransfer(owner(), balance);
        emit Withdrawal(balance);
    }

    /**
     * @notice  Sets a new royalty numerator
     * @dev     Cannot exceed 10%
     * @param   _royaltyBPS   New royalty, denominated in BPS (10000 = 100%)
     */
    function setRoyalty(uint96 _royaltyBPS) external onlyOwner {
        require(_royaltyBPS <= 1000, "!bps");
        _setDefaultRoyalty(owner(), _royaltyBPS);
        emit NewRoyalty(_royaltyBPS);
    }

    /**
     * @notice  Set a new base URI
     * @param   _newURI     New URI string
     */
    function setURI(string memory _newURI) external onlyOwner {
        emit NewURI(baseURI, _newURI);
        baseURI = _newURI;
    }

    /**
     * @notice  Set a new merkle root
     * @param   _newRoot    New whitelist merkle root
     */
    function setMerkleRoot(bytes32 _newRoot, uint256 _phase) external onlyOwner {
        require(_phase > 0 && _phase <= 3, "!param");
        if (_phase == 1) {
            emit NewRoot(1, merkleRoot_heroes, _newRoot);
            merkleRoot_heroes = _newRoot;
        } else if (_phase == 2) {
            emit NewRoot(2, merkleRoot_arcade, _newRoot);
            merkleRoot_arcade = _newRoot;
        } else if (_phase == 3) {
            emit NewRoot(3, merkleRoot_rebels, _newRoot);
            merkleRoot_rebels = _newRoot;
        }
    }

    /**
     * @notice  Set a new maximum supply
     * @dev     Cannot be set once supply is locked.
     * @dev     Cannot be set below existing total token supply.
     * @param   _newMax     New max supply
     */
    function setMaxSupply(uint256 _newMax) external onlyOwner {
        require(!supplyLocked, "Locked");
        require(_newMax >= nextId.current() - 1, "!supply");
        emit NewMaxSupply(maxSupply, _newMax);
        maxSupply = _newMax;
    }

    /**
     * @notice  Lock the maximum supply, preventing any further changes
     */
    function lockMaxSupply() external onlyOwner {
        supplyLocked = true;
        emit SupplyLocked(maxSupply);
    }

    /**
     * @notice  Set a new maximum per wallet
     * @param   _newMax     New max per wallet
     */
    function setMaxPerWallet(uint256 _newMax) external onlyOwner {
        emit NewMaxPerWallet(maxPerWallet, _newMax);
        maxPerWallet = _newMax;
    }

    /**
     * @notice  Set a new mint price
     * @param   _newPrice   New mint price in units of USDC
     */
    function setMintPrice(uint256 _newPrice) external onlyOwner {
        emit NewMintPrice(mintPrice, _newPrice);
        mintPrice = _newPrice;
    }

    /**
     * @notice  Set the minting pause status
     * @param   _status     True to pause, false to unpause
     */
    function setPaused(bool _status) external onlyOwner {
        if (_status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice  Set start time of each phase
     * @dev     Each phase start must be >= previous phase, all must be >= block.timestamp
     * @param   _startTime_heroes   Start time of Heroes phase in Unix epoch seconds
     * @param   _startTime_arcade   Start time of Arcadelist phase in Unix epoch seconds
     * @param   _startTime_rebels   Start time of Rebels phase in Unix epoch seconds
     */
    function setStartTimes(
        uint128 _startTime_heroes,
        uint128 _startTime_arcade,
        uint128 _startTime_rebels
    ) external onlyOwner {
        require(
            _startTime_rebels >= _startTime_arcade && _startTime_arcade >= _startTime_heroes && _startTime_heroes >= block.timestamp,
            "!timing"
        );
        // Set timestamps
        startTime_heroes = _startTime_heroes;
        startTime_arcade = _startTime_arcade;
        startTime_rebels = _startTime_rebels;

        emit NewStartTimes(_startTime_heroes, _startTime_arcade, _startTime_rebels);
    }

    // ----- View Functions -----

    /**
     * @notice  Get the Merkle root of the active phase
     * @return  Merkle root of the active phase, 0 if none active
     */
    function getActiveRoot() public view returns (bytes32) {
        uint256 phase = getActivePhase();
        if (phase == 1) {
            return merkleRoot_heroes;
        } else if (phase == 2) {
            return merkleRoot_arcade;
        } else if (phase == 3) {
            return merkleRoot_rebels;
        } else {
            return 0;
        }
    }

    /**
     * @notice  Get the ID the active phase
     * @return  1 for Heroes, 2 for Arcade, 3 for Rebels, 0 for no active phase
     */
    function getActivePhase() public view returns (uint256) {
        if (block.timestamp >= startTime_heroes && block.timestamp < startTime_arcade) {
            return 1;
        } else if (block.timestamp >= startTime_arcade && block.timestamp < startTime_rebels) {
            return 2;
        } else if (block.timestamp >= startTime_rebels) {
            return 3;
        } else {
            return 0;
        }
    }

    // ----- Overrides -----

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        unchecked {
            --totalSupply;
        }
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);
        unchecked {
            ++totalSupply;
        }
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return interfaceId == type(ERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // ----- Events -----

    event Withdrawal(uint256 balance);
    event SupplyLocked(uint256 finalMaxSupply);
    event NewRoyalty(uint96 newRoyalty);
    event NewURI(string oldURI, string newURI);
    event NewRoot(uint256 indexed phase, bytes32 oldRoot, bytes32 newRoot);
    event NewMaxSupply(uint256 oldMax, uint256 newMax);
    event NewMaxPerWallet(uint256 oldMax, uint256 newMax);
    event NewMintPrice(uint256 oldPrice, uint256 newPrice);
    event NewStartTimes(uint128 startTime_heroes, uint128 startTime_arcade, uint128 startTime_rebels);
}