// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ITheAmazingTozziDuckMachine {
    error AmountMustBeNonZero();
    error ProbationEnded();
    error CustomDuckLimitReached();
    error DuckAlreadyExists();
    error IncorrectDuckPrice();
    error InsufficientDuckAllowance();
    error InsufficientFunds();
    error InvalidDuckId();
    error InvalidProof();
    error InvalidStatusId();
    error MintingDisabled();
    error Unauthorized();

    enum DuckType {
        Tozzi,
        Custom
    }

    enum MintStatus {
        Enabled,
        Disabled,
        Allow
    }

    struct DuckAllowance {
        uint128 tozziDuckAllowance;
        uint128 customDuckAllowance;
    }
    
    struct DuckProfile {
        bytes32 name;
        bytes32 status;
        string description;
    }
    
    struct MachineConfig {
        uint256 tozziDuckPrice;
        uint256 customDuckPrice;
        uint256 maxCustomDucks;
        MintStatus tozziDuckMintStatus;
        MintStatus customDuckMintStatus;
    }    

    event CustomDuckBurned(
        uint256 indexed duckId,
        address indexed duckOwner,
        address machineOwner,        
        string webp,
        string reason
    );

    event DuckMinted(
        uint256 indexed tokenId,
        bytes32 indexed webpHash,
        address indexed creator,
        address recipient,
        DuckType duckType,    
        uint256 price
    );

    event DuckProfileUpdated(
        uint256 indexed duckId,
        bytes32 indexed name,
        bytes32 indexed status,
        string description
    );

    event DuckTitleGranted(
        uint256 indexed tokenId,
        bytes32 indexed title,
        address indexed owner
    );

    event MachineConfigUpdated(
        address indexed who,
        uint256 tozziDuckPrice,
        uint256 customDuckPrice,
        uint256 maxCustomDucks,
        MintStatus tozziDuckMintStatus,
        MintStatus customDuckMintStatus
    );

    event MOTDSet(address indexed owner, string message);

    function burnRenegadeDuck(uint256 tokenId, string calldata reason) external;
    function endProbation(uint256 tokenId) external;
    function mintCustomDuck(address to, string calldata webp) external payable;
    function mintTozziDuck(address to, uint256 duckId, string calldata webp, bytes32[] calldata merkleProof) external payable;
    function ownerMint(address to, string calldata webp) external;
    function setArtistName(uint256 tokenId, bytes32 name) external;
    function setDuckAllowance(address who, DuckAllowance calldata allowance) external;
    function setDuckAllowances(address[] calldata who, DuckAllowance calldata allowance) external;
    function setDuckProfile(uint256 tokenId, bytes32 name, bytes32 status, string calldata description) external;    
    function setDuckTitle(uint256 tokenId, bytes32 title) external;
    function setMOTD(string calldata motd) external;
    function setMachineConfig(MachineConfig calldata _machineConfig) external;
    function setOwnershipTokenURI(string calldata ownershipTokenUri) external;
    function withdraw(address recipient, uint256 amount) external;
}