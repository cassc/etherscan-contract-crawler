// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {
    IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {
    SafeERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {
    OwnableUpgradeable,
    Initializable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IVault } from "./Interfaces/IVault.sol";
import { IWhitelist } from "./Interfaces/IWhitelist.sol";
import { IStorageRegistry } from "./Interfaces/IStorageRegistry.sol";
import "../utils/DataTypes.sol";

/// @title NF3 Vault
/// @author NF3 Exchange
/// @notice This contract inherits from IVault interface.
/// @dev This contract acts as the pathway for transfering assets between two addresses.
/// @dev It also locks the assets as an escrow when a listing is reserved for the given time.

contract Vault is
    IVault,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Storage registry contract address
    address public storageRegistryAddress;

    /// @notice upper limit of fee that can be deducted
    mapping(address => uint256) public feeCaps;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyApproved() {
        _onlyApproved();
        _;
    }

    modifier onlySelf() {
        _onlySelf();
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
        __ReentrancyGuard_init();
    }

    /// -----------------------------------------------------------------------
    /// Transfer actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IVault
    function transferAssets(
        Assets calldata _assets,
        address _from,
        address _to,
        Royalty calldata _royalty,
        bool _allowEth
    ) external override onlyApproved {
        (AssetType[] memory nftTypes, AssetType[] memory ftTypes) = IWhitelist(
            _whitelistAddress()
        ).getAssetsTypes(_assets);

        unchecked {
            uint256 i;
            for (i = 0; i < _assets.tokens.length; i++) {
                if (nftTypes[i] == AssetType.ERC_721) {
                    IERC721(_assets.tokens[i]).safeTransferFrom(
                        _from,
                        _to,
                        _assets.tokenIds[i]
                    );
                } else if (nftTypes[i] == AssetType.ERC_1155) {
                    IERC1155(_assets.tokens[i]).safeTransferFrom(
                        _from,
                        _to,
                        _assets.tokenIds[i],
                        1,
                        ""
                    );
                } else if (nftTypes[i] == AssetType.KITTIES) {
                    _transferFromKitty(
                        _assets.tokens[i],
                        _assets.tokenIds[i],
                        _from,
                        _to
                    );
                } else if (nftTypes[i] == AssetType.PUNK) {
                    _receivePunk(_assets.tokens[i], _assets.tokenIds[i], _from);
                    _sendPunk(_assets.tokens[i], _assets.tokenIds[i], _to);
                } else {
                    revert VaultError(VaultErrorCodes.INVALID_ASSET_TYPE);
                }
            }
            for (i = 0; i < _assets.paymentTokens.length; i++) {
                if (ftTypes[i] == AssetType.ERC_20) {
                    uint256 royalty = _calculateRoyalty(
                        _royalty,
                        _from,
                        _assets.paymentTokens[i],
                        _assets.amounts[i],
                        ftTypes[i]
                    );
                    IERC20Upgradeable(_assets.paymentTokens[i])
                        .safeTransferFrom(
                            _from,
                            _to,
                            _assets.amounts[i] - royalty
                        );
                } else if (ftTypes[i] == AssetType.ETH) {
                    if (_allowEth) {
                        uint256 royalty = _calculateRoyalty(
                            _royalty,
                            _from,
                            _assets.paymentTokens[i],
                            _assets.amounts[i],
                            ftTypes[i]
                        );
                        (bool success, ) = _to.call{
                            value: _assets.amounts[i] - royalty
                        }("");
                        if (!success)
                            revert VaultError(
                                VaultErrorCodes.FAILED_TO_SEND_ETH
                            );
                    } else {
                        revert VaultError(VaultErrorCodes.ETH_NOT_ALLOWED);
                    }
                } else {
                    revert VaultError(VaultErrorCodes.INVALID_ASSET_TYPE);
                }
            }
        }

        emit AssetsTransferred(_assets, _from, _to);
    }

    /// @notice Inherit from IVault
    function receiveAssets(
        Assets calldata _assets,
        address _from,
        bool _allowEth
    ) external override onlyApproved {
        (AssetType[] memory nftTypes, AssetType[] memory ftTypes) = IWhitelist(
            _whitelistAddress()
        ).getAssetsTypes(_assets);

        unchecked {
            uint256 i;
            for (i = 0; i < _assets.tokens.length; i++) {
                if (nftTypes[i] == AssetType.ERC_721) {
                    IERC721(_assets.tokens[i]).safeTransferFrom(
                        _from,
                        address(this),
                        _assets.tokenIds[i]
                    );
                } else if (nftTypes[i] == AssetType.ERC_1155) {
                    IERC1155(_assets.tokens[i]).safeTransferFrom(
                        _from,
                        address(this),
                        _assets.tokenIds[i],
                        1,
                        ""
                    );
                } else if (nftTypes[i] == AssetType.KITTIES) {
                    _transferFromKitty(
                        _assets.tokens[i],
                        _assets.tokenIds[i],
                        _from,
                        address(this)
                    );
                } else if (nftTypes[i] == AssetType.PUNK) {
                    _receivePunk(_assets.tokens[i], _assets.tokenIds[i], _from);
                } else {
                    revert VaultError(VaultErrorCodes.INVALID_ASSET_TYPE);
                }
            }
            for (i = 0; i < _assets.paymentTokens.length; i++) {
                if (ftTypes[i] == AssetType.ERC_20) {
                    IERC20Upgradeable(_assets.paymentTokens[i])
                        .safeTransferFrom(
                            _from,
                            address(this),
                            _assets.amounts[i]
                        );
                } else if (ftTypes[i] == AssetType.ETH && _allowEth) {
                    continue;
                } else {
                    revert VaultError(VaultErrorCodes.INVALID_ASSET_TYPE);
                }
            }
        }
        emit AssetsReceived(_assets, _from);
    }

    /// @notice Inherit from IVault
    function sendAssets(
        Assets calldata _assets,
        address _to,
        Royalty calldata _royalty,
        bool _allowEth
    ) external override onlyApproved {
        (AssetType[] memory nftTypes, AssetType[] memory ftTypes) = IWhitelist(
            _whitelistAddress()
        ).getAssetsTypes(_assets);

        unchecked {
            uint256 i;
            for (i = 0; i < _assets.tokens.length; i++) {
                if (nftTypes[i] == AssetType.ERC_721) {
                    IERC721(_assets.tokens[i]).safeTransferFrom(
                        address(this),
                        _to,
                        _assets.tokenIds[i]
                    );
                } else if (nftTypes[i] == AssetType.ERC_1155) {
                    IERC1155(_assets.tokens[i]).safeTransferFrom(
                        address(this),
                        _to,
                        _assets.tokenIds[i],
                        1,
                        ""
                    );
                } else if (nftTypes[i] == AssetType.KITTIES) {
                    _sendKitty(_assets.tokens[i], _assets.tokenIds[i], _to);
                } else if (nftTypes[i] == AssetType.PUNK) {
                    _sendPunk(_assets.tokens[i], _assets.tokenIds[i], _to);
                } else {
                    revert VaultError(VaultErrorCodes.INVALID_ASSET_TYPE);
                }
            }
            for (i = 0; i < _assets.paymentTokens.length; i++) {
                if (ftTypes[i] == AssetType.ERC_20) {
                    uint256 royalty = _calculateRoyalty(
                        _royalty,
                        address(this),
                        _assets.paymentTokens[i],
                        _assets.amounts[i],
                        AssetType.ERC_20
                    );
                    IERC20Upgradeable(_assets.paymentTokens[i]).safeTransfer(
                        _to,
                        _assets.amounts[i] - royalty
                    );
                } else if (ftTypes[i] == AssetType.ETH && _allowEth) {
                    uint256 royalty = _calculateRoyalty(
                        _royalty,
                        address(this),
                        _assets.paymentTokens[i],
                        _assets.amounts[i],
                        ftTypes[i]
                    );
                    (bool success, ) = _to.call{
                        value: _assets.amounts[i] - royalty
                    }("");
                    if (!success)
                        revert VaultError(VaultErrorCodes.FAILED_TO_SEND_ETH);
                } else {
                    revert VaultError(VaultErrorCodes.INVALID_ASSET_TYPE);
                }
            }
        }
        emit AssetsSent(_assets, _to);
    }

    /// @notice Inherit from IVault
    function transferFees(
        Fees calldata sellerFees,
        address seller,
        Fees calldata buyerFees,
        address buyer
    ) external override onlyApproved {
        try this._transferFees(sellerFees, seller) {} catch {
            revert VaultError(VaultErrorCodes.COULD_NOT_TRANSFER_SELLER_FEES);
        }
        try this._transferFees(buyerFees, buyer) {} catch {
            revert VaultError(VaultErrorCodes.COULD_NOT_TRANSFER_BUYER_FEES);
        }

        emit FeesPaid(sellerFees, seller, buyerFees, buyer);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IVault
    function setStorageRegistry(address _storageRegistryAddress)
        external
        override
        onlyOwner
    {
        if (_storageRegistryAddress == address(0)) {
            revert VaultError(VaultErrorCodes.INVALID_ADDRESS);
        }
        emit StorageRegistrySet(
            storageRegistryAddress,
            _storageRegistryAddress
        );

        storageRegistryAddress = _storageRegistryAddress;
    }

    /// @notice Inherit from IVault
    function setFeeCap(address[] memory tokens, uint256[] memory caps)
        external
        override
        onlyOwner
    {
        for (uint256 i; i < tokens.length; ) {
            feeCaps[tokens[i]] = caps[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {IERC721Receiver - onERC721Received}
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    /// @dev See {IERC1155Receiver - onERC1155Received}
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// -----------------------------------------------------------------------
    /// Internal/Private functions
    /// -----------------------------------------------------------------------

    /// @dev helper function to transfer fee from the user
    /// @param fees Amount and tokens of fees to transfer
    /// @param from user from which the fee is transferred
    /// NOTE : The function is supposed to be used only by the vault contract itself
    ///        It is not set as internal so that try catch can be used for correct error messages
    function _transferFees(Fees calldata fees, address from) external onlySelf {
        unchecked {
            uint256 feeCap = feeCaps[fees.token];
            if (feeCap > 0 && fees.amount > 0) {
                IERC20Upgradeable(fees.token).safeTransferFrom(
                    from,
                    fees.to,
                    feeCap <= fees.amount ? feeCap : fees.amount
                );
            }
        }
    }

    /// @dev internal function to check if the caller is one of the approved contracts or not
    function _onlyApproved() internal view {
        address _storageRegistryAddress = storageRegistryAddress;
        if (
            msg.sender !=
            IStorageRegistry(_storageRegistryAddress).swapAddress() &&
            msg.sender !=
            IStorageRegistry(_storageRegistryAddress).reserveAddress() &&
            msg.sender !=
            IStorageRegistry(_storageRegistryAddress).loanAddress()
        ) {
            revert VaultError(VaultErrorCodes.CALLER_NOT_APPROVED);
        }
    }

    /// @dev internal function to check if the caller is self contract or not
    function _onlySelf() internal view {
        if (msg.sender != address(this)) {
            revert VaultError(VaultErrorCodes.CALLER_NOT_APPROVED);
        }
    }

    /// @dev internal function to get whitelist address from storage registry contract
    function _whitelistAddress() internal view returns (address) {
        return IStorageRegistry(storageRegistryAddress).whitelistAddress();
    }

    /// @dev Receive crypto punk NFT
    /// @param _punkAddress Address of crypto punk contract
    /// @param _punkIndex tokenId of PUNK
    /// @param _from owner of PUNK
    function _receivePunk(
        address _punkAddress,
        uint256 _punkIndex,
        address _from
    ) internal {
        // ensure no front running
        bytes memory punkIndexToAddress = abi.encodeWithSignature(
            "punkIndexToAddress(uint256)",
            _punkIndex
        );
        (bool checkSuccess, bytes memory result) = _punkAddress.staticcall(
            punkIndexToAddress
        );
        address punkOwner = abi.decode(result, (address));
        if (!(checkSuccess && punkOwner == _from)) {
            revert VaultError(VaultErrorCodes.INVALID_PUNK);
        }
        // transfer punk to vault
        bytes memory data = abi.encodeWithSignature(
            "buyPunk(uint256)",
            _punkIndex
        );
        (bool success, ) = address(_punkAddress).call(data);
        if (!success) {
            revert VaultError(VaultErrorCodes.COULD_NOT_RECEIVE_PUNK);
        }
    }

    /// @dev Send crypto kitty nft from _from address to _to address
    /// @param _token cryptoKitty contract address
    /// @param _tokenId cryptoKitty tokenId
    /// @param _from address to send from
    /// @param _to address to send to
    function _transferFromKitty(
        address _token,
        uint256 _tokenId,
        address _from,
        address _to
    ) internal {
        bytes memory data = abi.encodeWithSelector(
            IERC721.transferFrom.selector,
            _from,
            _to,
            _tokenId
        );
        (bool success, ) = address(_token).call(data);
        if (!success) {
            revert VaultError(VaultErrorCodes.COULD_NOT_RECEIVE_KITTY);
        }
    }

    /// @dev Send crypto punk NFT
    /// @param _punkAddress Address of crypto punk contract
    /// @param _punkIndex tokenId of PUNK
    /// @param _to address to send to
    function _sendPunk(
        address _punkAddress,
        uint256 _punkIndex,
        address _to
    ) internal {
        bytes memory data = abi.encodeWithSignature(
            "transferPunk(address,uint256)",
            _to,
            _punkIndex
        );
        (bool success, ) = _punkAddress.call(data);
        if (!success) {
            revert VaultError(VaultErrorCodes.COULD_NOT_SEND_PUNK);
        }
    }

    /// @dev Send CryptKitty NFT to _to address
    /// @param _token cryptoKitty contract address
    /// @param _tokenId cryptoKitty tokenId
    /// @param _to address to send to
    function _sendKitty(
        address _token,
        uint256 _tokenId,
        address _to
    ) internal {
        bytes memory data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            _to,
            _tokenId
        );
        (bool success, ) = _token.call(data);
        if (!success) {
            revert VaultError(VaultErrorCodes.COULD_NOT_SEND_KITTY);
        }
    }

    /// @dev Calculate the royalty and distribute to the collectors.
    ///      If the asset type is invalid, then only returns the total royalty amount.
    /// @param _royalty Royalty info
    /// @param _from Sender address
    /// @param _paymentToken Payment token address
    /// @param _amount Asset amount
    /// @param _type Payment token type
    function _calculateRoyalty(
        Royalty calldata _royalty,
        address _from,
        address _paymentToken,
        uint256 _amount,
        AssetType _type
    ) internal returns (uint256) {
        uint256 totalRoyalty;
        unchecked {
            for (uint256 i = 0; i < _royalty.to.length; i++) {
                uint256 royalty = (_amount * _royalty.percentage[i]) / 10000;
                if (_type == AssetType.ERC_20) {
                    IERC20Upgradeable(_paymentToken).safeTransferFrom(
                        _from,
                        _royalty.to[i],
                        royalty
                    );
                } else if (_type == AssetType.ETH) {
                    (bool success, ) = _royalty.to[i].call{ value: royalty }(
                        ""
                    );
                    if (!success)
                        revert VaultError(VaultErrorCodes.FAILED_TO_SEND_ETH);
                }
                totalRoyalty += royalty;
            }
        }
        return totalRoyalty;
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[46] private __gap;
}