pragma solidity ^0.8.9;

import "../interfaces/IPosiNFTFactory.sol";
import "../interfaces/IPositionBond.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./PositionBondLending.sol";

contract PositionBondFunction is
    IPositionBondFunction,
    ReentrancyGuard,
    Ownable
{
    IPosiNFTFactory internal _posiNFTFactory =
        IPosiNFTFactory(0x9D95b5eA6C8f678B7486Be7a6331ec10A54156BD);

    IERC721 public _posiNFT =
        IERC721(0xecA16dF8D11d3a160Ff7A835A8DD91e0AE296489);

    mapping(address => address) public mappingNftToToken;

    mapping(address => bool) public whileListUnderlyingAsset;

    mapping(address => bool) public whileListFaceAsset;

    mapping(address => bytes32) public mappingKeyPriceFeed;

    function setWhileListUnderlyingAsset(address asset, bool isWhileList)
        public
        onlyOwner
    {
        whileListUnderlyingAsset[asset] = isWhileList;
    }

    function setWhileListFaceAsset(address asset, bool isWhileList)
        public
        onlyOwner
    {
        whileListFaceAsset[asset] = isWhileList;
    }

    function setMappingKeyPriceFeed(address asset, bytes32 keyPriceFeed)
        public
        onlyOwner
    {
        mappingKeyPriceFeed[asset] = keyPriceFeed;
    }

    function getPosiNFTFactory() external view override returns (address) {
        return address(_posiNFTFactory);
    }

    function updatePosiNFTFactory(address newPosiNFTFactory_) public onlyOwner {
        _posiNFTFactory = IPosiNFTFactory(newPosiNFTFactory_);
    }

    function updatePosiNFT(address newPosiNFT_) public onlyOwner {
        _posiNFT = IERC721(newPosiNFT_);
    }

    function verifyRequire(
        IPositionBondLending.BondInformation memory bondInformation,
        IPositionBondLending.AssetInformation memory assetInformation
    ) external view override returns (bool) {
        if (
            _getLengthString(bondInformation.bondName) > 30 ||
            _getLengthString(bondInformation.bondName) == 0
        ) return false;

        if (_getLengthString(bondInformation.description) > 300) return false;

        if (
            _getLengthString(bondInformation.bondSymbol) > 6 ||
            _getLengthString(bondInformation.bondSymbol) == 0
        ) return false;

        if (
            !whileListUnderlyingAsset[assetInformation.underlyingAsset] ||
            !whileListFaceAsset[assetInformation.faceAsset]
        ) return false;

        if (
            mappingKeyPriceFeed[assetInformation.underlyingAsset] !=
            assetInformation.priceFeedKeyUnderlyingAsset ||
            mappingKeyPriceFeed[assetInformation.faceAsset] !=
            assetInformation.priceFeedKeyFaceAsset
        ) return false;

        if (bondInformation.startSale < block.timestamp + 1 hours)
            return false;

        if (
            bondInformation.issuePrice == 0 ||
            assetInformation.faceValue == 0 ||
            bondInformation.bondSupply == 0 ||
            bondInformation.duration < 30
        ) return false;

        if (assetInformation.underlyingAssetType == 0) {
            return verifyRequireToken(assetInformation.collateralAmount);
        }
        if (assetInformation.underlyingAssetType == 1) {
            return verifyRequireNFT(assetInformation.nftIds);
        }
        if (assetInformation.underlyingAssetType == 2) {
            // Current not supported ethereum
            return false;
        }
        return false;
    }

    function verifyRequireToken(uint256 collateralAmount)
        public
        view
        returns (bool)
    {
        if (
            collateralAmount < 10_000 * 10**18
        ) {
            return false;
        }
        return true;
    }

    function verifyRequireNFT(uint256[] memory nftIds)
        public
        view
        returns (bool)
    {
        (bool isPass, uint256 totalParAmount) = checkNft(nftIds);

        if (!isPass) return isPass;

        if (
            nftIds.length > 30 || totalParAmount < 10_000 * 10**18
        ) {
            return false;
        }
        return true;
    }

    function getParValue(uint256[] memory nftIds)
        external
        view
        returns (uint256 totalParAmount)
    {
        for (uint256 i = 0; i < nftIds.length; i++) {
            (
                ,
                ,
                uint256 amount,
                ,
                ,
                ,
                ,
                ,
                ,
                uint256 createdTime,
                ,
                uint256 lockedDays
            ) = _posiNFTFactory.getGego(nftIds[i]);
            totalParAmount += amount;
        }
        return totalParAmount;
    }

    function checkNft(uint256[] memory nftIds)
        public
        view
        returns (bool, uint256 totalParAmount)
    {
        uint256 currentTime = _now();

        for (uint256 i = 0; i < nftIds.length; i++) {
            if (nftIds[i] <= uint256(1_000_000)) {
                return (false, 0);
            }
            (
                ,
                ,
                uint256 amount,
                ,
                ,
                ,
                ,
                ,
                ,
                uint256 createdTime,
                ,
                uint256 lockedDays
            ) = _posiNFTFactory.getGego(nftIds[i]);
            totalParAmount += amount;
            if (currentTime < createdTime + lockedDays * 1 days) {
                return (false, 0);
            }
        }
        return (true, totalParAmount);
    }

    function verifyAddCollateral(
        uint256[] memory amountTransferAdded,
        uint256 underlyingAssetType
    ) public view override returns (bool) {
        if (underlyingAssetType == 0) {
            return amountTransferAdded.length == 1;
        }
        if (underlyingAssetType == 1) {
            (bool isPass, uint256 totalPairAmount) = checkNft(
                amountTransferAdded
            );
            if (!isPass) return isPass;
        }
        return true;
    }

    function verifyRemoveCollateral(
        uint256[] memory amountTransferRemoved,
        uint256[] memory nftIds,
        uint256 underlyingAmount,
        uint256 underlyingAssetType
    ) public view override returns (uint256) {
        if (underlyingAssetType == 0) {
            return
                amountTransferRemoved.length < 1 ? 0 : amountTransferRemoved[0];
        }
        if (underlyingAssetType == 1) {
            uint256[] memory nftIdsRemoved = new uint256[](
                amountTransferRemoved.length
            );
            for (uint256 i = 0; i < amountTransferRemoved.length; i++) {
                nftIdsRemoved[i] = nftIds[amountTransferRemoved[i]];
            }
            (, uint256 totalRemove) = checkNft(nftIdsRemoved);

            return totalRemove;
        }
        return 0;
    }

    function verifyRequireEther() internal view returns (bool) {
        return false;
    }

    function getTokenMapped(address nft)
        external
        view
        override
        returns (address)
    {
        return mappingNftToToken[nft];
    }

    function setTokenMapped(address nft, address tokenMapped) external  onlyOwner{
        mappingNftToToken[nft] = tokenMapped;
    }

    function _getLengthString(string memory text)
        internal
        pure
        returns (uint256)
    {
        return bytes(text).length;
    }

    function _now() public view returns (uint256) {
        return block.timestamp;
    }
}