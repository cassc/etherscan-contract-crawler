// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { CometDrop } from "../extensions/CometDrop.sol";

interface ERC721 {
    function balanceOf(address _owner) external view returns (uint256);
}

interface RandomNumberGenerator {
    function requestRandomWords(
        address partnerContract,
        uint32 totalEntries,
        uint32 totalSelections,
        string calldata title
    ) external;

    function getSender() external view returns (address);
}

contract SurvivorSeries2 is CometDrop, ReentrancyGuard {
    /**
     * @notice A struct defining the token receiver.
     *
     * @param to The address to receive the token.
     * @param tokenId The token ID.
     */
    struct TokenReceiver {
        address to;
        uint256 tokenId;
    }

    struct PhaseConfig {
        uint256 phaseIndex;
        uint256 minQuantity;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool isPublic;
    }

    /// @notice The Crossmint admin for credit card processing.
    address private _crossmintAdmin;

    /// @notice The VRF admin for VRF.
    address private _vrfAdmin;

    /// @notice The partner contract address.
    address private _vrfCoordinatorAddress;

    /// @notice If we want to override the current phase index.
    uint256 private _currentPhaseOverride;

    /// @notice the available phase indexes.
    uint256[] private _phaseArray;

    /// @notice The partner contract.
    ERC721 private _partnerContract;

    /// @notice The random number generator contract.
    RandomNumberGenerator private _randomNumberGenerator;

    mapping(uint256 => PhaseConfig) private _phases;

    event CrossmintAdministratorUpdated(address wallet);
    event PartnerContractUpdated(address contractAddress);
    event VRFAdministratorUpdated(address newWallet);
    event VRFCoordinatorUpdated(address contractAddress);

    error NewAdministratorIsZeroAddress();
    error OnlyCrossmintAdministrator();
    error AccessMintNotAllowed(uint256 balance, uint256 required);
    error PublicSaleNotActive();
    error SaleNotActive();

    modifier onlyCrossmintAdministrator() virtual {
        if (msg.sender != _crossmintAdmin) {
            revert OnlyCrossmintAdministrator();
        }
        _;
    }

    modifier onlyOwnerOrVRFAdministrator() virtual {
        if (msg.sender != owner()) {
            if (msg.sender != _vrfAdmin) {
                revert OnlyOwnerOrAdministrator();
            }
        }
        _;
    }

    /**
     * @notice SurvivorSeries2 constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     * @param maxSupply The max supply of the token.
     * @param baseTokenURI The base token URI.
     * @param contractURI The contract URI.
     * @param royalties The royalties wallet.
     * @param crossmintAdmin The Crossmint admin wallet.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory baseTokenURI,
        string memory contractURI,
        address royalties,
        address crossmintAdmin
    ) CometDrop(name, symbol) {
        // Initial maxSupply
        _maxSupply = maxSupply;

        // Initial token base URI
        _baseTokenURI = baseTokenURI;

        // Initial contract URI
        _contractURI = contractURI;

        // Initial royalties wallet
        _royalties = royalties;

        // Initial beneficiary wallet
        _beneficiary = royalties;

        // Initial Crossmint admin wallet
        _crossmintAdmin = crossmintAdmin;
    }

    /**
     * @notice Set the partner contract address.
     *
     * @param contractAddress The address of the contract.
     */
    function setPartnerContractAddress(
        address contractAddress
    ) external onlyOwner {
        _partnerContract = ERC721(contractAddress);

        emit PartnerContractUpdated(contractAddress);
    }

    /**
     * @notice Set the partner contract address.
     *
     * @param contractAddress The address of the contract.
     */
    function setVRFCoordinatorAddress(
        address contractAddress
    ) external onlyOwner {
        _vrfCoordinatorAddress = contractAddress;
        _randomNumberGenerator = RandomNumberGenerator(contractAddress);

        emit VRFCoordinatorUpdated(contractAddress);
    }

    /**
     * @notice Set the Crossmint administrator.
     *
     * @param newCrossmintAdministrator The address of the administrator.
     */
    function setCrossmintAdministrator(
        address newCrossmintAdministrator
    ) external onlyOwner {
        _crossmintAdmin = newCrossmintAdministrator;

        emit CrossmintAdministratorUpdated(newCrossmintAdministrator);
    }

    /**
     * @notice Set the VRF administrator.
     *
     * @param newWallet The address of the administrator.
     */
    function setVRFAdministrator(address newWallet) external onlyOwner {
        _vrfAdmin = newWallet;

        emit VRFAdministratorUpdated(newWallet);
    }

    function requestRandomWords(
        address partnerContract,
        uint32 totalEntries,
        uint32 totalSelections,
        string calldata title
    ) external onlyOwnerOrVRFAdministrator {
        _randomNumberGenerator.requestRandomWords(
            partnerContract,
            totalEntries,
            totalSelections,
            title
        );
    }

    function setPhases(
        PhaseConfig[] memory phaseConfigs
    ) external onlyOwnerOrAdministrator {
        uint256[] memory tempPhaseArray = new uint256[](phaseConfigs.length);

        for (uint256 i = 0; i < phaseConfigs.length; i++) {
            PhaseConfig memory config = phaseConfigs[i];

            _phases[config.phaseIndex] = config;
            tempPhaseArray[i] = config.phaseIndex;
        }

        _phaseArray = tempPhaseArray;
    }

    /**
     * @notice Update phase config.
     *
     * @param config Update a single phase.
     */
    function updatePhase(
        PhaseConfig memory config
    ) external onlyOwnerOrAdministrator {
        _phases[config.phaseIndex] = config;
    }

    /**
     * @notice Get the sender's balance of the access contract.
     *
     * @return uint256 The number of owned tokens.
     */
    function getPartnerBalance() public view returns (uint256) {
        address sender = _msgSender();

        return _partnerContract.balanceOf(sender);
    }

    /**
     * @notice Get the current phase of the contract.
     *
     * @return PhaseConfig The phase config.
     */
    function getCurrentPhase() public view returns (PhaseConfig memory) {
        for (uint256 i = 0; i < _phaseArray.length; i++) {
            PhaseConfig memory config = _phases[i + 1];

            if (
                block.timestamp >= config.startTime &&
                block.timestamp < config.endTime
            ) {
                return config;
            }
        }

        // Default phase if none active
        return PhaseConfig(0, 1, 0, 0, 0, false);
    }

    /**
     * @notice Get all phases in the config.
     *
     * @return PhaseConfig[] The phases.
     */
    function getPhases() public view returns (PhaseConfig[] memory) {
        uint256[] memory arr = _phaseArray;
        uint256 n = arr.length;
        uint256 temp;
        PhaseConfig[] memory configs = new PhaseConfig[](n);

        // sort the array by phase index
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }

        for (uint256 i = 0; i < n; i++) {
            configs[i] = _phases[arr[i]];
        }

        return configs;
    }

    /**
     * @notice Mint if user holds access pass.
     *
     * @param quantity The quantity to mint.
     */
    function mintAccessPass(uint256 quantity) external payable nonReentrant {
        address sender = _msgSender();

        // Check the ERC721 balance of the sender in the partner contract
        uint256 partnerBalance = _partnerContract.balanceOf(sender);

        PhaseConfig memory config = getCurrentPhase();

        if (config.phaseIndex == 0) {
            revert SaleNotActive();
        }

        if (partnerBalance < config.minQuantity) {
            revert AccessMintNotAllowed(partnerBalance, config.minQuantity);
        }

        // Run checks and mint the tokens
        _checkAndMint(quantity, config.price, sender, msg.value);

        // Emit event on successful mint
        emit AccessMint(sender, address(_partnerContract), quantity, msg.value);
    }

    /**
     * @notice Mint public if sale is active.
     *
     * @param quantity The quantity to mint.
     */
    function mint(uint256 quantity) external payable nonReentrant {
        address sender = _msgSender();
        PhaseConfig memory config = getCurrentPhase();

        if (config.phaseIndex == 0) {
            revert SaleNotActive();
        }

        if (!config.isPublic) {
            revert PublicSaleNotActive();
        }

        // Run checks and mint the tokens
        _checkAndMint(quantity, config.price, sender, msg.value);

        // Emit event on successful mint
        emit PublicMint(sender, quantity, msg.value);
    }

    /**
     * @notice Mint to address through Crossmint proxy. This function handles
     *         both access pass and public mints
     *
     * @param quantity The quantity to mint.
     * @param to The address to mint to.
     */
    function mintTo(
        uint256 quantity,
        address to
    ) external payable nonReentrant onlyCrossmintAdministrator {
        address sender = to;

        // Check the ERC721 balance of the sender in the partner contract
        uint256 partnerBalance = _partnerContract.balanceOf(sender);

        PhaseConfig memory config = getCurrentPhase();

        if (config.phaseIndex == 0) {
            revert SaleNotActive();
        }

        if (partnerBalance < config.minQuantity) {
            revert AccessMintNotAllowed(partnerBalance, config.minQuantity);
        }

        // Run checks and mint the tokens
        _checkAndMint(quantity, config.price, sender, msg.value);

        // Emit event on successful mint
        if (config.isPublic) {
            emit PublicMint(to, quantity, msg.value);
        } else {
            emit AccessMint(to, address(_partnerContract), quantity, msg.value);
        }
    }
}