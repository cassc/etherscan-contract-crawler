// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import {
    OwnableUpgradeable,
    Initializable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    ERC2771ContextUpgradeable,
    ContextUpgradeable
} from "./ERC2771ContextUpgradeable.sol";
import {
    IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {
    SafeERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { INF3Market } from "./Interfaces/INF3Market.sol";
import { ISwap } from "./Interfaces/ISwap.sol";
import { IReserve } from "./Interfaces/IReserve.sol";
import { IStorageRegistry } from "./Interfaces/IStorageRegistry.sol";
import { IWETH } from "./Interfaces/IWETH.sol";
import "../utils/DataTypes.sol";

/// @title NF3 Market
/// @author NF3 Exchange
/// @notice This contract inherits from INF3Market interface.
/// @dev This most of the functions in this contract are public callable.
/// @dev This contract has all the public facing functions. This contract is used as the implementation address at NF3Proxy contract.

contract NF3Market is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    INF3Market
{
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Storage registry contract address
    address public storageRegistryAddress;

    /// @notice WETH contract address
    address public wETH;

    /* ===== INIT ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initialize
    function initialize(address _wETH) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        require(_wETH != address(0));
        wETH = _wETH;
    }

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from INF3Market
    function cancelListing(Listing calldata _listing, bytes memory _signature)
        external
        whenNotPaused
        nonReentrant
    {
        // Call core contract.
        ISwap(_swapAddress(storageRegistryAddress)).cancelListing(
            _listing,
            _signature,
            _msgSender()
        );
    }

    /// @notice Inherit from INF3Market
    function cancelSwapOffer(SwapOffer calldata _offer, bytes memory _signature)
        external
        whenNotPaused
        nonReentrant
    {
        // Call core contract.
        ISwap(_swapAddress(storageRegistryAddress)).cancelSwapOffer(
            _offer,
            _signature,
            _msgSender()
        );
    }

    /// @notice Inherit from INF3Market
    function cancelCollectionSwapOffer(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        ISwap(_swapAddress(storageRegistryAddress)).cancelCollectionSwapOffer(
            _offer,
            _signature,
            _msgSender()
        );
    }

    /// @notice Inherit from INF3Market
    function cancelReserveOffer(
        ReserveOffer calldata _offer,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        IReserve(_reserveAddress(storageRegistryAddress)).cancelReserveOffer(
            _offer,
            _signature,
            _msgSender()
        );
    }

    /// @notice Inherit from INF3Market
    function cancelCollectionReserveOffer(
        CollectionReserveOffer calldata _offer,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        IReserve(_reserveAddress(storageRegistryAddress))
            .cancelCollectionReserveOffer(_offer, _signature, _msgSender());
    }

    /// -----------------------------------------------------------------------
    /// Direct Swap actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from INF3Market
    function directSwap(
        Listing calldata _listing,
        bytes memory _signature,
        uint256 _swapId,
        SwapParams calldata _swapParams,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees,
        uint256 _toWrap
    ) external payable whenNotPaused nonReentrant {
        // Check the length of tokens must be same as tokenIds.
        equalLength(_swapParams.tokens, _swapParams.tokenIds);

        address _storageRegistryAddress = storageRegistryAddress;

        if (_toWrap != 0) _getWETH(_toWrap, _msgSender());

        uint256 value = msg.value - _toWrap;
        // Transfer eth to the vault.
        (bool success, ) = payable(_vaultAddress(_storageRegistryAddress)).call{
            value: value
        }("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        ISwap(_swapAddress(_storageRegistryAddress)).directSwap(
            _listing,
            _signature,
            _swapId,
            _msgSender(),
            _swapParams,
            value,
            _royalty,
            sellerFees,
            buyerFees
        );
    }

    /// @notice Inherit from INF3Market
    function acceptUnlistedDirectSwapOffer(
        SwapOffer calldata _offer,
        bytes memory _signature,
        Assets calldata _consideration,
        bytes32[] calldata _proof,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees,
        uint256 _toWrap
    ) external payable whenNotPaused nonReentrant {
        address _storageRegistryAddress = storageRegistryAddress;

        if (_toWrap != 0) _getWETH(_toWrap, _msgSender());

        uint256 value = msg.value - _toWrap;

        // Transfer eth to the vault.
        (bool success, ) = payable(_vaultAddress(_storageRegistryAddress)).call{
            value: value
        }("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        ISwap(_swapAddress(_storageRegistryAddress))
            .acceptUnlistedDirectSwapOffer(
                _offer,
                _signature,
                _consideration,
                _proof,
                _msgSender(),
                value,
                _royalty,
                sellerFees,
                buyerFees
            );
    }

    /// @notice Inherit from INF3Market
    function acceptListedDirectSwapOffer(
        Listing calldata _listing,
        bytes memory _listingSignature,
        SwapOffer calldata _offer,
        bytes memory _offerSignature,
        bytes32[] calldata _proof,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        ISwap(_swapAddress(storageRegistryAddress)).acceptListedDirectSwapOffer(
                _listing,
                _listingSignature,
                _offer,
                _offerSignature,
                _proof,
                _msgSender(),
                sellerFees,
                buyerFees
            );
    }

    /// @notice Inherit from INF3Market
    function acceptCollectionSwapOffer(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature,
        SwapParams calldata _swapParams,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees,
        uint256 _toWrap
    ) external payable whenNotPaused nonReentrant {
        // Check the length of tokens must be same as tokenIds.
        equalLength(_swapParams.tokens, _swapParams.tokenIds);

        if (_toWrap != 0) _getWETH(_toWrap, _msgSender());

        uint256 value = msg.value - _toWrap;

        address _storageRegistryAddress = storageRegistryAddress;

        // Transfer eth to the vault.
        (bool success, ) = payable(_vaultAddress(_storageRegistryAddress)).call{
            value: value
        }("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        ISwap(_swapAddress(_storageRegistryAddress)).acceptCollectionSwapOffer(
            _offer,
            _signature,
            _swapParams,
            _msgSender(),
            value,
            _royalty,
            sellerFees,
            buyerFees
        );
    }

    /// -----------------------------------------------------------------------
    /// Reserve actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from INF3Market
    function reserveDeposit(
        Listing calldata _listing,
        bytes memory _listingSignature,
        uint256 _reserveId,
        Fees calldata sellerFees,
        Fees calldata buyerFees,
        uint256 _toWrap
    ) external payable whenNotPaused nonReentrant {
        address _storageRegistryAddress = storageRegistryAddress;

        if (_toWrap != 0) _getWETH(_toWrap, _msgSender());

        uint256 value = msg.value - _toWrap;

        // Transfer eth to the vault.
        (bool success, ) = payable(_vaultAddress(_storageRegistryAddress)).call{
            value: value
        }("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        IReserve(_reserveAddress(_storageRegistryAddress)).reserveDeposit(
            _listing,
            _listingSignature,
            _reserveId,
            _msgSender(),
            value,
            sellerFees,
            buyerFees
        );
    }

    /// @notice Inherit from INF3Market
    function acceptUnlistedReserveOffer(
        ReserveOffer calldata _offer,
        bytes memory _offerSignature,
        Assets calldata _consideration,
        bytes32[] calldata _proof,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees,
        uint256 _toWrap
    ) external payable whenNotPaused nonReentrant {
        address _storageRegistryAddress = storageRegistryAddress;

        if (_toWrap != 0) _getWETH(_toWrap, _msgSender());

        uint256 value = msg.value - _toWrap;

        // Transfer eth to the vault.
        (bool success, ) = payable(_vaultAddress(_storageRegistryAddress)).call{
            value: value
        }("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        //  Call core contract
        IReserve(_reserveAddress(_storageRegistryAddress))
            .acceptUnlistedReserveOffer(
                _offer,
                _offerSignature,
                _consideration,
                _proof,
                _msgSender(),
                value,
                _royalty,
                sellerFees,
                buyerFees
            );
    }

    /// @notice Inherit from INF3Market
    function acceptListedReserveOffer(
        Listing calldata _listing,
        bytes memory _listingSignature,
        ReserveOffer calldata _offer,
        bytes memory _offerSignature,
        bytes32[] memory _proof,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        IReserve(_reserveAddress(storageRegistryAddress))
            .acceptListedReserveOffer(
                _listing,
                _listingSignature,
                _offer,
                _offerSignature,
                _proof,
                _msgSender(),
                sellerFees,
                buyerFees
            );
    }

    /// @notice Inherit from INF3Market
    function acceptCollectionReserveOffer(
        CollectionReserveOffer calldata _offer,
        bytes memory _signature,
        SwapParams calldata _swapParams,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees,
        uint256 _toWrap
    ) external payable whenNotPaused nonReentrant {
        // Check the length of tokens must be same as tokenIds.
        equalLength(_swapParams.tokens, _swapParams.tokenIds);

        address _storageRegistryAddress = storageRegistryAddress;

        if (_toWrap != 0) _getWETH(_toWrap, _msgSender());

        uint256 value = msg.value - _toWrap;

        // Transfer eth to the vault.
        (bool success, ) = payable(_vaultAddress(_storageRegistryAddress)).call{
            value: value
        }("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        IReserve(_reserveAddress(_storageRegistryAddress))
            .acceptCollectionReserveOffer(
                _offer,
                _signature,
                _swapParams,
                _msgSender(),
                value,
                _royalty,
                sellerFees,
                buyerFees
            );
    }

    /// @notice Inherit from INF3Market
    function payRemains(
        Reservation calldata _reservation,
        uint256 _positionTokenId,
        Royalty calldata _royalty,
        Fees calldata buyerFees,
        uint256 _toWrap
    ) external payable nonReentrant {
        address _storageRegistryAddress = storageRegistryAddress;

        if (_toWrap != 0) _getWETH(_toWrap, _msgSender());

        uint256 value = msg.value - _toWrap;

        // Transfer eth to the vault.
        (bool success, ) = payable(_vaultAddress(_storageRegistryAddress)).call{
            value: value
        }("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        IReserve(_reserveAddress(_storageRegistryAddress)).payRemains(
            _reservation,
            _positionTokenId,
            _msgSender(),
            value,
            _royalty,
            buyerFees
        );
    }

    /// @notice Inherit from INF3Market
    function claimDefaulted(
        Reservation calldata _reservation,
        uint256 _positionTokenId
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        IReserve(_reserveAddress(storageRegistryAddress)).claimDefaulted(
            _reservation,
            _positionTokenId,
            _msgSender()
        );
    }

    /// @notice Inherit from INF3Market
    function claimAirdrop(
        Reservation calldata _reservation,
        uint256 _positionTokenId,
        address _airdropContract,
        bytes calldata _data
    ) external whenNotPaused nonReentrant {
        // Call core contracts
        IReserve(_reserveAddress(storageRegistryAddress)).claimAirdrop(
            _reservation,
            _positionTokenId,
            _airdropContract,
            _data,
            _msgSender()
        );
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from INF3Market
    function setStorageRegistry(address _storageRegistryAddress)
        external
        override
        onlyOwner
    {
        if (_storageRegistryAddress == address(0)) {
            revert NF3MarketError(NF3MarketErrorCodes.INVALID_ADDRESS);
        }
        emit StorageRegistrySet(
            _storageRegistryAddress,
            storageRegistryAddress
        );
        storageRegistryAddress = _storageRegistryAddress;
    }

    /// @notice Inherit from INF3Market
    function setTrustedForwarder(address __trustedForwarder)
        external
        override
        onlyOwner
    {
        if (__trustedForwarder == address(0)) {
            revert NF3MarketError(NF3MarketErrorCodes.INVALID_ADDRESS);
        }
        emit TrustedForwarderSet(_trustedForwarder, __trustedForwarder);
        _setTrustedForwarder(__trustedForwarder);
    }

    /// @notice Inherit from INF3Market
    function setPause(bool _setPause) external override onlyOwner {
        if (_setPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// -----------------------------------------------------------------------
    /// Interal functions
    /// -----------------------------------------------------------------------

    /// @dev Compare the length of arraies.
    /// @param _addr NFT token address array
    /// @param _ids NFT token id array
    function equalLength(address[] memory _addr, uint256[] memory _ids)
        internal
        pure
    {
        if (_addr.length != _ids.length) {
            revert NF3MarketError(NF3MarketErrorCodes.LENGTH_NOT_EQUAL);
        }
    }

    /// @dev internal function to get vault address from storage registry contract
    /// @param _storageRegistryAddress  memoized storage registry address
    function _vaultAddress(address _storageRegistryAddress)
        internal
        view
        returns (address)
    {
        return IStorageRegistry(_storageRegistryAddress).vaultAddress();
    }

    /// @dev internal function to get swap address from storage registry contract
    /// @param _storageRegistryAddress  memoized storage registry address
    function _swapAddress(address _storageRegistryAddress)
        internal
        view
        returns (address)
    {
        return IStorageRegistry(_storageRegistryAddress).swapAddress();
    }

    /// @dev internal function to get reserve address from storage registry contract
    /// @param _storageRegistryAddress  memoized storage registry address
    function _reserveAddress(address _storageRegistryAddress)
        internal
        view
        returns (address)
    {
        return IStorageRegistry(_storageRegistryAddress).reserveAddress();
    }

    /// @dev internal function to convert received ETH to wETH
    /// @param _toWrap amount of eth to be wrapped
    /// @param _user owner to which the wETH is to be transfered
    function _getWETH(uint256 _toWrap, address _user) internal {
        if (msg.value < _toWrap) {
            revert NF3MarketError(NF3MarketErrorCodes.INSUFFICIENT_ETH_SENT);
        }
        address _wETH = wETH;
        IWETH(_wETH).deposit{ value: _toWrap }();
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(_wETH),
            _user,
            _toWrap
        );
    }

    /// -----------------------------------------------------------------------
    /// EIP-2771 Actions
    /// -----------------------------------------------------------------------

    function _msgSender()
        internal
        view
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[47] private __gap;
}