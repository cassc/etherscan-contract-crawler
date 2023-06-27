// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IWGFeeDistributor.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract WayGateRoyalties is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IERC20Upgradeable wayGateToken;

    enum NftType {
        TYPE_NULL,
        TYPE_2D,
        TYPE_3D
    }
    NftType nftType;

    enum SaleTypeChoice {
        NotOnSale,
        onAuction,
        OnfixedPrice
    }

    enum NftTokenType {
        simpleNFT,
        specialNFT,
        airdropNFT
    }

    enum SaleTokenType {
        nativeBlockchainToken,
        utilityWayGateToken
    }

    struct NFTDetails {
        uint256 bidAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 tokenId;
        uint256 price;
        uint256 copies;
        address seller;
        address hostContract;
        address bidderAddress;
        NftType nftTypeStatus;
        SaleTypeChoice saleStatus;
        SaleTokenType saleTokenType;
        NftTokenType nftTokenTypeStatus;
    }

    uint256 airdropHolder2DPercentage;
    uint256 airdropHolder3DPercentage;

    address feeDistributorAddress;
    address platformFeeReceiver;

    mapping(address => bool) exists;

    mapping(bytes32 => NFTDetails) nftListingIdDetail;

    event RoyaltiesTransfer(uint256, uint256, uint256, uint256);

    event PartnersFeeTransferred(
        uint256 partnersLength,
        uint256 feePerPartner,
        uint256 totalPartnerFee
    );

    modifier onlyFeeDistributor() {
        require(
            _msgSender() == feeDistributorAddress,
            "WayGate: OnlyFeeDistributor"
        );
        _;
    }

    function initialize() public virtual onlyInitializing {
        __Ownable_init();
    }

    function setPlatformFeeReceiverAddress(
        address _platformFeeReceiver
    ) external onlyOwner {
        platformFeeReceiver = _platformFeeReceiver;
    }

    function setWayGateDistrubutorAddress(
        address _feeDistributorAddress
    ) external onlyOwner {
        feeDistributorAddress = _feeDistributorAddress;
    }

    function setAirdropHolderReceivingPercentage(
        uint256 _airdropHolder2DPercentage,
        uint256 _airdropHolder3DPercentage
    ) external onlyOwner {
        airdropHolder2DPercentage = _airdropHolder2DPercentage;
        airdropHolder3DPercentage = _airdropHolder3DPercentage;
    }

    function _royaltyAndWayGateNFTFee(
        bytes32 _nftListingIdHash,
        uint _nftPrice,
        uint royaltyAmount,
        address payable minterAddress,
        address payable nftSeller,
        uint256 serviceFee
    ) internal {
        uint _totalNftPrice = _nftPrice;
        uint _WayGateFee = _calculateWayGateFee(
            _nftListingIdHash,
            _nftPrice,
            serviceFee
        );

        uint _airdropFee = _calculateAirdropFee(_nftListingIdHash, _nftPrice);

        _transferAmountToMinter(
            _nftListingIdHash,
            royaltyAmount,
            minterAddress
        );
        _totalNftPrice =
            _totalNftPrice -
            (_WayGateFee + _airdropFee + royaltyAmount);
        _transferAmountToSeller(_nftListingIdHash, _totalNftPrice, nftSeller);
        emit RoyaltiesTransfer(
            _WayGateFee,
            _airdropFee,
            royaltyAmount,
            _totalNftPrice
        );
    }

    function _calculateWayGateFee(
        bytes32 _nftListingIdHash,
        uint price,
        uint256 serviceFee
    ) internal returns (uint) {
        uint WayGateAmount = (price * serviceFee) / 1000;
        _transferAmountToPlatform(_nftListingIdHash, WayGateAmount);
        return WayGateAmount;
    }

    function _calculateAirdropFee(
        bytes32 _nftListingIdHash,
        uint price
    ) internal returns (uint) {
        uint airdropAmount;
        if (
            nftListingIdDetail[_nftListingIdHash].nftTypeStatus ==
            NftType.TYPE_2D
        ) {
            airdropAmount = (price * airdropHolder2DPercentage) / 1000;
            _transferAmountToAirdropHolders(_nftListingIdHash, airdropAmount);
        } else {
            airdropAmount = (price * airdropHolder3DPercentage) / 1000;
            _transferAmountToAirdropHolders(_nftListingIdHash, airdropAmount);
        }
        return airdropAmount;
    }

    function _transferAmountToSeller(
        bytes32 _nftListingIdHash,
        uint256 amount,
        address payable seller
    ) internal {
        if (
            nftListingIdDetail[_nftListingIdHash].saleTokenType !=
            SaleTokenType.utilityWayGateToken
        ) {
            payable(seller).transfer(amount);
        } else {
            wayGateToken.transfer(seller, amount);
        }
    }

    function _transferAmountToMinter(
        bytes32 _nftListingIdHash,
        uint256 _royaltyAmount,
        address payable _minterAddress
    ) internal {
        if (
            nftListingIdDetail[_nftListingIdHash].saleTokenType !=
            SaleTokenType.utilityWayGateToken
        ) {
            payable(_minterAddress).transfer(_royaltyAmount);
        } else {
            wayGateToken.transfer(_minterAddress, _royaltyAmount);
        }
    }

    function _transferAmountToPlatform(
        bytes32 _nftListingIdHash,
        uint256 platformFormFee
    ) internal {
        if (
            nftListingIdDetail[_nftListingIdHash].saleTokenType !=
            SaleTokenType.utilityWayGateToken
        ) {
            payable(platformFeeReceiver).transfer(platformFormFee);
        } else {
            wayGateToken.transfer(feeDistributorAddress, platformFormFee);
        }
    }

    function _transferAmountToAirdropHolders(
        bytes32 _nftListingIdHash,
        uint airdropAmount
    ) internal {
        require(
            feeDistributorAddress != address(0),
            "WayGate Royalties: Set Airdrop Fee Distributor Address"
        );
        if (
            nftListingIdDetail[_nftListingIdHash].saleTokenType !=
            SaleTokenType.utilityWayGateToken
        ) {
            (bool success, ) = payable(feeDistributorAddress).call{
                value: airdropAmount
            }("");
        } else {
            wayGateToken.transfer(feeDistributorAddress, airdropAmount);
        }
    }

    function setWayGateToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "address invalid");
        wayGateToken = IERC20Upgradeable(_tokenAddress);
    }

    function getAllowance() public view returns (uint256) {
        return wayGateToken.allowance(msg.sender, address(this));
    }

    function getContractWatGateTokenBalance()
        external
        view
        onlyOwner
        returns (uint256)
    {
        return wayGateToken.balanceOf(address(this));
    }

    function getUserWayGateTokenBalance() external view returns (uint256) {
        return wayGateToken.balanceOf(msg.sender);
    }

    function getWayGateTokenAddress()
        external
        view
        returns (IERC20Upgradeable)
    {
        return wayGateToken;
    }

    function getwayGatePlatformFeeReceiver() external view returns (address) {
        return platformFeeReceiver;
    }
}