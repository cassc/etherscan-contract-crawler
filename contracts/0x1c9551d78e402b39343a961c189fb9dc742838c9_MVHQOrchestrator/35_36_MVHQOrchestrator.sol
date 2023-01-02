// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IMVHQOrchestrator} from "./IMVHQOrchestrator.sol";
import {IMVHQ} from "./IMVHQ.sol";
import {MVHQSBT} from "./MVHQSBT.sol";
import {IERC5192}  from "./IERC5192.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

/// @title MVHQ Orchestrator Minting Proccess
/// @author Kfish n Chips
/// @notice
/// @dev
/// @custom:security-contact [email protected]
contract MVHQOrchestrator is Initializable, UUPSUpgradeable, IMVHQOrchestrator, AccessControlUpgradeable {

    /// Stage 0: Initial State
    /// Stage 1: Whale Mint
    /// Stage 2: Member Mint
    /// Stage 3: Public Allowlist Mint
    enum Stages {
        STAGE0,
        STAGE1,
        STAGE2,
        STAGE3
    }

    /// @notice price for stage
    mapping (Stages => uint256) public prices;
    /// @notice Tracking mints for a season
    mapping (address => mapping(uint256 => bool)) private seasonMinters;
    /// @notice Stage of process
    Stages public stage;
    /// @notice Upgrade role
    bytes32 public constant UPGRADER_ROLE = bytes32("UPGRADER_ROLE");
    /// @notice MVHQ contract
    IMVHQ public constant MVHQ = IMVHQ(0x2809a8737477A534DF65C4b4cAe43d0365E52035);
    uint256 public constant INITIAL_SEASON = 2023;
    /// @notice MVHQ SBT contract
    MVHQSBT public mvhqSBT;
    /// @notice MVHQ Treasury
    address public treasury;
    /// @notice The merkle root for the allowlist
    bytes32 public allowlistMerkleRoot;
    /// @notice Current season
    uint256 public season;

    /// @notice Validates that all conditions of a state are met
    /// @dev for STAGE1 the amount must be divide by Whale requimiment
    /// @param stageToCheck Stage to validate
    /// @param amount of token to mint and/or burn
    modifier stageValidation(Stages stageToCheck, uint256 amount) {
        if (stage != stageToCheck) revert InvalidStage();
        if (stageToCheck == Stages.STAGE1) {
            if ((amount % MVHQ.whaleRequirement()) != 0) revert InvalidTokensAmount();
            amount = amount / MVHQ.whaleRequirement();
        }
        if (msg.value != amount * prices[stage]) revert InvalidEtherAmount();
        _;
    }

    /// @notice Set de SBT MVHQ contract
    /// @dev check that contract implement IERC5192 interface
    /// @param contractSBT the new contract
    function setMVHQSBT(address contractSBT) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(!IERC165(contractSBT).supportsInterface(0xb45a3c0e)) revert NotERC5192();
        mvhqSBT = MVHQSBT(contractSBT);
    }

    /// @notice Set the MVHQ Treasury
    /// @dev reverts if address is zero
    /// @param newTreasury the new treasury address
    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(newTreasury == address(0)) revert TreasuryZeroAddress();
        treasury = newTreasury;
    }

    /// @notice Update the allowlist merkle root
    /// @dev Only callable by contract owner
    /// @param merkleRoot the new merkle root
    function setAllowlistRoot(bytes32 merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowlistMerkleRoot = merkleRoot;
    }

    function airdrop(address[] calldata recipients, bool whales) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(recipients.length < 1) revert NoRecipients();
        for (uint256 i = 0; i < recipients.length; i++) {
            mvhqSBT.safeMint(recipients[i], whales);
        }
    }

    /// @notice Burn and Mint SBT for Whales
    /// @dev tokenIds must be a multiple of MVHQ.whaleRequirement
    /// @param tokenIds to burn
    function whaleMint(uint256[] memory tokenIds)
        external payable
        stageValidation(Stages.STAGE1, tokenIds.length)
    {
        MVHQ.burnBatch(msg.sender, tokenIds);
        uint256 whaleSBTtoMint =  tokenIds.length / MVHQ.whaleRequirement();
        for (uint256 i = 0; i < whaleSBTtoMint; i++) {
            mvhqSBT.safeMint(msg.sender, true);
        }
    }

    /// @notice Burn and Mint SBT for Members
    /// @dev tokenIds must be a multiple of MVHQ.whaleRequirement
    /// @param tokenIds to burn
    function memberMint(uint256[] memory tokenIds)
        external payable
        stageValidation(Stages.STAGE2, tokenIds.length)
    {
        MVHQ.burnBatch(msg.sender, tokenIds);
        uint256 memberSBTtoMint =  tokenIds.length;
        for (uint256 i = 0; i < memberSBTtoMint; i++) {
            mvhqSBT.safeMint( msg.sender, false);
        }
    }

    /// @notice Allowlist Mint
    function mint(bytes32[] calldata _merkleProof)
        external payable
        stageValidation(Stages.STAGE3, 1)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if(!MerkleProofUpgradeable.verify(_merkleProof, allowlistMerkleRoot, leaf)) {
            revert NotInAllowlist();
        }
        if(seasonMinters[msg.sender][season]) {
            revert AlreadyMinted();
        }
        seasonMinters[msg.sender][season] = true;
        MVHQ.mint(msg.sender);
    }

    /// @notice Withdraw function
    function withdrawToTreasury() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        if(treasury == address(0)) revert TreasuryZeroAddress();
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(treasury).call{value: address(this).balance}("");
        if(!success) revert WithdrawFailed();
    }

    /// @notice Set the Stage´s Price
    /// @dev has to be in Stages
    /// @param stageToPrice the Stage to set the price
    /// @param price the price to set
    function setPrice(uint256 stageToPrice, uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (stageToPrice > uint256(Stages.STAGE3)) revert InvalidStage();
        prices[Stages(stageToPrice)] = price;
    }

    /// @notice Set the current season
    /// @dev cannot be lower than the initial season
    function setSeason(uint256 newSeason) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(newSeason < INITIAL_SEASON) revert InvalidSeason();
        season = newSeason;
    }

    /// @notice Set the Stage
    /// @dev has to be in Stages
    /// @param nextStage the new Stage
    function setStage(uint256 nextStage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (nextStage > uint256(Stages.STAGE3)) revert InvalidStage();
        stage = Stages(nextStage);
    }

    function initialize(address sbtContract) public initializer {
        __AccessControl_init_unchained();
        if(!IERC165(sbtContract).supportsInterface(0xb45a3c0e)) revert NotERC5192();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        stage = Stages.STAGE0;
        season = INITIAL_SEASON;
        mvhqSBT = MVHQSBT(sbtContract);
        prices[Stages.STAGE2] = 0.4 ether;
        prices[Stages.STAGE3] = 0.8 ether;
        treasury = 0xe44aFEF0b0a4b02BAdF6023c57950476ca075A3D;
    }

    /// @notice The Stage
    /// @return Stages the actual stage
    function getStage() public view returns (Stages) {
        return stage;
    }

    /// @notice UUPSUpgradeable auth override
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {} // solhint-disable-line
}