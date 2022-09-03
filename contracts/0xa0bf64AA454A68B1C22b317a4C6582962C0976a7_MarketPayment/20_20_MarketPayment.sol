pragma solidity ^0.8.4;
pragma abicoder v2;

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../lib-part/LibPart.sol";
import "../lib-part/LibAsset.sol";
import "../market-transfer-proxy/ITransferProxy.sol";
import "../market-transfer-proxy/IERC20TransferProxy.sol";
import "../lib/LibTransfer.sol";

//import "hardhat/console.sol";

contract MarketPayment is
    Initializable,
    EIP712Upgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using LibTransfer for address;
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    string private constant SIGNING_DOMAIN = "Xooa Market";
    string private constant SIGNATURE_VERSION = "1";

    address private erc721transferProxy;
    address private erc20transferProxy;

    bytes32 public constant PAY_TYPEHASH =
        keccak256(
            "Order(string transferId,string appId,Asset[] fees,Asset[] assets)Asset(AssetType assetType,uint256 value,address from,address to)AssetType(bytes4 assetClass,bytes data)"
        );

    struct OrderData {
        string transferId;
        string appId;
        LibAsset.Asset[] fees;
        LibAsset.Asset[] assets;
        bytes signature;
    }

    event PaymentEvent(string transferId, string appId);

    function __MarketPayment_init(
        address signer,
        address _erc721transferProxy,
        address _erc20transferProxy
    ) public initializer {
        require(signer != address(0), "Trusted signer is required");
        erc721transferProxy = _erc721transferProxy;
        erc20transferProxy = _erc20transferProxy;

        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        _setupRole(SIGNER_ROLE, signer);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function pay(OrderData calldata data) public payable virtual nonReentrant {
        require(
            _verify(_hash(data), data.signature),
            "Signature invalid or unauthorized"
        );

        for (uint256 i = 0; i < data.fees.length; i++) {
            LibAsset.Asset memory asset = data.fees[i];
            if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
                //not using transfer proxy when transfering from this contract
                address token = abi.decode(asset.assetType.data, (address));

                IERC20TransferProxy(erc20transferProxy).erc20safeTransferFrom(
                    IERC20Upgradeable(token),
                    asset.from,
                    asset.to,
                    asset.value
                );
            } else if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
                if (asset.to != address(this)) {
                    (asset.to).transferEth(asset.value);
                }
            }
        }

        for (uint256 i = 0; i < data.assets.length; i++) {
            LibAsset.Asset memory asset = data.assets[i];

            if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
                //not using transfer proxy when transfering from this contract
                (address token, uint256 tokenId) = abi.decode(
                    asset.assetType.data,
                    (address, uint256)
                );
                require(asset.value == 1, "erc721 value error");

                ITransferProxy(erc721transferProxy).erc721safeTransferFrom(
                    IERC721Upgradeable(token),
                    asset.from,
                    asset.to,
                    tokenId
                );
            } else if (
                asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS
            ) {
                //not using transfer proxy when transfering from this contract
                (address token, uint256 tokenId) = abi.decode(
                    asset.assetType.data,
                    (address, uint256)
                );

                ITransferProxy(erc721transferProxy).erc1155safeTransferFrom(
                    IERC1155Upgradeable(token),
                    asset.from,
                    asset.to,
                    tokenId,
                    asset.value,
                    ""
                );
            } else {
                ITransferProxy(erc721transferProxy).transfer(asset);
            }
        }

        emit PaymentEvent(data.transferId, data.appId);
    }

    function _hash(OrderData calldata data) internal view returns (bytes32) {
        bytes32[] memory feesBytes = new bytes32[](data.fees.length);
        for (uint256 i = 0; i < data.fees.length; i++) {
            feesBytes[i] = LibAsset.hash(data.fees[i]);
        }

        bytes32[] memory assetsBytes = new bytes32[](data.assets.length);
        for (uint256 i = 0; i < data.assets.length; i++) {
            assetsBytes[i] = LibAsset.hash(data.assets[i]);
        }

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        PAY_TYPEHASH,
                        keccak256(bytes(data.transferId)),
                        keccak256(bytes(data.appId)),
                        keccak256(abi.encodePacked(feesBytes)),
                        keccak256(abi.encodePacked(assetsBytes))
                    )
                )
            );
    }

    function _verify(bytes32 digest, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return
            hasRole(SIGNER_ROLE, ECDSAUpgradeable.recover(digest, signature));
    }
}