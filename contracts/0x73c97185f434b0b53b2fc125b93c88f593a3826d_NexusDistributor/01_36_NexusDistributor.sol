/* Copyright (C) 2022 BrightUnion.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "@openzeppelin/contracts/math/Math.sol";
import "./interfaces/IGateway.sol";
import "./interfaces/INXMaster.sol";
import "./interfaces/IQuotation.sol";
import "../../IDistributor.sol";
import "./interfaces/IQuotationData.sol";
import "../AbstractDistributor.sol";
import "./interfaces/IWNXMToken.sol";
import "./utils/NexusHelper.sol";
import "../../helpers/interfaces/IExchangeAdapter.sol";
import "../../dependencies/token/IWETH.sol";

contract NexusDistributor is
    AbstractDistributor,
    IDistributor,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using Math for uint256;

    string public constant DEFAULT_BASE_URI =
        "https://brightunion.io/documents/nfts/nexus/cover.png";
    // @dev DEPRECATED
    uint256 public feePercentage;
    // @dev DEPRECATED
    bool public buysAllowed;
    address payable public treasury;
    IGateway public gateway;
    IERC20Upgradeable public nxmToken;
    IWETH public wEthToken;
    INXMaster public master;
    IWNXMToken public wnxmToken;
    address public uniswapV2Adapter;
    address public uniswapV3Adapter;

    struct BuyCoverInfo {
        address contractAddress;
        address coverAsset;
        uint16 coverPeriod;
        uint256 sumAssured;
        uint256 coverPriceNXM;
    }

    modifier onlyTokenApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "NexusDistributor: Not approved or owner"
        );
        _;
    }

    /**
     * @dev Standard pattern of constructing proxy contracts with the same signature as the constructor.
     */
    function __NexusDistributor_init(
        address _gatewayAddress,
        address _nxmTokenAddress,
        address _masterAddress,
        address _wnxmTokenAddress,
        address _wETHAddress,
        address payable _treasury,
        string memory _tokenName,
        string memory _tokenSymbol,
        address[] calldata _exchangeAdapters
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init(_tokenName, _tokenSymbol);

        _setBaseURI(DEFAULT_BASE_URI);
        treasury = _treasury;
        gateway = IGateway(_gatewayAddress);
        nxmToken = IERC20Upgradeable(_nxmTokenAddress);
        wEthToken = IWETH(_wETHAddress);
        wnxmToken = IWNXMToken(_wnxmTokenAddress);
        master = INXMaster(_masterAddress);
        uniswapV2Adapter = _exchangeAdapters[0];
        uniswapV3Adapter = _exchangeAdapters[1];
    }

    function getCoverCount(address _owner, bool _isActive)
        external
        view
        override
        returns (uint256)
    {
        return balanceOf(_owner);
    }

    function getQuote(
        uint256 _sumAssured,
        uint256 _coverPeriod,
        address _contractAddress,
        address _coverAsset,
        address _nexusCoverable,
        bytes calldata _data
    ) external pure override returns (IDistributor.CoverQuote memory) {
        revert("Unsupported method, must be called offchain");
    }

    function getCover(
        address _owner, //not used
        uint256 _coverId,
        bool _isActive, //not used
        uint256 _loopLimit //not used
    ) external view override returns (IDistributor.Cover memory _cover) {
        (
            uint8 status,
            uint256 sumAssured, /*uint16 coverPeriod*/
            ,
            uint256 validUntil,
            address contractAddress,
            address coverAsset,
            uint256 premiumInNXM,
            address memberAddress
        ) = gateway.getCover(_coverId);
        _cover.productId = _coverId;
        _cover.coverAmount = sumAssured;
        _cover.premium = premiumInNXM;
        _cover.currency = coverAsset;
        _cover.contractAddress = contractAddress;
        _cover.expiration = validUntil;
        _cover.status = status;
        _cover.refAddress = memberAddress;
    }

    // @dev buy cover for a coverable identified by its contractAddress
    // @param contractAddress contract address of coverable
    // @param coverAsset asset of the premium and of the sum assured.
    // @param sumAssured amount payable if claim is submitted and considered valid
    // @param amountOut amount of expected wNXM out after swap
    // @param coverType cover type dermining how the data parameter is decoded
    // @param maxPriceWithFee max price (including fee) to be spent on the cover.
    // @param data abi-encoded field with additional cover data fields
    function buyCover(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint256 amountOut,
        uint16 coverPeriod,
        uint8 coverType,
        uint256 maxPriceWithFee,
        bytes calldata data
    ) external payable nonReentrant {
        // Buy wNXM with Ether or ERC20 asset
        uint256 coverPriceNXM = _buyWNXM(
            coverAsset,
            amountOut,
            maxPriceWithFee,
            data
        );
        wnxmToken.unwrap(wnxmToken.balanceOf(address(this)));
        nxmToken.approve(master.getLatestAddress("TC"), coverPriceNXM);
        BuyCoverInfo memory _buyInfo = BuyCoverInfo(
            contractAddress,
            coverAsset,
            coverPeriod,
            sumAssured,
            coverPriceNXM
        );
        // Buy nexus cover with NXM
        uint256 _coverId = _buyCover(_buyInfo, data);
        _mint(_msgSender(), _coverId);
        if (IERC20(coverAsset).balanceOf(address(this)) > 0) {
            IERC20(coverAsset).transfer(
                address(treasury),
                IERC20(coverAsset).balanceOf(address(this))
            );
        }
        if (wEthToken.balanceOf(address(this)) > 0) {
            wEthToken.transfer(
                address(treasury),
                wEthToken.balanceOf(address(this))
            );
        }

        emit BuyCoverEvent(
            contractAddress,
            coverType,
            coverPeriod,
            coverAsset,
            sumAssured,
            maxPriceWithFee
        );
    }

    /**
        @dev We avoid decoding previous variables already in memory
        @dev makeCoverUsingNXMTokens does not return a coverId as regular buy does
     */
    function _buyCover(BuyCoverInfo memory _buyInfo, bytes calldata data)
        internal
        returns (uint256 _coverId)
    {
        (
            ,
            ,
            ,
            uint256 coverPrice,
            ,
            uint256 expiresAt,
            uint256 generatedAt,
            uint8 _v,
            bytes32 _r,
            bytes32 _s
        ) = abi.decode(
                data,
                (
                    address[],
                    uint24[],
                    string,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint8,
                    bytes32,
                    bytes32
                )
            );

        uint256[] memory _coverDetails = new uint256[](5);
        _coverDetails[0] = _buyInfo.sumAssured;
        _coverDetails[1] = coverPrice;
        _coverDetails[2] = _buyInfo.coverPriceNXM;
        _coverDetails[3] = expiresAt;
        _coverDetails[4] = generatedAt;

        bytes4 _currency = address(gateway.ETH()) == _buyInfo.coverAsset
            ? bytes4("ETH")
            : bytes4("DAI");
        uint16 _coverPeriodToCover = _buyInfo.coverPeriod;
        address _contractAddressToCover = _buyInfo.contractAddress;
        IQuotation(master.getLatestAddress("QT")).makeCoverUsingNXMTokens(
            _coverDetails,
            _coverPeriodToCover,
            _currency,
            _contractAddressToCover,
            _v,
            _r,
            _s
        );

        _coverId =
            IQuotationData(master.getLatestAddress("QD")).getCoverLength() -
            1;
    }

    // @notice Internal logic to buy wNXM
    // @dev solves function stack limit of buyCover method
    // @param tokenAsset ERC20 paye to buy cover
    // @param amountOut uint256 expected amount out from SDK
    // @param maxPriceWithFee uint256 price with fee
    function _buyWNXM(
        address asset,
        uint256 amountOut,
        uint256 priceWithFee,
        bytes calldata data
    ) internal returns (uint256) {
        (
            address[] memory path,
            uint24[] memory poolFees,
            string memory exchangeVersion,
            ,
            uint256 priceInNXM
        ) = abi.decode(data, (address[], uint24[], string, uint256, uint256));

        address exchangeAddress = keccak256(bytes(exchangeVersion)) ==
            keccak256(bytes("V2"))
            ? uniswapV2Adapter
            : uniswapV3Adapter;

        uint256 expectedAmountOut = amountOut;
        uint256 maxPriceWithFee = priceWithFee;
        address tokenAssetAddress = asset;
        if (tokenAssetAddress == ETH) {
            // Wrap ETH into WETH
            wEthToken.deposit{value: msg.value}();
            wEthToken.approve(exchangeAddress, maxPriceWithFee);
            _swapTokenForWNXM(
                exchangeAddress,
                address(wEthToken),
                path,
                expectedAmountOut,
                maxPriceWithFee,
                poolFees
            );
        } else {
            IERC20(tokenAssetAddress).transferFrom(
                _msgSender(),
                address(this),
                maxPriceWithFee
            );
            IERC20(tokenAssetAddress).approve(
                address(exchangeAddress),
                maxPriceWithFee
            );
            _swapTokenForWNXM(
                exchangeAddress,
                tokenAssetAddress,
                path,
                expectedAmountOut,
                maxPriceWithFee,
                poolFees
            );
        }

        return priceInNXM;
    }

    // @notice Define Dex swap method to use
    // @dev If path of intermediary tokens array is > 0, it will call multihop on dex v2 or v3
    // @dev The array of fees will be passed as it is & either be used for v3 or ignored on v2
    // @param exchangeAddress Uniswap dex address, defined on caller method, either v2 or v3
    // @param tokenIn Asset address used to buy wNXM
    // @param path Array of intermediary tokens to compleete the swap
    // @param expectedAmountOut amount expected out from swap
    // @param maxPriceWithFee cover price with internal fee
    // @param poolFees Array of fees from intermediary token pools if any
    function _swapTokenForWNXM(
        address exchangeAddress,
        address tokenIn,
        address[] memory path,
        uint256 expectedAmountOut,
        uint256 maxPriceWithFee,
        uint24[] memory poolFees
    ) internal {
        if (path[0] != address(0)) {
            IExchangeAdapter(exchangeAddress).exactOutput(
                address(tokenIn),
                path,
                address(wnxmToken),
                address(this),
                expectedAmountOut, // Expected wNXM out froim SDK
                maxPriceWithFee, // _amountInMaximum,
                poolFees
            );
        } else {
            IExchangeAdapter(exchangeAddress).exactOutputSingle(
                address(tokenIn),
                address(wnxmToken),
                address(this),
                expectedAmountOut, // Expected wNXM out froim SDK
                maxPriceWithFee, // _amountInMaximum,
                poolFees[0]
            );
        }
    }

    // @notice Submit a claim for the cover
    // @param tokenId cover token id
    // @param data abi-encoded field with additional claim data fields
    function submitClaim(uint256 tokenId, bytes calldata data)
        external
        onlyTokenApprovedOrOwner(tokenId)
        returns (uint256)
    {
        // coverId = tokenId
        uint256 claimId = gateway.submitClaim(tokenId, data);
        emit NexusHelper.ClaimSubmitted(tokenId, claimId, _msgSender());
        return claimId;
    }

    // @notice Submit a claim for the cover
    // @param tokenId cover token id
    // @param incidentId id of the incident
    // @param coveredTokenAmount amount of yield tokens covered
    // @param coverAsset yield token that is covered
    function claimTokens(
        uint256 tokenId,
        uint256 incidentId,
        uint256 coveredTokenAmount,
        address coverAsset
    )
        external
        onlyTokenApprovedOrOwner(tokenId)
        returns (
            uint256 claimId,
            uint256 payoutAmount,
            address payoutToken
        )
    {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(coverAsset),
            _msgSender(),
            address(this),
            coveredTokenAmount
        );
        SafeERC20Upgradeable.safeApprove(
            IERC20Upgradeable(coverAsset),
            address(gateway),
            coveredTokenAmount
        );
        // coverId = tokenId
        (claimId, payoutAmount, payoutToken) = gateway.claimTokens(
            tokenId,
            incidentId,
            coveredTokenAmount,
            coverAsset
        );
        _burn(tokenId);
        if (payoutToken == ETH) {
            (
                bool ok, /* data */

            ) = address(_msgSender()).call{value: payoutAmount}("");
            require(ok, "Distributor: ETH transfer to sender failed.");
        } else {
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(payoutToken),
                _msgSender(),
                payoutAmount
            );
        }
        emit NexusHelper.ClaimSubmitted(tokenId, claimId, _msgSender());
    }

    // @notice Redeem the claim to the cover. Requires that the payout is completed.
    // @param tokenId cover token id
    function redeemClaim(uint256 tokenId, uint256 claimId)
        public
        onlyTokenApprovedOrOwner(tokenId)
        nonReentrant
    {
        require(
            gateway.getClaimCoverId(claimId) == tokenId,
            "Distributor: coverId claimId mismatch"
        );
        (
            IGateway.ClaimStatus status,
            uint256 amountPaid,
            address coverAsset
        ) = gateway.getPayoutOutcome(claimId);
        require(
            status == IGateway.ClaimStatus.ACCEPTED,
            "Distributor: Claim not accepted"
        );

        _burn(tokenId);
        if (coverAsset == ETH) {
            (
                bool ok, /* data */

            ) = _msgSender().call{value: amountPaid}("");
            require(ok, "Distributor: Transfer to NFT owner failed");
        } else {
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(coverAsset),
                _msgSender(),
                amountPaid
            );
        }

        emit NexusHelper.ClaimPayoutRedeemed(
            tokenId,
            claimId,
            _msgSender(),
            amountPaid,
            coverAsset
        );
    }

    // @notice Execute an action on specific cover token. The action is identified by an `action` id.
    //  Allows for an ETH transfer or an ERC20 transfer.
    //  If less than the supplied assetAmount is needed, it is returned to `_msgSender()`.
    // @dev The purpose of this function is future-proofing for updates to the cover buy->claim cycle.
    // @param tokenId id of the cover token
    // @param assetAmount optional asset amount to be transferred along with the action executed
    // @param asset optional asset to be transferred along with the action executed
    // @param action action identifier
    // @param data abi-encoded field with action parameters
    // @return response (abi-encoded response, amount withheld from the original asset amount supplied)

    function executeCoverAction(
        uint256 tokenId,
        uint256 assetAmount,
        address asset,
        uint8 action,
        bytes calldata data
    )
        external
        payable
        onlyTokenApprovedOrOwner(tokenId)
        nonReentrant
        returns (bytes memory response, uint256 withheldAmount)
    {
        if (assetAmount == 0) {
            return gateway.executeCoverAction(tokenId, action, data);
        }
        if (asset == ETH) {
            require(
                msg.value >= assetAmount,
                "Distributor: Insufficient ETH sent"
            );
            (response, withheldAmount) = gateway.executeCoverAction{
                value: msg.value
            }(tokenId, action, data);
            uint256 ethRemainder = assetAmount.sub(withheldAmount);
            (
                bool ok, /* data */

            ) = address(_msgSender()).call{value: ethRemainder}("");
            require(
                ok,
                "Distributor: Returning ETH remainder to sender failed."
            );
            return (response, withheldAmount);
        }
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(asset),
            _msgSender(),
            address(this),
            assetAmount
        );
        SafeERC20Upgradeable.safeApprove(
            IERC20Upgradeable(asset),
            address(gateway),
            assetAmount
        );
        (response, withheldAmount) = gateway.executeCoverAction(
            tokenId,
            action,
            data
        );
        uint256 remainder = assetAmount.sub(withheldAmount);

        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(asset),
            _msgSender(),
            remainder
        );
        return (response, withheldAmount);
    }

    /**
     * @notice Moves `amount` tokens from the distributor to `recipient`.
     * @param recipient recipient of NXM
     * @param amount amount of NXM
     */
    function withdrawNXM(address recipient, uint256 amount) public onlyOwner {
        nxmToken.transfer(recipient, amount);
    }

    // @notice Switch NexusMutual membership to `newAddress`.
    // @param newAddress address
    function switchMembership(address newAddress) external onlyOwner {
        nxmToken.approve(address(gateway), uint256(-1));
        gateway.switchMembership(newAddress);
    }

    // @notice Set treasury address where `buyCover` distributor fees and `ethOut` from `sellNXM` are sent.
    // @param _treasury new treasury address
    function setTreasuryDetails(address payable _treasury) external onlyOwner {
        treasury = _treasury;
    }

    // @dev required to be allow for receiving ETH claim payouts
    receive() external payable {}
}