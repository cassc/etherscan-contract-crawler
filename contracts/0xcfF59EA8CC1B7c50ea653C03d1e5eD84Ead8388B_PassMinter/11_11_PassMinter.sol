//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * >>> Join the Resistance <<<
 * >>>   https://nfa.gg/   <<<
 * @title   NonFungibleArcade Arcade Pass Minter
 * @author  BowTiedPickle
 */
contract PassMinter is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// @notice Next token ID to be sold
    uint256 public nextId;

    /// @notice Amount minted per address per phase
    mapping(address => mapping(uint256 => uint256)) public claimed;

    uint256 public mintPrice = 250e6;
    uint256 public maxSupply;

    uint128 public startTime_heroes;
    uint128 public startTime_arcade;
    uint128 public startTime_partners;
    uint128 public startTime_rebels;

    bytes32 public merkleRoot_heroes;
    bytes32 public merkleRoot_arcade;
    bytes32 public merkleRoot_partners;
    bytes32 public merkleRoot_rebels;

    IERC20 public immutable USDC;
    IERC721 public immutable pass;

    /// @notice Total number of tokens sold
    uint256 public totalSold;

    /**
     * @param   _pass                   Arcade Pass contract address
     * @param   _owner                  Owner address
     * @param   _merkleRoot_heroes      Merkle root for Heroes phase
     * @param   _merkleRoot_arcade      Merkle root for Arcade phase
     * @param   _merkleRoot_partners    Merkle root for Partners phase
     * @param   _merkleRoot_rebels      Merkle root for Rebels phase
     * @param   _USDC                   Address of the USDC token proxy
     * @param   _startTime_heroes       Start time for Heroes phase
     * @param   _startTime_arcade       Start time for Arcade phase
     * @param   _startTime_partners     Start time for Partners phase
     * @param   _startTime_rebels       Start time for Rebels phase
     */
    constructor(
        IERC721 _pass,
        address _owner,
        bytes32 _merkleRoot_heroes,
        bytes32 _merkleRoot_arcade,
        bytes32 _merkleRoot_partners,
        bytes32 _merkleRoot_rebels,
        address _USDC,
        uint128 _startTime_heroes,
        uint128 _startTime_arcade,
        uint128 _startTime_partners,
        uint128 _startTime_rebels
    ) {
        require(_owner != address(0), "!addr");

        _transferOwnership(_owner);

        // Set the merkle roots
        merkleRoot_heroes = _merkleRoot_heroes;
        merkleRoot_arcade = _merkleRoot_arcade;
        merkleRoot_partners = _merkleRoot_partners;
        merkleRoot_rebels = _merkleRoot_rebels;

        // Set timestamps
        startTime_heroes = _startTime_heroes;
        startTime_arcade = _startTime_arcade;
        startTime_partners = _startTime_partners;
        startTime_rebels = _startTime_rebels;

        // Set the contract deployments
        USDC = IERC20(_USDC);
        pass = _pass;

        // Deploy in paused state
        _pause();
    }

    /**
     * @notice  Mint arcade passes
     * @dev     User must have approved this contract for the required value of USDC already
     * @param   _qty            Quantity to mint
     * @param   _whitelistQty   Quantity user is whitelisted for
     * @param   _proof          Merkle whitelist proof
     */
    function mint(
        uint256 _qty,
        uint256 _whitelistQty,
        bytes32[] calldata _proof
    ) external whenNotPaused {
        require(_qty > 0, "!zero");
        uint256 phase = getActivePhase();
        require(claimed[msg.sender][phase] + _qty <= _whitelistQty, "User max");
        require(totalSold + _qty <= maxSupply, "Max supply");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _whitelistQty));
        bytes32 root = getActiveRoot();
        require(root != 0, "!phase");
        require(MerkleProof.verify(_proof, root, leaf), "!proof");

        claimed[msg.sender][phase] += _qty;
        totalSold += _qty;

        USDC.safeTransferFrom(msg.sender, address(this), mintPrice * _qty);

        // Transfer out
        uint256 tokenId;
        for (uint256 i; i < _qty; ) {
            tokenId = nextId;
            unchecked {
                ++i;
                ++nextId;
            }
            pass.transferFrom(address(this), msg.sender, tokenId);
        }

        emit Mint(msg.sender, _qty);
    }

    // ----- Admin Functions -----

    /**
     * @notice  Set critical sale parameters
     * @dev     This is permissive to be flexible, use caution
     * @param   _startingTokenId    Token ID to start from
     * @param   _maxSupply          Total maximum supply
     */
    function notify(uint256 _startingTokenId, uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > totalSold, "!param");
        emit NewMaxSupply(maxSupply, _maxSupply);
        nextId = _startingTokenId;
        maxSupply = _maxSupply;
    }

    /**
     * @notice  Permissioned mint function
     * @dev     Respects max supply
     * @param   _to     Recipient address
     * @param   _qty    Quantity to mint
     */
    function adminMint(address _to, uint256 _qty) external onlyOwner {
        require(_qty > 0, "!zero");
        require(totalSold + _qty <= maxSupply, "Max supply");
        totalSold += _qty;

        uint256 tokenId;
        for (uint256 i; i < _qty; ) {
            tokenId = nextId;
            unchecked {
                ++i;
                ++nextId;
            }
            pass.transferFrom(address(this), _to, tokenId);
        }

        emit Mint(_to, _qty);
    }

    /**
     * @notice  Withdraw profits from the contract
     */
    function withdraw() external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        USDC.safeTransfer(msg.sender, balance);
        emit Withdrawal(balance);
    }

    /**
     * @notice  Set a new merkle root
     * @param   _newRoot    New whitelist merkle root
     */
    function setMerkleRoot(bytes32 _newRoot, uint256 _phase) external onlyOwner {
        require(_phase > 0 && _phase <= 4, "!param");
        if (_phase == 1) {
            emit NewRoot(1, merkleRoot_heroes, _newRoot);
            merkleRoot_heroes = _newRoot;
        } else if (_phase == 2) {
            emit NewRoot(2, merkleRoot_arcade, _newRoot);
            merkleRoot_arcade = _newRoot;
        } else if (_phase == 3) {
            emit NewRoot(3, merkleRoot_partners, _newRoot);
            merkleRoot_partners = _newRoot;
        } else if (_phase == 4) {
            emit NewRoot(4, merkleRoot_rebels, _newRoot);
            merkleRoot_rebels = _newRoot;
        }
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
        uint128 _startTime_partners,
        uint128 _startTime_rebels
    ) external onlyOwner {
        require(
            _startTime_rebels >= _startTime_partners &&
                _startTime_partners >= _startTime_arcade &&
                _startTime_arcade >= _startTime_heroes &&
                _startTime_heroes >= block.timestamp,
            "!timing"
        );
        // Set timestamps
        startTime_heroes = _startTime_heroes;
        startTime_arcade = _startTime_arcade;
        startTime_partners = _startTime_partners;
        startTime_rebels = _startTime_rebels;

        emit NewStartTimes(_startTime_heroes, _startTime_arcade, _startTime_partners, _startTime_rebels);
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
            return merkleRoot_partners;
        } else if (phase == 4) {
            return merkleRoot_rebels;
        } else {
            return 0;
        }
    }

    /**
     * @notice  Get the ID of the active phase
     * @return  1 for Heroes, 2 for Arcade, 3 for Partner, 4 for Rebels, 0 for no active phase
     */
    function getActivePhase() public view returns (uint256) {
        if (block.timestamp >= startTime_heroes && block.timestamp < startTime_arcade) {
            return 1;
        } else if (block.timestamp >= startTime_arcade && block.timestamp < startTime_partners) {
            return 2;
        } else if (block.timestamp >= startTime_partners && block.timestamp < startTime_rebels) {
            return 3;
        } else if (block.timestamp >= startTime_rebels) {
            return 4;
        } else {
            return 0;
        }
    }

    // ----- Events -----

    event Mint(address indexed user, uint256 quantity);

    event Withdrawal(uint256 balance);
    event NewRoot(uint256 indexed phase, bytes32 oldRoot, bytes32 newRoot);
    event NewMaxSupply(uint256 oldMax, uint256 newMax);
    event NewMintPrice(uint256 oldPrice, uint256 newPrice);
    event NewStartTimes(uint128 startTime_heroes, uint128 startTime_arcade, uint128 startTime_partners, uint128 startTime_rebels);
}