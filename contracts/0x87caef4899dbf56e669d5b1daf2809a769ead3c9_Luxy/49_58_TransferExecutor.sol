/*
                            __;φφφ≥,,╓╓,__
                           _φ░░░░░░░░░░░░░φ,_
                           φ░░░░░░░░░░░░╚░░░░_
                           ░░░░░░░░░░░░░░░▒▒░▒_
                          _░░░░░░░░░░░░░░░░╬▒░░_
    _≤,                    _░░░░░░░░░░░░░░░░╠░░ε
    _Σ░≥_                   `░░░░░░░░░░░░░░░╚░░░_
     _φ░░                     ░░░░░░░░░░░░░░░▒░░
       ░░░,                    `░░░░░░░░░░░░░╠░░___
       _░░░░░≥,                 _`░░░░░░░░░░░░░░░░░φ≥, _
       ▒░░░░░░░░,_                _ ░░░░░░░░░░░░░░░░░░░░░≥,_
      ▐░░░░░░░░░░░                 φ░░░░░░░░░░░░░░░░░░░░░░░▒,
       ░░░░░░░░░░░[             _;░░░░░░░░░░░░░░░░░░░░░░░░░░░
       \░░░░░░░░░░░»;;--,,. _  ,░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Γ
       _`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ,,
         _"░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"=░░░░░░░░░░░░░░░░░
            Σ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_    `╙δ░░░░Γ"  ²░Γ_
         ,φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_
       _φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ░░≥_
      ,▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
     ,░░░░░░░░░░░░░░░░░╠▒░▐░░░░░░░░░░░░░░░╚░░░░░≥
    _░░░░░░░░░░░░░░░░░░▒░░▐░░░░░░░░░░░░░░░░╚▒░░░░░
    φ░░░░░░░░░░░░░░░░░φ░░Γ'░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░░░░░░_ ░░░░░░░░░░░░░░░░░░░░░░░░[
    ╚░░░░░░░░░░░░░░░░░░░_  └░░░░░░░░░░░░░░░░░░░░░░░░
    _╚░░░░░░░░░░░░░▒"^     _7░░░░░░░░░░░░░░░░░░░░░░Γ
     _`╚░░░░░░░░╚²_          \░░░░░░░░░░░░░░░░░░░░Γ
         ____                _`░░░░░░░░░░░░░░░Γ╙`
                               _"φ░░░░░░░░░░╚_
                                 _ `""²ⁿ""

        ██╗         ██╗   ██╗    ██╗  ██╗    ██╗   ██╗
        ██║         ██║   ██║    ╚██╗██╔╝    ╚██╗ ██╔╝
        ██║         ██║   ██║     ╚███╔╝      ╚████╔╝ 
        ██║         ██║   ██║     ██╔██╗       ╚██╔╝  
        ███████╗    ╚██████╔╝    ██╔╝ ██╗       ██║   
        ╚══════╝     ╚═════╝     ╚═╝  ╚═╝       ╚═╝   
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./assets/LibAsset.sol";
import "./exchangeInterfaces/ITransferProxy.sol";
import "./exchangeInterfaces/INftTransferProxy.sol";
import "./exchangeInterfaces/IERC20TransferProxy.sol";
import "./interfaces/ITransferExecutor.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/LibTransfer.sol";

abstract contract TransferExecutor is
    Initializable,
    OwnableUpgradeable,
    ITransferExecutor
{
    using LibTransfer for address;
    using SafeMathUpgradeable for uint256;
    address public feeWallet;
    address public burningWallet;
    address luxyAddress;
    uint256 public burningPercent;

    mapping(bytes4 => address) proxies;

    event ProxyChange(bytes4 indexed assetType, address proxy);

    bool burnMode;
    bytes4 private constant PROTOCOL = bytes4(keccak256("PROTOCOL"));

    function __TransferExecutor_init_unchained(
        INftTransferProxy transferProxy,
        IERC20TransferProxy erc20TransferProxy,
        address _feeWallet,
        address _burningWallet,
        address _luxyAddress,
        uint256 _burningPercent
    ) internal {
        proxies[LibAsset.ERC20_ASSET_CLASS] = address(erc20TransferProxy);
        proxies[LibAsset.ERC721_ASSET_CLASS] = address(transferProxy);
        proxies[LibAsset.ERC1155_ASSET_CLASS] = address(transferProxy);
        feeWallet = _feeWallet;
        burningWallet = _burningWallet;
        luxyAddress = _luxyAddress;
        burningPercent = _burningPercent;
        burnMode = false;
    }

    function setBurnMode(bool _burnMode) external onlyOwner {
        burnMode = _burnMode;
    }

    function setLuxyAddress(address _luxyAddress) external onlyOwner {
        luxyAddress = _luxyAddress;
    }

    function setBurningPercent(uint256 _burningPercent) external onlyOwner {
        require(_burningPercent <= 100);
        require(_burningPercent > 0);
        burningPercent = _burningPercent;
    }

    function setFeeWallet(address _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
    }

    function setBurningWallet(address _burningWallet) external onlyOwner {
        burningWallet = _burningWallet;
    }

    function setTransferProxy(bytes4 assetType, address proxy)
        external
        onlyOwner
    {
        proxies[assetType] = proxy;
        emit ProxyChange(assetType, proxy);
    }

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        bytes4 transferDirection,
        bytes4 transferType
    ) internal override {
        if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            if (transferType == PROTOCOL && burnMode == true) {
                uint256 amountBurn = asset.value.mul(burningPercent).div(100);
                uint256 amountFee = asset.value.sub(amountBurn);
                if (amountBurn > 0) {
                    burningWallet.transferEth(amountBurn);
                }
                feeWallet.transferEth(amountFee);
            } else {
                to.transferEth(asset.value);
            }
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            address token = abi.decode(asset.assetType.data, (address));
            if (transferType == PROTOCOL && burnMode == true) {
                uint256 amountBurn = asset.value.mul(burningPercent).div(100);
                uint256 amountFee = asset.value.sub(amountBurn);
                if (token == luxyAddress) {
                    IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS])
                        .erc20safeTransferFrom(
                            IERC20Upgradeable(token),
                            from,
                            burningWallet,
                            asset.value
                        );
                } else {
                    IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS])
                        .erc20safeTransferFrom(
                            IERC20Upgradeable(token),
                            from,
                            feeWallet,
                            amountFee
                        );
                    if (amountBurn > 0) {
                        IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS])
                            .erc20safeTransferFrom(
                                IERC20Upgradeable(token),
                                from,
                                burningWallet,
                                amountBurn
                            );
                    }
                }
            } else {
                IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS])
                    .erc20safeTransferFrom(
                        IERC20Upgradeable(token),
                        from,
                        to,
                        asset.value
                    );
            }
        } else if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            (address token, uint256 tokenId) = abi.decode(
                asset.assetType.data,
                (address, uint256)
            );
            require(asset.value == 1, "erc721 value error");
            INftTransferProxy(proxies[LibAsset.ERC721_ASSET_CLASS])
                .erc721safeTransferFrom(
                    IERC721Upgradeable(token),
                    from,
                    to,
                    tokenId
                );
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            (address token, uint256 tokenId) = abi.decode(
                asset.assetType.data,
                (address, uint256)
            );
            INftTransferProxy(proxies[LibAsset.ERC1155_ASSET_CLASS])
                .erc1155safeTransferFrom(
                    IERC1155Upgradeable(token),
                    from,
                    to,
                    tokenId,
                    asset.value,
                    ""
                );
        } else {
            ITransferProxy(proxies[asset.assetType.assetClass]).transfer(
                asset,
                from,
                to
            );
        }
        emit Transfer(asset, from, to, transferDirection, transferType);
    }

    uint256[50] private __gap;
}