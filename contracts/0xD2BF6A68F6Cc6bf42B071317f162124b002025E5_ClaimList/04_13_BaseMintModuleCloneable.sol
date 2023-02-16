//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../../interfaces/modules/minting/IBaseMintingModuleCloneable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract BaseMintModuleCloneable is Initializable, AccessControlUpgradeable, IBaseMintingModuleCloneable {
    address public minterAddress; // address of the wallet or contract that can call canMint
    uint256 public maxClaim; // number of tokens that can be minted per unique id
    uint256 public mintPrice; // cost to mint a single token
    bool public isActive; // if the mint is active and can be used

    modifier onlyMinter() {
        require(msg.sender == minterAddress, "T24");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer function to be called during contract creation
    /// @param _admin The address of the admin
    /// @param _minter The address of the wallet or contract that can call canMint. Should be used to check caller if minting module modifies storage.
    /// @param _maxClaim The number of tokens that can be minted per constraint of implementing module
    /// @param _mintPrice The price per token in wei
    function __BaseMintModule_init(
        address _admin,
        address _minter,
        uint256 _maxClaim,
        uint256 _mintPrice
    ) internal onlyInitializing {
        require(_admin != address(0), "T23");
        require(_minter != address(0), "T24");

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        minterAddress = _minter;
        maxClaim = _maxClaim;
        mintPrice = _mintPrice;
    }

    /// @notice Set maxClaim
    /// @param _maxClaim uint256
    function setMaxClaim(uint256 _maxClaim) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxClaim = _maxClaim;
    }

    /// @notice Set isActive
    /// @param _isActive boolean
    function setIsActive(bool _isActive) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isActive = _isActive;
    }

    /// @notice Set mintPrice
    /// @param _mintPrice uint256
    function setMintPrice(uint256 _mintPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = _mintPrice;
    }

    /// @notice Set minterAddress
    /// @param _minterAddress new minterAddress
    function setMinterAddress(address _minterAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minterAddress = _minterAddress;
    }

    function initialize(
        address _admin,
        address _minter,
        bytes calldata data
    ) external virtual;
}