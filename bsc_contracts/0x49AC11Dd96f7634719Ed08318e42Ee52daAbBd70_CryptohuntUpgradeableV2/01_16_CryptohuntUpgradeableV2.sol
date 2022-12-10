// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./LibTokenAsset.sol";

contract CryptohuntUpgradeableV2 is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable
{
    using ECDSAUpgradeable for bytes32;
    using LibTokenAsset for LibTokenAsset.TokenAssetV2;

    enum PaymentType {
        BALANCE,
        WALLET
    }

    mapping(address => uint256) public tokenPool;
    mapping(bytes32 => bool) public isAssetHashAlreadyUsed;

    event Replenishment(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 value
    );
    event Withdrawal(
        address indexed user,
        address indexed token,
        uint256 value
    );

    event Transfer(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 value
    );

    event SignatureHasUsed(bytes signature);

    function __Cryptohunt_init() external initializer {
        __Ownable_init();
        __Pausable_init();
        __Cryptohunt_init_unchained();
    }

    function __Cryptohunt_init_unchained() internal onlyInitializing {}

    function addFunds(LibTokenAsset.TokenAssetV2 calldata asset, address to)
        external
        whenNotPaused
    {
        IERC20 token = IERC20(asset.token);
        token.transferFrom(_msgSender(), address(this), asset.amount);
        tokenPool[asset.token] += asset.amount;

        emit Replenishment(_msgSender(), to, asset.token, asset.amount);
    }

    function transfer(
        LibTokenAsset.TokenAssetV2 calldata asset,
        address to,
        bytes calldata signature
    ) external whenNotPaused {
        bytes32 assetHash = asset.hash();
        require(
            isAdminSignatureValid(assetHash, signature),
            "Signature is not valid"
        );
        require(asset.expirationTimestamp > block.timestamp, "Asset expired");
        require(
            !isAssetHashAlreadyUsed[assetHash],
            "Asset has already been used"
        );

        isAssetHashAlreadyUsed[assetHash] = true;

        emit Transfer(_msgSender(), to, asset.token, asset.amount);
        emit SignatureHasUsed(signature);
    }

    function withdraw(
        LibTokenAsset.TokenAssetV2 calldata asset,
        bytes calldata signature
    ) external whenNotPaused {
        bytes32 assetHash = asset.hash();
        require(asset.owner == _msgSender(), "Sender must be owner of asset");
        require(
            isAdminSignatureValid(assetHash, signature),
            "Signature is not valid"
        );
        require(asset.expirationTimestamp > block.timestamp, "Asset expired");
        require(
            !isAssetHashAlreadyUsed[assetHash],
            "Asset has already been used"
        );

        IERC20(asset.token).transfer(_msgSender(), asset.amount);
        tokenPool[asset.token] -= asset.amount;
        isAssetHashAlreadyUsed[assetHash] = true;

        emit Withdrawal(_msgSender(), asset.token, asset.amount);
        emit SignatureHasUsed(signature);
    }

    function isAdminSignatureValid(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        return owner() == hash.toEthSignedMessageHash().recover(signature);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    uint256[50] private __gap;
}