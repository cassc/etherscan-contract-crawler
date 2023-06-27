// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
import {ERC20} from "ERC20.sol";
import {Owned} from "Owned.sol";
import {ERC4626} from "ERC4626.sol";
import {IBuyBack} from "IBuyBack.sol";
import {IBurner} from "IBurner.sol";
import {IVester} from "IVester.sol";
import {IGelatoTopUp} from "IGelatoTopUp.sol";
import {ICurve3Pool} from "ICurve3Pool.sol";
import {IUniFactory} from "IUniFactory.sol";
import {IUniV2} from "IUniV2.sol";
import {IUniV3} from "IUniV3.sol";
import {IUniV3_POOL} from "IUniV3Pool.sol";
import {IWETH9} from "IWETH9.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                  LIBRARIES
////////////////////////////////////////////////////////////////////////////////////////////

library BuyBackErrors {
    error NotOwner(); // 0x30cd7471
    error NotKeeper(); // 0xf512b278
    error GelatoDepositFailed(); //
}

////////////////////////////////////////////////////////////////////////////////////////////
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▓▓▓▓▓▓▓▓█▌░,,▀██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓
//    █▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓▓▓▓█▌▒▒▒▒▒░▀█▓▓▓▓▓▓▓▓▓▓▓█▓`╙█▓▓▓▓▓▓▓▓▓▓
//    █▓▓▓███████▓▓▓▓▓▓▓▓▓▓▓▓▓██████████▓▓▓▓▓▓▓▓▓▓▓▌▒▒▒▒▒▒░░██▓▓▓▓▓▓▓▓█╜░▒▒█▓▓▓▓▓▓▓▓▓▓
//    ██▓▓███████████▓▓▓█████████████████▓▓▓▓▓▓▓▓▓▓█▒▒▒▒▒▒░░░▀█▓▓▓▓▓▓█░░▒▒▒▓█▓▓▓▓▓▓▓▓▓
//    ██▓▓████████████████████████████████▓▓▓▓▓▓▓▓▓█▒▒▒▒▒▒░░░░░▀▀▀▀▀▀▀▀Ñ▄▒▒▒█▓▓▓▓▓▓▓▓▓
//    ███▓▓███████████▀▒██▌▒▀██████████▄▓▒█▓▓▓▓▓▓▓▓█░░░░░@▓██▄░░░░░░░░░░▒▓█▓▓▓▓▓▓▓▓▓▓▓
//    ▓██▓▓▓██████████▒▒▀██▒████████████████▓▓▓▓▓▓▓█▌ ░╠▒╠█████▌░░░░░░░▒▓████▓▓▓▓▓▓▓▓▓
//    ████▓▓▓████████████████████▀▀▀░░░ ░╙▀███▓▓▓▓▓█▒░░░▀▄▓██▓█▀░░░░╙╣ ░▀▓████▓▓▓▓▓▓▓▓
//    █▓▓███▓████████████████▀░░░░░░░░░░░░░░██▓▓▓▓█▀░░░░░░╙╙▀'░,▄▄╖╖▄▄▄µ▄█▄▄░▐█▓▓▓▓▓▓▓
//    ███████▓█████████████▀░▄█████▄░░░░░░░▓███▓▓▓▌░░░ `    ░╓▄██████████████▄▓▓▓▓▓▓▓▓
//    ████▓▓██████████████▌░██▓▓██▓█▄,░░░ ╙██▓█▓▓█░░░░░  ░░╓█████████████████▓█▓▓▓▓▓▓▓
//    █▒▓█▓▓▓█████████████ ░░▀▓▓██▓█▀M ░░░╢╟▀▐█▓▓▓░' ░ ░░░███╣╣▓█▓█████████▌▓▌ ╟▓▓▓▓▓▓
//    ▓█╣▓██▓████████████▒░░░░░░╜░░.░░░░░▒▓█▒░▓█▓▌ ▒▒░░ ▄████▓╣▓█╢▓██████▌╫▌▓█U░█▓▓▓▓▓
//    ▓▓█▒▓██████████████░░░░░  ░░ ░░░░░░░▓▌░░▓█▓░░░░░░▐██████████████████▓███▌ ▓█▓▓▓▓
//    ▓▓▓█▒▓████████████▌░  ░░   ░░░░░░░╙╙░░▄▓▓█▌░░░░░ ▓██████████████████████▌░▐█▓▓▓▓
//    ▓▓▓▓█▒▓███████████▒'  ░░     ░░░░g██████▓█░░░░░░░▐█████████████████████▀░  █▓▓▓▓
//    ▓╢▓▓██▒▒███████████╓  ░░      '░]██████▓▓█░ ░░░░ ░▀██████████████████▀░░  ╓▓▓▓▓▓
//    ▒╢╢╢█▓█▒▓█████████████▄,      ,▄██████▓▓▓▓▓▄╖░░ ░░░╙▀█████████████▀░g▒░,▄▄██▓▓▓▓
//    ▒╢╫╣▓███▒▓████████████████▄ ▓█████████▓▓▓▓▓▓██╙╨m▄, ░░▀██████████▄Ñ▒▄███▓▓╢▓▓▓▓▓
//    ▒╫╫██████▓█████████████████████████████▓▓▓▓█▀░░░░'⌠╙░░░▒░▀██▀▓██▀░▒▀▀████▓▓▓▓▓▓▓
//    ╢▓█████▓▀'▒▒▀████████████████████████████▓▓▓█▀░░░░░░░░░░░░░░░░░░  ░░░░░▀██▓▓▓▓▓▓
//    ▓█████▒░░░▒▒▓█▓█████████████████████████████▀░`' ░░ ░░░░░░░░░▒░░░  ░    ░▀█▓▓▓▓▓
//    ██████▄░░░░▒▒▒▀████████████▀▓███████████████▄░░  ░   ░░░░░░ ░░░░░░    ░    ▀▓╣▓▓
//    ████████W░░░░░▄█▀▀█▀▀▀███▀╙░╙████████████████▌░        ░░░░░░░░░░░░░░       ╙███
//    █████████░w░╟█▓▓▄ ░░░░░░░░░░░▓█████████████████,      ░,░ ░░░░░░░░░░░░░░ ░░  `░▀
//    █████████▄████▌▒▓▌`  ░░░░░ ░░╠██████████████████▌     ░░░  ░██░░░░░░░░░░░░░░░ ░
//    ████████████▌╙█▒╢█W  ░ ░░░ ░░░▓███████████████████╖░  ░░ ░ ░██▌░░░░░░░░░ ░░  ░░░
//    ███████████▓▄¿▐███████▄,░    ░░▀████████████████████╖░░ ░░ ░███▒░░░░░░ ░ ░░░ ░ ░
//    ███████████▌▀████▌░░ ░▀▀▓▄░░ ░░░╙█████████████████████▄,   └███▌░░░░░░░░   ░ ░░
//    ████████████░ ██▓▒▒▒▒░ ░░░╙▀▀╜░░░ ▀████████████████████░  ░j████░   ░  ░ ░░░░░░
//    ████████████░░▐█▓█▀░▒░░░░    ░ '   ▓██████████████████░ ░░░░████░░░░░░░░░ ░░ ░░░
//    ███████████▌░░  ╙▀█▓▄╓▄   ░       ╓███████████████████     ░████▌  ░  ░░░░
//    ███████████┘      ` ██████▌%▄,╓,╥╙▀▐█████████████████M      ████▌              ,
////////////////////////////////////////////////////////////////////////////////////////////
//                  BUY BACK CONTRACT
////////////////////////////////////////////////////////////////////////////////////////////

