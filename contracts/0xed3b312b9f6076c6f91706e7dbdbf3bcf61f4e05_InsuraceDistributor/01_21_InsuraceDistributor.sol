// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/ICover.sol";
import "./interfaces/ICoverData.sol";
import "./interfaces/IProduct.sol";
import "./interfaces/ICoverQuotation.sol";
import "../../IDistributor.sol";
import "../AbstractDistributor.sol";

contract InsuraceDistributor is
    AbstractDistributor,
    IDistributor,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ICover public masterCover;
    ICoverData public coverData;
    IProduct public product;

    function __InsuraceDistributor_init(address _masterCover)
        public
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        masterCover = ICover(_masterCover);
        coverData = ICoverData(masterCover.data());
        product = IProduct(masterCover.product());
    }

    function getCoverCount(address _owner, bool _isActive)
        external
        view
        override
        returns (uint256)
    {
        return coverData.getCoverCount(_owner);
    }

    function getCover(
        address _owner,
        uint256 _coverId,
        bool _interfaceCompliant,
        uint256 _loopLimit
    ) external view override returns (IDistributor.Cover memory cover) {
        cover.productId = coverData.getCoverProductId(_owner, _coverId);
        (bytes32 _contractName, bytes32 _coverType, , , ) = product
            .getProductDetails(cover.productId);
        cover.coverType = _coverType;
        cover.contractName = _contractName;
        cover.coverAmount = coverData.getCoverAmount(_owner, _coverId);
        cover.currency = coverData.getCoverCurrency(_owner, _coverId);
        cover.contractAddress = 0x0000000000000000000000000000000000000000;
        cover.refAddress = 0x0000000000000000000000000000000000000000;
        cover.status = coverData.getAdjustedCoverStatus(_owner, _coverId);
        cover.expiration = coverData.getCoverEndTimestamp(_owner, _coverId);
        cover.premium = 0;

        return cover;
    }

    function getAllowance(address owner, address currency)
        public
        view
        returns (uint256)
    {
        return IERC20Upgradeable(currency).allowance(owner, address(this));
    }

    function buyCoverInsurace(IDistributor.BuyInsuraceQuote memory quote)
        external
        payable
        nonReentrant
    {
        if (quote.currency != ETH) {
            // check and receive the premium from this transaction
            require(
                IERC20Upgradeable(quote.currency).allowance(
                    _msgSender(),
                    address(this)
                ) >= quote.premium,
                "Error on BU Contract - Need premium allowance"
            );

            // transfer erc20 funds to this contract
            IERC20Upgradeable(quote.currency).safeTransferFrom(
                _msgSender(),
                address(this),
                quote.premium
            );

            // Set USDT allowance to zero
            if (
                IERC20Upgradeable(quote.currency).allowance(
                    address(this),
                    address(masterCover)
                ) == uint256(0)
            ) {
                //safe as this contract has no funds stored
                //will be called once only
                IERC20Upgradeable(quote.currency).safeApprove(
                    address(masterCover),
                    MAX_INT
                );
            }
        }
        masterCover.buyCoverV3{value: msg.value}(
            quote.products,
            quote.durationInDays,
            quote.amounts,
            quote.addresses,
            quote.premium,
            quote.refCode,
            quote.helperParameters,
            quote.securityParameters,
            quote.freeText,
            quote.v,
            quote.r,
            quote.s
        );
        emit BuyCoverEvent(
            quote.addresses[0],
            quote.products[0],
            quote.durationInDays[0],
            quote.currency,
            quote.amounts[0],
            quote.premium
        );
    }

    function getQuote(
        uint256 _sumAssured,
        uint256 _coverPeriod,
        address _contractAddress,
        address _coverAsset,
        address _nexusCoverable,
        bytes calldata _data
    ) external view override returns (IDistributor.CoverQuote memory) {
        revert(
            "Unsupported method, Isurace quotes are available at api.insurace.io"
        );
    }

    fallback() external payable {
        revert("Method does not exist!");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IDistributor).interfaceId ||
            supportsInterface(interfaceId);
    }
}