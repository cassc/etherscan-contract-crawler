// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/INFT.sol";
import "../interfaces/IMarketplace.sol";
import "../interfaces/ISaleToken.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable, IMarketplace, ReentrancyGuard {
    event KangaPOSAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event NFTSTypeForSaleDataUpdated(
        string membershipType,
        uint256 quantity,
        bool isEnabled,
        uint256 price,
        uint256 validity
    );

    event NFTSold(
        address indexed to,
        uint256 nftId,
        string membershipType,
        uint256 membershipTypeSerialId,
        uint256 price
    );

    event BETokenBought(address indexed to, uint256 tokenAmount, uint256 exchangedTokenAmount);

    struct NFTTypeSaleData {
        uint256 quantity;
        bool isEnabled;
        uint256 price;
        uint256 validity;
    }

    mapping(string => NFTTypeSaleData) public nftsSaleDataByType;

    uint256 private constant _INITIAL_BE_PRICE = 1 ether;
    uint256 public marketplaceSaleUnlock = 1670922000;

    INFT private _nftContract;
    ISaleToken private _tokenContract;
    IERC20 private _usdtContract;
    address private _kangaPOS;

    modifier marketplaceSaleGuard() {
        require(block.timestamp >= marketplaceSaleUnlock, "Marketplace: The sale is not unlocked yet");
        _;
    }

    constructor(
        address beTokenAddress,
        address nftContract,
        address usdtTokenAddress
    ) {
        _nftContract = INFT(nftContract);
        _tokenContract = ISaleToken(beTokenAddress);
        _usdtContract = IERC20(usdtTokenAddress);
    }

    function setMarketplaceUnlockTime(uint256 unlockTime) external onlyOwner {
        marketplaceSaleUnlock = unlockTime;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Token: ownership renounce not allowed");
    }

    function setKangaPOSAddress(address kangaPOS) external onlyOwner {
        address previousAddress = _kangaPOS;

        _kangaPOS = kangaPOS;

        emit KangaPOSAddressUpdated(previousAddress, kangaPOS);
    }

    function remainingTokenSupply() external view returns (uint256) {
        return _tokenContract.balanceOf(address(this));
    }

    function buyToken(uint256 amount) external nonReentrant marketplaceSaleGuard {
        require(_tokenContract.balanceOf(address(this)) >= amount, "Marketplace: Not enough token supply for the sale");

        address caller = _msgSender();
        uint256 exchangedAmount = _beTokensPriceInUSDT(amount);

        _usdtContract.transferFrom(caller, owner(), exchangedAmount);
        _tokenContract.transfer(caller, amount);

        emit BETokenBought(caller, amount, exchangedAmount);
    }

    function upsertNFTSaleTypeData(
        string memory membershipType,
        uint256 quantity,
        bool isEnabled,
        uint256 price,
        uint256 validity
    ) external onlyOwner {
        require(validity == 0 || validity >= 1 hours, "Marketplace: NFT validity should be at least 1 hour");

        nftsSaleDataByType[membershipType] = NFTTypeSaleData({
            quantity: quantity,
            isEnabled: isEnabled,
            price: price,
            validity: validity
        });

        emit NFTSTypeForSaleDataUpdated(membershipType, quantity, isEnabled, price, validity);
    }

    function _remainingNFTSupplyByType(string memory membershipType) internal view returns (uint256) {
        uint256 soldNfts = _nftContract.soldNftsByDataType(membershipType);
        uint256 nftSupply = nftsSaleDataByType[membershipType].quantity;

        if (nftSupply >= soldNfts) {
            return nftSupply - soldNfts;
        } else {
            return 0;
        }
    }

    function remainingNFTSupplyByType(string memory membershipType) external view returns (uint256) {
        if (nftsSaleDataByType[membershipType].isEnabled) {
            return _remainingNFTSupplyByType(membershipType);
        } else {
            return 0;
        }
    }

    function _beTokenPrice() internal view returns (uint256) {
        uint256 currentRound = _tokenContract.currentRound();

        if (currentRound <= 1) {
            return _INITIAL_BE_PRICE;
        }

        return (_INITIAL_BE_PRICE * (105**(currentRound - 1))) / (100**(currentRound - 1));
    }

    function _beTokensPriceInUSDT(uint256 amount) internal view returns (uint256) {
      return SafeMath.div(SafeMath.div(SafeMath.mul(amount, _beTokenPrice()), 1 ether), 10 ** 12);
    }

    function beTokensPriceInUSDT(uint256 amount) external view returns (uint256) {
        return _beTokensPriceInUSDT(amount);
    }

    function buyNFT(string memory membershipType) external nonReentrant marketplaceSaleGuard {
        require(_kangaPOS != address(0), "Marketplace: kangaPOS has to be set before lunching the NFT sale");
        require(
            nftsSaleDataByType[membershipType].isEnabled,
            "Marketplace: specified membership type NFT is not for sale"
        );
        require(
            _remainingNFTSupplyByType(membershipType) > 0,
            "Marketplace: no NFT supply for specified membership type"
        );

        address caller = _msgSender();
        NFTTypeSaleData memory dataType = nftsSaleDataByType[membershipType];

        uint256 nftPrice = dataType.price;
        uint256 burnableAmount = SafeMath.div(SafeMath.mul(nftPrice, 19), 20);
        uint256 posReward = nftPrice - burnableAmount;

        /**
         * First burn the 95% of the amount and transfer rest to contract address
         */
        _tokenContract.burnFrom(caller, burnableAmount);

        /**
         * Transfer reward with allowance to kangaPOS
         */
        _tokenContract.transferFrom(caller, _kangaPOS, posReward);

        /**
         * Mint a NFT to an address and store the change
         */
        (uint256 nftId, uint256 membershipTypeSerialId) = _nftContract.mintNFT(
            caller,
            membershipType,
            dataType.validity
        );

        emit NFTSold(caller, nftId, membershipType, membershipTypeSerialId, nftPrice);
    }
}