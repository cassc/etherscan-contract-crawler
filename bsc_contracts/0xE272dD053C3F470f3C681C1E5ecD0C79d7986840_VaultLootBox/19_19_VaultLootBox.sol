// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IPegSwap.sol";

contract VaultLootBox is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Chainlink data
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 subscriptionId;

    IERC20Upgradeable public busd;
    IERC20Upgradeable public paymentToken;
    IERC20Upgradeable public pegToken;
    IERC20Upgradeable public link;
    IPancakeRouter02 public router;
    IPancakeFactory public factory;
    IPegSwap public pegSwapContract;

    uint256 public percentageToLink;
    uint256 public percentageToGQ;
    IERC20Upgradeable public gqToken;

    address public recipient;

    event SwapPaymentToken(uint256 amount, uint256 timestamp);
    event SwapBUSDToPegToken(uint256 amount, uint256 timestamp);
    event SwapPegTokenToLiquidityLink(uint256 amount, uint256 timestamp);
    event SwapBUSDToGQToken(uint256 amount, uint256 timestamp);

    constructor() initializer {}

    /// @notice This function initializes data for proxy
    /// @param _busd Interface to interact with BUSD token
    /// @param _paymentToken Interface to interact with the payment token
    function initialize(
        IERC20Upgradeable _busd,
        IERC20Upgradeable _paymentToken,
        IPancakeRouter02 _router,
        IPancakeFactory _factory,
        IERC20Upgradeable _pegToken,
        IERC20Upgradeable _gqToken,
        IERC20Upgradeable _link,
        IPegSwap _pegSwapContract,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        address _recipient
    ) public initializer {
        __AccessControl_init();
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(address(_link));
        busd = _busd;
        paymentToken = _paymentToken;
        router = _router;
        factory = _factory;
        pegToken = _pegToken;
        gqToken = _gqToken;
        link = _link;
        pegSwapContract = _pegSwapContract;
        subscriptionId = _subscriptionId;
        percentageToLink = 1000;
        percentageToGQ = 1000;
        recipient = _recipient;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    function setPercentageToLink(uint256 _percentageToLink)
        external
        onlyRole(MANAGER_ROLE)
    {
        percentageToLink = _percentageToLink;
    }

    function setGQToken(IERC20Upgradeable _gqToken)
        external
        onlyRole(MANAGER_ROLE)
    {
        gqToken = _gqToken;
    }

    function setPercentageToGQ(uint256 _percentageToGQ)
        external
        onlyRole(MANAGER_ROLE)
    {
        percentageToGQ = _percentageToGQ;
    }

    function withdraw() public onlyRole(MANAGER_ROLE) {
        address pair = factory.getPair(address(busd), address(gqToken));
        IERC20Upgradeable(pair).safeTransfer(
            recipient,
            IERC20Upgradeable(pair).balanceOf(address(this))
        );
        busd.safeTransfer(recipient, busd.balanceOf(address(this)));
        link.safeTransfer(recipient, link.balanceOf(address(this)));
    }

    function swapAndRefund() external onlyRole(MANAGER_ROLE) {
        require(
            paymentToken.balanceOf(address(this)) > 0 ||
                busd.balanceOf(address(this)) > 0,
            "Not balance"
        );
        _swapPaymentTokenToBUSD();
        _swapBUSDToPegToken();
        _swapPegTokenToLiquidityLink();
        _feedConsumer();
        _swapBUSDToGQTokenAndAddLiq();
        withdraw();
    }

    function _swapPaymentTokenToBUSD() internal {
        if (paymentToken.balanceOf(address(this)) > 0) {
            address[] memory path = new address[](2);
            path[0] = address(paymentToken);
            path[1] = address(busd);
            uint256[] memory minAmounts = router.getAmountsOut(
                (paymentToken.balanceOf(address(this)) * 3500) / 10000,
                path
            );
            paymentToken.approve(
                address(router),
                paymentToken.balanceOf(address(this))
            );
            router.swapExactTokensForTokens(
                ((paymentToken.balanceOf(address(this))) * 3500) / 10000,
                minAmounts[1],
                path,
                address(this),
                block.timestamp
            );
            emit SwapPaymentToken(minAmounts[1], block.timestamp);
        }
    }

    function _swapBUSDToPegToken() internal {
        if (busd.balanceOf(address(this)) > 0) {
            address[] memory path = new address[](2);
            path[0] = address(busd);
            path[1] = address(pegToken);
            uint256 quantityToLink = (busd.balanceOf(address(this)) *
                percentageToLink) / 10000;
            uint256[] memory minAmounts = router.getAmountsOut(
                quantityToLink,
                path
            );
            busd.approve(address(router), busd.balanceOf(address(this)));
            router.swapExactTokensForTokens(
                quantityToLink,
                minAmounts[1],
                path,
                address(this),
                block.timestamp
            );
            emit SwapBUSDToPegToken(minAmounts[1], block.timestamp);
        }
    }

    function _swapPegTokenToLiquidityLink() internal {
        if (pegToken.balanceOf(address(this)) > 0) {
            address[] memory path = new address[](2);
            path[0] = address(pegToken);
            path[1] = address(link);
            pegToken.approve(
                address(pegSwapContract),
                pegToken.balanceOf(address(this))
            );
            pegSwapContract.swap(
                pegToken.balanceOf(address(this)),
                address(pegToken),
                address(link)
            );
            emit SwapPegTokenToLiquidityLink(
                link.balanceOf(address(this)),
                block.timestamp
            );
        }
    }

    function _feedConsumer() internal {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            IERC20Upgradeable(link).balanceOf(address(this)),
            abi.encode(subscriptionId)
        );
    }

    function _swapBUSDToGQTokenAndAddLiq() internal {
        address[] memory path = new address[](2);
        path[0] = address(busd);
        path[1] = address(gqToken);
        uint256 quantityBUSDToGQ = (busd.balanceOf(address(this)) *
            percentageToGQ) / 10000;
        uint256[] memory minAmounts = router.getAmountsOut(
            quantityBUSDToGQ,
            path
        );
        busd.approve(address(router), busd.balanceOf(address(this)));
        router.swapExactTokensForTokens(
            quantityBUSDToGQ,
            minAmounts[1],
            path,
            address(this),
            block.timestamp
        );
        emit SwapBUSDToGQToken(minAmounts[1], block.timestamp);

        uint256 quantityGQ = gqToken.balanceOf(address(this));
        uint256 minQuantityBUSDtoGQ = (quantityBUSDToGQ * 9500) / 10000;
        uint256 minQuantityGQ = (quantityGQ * 9500) / 10000;

        busd.approve(address(router), busd.balanceOf(address(this)));
        gqToken.approve(address(router), gqToken.balanceOf(address(this)));
        router.addLiquidity(
            address(busd),
            address(gqToken),
            quantityBUSDToGQ,
            quantityGQ,
            minQuantityBUSDtoGQ,
            minQuantityGQ,
            address(this),
            block.timestamp
        );
    }
}