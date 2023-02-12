// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IERC20TransferProxy.sol";
import "../interfaces/INftTransferProxy.sol";
import "../interfaces/ITransferProxy.sol";
import "../interfaces/ITransferExecutor.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IERC165.sol";

abstract contract TransferExecutor is Initializable, OwnableUpgradeable, ITransferExecutor {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // bitpacked storage
    struct RoyaltyInfo {
        address owner;
        uint96 percent; // 0 - 10000, where 10000 is 100%, 100 = 1%
    }

    address public nftBuyContract; // uint160
    uint48 public offerProfile; // 0 - 2000, where 2000 = 20% fees, 100 = 1%
    uint48 public unusedVar; // 0 - 2000, where 2000 = 20% fees, 100 = 1%

    uint256 public protocolFee; // value 0 - 2000, where 2000 = 20% fees, 100 = 1%

    mapping(bytes4 => address) public proxies;
    mapping(address => bool) public whitelistERC20; // whitelist of supported ERC20s
    mapping(address => RoyaltyInfo) public royaltyInfo; // mapping of NFT to their royalties

    // bitpacked 256
    address public funToken; // same as uint160
    uint48 public constant MAX_PERCENTAGE = 10000; // 10000 = 100%
    uint48 public constant MAX_PROTOCOL_FEE = 2000; // 2000 = 20%

    // bitpacked 256
    address public nftProfile; // uint160
    uint48 public profileFee; // value 0 - 2000, where 2000 = 20% fees, 100 = 1%
    uint48 public funTokenDiscount; // 0 - 10000, where 10000 = 100% discount, 100 = 1%

    address public gkContract; // uint160
    uint48 public gkFee; // 0 - 2000, where 2000 = 20% fees, 100 = 1%
    uint48 public offerGk; // 0 - 2000, where 2000 = 20% fees, 100 = 1%

    event ProxyChange(bytes4 indexed assetType, address proxy);
    event WhitelistChange(address indexed token, bool value);
    event ProtocolFeeChange(uint256 publicFee, uint48 profileFee, uint48 gkFee, uint48 offerGk, uint48 offerProfile);
    event RoyaltyInfoChange(address indexed token, address indexed owner, uint256 percent, address indexed setter);
    event FunTokenDiscount(uint48 discount);

    function __TransferExecutor_init_unchained(
        INftTransferProxy _transferProxy,
        IERC20TransferProxy _erc20TransferProxy,
        address _cryptoKittyProxy,
        address _nftBuyContract,
        address _funToken,
        uint256 _protocolFee,
        address _nftProfile,
        address _gkContract,
        address[] memory _whitelistERC20s
    ) internal {
        proxies[LibAsset.ERC20_ASSET_CLASS] = address(_erc20TransferProxy);
        proxies[LibAsset.ERC721_ASSET_CLASS] = address(_transferProxy);
        proxies[LibAsset.ERC1155_ASSET_CLASS] = address(_transferProxy);
        proxies[LibAsset.CRYPTO_KITTY] = _cryptoKittyProxy;
        nftBuyContract = _nftBuyContract;
        protocolFee = _protocolFee;
        profileFee = 50;
        funToken = _funToken;
        nftProfile = _nftProfile;
        gkContract = _gkContract;
        funTokenDiscount = 5000; // 50% discount by default

        for (uint256 i = 0; i < _whitelistERC20s.length;) {
            whitelistERC20[_whitelistERC20s[i]] = true;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev external function for admin (onlyOwner) to update royalty amount
     * @param nftContract is the ERC721/ERC1155 collection in question
     * @param recipient is where royalties are sent to
     * @param amount is the percentage of the atomic sale proceeds
     */
    function setRoyalty(
        address nftContract,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(amount <= MAX_PERCENTAGE);

        royaltyInfo[nftContract].owner = recipient;
        royaltyInfo[nftContract].percent = uint96(amount);

        emit RoyaltyInfoChange(nftContract, recipient, amount, msg.sender);
    }

    /**
     * @dev external function for owners / admins to self-set royalties for their contracts
     * @param nftContract is the ERC721/ERC1155 collection in question
     * @param recipient is where royalties are sent to
     * @param amount is the percentage of the atomic sale proceeds
     */
    function setRoyaltyOwnerAdmin(
        address nftContract,
        address recipient,
        uint256 amount
    ) external {
        require(amount <= MAX_PERCENTAGE);
        // bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;
        require(!IERC165(nftContract).supportsInterface(0x2a55205a), "!erc2981");
        require(msg.sender == IOwnable(nftContract).owner() ||
            msg.sender == IOwnable(nftContract).admin(), "!owner/!admin");

        royaltyInfo[nftContract].owner = recipient;
        royaltyInfo[nftContract].percent = uint96(amount);

        emit RoyaltyInfoChange(nftContract, recipient, amount, msg.sender);
    }

    function updateFee(ITransferExecutor.FeeType feeType, uint256 _newFee) external onlyOwner {
        require(_newFee <= MAX_PROTOCOL_FEE);

        if (feeType == FeeType.PROTOCOL_FEE) {
            protocolFee = _newFee;
        } else if (feeType == FeeType.PROFILE_FEE) {
            profileFee = uint48(_newFee);
        } else if (feeType == FeeType.GK_FEE) {
            gkFee = uint48(_newFee);
        } else if (feeType == FeeType.OFFER_GK) {
            offerGk = uint48(_newFee);
        } else if (feeType == FeeType.OFFER_PROFILE) {
            offerProfile = uint48(_newFee);
        } else {
            revert InvalidFeeType();
        }
        emit ProtocolFeeChange(protocolFee, profileFee, gkFee, offerGk, offerProfile);
    }

    function modifyWhitelist(address _token, bool _val) external onlyOwner {
        require(whitelistERC20[_token] != _val);
        whitelistERC20[_token] = _val;
        emit WhitelistChange(_token, _val);
    }

    function setTransferProxy(bytes4 assetType, address proxy) external onlyOwner {
        proxies[assetType] = proxy;
        emit ProxyChange(assetType, proxy);
    }

    // only meant to be set by owner
    function setNftProfile(address _nftProfile) external onlyOwner {
        nftProfile = _nftProfile;
    }

    function setGkContract(address _gkContract) external onlyOwner {
        gkContract = _gkContract;
    }

    function setFunTokenDiscount(uint48 _discount) external onlyOwner {
        require(_discount <= MAX_PERCENTAGE);
        funTokenDiscount = _discount;
        emit FunTokenDiscount(_discount);
    }

    function setFunToken(address _funToken) external onlyOwner {
        funToken = _funToken;
    }

    function setNftBuyContract(address _nftBuyContract) external onlyOwner {
        nftBuyContract = _nftBuyContract;
    }

    function hasNft(address nft, address user) private view returns (bool) {
        (bool success, bytes memory data) = nft.staticcall(
            abi.encodeWithSelector(bytes4(keccak256("balanceOf(address)")), user)
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256)) > 0;
    }

    /**
     * @dev internal function for transferring ETH w/ fees
     * @notice fees are being sent in addition to base ETH price
     * @param to counterparty receiving ETH for transaction
     * @param value base value of ETH in wei
     * @param validRoyalty true if singular NFT asset paired with only fungible token(s) trade
     * @param optionalNftAssets only used if validRoyalty is true, should be 1 asset => NFT collection being traded
     * @param feePercent is the percentage of the atomic sale proceeds
     */
    function transferEth(
        address to,
        uint256 value,
        bool validRoyalty,
        LibAsset.Asset[] memory optionalNftAssets,
        uint256 feePercent
    ) internal {
        uint256 royalty;

        // handle royalty
        if (validRoyalty) {
            require(optionalNftAssets.length == 1, "NFT.com: Royalty not supported for multiple NFTs");
            require(optionalNftAssets[0].assetType.assetClass == LibAsset.ERC721_ASSET_CLASS, "te !721");
            (address nftRoyalty, , ) = abi.decode(optionalNftAssets[0].assetType.data, (address, uint256, bool));

            // handle royalty
            if (royaltyInfo[nftRoyalty].owner != address(0) && royaltyInfo[nftRoyalty].percent != uint256(0)) {
                // Royalty
                royalty = (value * royaltyInfo[nftRoyalty].percent) / MAX_PERCENTAGE;

                (bool success3, ) = royaltyInfo[nftRoyalty].owner.call{ value: royalty }("");
                require(success3, "te !rty");
            }
        }

        // ETH Fee
        uint256 fee = ((value - royalty) * feePercent) / MAX_PERCENTAGE;

        (bool success1, ) = nftBuyContract.call{ value: fee }("");
        (bool success2, ) = to.call{ value: (value - royalty) - fee }("");

        require(success1 && success2, "te !eth");
    }

    /**
     * @dev multi-asset transfer function
     * @param params struct containing all necessary data for transfer
     */
    function transfer(
        TransferParams memory params
    ) internal override {
        require(nftBuyContract != address(0));
        require(params.to != address(0) && params.from != address(0));
        uint256 value;
        bool hasGK = hasNft(gkContract, params.from);
        bool hasProfile = hasNft(nftProfile, params.from);
        bool privateOffer = params.taker != address(0);

        if (privateOffer) {
            require(hasGK && hasProfile, "t !gk_nft");
        } 

        if (params.auctionType == LibSignature.AuctionType.Decreasing && params.from == msg.sender) value = params.decreasingPriceValue;
        else (value, ) = abi.decode(params.asset.data, (uint256, uint256));

        require(value != 0);

        uint256 feePercent = hasGK ?
            privateOffer ? offerGk : gkFee :
            hasProfile ?
                privateOffer ? offerProfile : profileFee :
                protocolFee;

        if (params.asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            transferEth(params.to, value, params.validRoyalty, params.optionalNftAssets, feePercent);
        } else if (params.asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            address token = abi.decode(params.asset.assetType.data, (address));
            require(whitelistERC20[token], "t !list");
            uint256 royalty;

            // handle royalty
            if (params.validRoyalty) {
                require(params.optionalNftAssets.length == 1, "t len");
                require(params.optionalNftAssets[0].assetType.assetClass == LibAsset.ERC721_ASSET_CLASS, "t !721");
                (address nftContract, , ) = abi.decode(params.optionalNftAssets[0].assetType.data, (address, uint256, bool));

                if (royaltyInfo[nftContract].owner != address(0) && royaltyInfo[nftContract].percent != uint256(0)) {
                    royalty = (value * royaltyInfo[nftContract].percent) / MAX_PERCENTAGE;

                    // Royalty
                    IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS]).erc20safeTransferFrom(
                        IERC20Upgradeable(token),
                        params.from,
                        royaltyInfo[nftContract].owner,
                        royalty
                    );
                }
            }
                        
            uint256 updatedFee = token == funToken ? ((MAX_PERCENTAGE - funTokenDiscount) * feePercent / MAX_PERCENTAGE) : feePercent;
            uint256 fee = ((value - royalty) *  updatedFee) / MAX_PERCENTAGE;
            // ERC20 Fee
            IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS]).erc20safeTransferFrom(
                IERC20Upgradeable(token),
                params.from,
                nftBuyContract,
                fee
            );

            IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS]).erc20safeTransferFrom(
                IERC20Upgradeable(token),
                params.from,
                params.to,
                (value - royalty) - fee
            );
        } else if (params.asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            (address token, uint256 tokenId, ) = abi.decode(params.asset.assetType.data, (address, uint256, bool));

            require(value == 1, "t !1");
            INftTransferProxy(proxies[LibAsset.ERC721_ASSET_CLASS]).erc721safeTransferFrom(
                IERC721Upgradeable(token),
                params.from,
                params.to,
                tokenId
            );
        } else if (params.asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            (address token, uint256 tokenId, ) = abi.decode(params.asset.assetType.data, (address, uint256, bool));
            INftTransferProxy(proxies[LibAsset.ERC1155_ASSET_CLASS]).erc1155safeTransferFrom(
                IERC1155Upgradeable(token),
                params.from,
                params.to,
                tokenId,
                value
            );
        } else {
            // non standard assets
            ITransferProxy(proxies[params.asset.assetType.assetClass]).transfer(params.asset, params.from, params.to);
        }
        emit Transfer(params.asset, params.from, params.to);
    }

    uint256[47] private __gap;
}