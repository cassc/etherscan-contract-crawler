/* Copyright (C) 2023 BrightUnion.io

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
import "./interfaces/ICover.sol";

contract NexusDistributor is
    AbstractDistributor,
    IDistributor,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using Math for uint256;

    // @dev DEPRECATED
    string public constant DEFAULT_BASE_URI =
        "https://brightunion.io/documents/nfts/nexus/cover.png";
    // @dev DEPRECATED
    uint256 public feePercentage;
    // @dev DEPRECATED
    bool public buysAllowed;
    address payable public treasury;
    // @dev DEPRECATED
    IGateway public gateway;
    IERC20Upgradeable public nxmToken;
    IWETH public wEthToken;
    // @dev DEPRECATED
    INXMaster public master;
    IWNXMToken public wnxmToken;
    address public uniswapV2Adapter;
    address public uniswapV3Adapter;
    ICover public nexusCoverContract;

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
        address _nxmTokenAddress,
        address _wnxmTokenAddress,
        address _wETHAddress,
        address payable _treasury,
        string memory _tokenName,                   // DEPRECATED
        string memory _tokenSymbol,                 // DEPRECATED
        address[] calldata _exchangeAdapters,
        address _nexusCoverContract
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init(_tokenName, _tokenSymbol);

        treasury = _treasury;
        nxmToken = IERC20Upgradeable(_nxmTokenAddress);
        wEthToken = IWETH(_wETHAddress);
        wnxmToken = IWNXMToken(_wnxmTokenAddress);
        uniswapV2Adapter = _exchangeAdapters[0];
        uniswapV3Adapter = _exchangeAdapters[1];
        nexusCoverContract = ICover(_nexusCoverContract);
        // DEPRECATED
        /*_setBaseURI(DEFAULT_BASE_URI);
        gateway = IGateway(_gatewayAddress);
        master = INXMaster(_masterAddress);*/
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
        revert("Unsupported method, must be called offchain");
    }

    function buyCover(
        BuyCoverParams memory params,
        PoolAllocationRequest[] memory poolAllocationRequests,
        bytes calldata swapData
    ) external payable nonReentrant {
        (uint256 coverPriceNXM, address assetIn, uint256 maxPriceWithFee) = _buyWNXM(swapData);

        wnxmToken.unwrap(wnxmToken.balanceOf(address(this)));
        nxmToken.approve(nexusCoverContract.getInternalContractAddress(ID.TC), coverPriceNXM);
        uint coverId = nexusCoverContract.buyCover(params, poolAllocationRequests);

        if (
            assetIn != ETH && IERC20(assetIn).balanceOf(address(this)) > 0
        ) {
            IERC20(assetIn).transfer(
                address(treasury),
                IERC20(assetIn).balanceOf(address(this))
            );
        }
        if (wEthToken.balanceOf(address(this)) > 0) {
            wEthToken.transfer(
                address(treasury),
                wEthToken.balanceOf(address(this))
            );
        }

        emit BuyCoverEvent(
            address(0),
            params.productId,
            params.period,
            assetIn,
            params.amount,
            maxPriceWithFee
        );
    }

    function _buyWNXM(
        bytes calldata data
    ) internal returns (uint256, address, uint256) {
        (
            address[] memory path,
            uint24[] memory poolFees,
            string memory exchangeVersion,
            uint256 priceInNXM,
            address asset,
            uint256 amountOut,
            uint256 maxInForSwap,
            uint256 priceWithFee
        ) = abi.decode(data, (address[], uint24[], string, uint256, address, uint256, uint256, uint256));

        address exchangeAddress = keccak256(bytes(exchangeVersion)) ==
            keccak256(bytes("V2"))
            ? uniswapV2Adapter
            : uniswapV3Adapter;

        if (asset == ETH) {
            // Wrap ETH into WETH
            wEthToken.deposit{value: msg.value}();
            wEthToken.approve(exchangeAddress, maxInForSwap);
            _swapTokenForWNXM(
                exchangeAddress,
                address(wEthToken),
                path,
                amountOut,
                maxInForSwap,
                poolFees
            );
        } else {
            IERC20(asset).transferFrom(
                _msgSender(),
                address(this),
                priceWithFee
            );
            IERC20(asset).approve(
                address(exchangeAddress),
                maxInForSwap
            );
            _swapTokenForWNXM(
                exchangeAddress,
                asset,
                path,
                amountOut,
                maxInForSwap,
                poolFees
            );
        }

        return (priceInNXM, asset, priceWithFee);
    }

    // @notice Define Dex swap method to use
    // @dev If path of intermediary tokens array is > 0, it will call multihop on dex v2 or v3
    // @dev The array of fees will be passed as it is & either be used for v3 or ignored on v2
    // @param exchangeAddress Uniswap dex address, defined on caller method, either v2 or v3
    // @param tokenIn Asset address used to buy wNXM
    // @param path Array of intermediary tokens to compleete the swap
    // @param expectedAmountOut amount expected out from swap
    // @param amountInMaximum max amount to be used for swap
    // @param poolFees Array of fees from intermediary token pools if any
    function _swapTokenForWNXM(
        address exchangeAddress,
        address tokenIn,
        address[] memory path,
        uint256 expectedAmountOut,
        uint256 amountInMaximum,
        uint24[] memory poolFees
    ) internal {
        if (path[0] != address(0)) {
            IExchangeAdapter(exchangeAddress).exactOutput(
                address(tokenIn),
                path,
                address(wnxmToken),
                address(this),
                expectedAmountOut, // Expected wNXM out froim SDK
                amountInMaximum,
                poolFees
            );
        } else {
            IExchangeAdapter(exchangeAddress).exactOutputSingle(
                address(tokenIn),
                address(wnxmToken),
                address(this),
                expectedAmountOut, // Expected wNXM out froim SDK
                amountInMaximum,
                poolFees[0]
            );
        }
    }

    // @notice Submit a claim for the cover
    // @dev Nexus V1 required
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

    function setNexusCoverAddress(address _nexusCover) external onlyOwner {
        nexusCoverContract = ICover(_nexusCover);
    }

}