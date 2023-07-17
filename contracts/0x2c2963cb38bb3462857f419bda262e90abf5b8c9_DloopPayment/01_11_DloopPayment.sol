/**
Author: dloop ltd
Website: https://www.dloop.ch
Source Code & Licensing Agreement: https://github.com/dloop-ltd/art-payment
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./vendor/IUniswapV2Router01.sol";
import "./DloopPaymentGovernance.sol";
import "./DloopPaymentUtil.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract DloopPayment is DloopPaymentGovernance, DloopPaymentUtil {
    address
        private constant UNISWAP_ADDR = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    address
        private constant DAI_ADDR = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address
        private constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router01 private _uniswapRouter;
    address private _paymentTokenAddr;
    address private _wethAddr;
    uint256 private _weiToRefund = 0;

    mapping(uint64 => bool) _checkoutIdMap;

    event SwapParamsSet(
        address uniswapRouterAddr,
        address paymentTokenAddr,
        address wethAddr
    );

    event PaymentDone(
        uint64 indexed checkoutId,
        uint256 weiInFromBuyer,
        uint256 weiOutToUniswap,
        uint256 weiOutRefundBuyer,
        uint256 tokenInFromUniswap,
        uint256 tokenOutToDloop,
        uint256 tokenOutToArtist
    );

    event EditionBought(
        uint64 indexed artistId,
        uint64 indexed artworkId,
        uint256 indexed tokenId,
        uint64 checkoutId
    );

    constructor() public {
        setSwapParams(UNISWAP_ADDR, DAI_ADDR, WETH_ADDR);
    }

    function setSwapParams(
        address uniswapRouterAddr,
        address paymentTokenAddr,
        address wethAddr
    ) public onlyOwner {
        require(
            uniswapRouterAddr != address(0x0),
            "uniswapRouterAddr must not be 0x0"
        );
        require(
            paymentTokenAddr != address(0x0),
            "paymentTokenAddr must not be 0x0"
        );
        require(wethAddr != address(0x0), "wethAddr must not be 0x0");

        _uniswapRouter = IUniswapV2Router01(uniswapRouterAddr);
        _paymentTokenAddr = paymentTokenAddr;
        _wethAddr = wethAddr;

        emit SwapParamsSet(uniswapRouterAddr, _paymentTokenAddr, _wethAddr);
    }

    function buyEdition(
        uint64 artistId,
        uint64 artworkId,
        uint256 tokenId,
        uint64 checkoutId,
        address dloopAddress,
        uint256 dloopAmount,
        address artistAddress,
        uint256 artistAmount,
        uint256 maxEthAmount,
        uint256 expiresAt,
        bytes memory sig
    ) external payable nonReentrant whenNotPaused {
        require(artistId > 0, "artistId must be positive");
        require(artworkId > 0, "artworkId must be positive");
        require(tokenId > 0, "tokenId must be positive");
        require(checkoutId > 0, "checkoutId must be positive");
        require(dloopAddress != address(0x0), "dloopAddress must not be 0x0");
        require(dloopAmount > 0, "dloopAmount must be positive");
        require(artistAddress != address(0x0), "artistAddress must not be 0x0");
        require(artistAmount > 0, "artistAmount must be positive");
        require(maxEthAmount > 0, "maxEthAmount must be positive");
        require(maxEthAmount >= msg.value, "sent Ether exceeds maxEthAmount");
        require(msg.value > 0, "no Ether sent");
        require(expiresAt >= block.timestamp, "checkout expired");
        require(sig.length > 0, "signature missing");
        require(!_checkoutIdMap[checkoutId], "edition already bought");
        require(
            dloopAddress != artistAddress,
            "dloopAddress must not equal artistAddress"
        );

        _checkoutIdMap[checkoutId] = true;
        {
            // scope to avoid stack too deep errors

            bytes32 hash = createHash(
                artistId,
                artworkId,
                tokenId,
                checkoutId,
                dloopAddress,
                dloopAmount,
                artistAddress,
                artistAmount,
                maxEthAmount,
                expiresAt
            );

            require(
                validateSignature(hash, sig, getSigningAddress()),
                "signature invalid"
            );
        }

        uint256 totalAmount = SafeMath.add(dloopAmount, artistAmount);
        {
            // scope to avoid stack too deep errors

            exchangeEthToToken(totalAmount);

            IERC20 paymentToken = IERC20(_paymentTokenAddr);
            uint256 contractAmount = paymentToken.balanceOf(address(this));
            require(
                contractAmount >= totalAmount,
                "not enough payment tokens received"
            );

            require(
                paymentToken.transfer(artistAddress, artistAmount),
                "artistAddress payment token transfer failed"
            );
            require(
                paymentToken.transfer(dloopAddress, dloopAmount),
                "dloopAddress payment token transfer failed"
            );

            bool result = msg.sender.send(_weiToRefund);
            require(result, "Ether refund failed");
        }

        {
            // scope to avoid stack too deep errors

            uint256 weiOutToUniswap = SafeMath.sub(msg.value, _weiToRefund);

            emit PaymentDone(
                checkoutId,
                msg.value,
                weiOutToUniswap,
                _weiToRefund,
                totalAmount,
                dloopAmount,
                artistAmount
            );

            emit EditionBought(artistId, artworkId, tokenId, checkoutId);
        }
        _weiToRefund = 0; // reset the state
    }

    function isSold(uint64 checkOutId) external view returns (bool) {
        return _checkoutIdMap[checkOutId];
    }

    function getSwapParams()
        external
        view
        returns (
            address uniswapRouterAddr,
            address paymentTokenAddr,
            address wethAddr
        )
    {
        uniswapRouterAddr = address(_uniswapRouter);
        paymentTokenAddr = _paymentTokenAddr;
        wethAddr = _wethAddr;
    }

    function exchangeEthToToken(uint256 tokenAmount) private {
        _uniswapRouter.swapETHForExactTokens{value: msg.value}(
            tokenAmount,
            getPathForETHtoToken(),
            address(this),
            block.timestamp
        );
    }

    function getPathForETHtoToken() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _wethAddr;
        path[1] = _paymentTokenAddr;

        return path;
    }

    // Fallback function
    // Uniswap will refund not used Ether here.
    receive() external payable {
        _weiToRefund = msg.value;
    }
}