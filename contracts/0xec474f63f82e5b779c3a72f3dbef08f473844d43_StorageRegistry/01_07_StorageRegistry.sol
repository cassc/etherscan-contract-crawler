// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {
    OwnableUpgradeable,
    Initializable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IStorageRegistry } from "./Interfaces/IStorageRegistry.sol";

contract StorageRegistry is
    IStorageRegistry,
    Initializable,
    OwnableUpgradeable
{
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using BitMaps for BitMaps.BitMap;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice whitelist contract address
    address public whitelistAddress;

    /// @notice vault contract address
    address public vaultAddress;

    /// @notice swap contract address
    address public swapAddress;

    /// @notice reserve contract address
    address public reserveAddress;

    /// @notice NF3Market contract address
    address public marketAddress;

    /// @notice NF3Loan contract address
    address public loanAddress;

    /// @notice airdropClaimImplementation contract address
    address public airdropClaimImplementation;

    /// @notice signing utility library's address
    address public signingUtilsAddress;

    /// @notice positionToken contract address
    address public positionTokenAddress;

    /// @notice Mapping of users and their nonce in form of bitmap
    mapping(address => BitMaps.BitMap) private nonce;

    /// @notice mapping from position tokenId to claim contract address
    mapping(uint256 => address) public claimContractAddresses;

    /// @notice mapping for whitelisted airdrop contracts that can be called by the user
    mapping(address => bool) public airdropWhitelist;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyApproved() {
        _onlyApproved();
        _;
    }

    /* ===== INIT ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initialize
    function initialize() public initializer {
        __Ownable_init();
    }

    /// -----------------------------------------------------------------------
    /// Nonce actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IStorageRegistry
    function getNonce(address _owner, uint256 _nonce)
        external
        view
        override
        returns (bool)
    {
        return nonce[_owner].get(_nonce);
    }

    /// @notice Inherit from IStorageRegistry
    function checkNonce(address _owner, uint256 _nonce) external view {
        bool _status = nonce[_owner].get(_nonce);
        if (_status) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_NONCE
            );
        }
    }

    /// @notice Inherit from IStorageRegistry
    function setNonce(address _owner, uint256 _nonce)
        external
        override
        onlyApproved
    {
        emit NonceSet(_owner, _nonce);

        nonce[_owner].set(_nonce);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IStorageRegistry
    function setMarket(address _marketAddress) external override onlyOwner {
        if (_marketAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit MarketSet(marketAddress, _marketAddress);

        marketAddress = _marketAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setVault(address _vaultAddress) external override onlyOwner {
        if (_vaultAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit VaultSet(vaultAddress, _vaultAddress);

        vaultAddress = _vaultAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setReserve(address _reserveAddress) external override onlyOwner {
        if (_reserveAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit ReserveSet(reserveAddress, _reserveAddress);

        reserveAddress = _reserveAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setWhitelist(address _whitelistAddress)
        external
        override
        onlyOwner
    {
        if (_whitelistAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit WhitelistSet(whitelistAddress, _whitelistAddress);
        whitelistAddress = _whitelistAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setSwap(address _swapAddress) external override onlyOwner {
        if (_swapAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit SwapSet(swapAddress, _swapAddress);

        swapAddress = _swapAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setLoan(address _loanAddress) external override onlyOwner {
        if (_loanAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit LoanSet(loanAddress, _loanAddress);
        loanAddress = _loanAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setSigningUtil(address _signingUtilsAddress)
        external
        override
        onlyOwner
    {
        if (_signingUtilsAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit SigningUtilSet(signingUtilsAddress, _signingUtilsAddress);

        signingUtilsAddress = _signingUtilsAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setAirdropClaimImplementation(address _airdropClaimImplementation)
        external
        override
        onlyOwner
    {
        if (_airdropClaimImplementation == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit AirdropClaimImplementationSet(
            airdropClaimImplementation,
            _airdropClaimImplementation
        );
        airdropClaimImplementation = _airdropClaimImplementation;
    }

    /// @notice Inherit from IStorageRegistry
    function setPositionToken(address _positionTokenAddress)
        external
        override
        onlyOwner
    {
        if (_positionTokenAddress == address(0)) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.INVALID_ADDRESS
            );
        }
        emit PositionTokenSet(positionTokenAddress, _positionTokenAddress);
        positionTokenAddress = _positionTokenAddress;
    }

    /// @notice Inherit from IStorageRegistry
    function setAirdropWhitelist(address _contract, bool _allow)
        external
        override
        onlyOwner
    {
        airdropWhitelist[_contract] = _allow;
    }

    /// @notice Inherit from IStorageRegistry
    function setClaimContractAddresses(uint256 _tokenId, address _claimContract)
        external
        override
        onlyApproved
    {
        claimContractAddresses[_tokenId] = _claimContract;
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _onlyApproved() internal view {
        if (
            msg.sender != swapAddress &&
            msg.sender != reserveAddress &&
            msg.sender != loanAddress
        ) {
            revert StorageRegistryError(
                StorageRegistryErrorCodes.CALLER_NOT_APPROVED
            );
        }
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[45] private __gap;
}