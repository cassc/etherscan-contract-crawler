// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAstroSale {
    function balanceOf(address account) external view returns (uint256);
}

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./interfaces/INFT.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTStakingPresale is
    Initializable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using Strings for uint256;
    IAstroSale private _astro;
    INFT private _rigel;
    INFT private _sirius;
    INFT private _vega;
    IERC20 private _tokenBusd;
    uint256[3] private _nftBuyPrices; //rigel - 0 //sirius - 1 //vega - 2
    address private collectorAddress; //rigel-0, sirius-1, vega-2
    bool isAstroNftNeccesary;

    struct NFTSettings {
        uint16 sold;
        uint16 total;
    }
    NFTSettings private _nftSettings;
    mapping(bytes32 => bool) private _isValidReferralId;
    bytes32[] private _allReferrals;
    mapping(bytes32 => mapping(uint256 => uint256)) totalPurchasePerLinkPerType;
    uint256[3] presaleDis; //presale discount
    mapping(uint256 => NFTSettings) private _nftInfo; // mapped to nft type
    string[3] private _baseUri;
    string private _suffix;
    uint256 private _saleEndTime;

    function initialize(
        address[6] memory addr, //nftinterface-0, busd-1, coladd-2, astrolist-3
        uint256[3] memory amounts,
        uint256[3] memory nftQuan, //rigel-0, sirius-1, vega-2
        uint256[3] memory _presaleDis,
        string[3] memory baseUri,
        string memory suffix,
        bool _isAstroNftNeccesary,
        uint256 saleEndTime
    ) public initializer {
        __Ownable_init();
        _rigel = INFT(addr[0]);
        _sirius = INFT(addr[1]);
        _vega = INFT(addr[2]);

        _tokenBusd = IERC20(addr[3]);
        collectorAddress = addr[4];
        _astro = IAstroSale(addr[5]);
        _nftInfo[0].total = uint16(nftQuan[0]);
        _nftInfo[1].total = uint16(nftQuan[1]);
        _nftInfo[2].total = uint16(nftQuan[2]);
        isAstroNftNeccesary = _isAstroNftNeccesary;
        setDiscountOnPresale(_presaleDis);
        _nftBuyPrices = amounts;
        _baseUri = baseUri;
        _suffix = suffix;
        _saleEndTime = saleEndTime;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function isEligible(address userAddress) external view returns (bool) {
        if (_astro.balanceOf(userAddress) >= 1) {
            return true;
        }
        return false;
    }

    function getPriceOfNFTs() external view returns (uint256[3] memory) {
        return _nftBuyPrices;
    }

    function getDiscountPriceOfNFTs()
        external
        view
        returns (uint256[3] memory)
    {
        return presaleDis;
    }

    function isValidReferral(bytes32 referral) external view returns (bool) {
        return _isValidReferralId[referral];
    }

    function setReferralLinks(bytes32[] memory _setRefLink) public onlyOwner {
        for (uint256 i = 0; i < _setRefLink.length; i++) {
            _isValidReferralId[_setRefLink[i]] = true;
            _allReferrals.push(_setRefLink[i]);
        }
    }

    function removeAllReferralLinks() public onlyOwner {
        for (uint256 i = 0; i < _allReferrals.length; i++) {
            _isValidReferralId[_allReferrals[i]] = false;
        }
    }

    function removeReferralLink(bytes32 link) external onlyOwner {
        require(_isValidReferralId[link], "Already removed");
        _isValidReferralId[link] = false;
    }

    function getAllReferralLinks() public view returns (bytes32[] memory) {
        return _allReferrals;
    }

    function changeAstroRestriction(bool _restriction) public onlyOwner {
        isAstroNftNeccesary = _restriction;
    }

    function setDiscountOnPresale(uint256[3] memory _presaleDis)
        public
        onlyOwner
    {
        presaleDis = _presaleDis;
    }

    function setNFTPresaleQuant(uint16[3] memory _increaseNFT)
        public
        onlyOwner
    {
        _nftInfo[0].total = _increaseNFT[0];
        _nftInfo[1].total = _increaseNFT[1];
        _nftInfo[2].total = _increaseNFT[2];
    }

    function changeCollectorAdd(address _changedAdd) public onlyOwner {
        collectorAddress = _changedAdd;
    }

    function getRefLinkPurchaseDataOfRigel(bytes32 _Link)
        external
        view
        returns (uint256)
    {
        return totalPurchasePerLinkPerType[_Link][0];
    }

    function getRefLinkPurchaseDataOfSirius(bytes32 _Link)
        external
        view
        returns (uint256)
    {
        return totalPurchasePerLinkPerType[_Link][1];
    }

    function getRefLinkPurchaseDataOfVega(bytes32 _Link)
        external
        view
        returns (uint256)
    {
        return totalPurchasePerLinkPerType[_Link][2];
    }

    function getRefLinkTotalPurchaseData(bytes32 _Link)
        public
        view
        returns (uint256)
    {
        uint256 totalSoldAllTypePerLink;
        for (uint256 j = 0; j < 3; j++) {
            totalSoldAllTypePerLink += totalPurchasePerLinkPerType[_Link][j];
        }
        return totalSoldAllTypePerLink;
    }

    function batchCreateNFTs(
        uint256 _nftType, //rigel - 0 //sirius - 1 //vega - 2
        uint256 quantity,
        bytes32 _Link
    ) external {
        require(block.timestamp < _saleEndTime, "Sale is Ended");
        uint256 balOfAstro = _astro.balanceOf(msg.sender);
        if (isAstroNftNeccesary) {
            require(balOfAstro >= 1, "Can't buy nft without Astro DNFT");
        }
        address userAddress = _msgSender();
        uint256 PriceOfOne;
        if (balOfAstro >= 1) {
            PriceOfOne = _nftBuyPrices[_nftType] - presaleDis[_nftType];
        } else {
            PriceOfOne = _nftBuyPrices[_nftType];
        }
        uint256 Price = PriceOfOne * quantity;
        _checkAndTakeToken(userAddress, Price, _nftType, quantity);

        _createNFT(userAddress, _nftType, quantity);

        _nftInfo[_nftType].sold = _nftInfo[_nftType].sold + uint16(quantity);

        if (_isValidReferralId[_Link]) {
            totalPurchasePerLinkPerType[_Link][_nftType] += quantity;
        }
    }

    function _checkAndTakeToken(
        address userAddress,
        uint256 price,
        uint256 _nftType,
        uint256 quantity
    ) internal {
        require(
            _nftInfo[_nftType].sold + quantity <= _nftInfo[_nftType].total,
            "All NFT sold"
        );
        _tokenBusd.transferFrom(userAddress, collectorAddress, price);
    }

    function _createNFT(
        address userAddress,
        uint256 _nftType,
        uint256 quantity
    ) internal {
        uint256 assignId = _nftInfo[_nftType].sold;

        for (uint256 i; i < quantity; i++) {
            assignId++;
            string memory assignURI = string(
                abi.encodePacked(
                    _baseUri[_nftType],
                    assignId.toString(),
                    _suffix
                )
            );

            if (_nftType == 0) {
                _rigel.safeMint(userAddress, assignURI);
                continue;
            }

            if (_nftType == 1) {
                _sirius.safeMint(userAddress, assignURI);
                continue;
            }

            if (_nftType == 2) {
                _vega.safeMint(userAddress, assignURI);
                continue;
            }
        }
    }

    function createNFT(uint256 _nftType, bytes32 _Link) external {
        require(block.timestamp < _saleEndTime, "Sale is Ended");

        uint256 balOfAstro = _astro.balanceOf(msg.sender);
        if (isAstroNftNeccesary) {
            require(balOfAstro >= 1, "Can't buy nft without Astro DNFT");
        }
        uint256 price;
        address userAddress = _msgSender();
        if (balOfAstro >= 1) {
            price = _nftBuyPrices[_nftType] - presaleDis[_nftType];
        } else {
            price = _nftBuyPrices[_nftType];
        }

        _checkAndTakeToken(userAddress, price, _nftType, 1);
        _createNFT(userAddress, _nftType, 1);
        _nftInfo[_nftType].sold = _nftInfo[_nftType].sold + 1;
        if (_isValidReferralId[_Link]) {
            totalPurchasePerLinkPerType[_Link][_nftType] += 1;
        }
    }

    function getNFTSold(uint256 _nftType) external view returns (uint256) {
        return _nftInfo[_nftType].sold;
    }

    function getNFTTotal(uint256 _nftType) external view returns (uint256) {
        return _nftInfo[_nftType].total;
    }

    function getTotalNFTs()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (_nftInfo[0].total, _nftInfo[1].total, _nftInfo[2].total);
    }

    function getAllNFTSold()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (_nftInfo[0].sold, _nftInfo[1].sold, _nftInfo[2].sold);
    }

    function getAllAddresses() external view returns (address[6] memory) {
        return (
            [
                address(_astro),
                address(_rigel),
                address(_sirius),
                address(_vega),
                address(_tokenBusd),
                address(collectorAddress)
            ]
        );
    }

    function getIsAstroNFTNeccesary() external view returns (bool) {
        return isAstroNftNeccesary;
    }

    function getBaseURIs() external view returns (string[3] memory) {
        return _baseUri;
    }

    function getSuffix() external view returns (string memory) {
        return _suffix;
    }

    function getNFTRemaining(uint256 _nftType) external view returns (uint256) {
        uint256 remaining = _nftInfo[_nftType].total - _nftInfo[_nftType].sold;
        return remaining;
    }

    function getSaleEndTime() external view returns (uint256) {
        return _saleEndTime;
    }

    function setAstrolistAddress(address astro) external onlyOwner {
        _astro = IAstroSale(astro);
    }

    function setRigelAddress(address rigel) external onlyOwner {
        _rigel = INFT(rigel);
    }

    function setSiriusAddress(address sirius) external onlyOwner {
        _sirius = INFT(sirius);
    }

    function setVegaAddress(address vega) external onlyOwner {
        _vega = INFT(vega);
    }

    function setERC20TokenAddress(address usdt) external onlyOwner {
        _tokenBusd = IERC20(usdt);
    }

    function setPresaleDiscount(uint256[3] memory discounts)
        external
        onlyOwner
    {
        presaleDis = discounts;
    }

    function setBaseURI(string[3] memory newURI) external onlyOwner {
        _baseUri = newURI;
    }

    function setSuffix(string memory newSuffix) external onlyOwner {
        _suffix = newSuffix;
    }

    function setBuyPrice(uint256[3] memory buyPrice) external onlyOwner {
        _nftBuyPrices = buyPrice;
    }

    function setSaleEndTime(uint256 saleEndTime) external onlyOwner {
        _saleEndTime = saleEndTime;
    }
}