contract BuyBack is IBuyBack, Owned {
    ////////////////////////////////////////////////////////////////////////////////////////////
    //                  CONSTANTS
    ////////////////////////////////////////////////////////////////////////////////////////////
    enum AMM {
        UNIv2,
        UNIv3,
        CURVE
    }

    uint256 public constant KEEPER_MIN_ETH = 2E17;
    uint256 public constant MIN_TOPUP_ETH = 5E17;
    uint256 public constant MIN_SEND_TO_TREASURY = 1E9;
    uint256 public constant MIN_BURN = 1E22;

    /// crv pool usdc index
    int128 internal constant USDC_CRV_INDEX = 1;
    uint256 internal constant DEFAULT_DECIMALS_FACTOR = 1E18;
    uint256 internal constant BP = 1E4;

    /// Gelato addresses
    address internal constant GELATO_WALLET =
        0x2807B4aE232b624023f87d0e237A3B1bf200Fd99;
    address internal constant GELATO_KEEPER =
        0x701137e5b01c7543828DF340d05b9f9BEd277F7d;
    address internal constant GELATO_ETH =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// Gro addresses
    address public constant GRO_TREASURY =
        0x359F4fe841f246a095a82cb26F5819E10a91fe0d;
    address public constant GRO_BURNER =
        0x1F09e308bb18795f62ea7B114041E12b426b8880;
    address public constant GRO_VESTER =
        0x748218256AfE0A19a88EBEB2E0C5Ce86d2178360;

    /// token addresses
    address internal constant WETH =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address internal constant USDC =
        address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address internal constant GRO =
        address(0x3Ec8798B81485A254928B70CDA1cf0A2BB0B74D7);
    address internal constant CRV_3POOL =
        address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    ERC20 internal constant CRV_3POOL_TOKEN =
        ERC20(address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490));

    /// AMM addresses
    address internal constant THREE_POOL =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address internal constant UNI_V2 =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address internal constant UNI_V3 =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address internal constant UNI_V2_FACTORY =
        address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address internal constant USDC_ETH_V3 =
        address(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                  CONTRACT VARIABLES
    ////////////////////////////////////////////////////////////////////////////////////////////

    // keep track of the total amount of USDC
    uint256 public treasury;
    uint256 public burner;
    uint256 public keeper;

    /// Percentage division between recievers of buy back actions
    ///     denoted in BP, should add up to 100%
    struct distributionSplit {
        uint16 treasury;
        uint16 burner;
        uint16 keeper;
    }

    /// Information regarding tokens that are being used
    struct tokenData {
        address wrapped; // if 4626, address of the vault
        uint256 minSellAmount;
        AMM amm;
        uint24 fee; // amm fee, used for uniV3
    }

    // list of tokens
    address[] public tokens;
    mapping(address => tokenData) public tokenInfo;

    mapping(address => bool) public keepers;
    distributionSplit public tokenDistribution;

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                  EVENTS
    ////////////////////////////////////////////////////////////////////////////////////////////
    event LogNewTokenAdded(
        address token,
        address wrapped,
        uint256 minSellAmount,
        AMM amm,
        uint24 fee
    );
    event LogTokenRemoved(address token);
    event tokenSold(
        address token,
        uint256 amountToSell,
        uint256 amountToTreasury,
        uint256 amountToKeeper,
        uint256 amountToBurner
    );
    event TopUpKeeper(uint256 tokenAmount);
    event SendToTreasury(uint256 tokenAmount);
    event BurnTokens(uint256 tokenAmount, uint256 groAmount);
    event LogDepositReceived(address sender, uint256 value);

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                  CONSTRUCTOR
    ////////////////////////////////////////////////////////////////////////////////////////////

    constructor() Owned(msg.sender) {
        ERC20(GRO).approve(GRO_BURNER, type(uint256).max);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                  SETTERS
    ////////////////////////////////////////////////////////////////////////////////////////////

    function setKeeper(address _keeper) external {
        if (msg.sender != owner) revert BuyBackErrors.NotOwner();
        keepers[_keeper] = true;
    }

    function revokeKeeper(address _keeper) external {
        if (msg.sender != owner) revert BuyBackErrors.NotOwner();
        keepers[_keeper] = false;
    }

    /// @notice sets the distribution of tokens between treasury, burner and keeper
    /// @param _treasury percentage of tokens to be sent to treasury
    /// @param _burner percentage of tokens to be sent to burner
    /// @param _keeper percentage of tokens to be sent to keeper
    function setTokenDistribution(
        uint16 _treasury,
        uint16 _burner,
        uint16 _keeper
    ) external {
        if (msg.sender != owner) revert BuyBackErrors.NotOwner();
        tokenDistribution.treasury = _treasury;
        tokenDistribution.burner = _burner;
        tokenDistribution.keeper = _keeper;
    }

    /// @notice adds token to list of tokens that can be sold
    /// @param _token address of token to be added
    /// @param _wrapped address of wrapped token
    /// @param _minSellAmount minimum amount of token to be sold
    /// @param _amm index of AMM to be used
    /// @param _fee fee of AMM to be used
    function setToken(
        address _token,
        address _wrapped,
        uint256 _minSellAmount,
        uint8 _amm,
        uint24 _fee
    ) external {
        if (msg.sender != owner) revert BuyBackErrors.NotOwner();
        tokens.push(_token);
        AMM amm = AMM(_amm);
        tokenData memory tokenI = tokenData(
            _wrapped,
            _minSellAmount,
            amm,
            _fee
        );
        tokenInfo[_token] = tokenI;
        if (_amm == 0) {
            ERC20(_token).approve(UNI_V2, type(uint256).max);
        } else if (_amm == 1) {
            ERC20(_token).approve(UNI_V3, type(uint256).max);
        }
        emit LogNewTokenAdded(_token, _wrapped, _minSellAmount, amm, _fee);
    }

    /// @notice removes token from list of tokens that can be sold
    /// @param _token address of token to be removed
    function removeToken(address _token) external {
        if (msg.sender != owner) revert BuyBackErrors.NotOwner();

        uint256 noOfTokens = tokens.length;
        for (uint256 i = 0; i < noOfTokens; i++) {
            if (tokens[i] == _token) {
                tokens[i] = tokens[noOfTokens - 1];
                tokens.pop();
                delete tokenInfo[_token];
                emit LogTokenRemoved(_token);
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                  TRIGGERS
    ////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Iterates through tokens and returns first token that can be sold
    /// @return address of token that can be sold
    function canSellToken() public view override returns (address) {
        uint256 noOfTokens = tokens.length;
        address token;
        for (uint256 i = 0; i < noOfTokens - 1; i++) {
            token = tokens[i];
            if (
                ERC20(token).balanceOf(address(this)) >
                tokenInfo[token].minSellAmount
            ) {
                return token;
            }
        }
        return address(0);
    }

    /// @notice returns bool if the contract can send to treasury if value of USDC > MIN_SEND_TO_TREASURY
    function canSendToTreasury() public view override returns (bool) {
        if (ERC20(USDC).balanceOf(address(this)) > MIN_SEND_TO_TREASURY)
            return true;
        return false;
    }

    /// @notice returns bool if the contract can burn tokens if value of GRO denominated in USDC > MIN_BURN
    /// @return bool if the contract can burn tokens
    function canBurnTokens() public view override returns (bool) {
        if (
            getPriceV2(USDC, GRO, ERC20(USDC).balanceOf(address(this))) >
            MIN_BURN
        ) {
            return true;
        }
        return false;
    }

    /// @notice returns bool if the contract can top up keeper if gelato wallet balance < KEEPER_MIN_ETH
    /// and contract balance > MIN_TOPUP_ETH
    /// @return bool if the contract can top up keeper
    function canTopUpKeeper() public view override returns (bool) {
        if (
            IGelatoTopUp(GELATO_WALLET).userTokenBalance(
                GELATO_KEEPER,
                GELATO_ETH
            ) <
            KEEPER_MIN_ETH &&
            topUpAvailable() > MIN_TOPUP_ETH
        ) {
            return true;
        }
        return false;
    }

    /// @notice returns cumulative amount of ETH in this contract plus USDC value of keeper balance denomiated in ETH
    /// @return uint256 of ETH available to top up keeper
    function topUpAvailable() public view returns (uint256) {
        uint256 balance = address(this).balance;
        balance += getPriceV3(keeper);
        return balance;
    }

    /// @notice returns bool if the contract can buy back tokens
    /// @return tokenToSell address of token that can be sold
    /// @return canTreasury bool if contract can send to treasury
    /// @return canBurn bool if contract can burn tokens
    /// @return canTopUp bool if contract can top up keeper
    function buyBackTrigger()
        external
        view
        returns (
            address tokenToSell,
            bool canTreasury,
            bool canBurn,
            bool canTopUp
        )
    {
        tokenToSell = canSellToken();
        canTreasury = canSendToTreasury();
        canBurn = canBurnTokens();
        canTopUp = canTopUpKeeper();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                  CORE
    ////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Unwraps WETH to ETH and send it to Gelato keeper, then sets keeper storage var to 0
    function topUpKeeper() public override {
        if (msg.sender != owner || !keepers[msg.sender])
            revert BuyBackErrors.NotKeeper();
        uint256 _keeperAmount = uniV3Swap(USDC, WETH, 500, keeper, true);
        if (_keeperAmount == 0) return;
        (bool success, ) = GELATO_WALLET.call{value: _keeperAmount}(
            abi.encodeWithSignature(
                "depositFunds(address,address,uint256)",
                GELATO_KEEPER,
                GELATO_ETH,
                _keeperAmount
            )
        );
        if (!success) revert BuyBackErrors.GelatoDepositFailed();
        emit TopUpKeeper(_keeperAmount);
        keeper = 0;
    }

    /// @notice sends USDC to treasury then sets treasury storage var to 0
    function sendToTreasury() public override {
        if (msg.sender != owner || !keepers[msg.sender])
            revert BuyBackErrors.NotKeeper();
        uint256 _treasury = treasury;
        ERC20(USDC).transfer(GRO_TREASURY, _treasury);
        emit SendToTreasury(_treasury);
        treasury = 0;
    }

    /// @notice burns GRO tokens then sets burner storage var to 0
    function burnTokens() public override {
        if (msg.sender != owner || !keepers[msg.sender])
            revert BuyBackErrors.NotKeeper();
        uint256 _burner = burner;
        uint256 amount = uniV2Swap(USDC, GRO, _burner);
        IBurner(GRO_BURNER).reVest(amount);
        IVester(GRO_VESTER).exit(amount);
        emit BurnTokens(_burner, amount);
        burner = 0;
    }

    /// @notice Unwraps ERC4626 tokens to underlying asset
    /// @param _amount amount of tokens to unwrap
    /// @param _wrapper address of wrapper contract
    function _unwrapToken(
        uint256 _amount,
        address _wrapper
    ) internal returns (uint256, address) {
        ERC4626 wrapper = ERC4626(_wrapper);
        address asset = address(wrapper.asset());
        uint256 amount = wrapper.redeem(_amount, address(this), address(this));
        return (amount, asset);
    }

    /// @notice sell tokens for USDC through predefined AMM
    /// @param _token address of token to sell
    /// @param _amount amount of token to sell
    /// @param _amm AMM to use for swap
    /// @param _fee fee to use for swap
    /// @return amount of tokens received from swap
    function _sellTokens(
        address _token,
        uint256 _amount,
        AMM _amm,
        uint24 _fee
    ) internal returns (uint256 amount) {
        if (_amm == AMM.CURVE) {
            amount = curveSwap(_amount);
        } else if (_amm == AMM.UNIv2) {
            amount = uniV2Swap(_token, USDC, _amount);
        } else if (_amm == AMM.UNIv3) {
            amount = uniV3Swap(_token, USDC, _fee, _amount, false);
        }
    }

    /// @notice sell tokens for USDC and distribute to treasury, burner, keeper, and owner
    /// @param _token address of token to sell
    function sellTokens(address _token) public override {
        if (msg.sender != owner || !keepers[msg.sender])
            revert BuyBackErrors.NotKeeper();

        uint256 amountToSell = ERC20(_token).balanceOf(address(this));
        tokenData memory tokenI = tokenInfo[_token];
        if (amountToSell < tokenI.minSellAmount) return;

        address wrapper = tokenI.wrapped;
        if (wrapper != address(0))
            (amountToSell, _token) = _unwrapToken(amountToSell, wrapper);
        uint256 amount = _sellTokens(
            _token,
            amountToSell,
            tokenI.amm,
            tokenI.fee
        );
        uint256 amountToTreasury = (amount * tokenDistribution.treasury) / BP;
        uint256 amountToBurner = (amount * tokenDistribution.burner) / BP;
        uint256 amountToKeeper = amount - (amountToTreasury + amountToBurner);

        treasury += amountToTreasury;
        burner += amountToBurner;
        keeper += amountToKeeper;

        emit tokenSold(
            _token,
            amountToSell,
            amountToTreasury,
            amountToKeeper,
            amountToBurner
        );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                  UTILITY
    ////////////////////////////////////////////////////////////////////////////////////////////

    function getToken(address _token) external view returns (tokenData memory) {
        return tokenInfo[_token];
    }

    /// @notice Fetch price from Uniswap V2
    /// @param _start address of token to sell
    /// @param _end address of token to buy
    /// @param _amount amount of token to sell
    function getPriceV2(
        address _start,
        address _end,
        uint256 _amount
    ) internal view returns (uint256 price) {
        if (_amount == 0) return 0;
        address[] memory path = new address[](2);
        path[0] = _start;
        path[1] = _end;

        uint256[] memory uniSwap = IUniV2(UNI_V2).getAmountsOut(_amount, path);
        return uniSwap[uniSwap.length - 1];
    }

    /// @notice Returns the amount of ETH that can be bought with the given amount of USDC
    /// @param _amount The amount of USDC to sell for ETH
    /// @return price The amount of ETH that can be bought with the given amount of USDC
    function getPriceV3(uint256 _amount) public view returns (uint256 price) {
        (uint160 sqrtPriceX96, , , , , , ) = IUniV3_POOL(USDC_ETH_V3).slot0();
        price = ((2 ** 192 * DEFAULT_DECIMALS_FACTOR) /
            uint256(sqrtPriceX96) ** 2);
        return (_amount * 1E18) / price;
    }

    /// @notice Swap tokens on Uniswap V2
    /// @param _start address of token to sell
    /// @param _end address of token to buy
    /// @param _amount amount of token to sell
    function uniV2Swap(
        address _start,
        address _end,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == 0) return 0;
        if (ERC20(_start).allowance(address(this), UNI_V2) == 0)
            ERC20(_start).approve(UNI_V2, _amount);
        address[] memory path = new address[](2);
        path[0] = _start;
        path[1] = _end;

        uint256[] memory swap = IUniV2(UNI_V2).swapExactTokensForTokens(
            _amount,
            uint256(0),
            path,
            address(this),
            block.timestamp
        );
        return swap[1];
    }

    /// @notice Swap tokens on Uniswap V3
    /// @param _start address of token to sell
    /// @param _end address of token to buy
    /// @param _fees fees to use for swap
    /// @param _amount amount of token to sell
    /// @param _eth whether to unwrap WETH or not
    function uniV3Swap(
        address _start,
        address _end,
        uint24 _fees,
        uint256 _amount,
        bool _eth
    ) internal returns (uint256 amount) {
        if (_amount == 0) return 0;
        amount = IUniV3(UNI_V3).exactInput(
            IUniV3.ExactInputParams(
                abi.encodePacked(_start, uint24(_fees), _end),
                address(this),
                block.timestamp,
                _amount,
                uint256(1)
            )
        );
        if (_eth) {
            IWETH9(WETH).withdraw(amount);
        }
    }

    /// @notice Swap tokens on Curve
    /// @param _amount amount of token to sell
    function curveSwap(uint256 _amount) internal returns (uint256) {
        if (_amount == 0) return 0;
        ICurve3Pool(THREE_POOL).remove_liquidity_one_coin(
            _amount,
            USDC_CRV_INDEX,
            0
        );
        return ERC20(USDC).balanceOf(address(this));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                  FALLBACK
    ////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {
        emit LogDepositReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit LogDepositReceived(msg.sender, msg.value);
    }

    /// @notice This function is used to sweep any tokens that are stuck in the contract
    function sweep(address asset) external onlyOwner {
        ERC20(asset).transfer(
            msg.sender,
            ERC20(asset).balanceOf(address(this))
        );
    }
}