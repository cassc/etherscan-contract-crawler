// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

interface IERC721 {
    function mint(address user, uint256 quantity) external;
}

contract Sale is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // Tokens available for mint
    uint256 public maxPhase1MintLimit;
    uint256 public maxPhase2MintLimit;
    uint256 public maxSupply;

    // Minting start block and duration
    uint256 public phaseOneStartBlock;
    uint256 public phaseTwoStartBlock;
    uint256 public phaseThreeStartBlock;
    uint256 public phaseOneDuration;
    uint256 public phaseTwoDuration;
    uint256 public phaseThreeDuration;

    // Mint price
    uint256 public phaseOnePrice;
    uint256 public phaseTwoPrice;
    uint256 public phaseThreePrice;

    // Keep track of tokens minted
    uint256 public totalMinted;
    uint256 public phaseOneMinted;
    uint256 public phaseTwoMinted;
    uint256 public phaseThreeMinted;

    bytes32 private merkleRootPhaseOne;
    bytes32 private merkleRootPhaseTwo;

    address public nftAddres;

    mapping(address => uint256) public userMinted;
    mapping(address => uint256) public userPhase1Minted;
    mapping(address => uint256) public userPhase2Minted;

    // Events emitted.
    event Minted(
        address indexed _user,
        uint256 indexed _phase,
        uint256 _quantity
    );
    event UpdateSalePrice(
        uint256 _phaseOnePrice,
        uint256 _phaseTwoPrice,
        uint256 _phaseThreePrice
    );
    event UpdateMerkleProofRoot(
        bytes32 _merkleRootPhaseOne,
        bytes32 _merkleRootPhaseTwo
    );
    event UpdateSaleSupply(
        uint256 _maxPhase1MintLimit,
        uint256 _maxPhase2MintLimit,
        uint256 _maxSupply
    );
    event UpdateSaleTime(
        uint256 _phaseOneStartBlock,
        uint256 _phaseTwoStartBlock,
        uint256 _phaseThreeStartBlock,
        uint256 _phaseOneDuration,
        uint256 _phaseTwoDuration,
        uint256 _phaseThreeDuration
    );

    // Validate if user is eligible for phase one purchase.
    modifier validatPhaseOnePurchase(uint256 amount, bytes32[] calldata proof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            block.number >= phaseOneStartBlock &&
                block.number < (phaseOneStartBlock + phaseOneDuration),
            "Sale not open"
        );
        require(
            MerkleProofUpgradeable.verify(proof, merkleRootPhaseOne, leaf),
            "Not whitelisted"
        );
        require(msg.value == amount * phaseOnePrice, "Invalid ether amount");
        require(totalMinted + amount <= maxSupply, "Sale completed");
        require(
            userPhase1Minted[msg.sender] + amount <= maxPhase1MintLimit,
            "Minting limit"
        );
        _;
    }

    // Validate if user is eligible for phase two purchase.
    modifier validatPhaseTwoPurchase(uint256 amount, bytes32[] calldata proof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            block.number >= phaseTwoStartBlock &&
                block.number < (phaseTwoStartBlock + phaseTwoDuration),
            "Sale not open"
        );
        require(
            MerkleProofUpgradeable.verify(proof, merkleRootPhaseTwo, leaf),
            "Not whitelisted"
        );
        require(msg.value == amount * phaseTwoPrice, "Invalid ether amount");
        require(totalMinted + amount <= maxSupply, "Sale completed");
        require(
            userPhase2Minted[msg.sender] + amount <= maxPhase2MintLimit,
            "Minting limit"
        );
        _;
    }

    // Validate if user is eligible for phase three purchase.
    modifier validatPhaseThreePurchase(uint256 amount) {
        require(
            block.number >= phaseThreeStartBlock &&
                block.number < (phaseThreeStartBlock + phaseThreeDuration),
            "Sale not open"
        );
        require(totalMinted + amount <= maxSupply, "Sale completed");
        require(msg.value == amount * phaseThreePrice, "Invalid ether amount");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize function use in place of constructor function.
     */
    function initialize(address _nftAddres) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        require(_nftAddres != address(0), "initialize: zero address");
        nftAddres = _nftAddres;
    }

    /**
     * @notice Pause Contract
     *
     * @dev Only owner can call this function.
     */

    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Un-pause Contract
     *
     * @dev Only owner can call this function.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Update Merkleproof Root.
     *
     * @dev Update merkleproof root for whitelisted and waitlist sale. Only owner can call this function.
     * @param _merkleRootPhaseOne Merkle proof root phase one.
     * @param _merkleRootPhaseTwo Merkle proof root phase two.
     */
    function updateMerkleProofRoot(
        bytes32 _merkleRootPhaseOne,
        bytes32 _merkleRootPhaseTwo
    ) external onlyOwner {
        merkleRootPhaseOne = _merkleRootPhaseOne;
        merkleRootPhaseTwo = _merkleRootPhaseTwo;
        emit UpdateMerkleProofRoot(_merkleRootPhaseOne, _merkleRootPhaseTwo);
    }

    /**
     * @notice Update NFT sale time.
     *
     * @dev Update sale start block and duration. Only owner can call this function.
     * @param _phaseOneStartBlock Start block for phase one.
     * @param _phaseTwoStartBlock Start block for phase two.
     * @param _phaseThreeStartBlock Start block for phase three.
     * @param _phaseOneDuration Duration of phase one sale in blocks.
     * @param _phaseTwoDuration Duration of phase two sale in blocks.
     * @param _phaseThreeDuration Duration of phase three sale in blocks.
     */
    function updateSaleTime(
        uint256 _phaseOneStartBlock,
        uint256 _phaseTwoStartBlock,
        uint256 _phaseThreeStartBlock,
        uint256 _phaseOneDuration,
        uint256 _phaseTwoDuration,
        uint256 _phaseThreeDuration
    ) external onlyOwner {
        phaseOneStartBlock = _phaseOneStartBlock;
        phaseTwoStartBlock = _phaseTwoStartBlock;
        phaseThreeStartBlock = _phaseThreeStartBlock;
        phaseOneDuration = _phaseOneDuration;
        phaseTwoDuration = _phaseTwoDuration;
        phaseThreeDuration = _phaseThreeDuration;
        emit UpdateSaleTime(
            _phaseOneStartBlock,
            _phaseTwoStartBlock,
            _phaseThreeStartBlock,
            _phaseOneDuration,
            _phaseTwoDuration,
            _phaseThreeDuration
        );
    }

    /**
     * @notice Update NFT sale price.
     *
     * @dev Update price for each sale phase. Only owner can call this function.
     * @param _phaseOnePrice Price of phase one sale in wei.
     * @param _phaseTwoPrice Price of phase two sale in wei.
     * @param _phaseThreePrice Price of phase three sale in wei.
     */
    function updateSalePrice(
        uint256 _phaseOnePrice,
        uint256 _phaseTwoPrice,
        uint256 _phaseThreePrice
    ) external onlyOwner {
        phaseOnePrice = _phaseOnePrice;
        phaseTwoPrice = _phaseTwoPrice;
        phaseThreePrice = _phaseThreePrice;
        emit UpdateSalePrice(_phaseOnePrice, _phaseTwoPrice, _phaseThreePrice);
    }

    /**
     * @notice Update NFT supply.
     *
     * @dev Update supply for each sale phase. Only owner can call this function.
     * @param _maxPhase1MintLimit Max supply for user mint in phase1.
     * @param _maxPhase2MintLimit Max supply for user mint in phase2.
     * @param _maxSupply Max supply for user.
     */
    function updateSaleSupply(
        uint256 _maxPhase1MintLimit,
        uint256 _maxPhase2MintLimit,
        uint256 _maxSupply
    ) external onlyOwner {
        maxPhase1MintLimit = _maxPhase1MintLimit;
        maxPhase2MintLimit = _maxPhase2MintLimit;
        maxSupply = _maxSupply;
        emit UpdateSaleSupply(
            _maxPhase1MintLimit,
            _maxPhase2MintLimit,
            _maxSupply
        );
    }

    /**
     * @dev Get active minting phase.
     */
    function getActivePhase() external view returns (uint8) {
        if (
            block.number >= phaseOneStartBlock &&
            block.number < (phaseOneStartBlock + phaseOneDuration)
        ) {
            return 1;
        } else if (
            block.number >= phaseTwoStartBlock &&
            block.number < (phaseTwoStartBlock + phaseTwoDuration)
        ) {
            return 2;
        } else if (
            (block.number >= phaseThreeStartBlock &&
                block.number < (phaseThreeStartBlock + phaseThreeDuration))
        ) {
            return 3;
        } else {
            return 0;
        }
    }

    /**
     * Whiteisted mint
     * @dev Whitelisted minting of token by paying price. A new token will be minted by calling mint function of NFT contract.
     * @param quantity Number of tokens to mint.
     */
    function mintWhitelisted(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        whenNotPaused
        validatPhaseOnePurchase(quantity, proof)
    {
        phaseOneMinted = phaseOneMinted + quantity;
        userPhase1Minted[msg.sender] = userPhase1Minted[msg.sender] + quantity;
        mint(quantity);
        emit Minted(msg.sender, 1, quantity);
    }

    /**
     * Waitlist mint
     * @dev Waitlist minting of token by paying price. A new token will be minted by calling mint function of NFT contract.
     * @param quantity Number of tokens to mint.
     */
    function mintWaitlist(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        whenNotPaused
        validatPhaseTwoPurchase(quantity, proof)
    {
        phaseTwoMinted = phaseTwoMinted + quantity;
        userPhase2Minted[msg.sender] = userPhase2Minted[msg.sender] + quantity;
        mint(quantity);
        emit Minted(msg.sender, 2, quantity);
    }

    /**
     * Public Sale
     * @dev Public  Minting token by paying price. A new token will be minted by calling mint function of NFT contract.
     * @param quantity Number of tokens to mint.
     */
    function mintPublicSale(uint256 quantity)
        external
        payable
        whenNotPaused
        validatPhaseThreePurchase(quantity)
    {
        phaseThreeMinted = phaseThreeMinted + quantity;
        mint(quantity);
        emit Minted(msg.sender, 3, quantity);
    }

    /**
     * @dev Mint token by paying price. A new token will be minted by calling mint function of NFT contract.
     * @param quantity Number of tokens to mint.
     */
    function mint(uint256 quantity) internal {
        userMinted[msg.sender] = userMinted[msg.sender] + quantity;
        totalMinted = totalMinted + quantity;
        IERC721(nftAddres).mint(msg.sender, quantity);
    }

    /**
     * @notice Withdraw Funds
     *
     * @dev Withdraw collected funds. Only owner can call this function.
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Authorize upgradation of token. Transaction will be reverted if non owner tries to upgrade.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}