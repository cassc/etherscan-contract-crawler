// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Token.sol";

contract Gaia is OwnableUpgradeable {
    address public tykheFortuneDistributorAddress;
    address public midasToken;
    address public routerAddress;
    address public stableCoinAddress;
    address public nativeTokenAddress;

    uint256 public chainId;
    uint256 public discountPct;
    uint256 public burnPct;
    uint256 public tokensCounter;
    uint256 public freeCreationNumber;
    uint256 private constant TAX_DIVISOR = 10000;
    uint256 public creationTokenPrice;

    bool public availableChainlinkNet;

    AggregatorV3Interface private nativeTokenOracle;

    mapping(address => address[]) private usersCreatedTokens;

    event TokenCreated(address indexed account, address _token);

    /// @custom:oz-upgrades-unsafe-allow constructor
    function initialize(
        address _tykheFortuneDistributorAddress,
        bool _availableChainlinkNet,
        address _routerAddress,
        address _nativeTokenOracle,
        address _stableCoinAddress
    ) public initializer {
        __Ownable_init();
        tykheFortuneDistributorAddress = _tykheFortuneDistributorAddress;
        discountPct = 1000;
        tokensCounter = 0;
        creationTokenPrice = 100000000000000000000; // 100$
        availableChainlinkNet = _availableChainlinkNet;

        chainId = block.chainid;
        
        routerAddress = _routerAddress;
        nativeTokenOracle = AggregatorV3Interface(_nativeTokenOracle);
        stableCoinAddress = _stableCoinAddress;
        nativeTokenAddress = getNativeTokenAddress();
        freeCreationNumber = 25;
    }

    receive() external payable {}

    function setFreeCreationNumber(uint256 _freeCreationNumber) public onlyOwner {
        freeCreationNumber = _freeCreationNumber;
    }

    function setRouterAddress(address _routerAddress) public onlyOwner {
        routerAddress = _routerAddress;
    }

    function setTokenAddress(address _midasToken) public onlyOwner {
        midasToken = _midasToken;
    }

    function setDiscountPct(uint256 _discountPct) public onlyOwner {
        discountPct = _discountPct;
    }

    function setBurnPct(uint256 _burnPct) public onlyOwner {
        burnPct = _burnPct;
    }

    function getUserCreatedTokens(
        address account
    ) public view returns (address[] memory) {
        return usersCreatedTokens[account];
    }

    function setStableCoinAddress(address token) public onlyOwner {
        stableCoinAddress = token;
    }

    function getStableCoinAddress() public view returns (address) {
        return stableCoinAddress;
    }

    function transferNative(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function createToken(
        address tokenOwner,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supply,
        address _routerAddress
    ) internal {
        Token token = new Token(
            tokenOwner,
            tokenName,
            tokenSymbol,
            supply,
            _routerAddress
        );
        usersCreatedTokens[tokenOwner].push(address(token));
        tokensCounter++;
        emit TokenCreated(tokenOwner, address(token));
    }

    // return the route given the busd addresses and the token
    function pathTokensForTokens(
        address add1,
        address add2
    ) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = add1;
        path[1] = add2;
        return path;
    }

    // return amount of tokenA needed to buy 1 tokenB
    function estimatedTokensForTokens(
        address add1,
        address add2,
        uint256 amount
    ) public view returns (uint256) {
        uint256[] memory amountsOut;
        address[] memory path = pathTokensForTokens(add1, add2);

        bytes4 methodGetAmountsOut = bytes4(
            keccak256(bytes("getAmountsOut(uint256,address[])"))
        );
        (bool amountsOutSuccess, bytes memory data) = routerAddress.staticcall(
            abi.encodeWithSelector(methodGetAmountsOut, amount, path)
        );
        if (amountsOutSuccess) {
            amountsOut = abi.decode(data, (uint256[]));
        }

        return amountsOut[1];
    }

    function getLastPrice() internal view returns (uint256) {
        (, int256 price, , , ) = nativeTokenOracle.latestRoundData();
        return uint256(price);
    }

    function getNativeNetworkCurrencyPriceInUsd()
        public
        view
        returns (uint256)
    {
        return getLastPrice();
    }

    function getRequiredEthAmount() public view returns (uint256) {
        uint256 nativeTokenPrice;

        // contract need know if user are using network available on chainlink
        // for get native crypto price from chainlink or from router pool
        if (availableChainlinkNet) {
            nativeTokenPrice = uint256(
                this.getNativeNetworkCurrencyPriceInUsd()
            );
        } else {
            // get price from router pool
            nativeTokenPrice = estimatedTokensForTokens(
                nativeTokenAddress,
                this.getStableCoinAddress(),
                1 ether
            );
        }
        return (creationTokenPrice / nativeTokenPrice) * 1e8;
    }

    function swapNativeForTokens(
        address token,
        address to,
        uint256 amount
    ) public payable {
        address[] memory path = pathTokensForTokens(nativeTokenAddress, token);

        string
            memory methodName = "swapExactETHForTokens(uint256,address[],address,uint256)";

        if (chainId == 43114) {
            methodName = "swapExactAVAXForTokens(uint256,address[],address,uint256)";
        }

        (bool success, ) = routerAddress.call{value: amount}(
            abi.encodeWithSelector(
                bytes4(keccak256(bytes(methodName))),
                0,
                path,
                to,
                block.timestamp + 20000
            )
        );

        require(success, "Error: swapNativeForTokens");
    }

    function createNewTokenWithNative(
        address tokenOwner,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supply,
        bool autoSwap
    ) public payable {
        if (tokensCounter >= freeCreationNumber) {
            uint256 requiredAmount = getRequiredEthAmount();

            // if user use autoSwap, the contract will swap native currency
            // for midas tokens
            if (autoSwap) {
                requiredAmount -= (requiredAmount * discountPct) / TAX_DIVISOR;
                // swap native tokens to midas tokens
                swapNativeForTokens(midasToken, address(this), requiredAmount);

                // get contract midas balance
                uint256 midasTokenBalance = IERC20(midasToken).balanceOf(
                    address(this)
                );

                // calc burn amount
                uint256 burnAmount = (midasTokenBalance * burnPct) /
                    TAX_DIVISOR;

                ERC20Burnable(midasToken).burn(burnAmount);
                ERC20(midasToken).transfer(
                    tykheFortuneDistributorAddress,
                    midasTokenBalance - burnAmount
                );
            }
            // transfer team fees and create token
            require(msg.value >= requiredAmount, "low value");
            transferNative(tykheFortuneDistributorAddress, msg.value);
        }
        createToken(tokenOwner, tokenName, tokenSymbol, supply, routerAddress);
    }

    function getMinimunTokenAmount(
        address tokenAddress
    ) public view returns (uint256) {
        return
            estimatedTokensForTokens( //cambiando el orden de los address me devuelve lo que coincide con pancake en testnet
                nativeTokenAddress, //segundo
                tokenAddress, //primero
                getRequiredEthAmount()
            );
    }

    function createNewTokenWithTokens(
        address paymentTokenAddress,
        address tokenOwner,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supply
    ) public {
        if (tokensCounter >= freeCreationNumber) {
            // get minimum tokens required for pay fees
            uint256 requiredAmount = getMinimunTokenAmount(paymentTokenAddress);

            // check if user are using midas token and apply discount
            if (paymentTokenAddress == midasToken) {
                requiredAmount -= (requiredAmount * discountPct) / TAX_DIVISOR;
            }

            // transfer tokens from user to contract
            IERC20(paymentTokenAddress).transferFrom(
                msg.sender,
                address(this),
                requiredAmount
            );

            swapTokensForNative(
                paymentTokenAddress,
                tykheFortuneDistributorAddress,
                requiredAmount
            );
        }

        createToken(tokenOwner, tokenName, tokenSymbol, supply, routerAddress);
    }

    function getNativeTokenAddress() public view returns (address) {
        string memory methodName = "WETH()";

        if (chainId == 43114) {
            methodName = "WAVAX()";
        }

        (bool success, bytes memory data) = routerAddress.staticcall(
            abi.encodeWithSelector(bytes4(keccak256(bytes(methodName))))
        );
        require(success, "Error: getNativeTokenAddress");
        return abi.decode(data, (address));
    }

    function swapTokensForNative(
        address paymentTokenAddress,
        address to,
        uint256 amount
    ) private {
        address[] memory path = pathTokensForTokens(
            paymentTokenAddress,
            nativeTokenAddress
        );

        string
            memory methodName = "swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)";

        if (chainId == 43114) {
            methodName = "swapExactTokensForAVAXSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)";
        }

        IERC20(paymentTokenAddress).approve(routerAddress, type(uint256).max);

        (bool success, ) = routerAddress.call(
            abi.encodeWithSelector(
                bytes4(keccak256(bytes(methodName))),
                amount,
                0,
                path,
                to,
                block.timestamp + 20000
            )
        );
        require(success, "Error: swapTokensForNative");
    }
}