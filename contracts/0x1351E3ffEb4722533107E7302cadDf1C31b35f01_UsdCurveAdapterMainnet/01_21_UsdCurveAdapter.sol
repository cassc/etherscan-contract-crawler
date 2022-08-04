// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../interfaces/curve/mainnet/ICurvePoolUSD.sol";

contract UsdCurveAdapterMainnet is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using Address for address;
    using SafeERC20 for IERC20;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant curvePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant curveLp = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public wallet;
    bool public upgradeStatus;
    uint64 public slippage;

    uint64 public primaryTokenIndex;
    uint128 public liquidTokenIndex;
    
    mapping(address => uint128) public indexes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

   function initialize(address _multiSigWallet, address _liquidityHandler, uint64 _slippage) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Adapter: Not contract");
        require(_liquidityHandler.isContract(), "Adapter: Not contract");
        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(DEFAULT_ADMIN_ROLE, _liquidityHandler);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);
        wallet = _multiSigWallet;
        slippage = _slippage;

        indexes[DAI] = 0;
        indexes[USDC] = 1;
        indexes[USDT] = 2;

        liquidTokenIndex = 1;
        primaryTokenIndex = 1;
    }

    function adapterApproveAll() external onlyRole(DEFAULT_ADMIN_ROLE){
        IERC20(DAI).safeApprove(curvePool, type(uint256).max);
        IERC20(USDC).safeApprove(curvePool, type(uint256).max);
        IERC20(USDT).safeApprove(curvePool, type(uint256).max);
        IERC20(curveLp).safeApprove(curvePool, type(uint256).max);
    }

    /// @notice When called by liquidity handler, moves some funds to the Gnosis multisig and others into a LP to be kept as a 'buffer'
    /// @param _token Deposit token address (eg. USDC)
    /// @param _fullAmount Full amount deposited in 10**18 called by liquidity handler
    /// @param _leaveInPool  Amount to be left in the LP rather than be sent to the Gnosis wallet (the "buffer" amount)
    function deposit(address _token, uint256 _fullAmount, uint256 _leaveInPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 toSend = _fullAmount - _leaveInPool;
        address primaryToken = ICurvePoolUSD(curvePool).coins(primaryTokenIndex);
        if(_token == primaryToken){
            if (toSend != 0) {
                IERC20(primaryToken).safeTransfer(wallet, toSend / 10**(18 - IERC20Metadata(primaryToken).decimals()));
            }
            if (_leaveInPool != 0) {
                uint256[3] memory amounts;
                amounts[primaryTokenIndex] = _leaveInPool / 10**(18 - IERC20Metadata(primaryToken).decimals());
                ICurvePoolUSD(curvePool).add_liquidity(amounts, 0);
            }
        }
        else{
            uint256[3] memory amounts;
            amounts[indexes[_token]] = _fullAmount / 10**(18 - IERC20Metadata(_token).decimals());

            uint256 lpAmountBefore = IERC20(curveLp).balanceOf(address(this));
            ICurvePoolUSD(curvePool).add_liquidity(amounts, 0);
            uint256 delta = IERC20(curveLp).balanceOf(address(this)) - lpAmountBefore;

            delete amounts;
            if (toSend != 0) {
                toSend = toSend / 10**(18 - IERC20Metadata(primaryToken).decimals());
                amounts[primaryTokenIndex] = toSend;
                ICurvePoolUSD(curvePool).remove_liquidity_imbalance(
                            amounts, 
                            delta * (10000+slippage)/10000);
                IERC20(primaryToken).safeTransfer(wallet, toSend);
            }
        }
    } 

    /// @notice When called by liquidity handler, withdraws funds from liquidity pool
    /// @dev It checks against arbitragers attempting to exploit spreads in stablecoins. 
    /// @param _user Recipient address
    /// @param _token Deposit token address (eg. USDC)
    /// @param _amount  Amount to be withdrawn in 10*18
    function withdraw (address _user, address _token, uint256 _amount ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        
        uint256[3] memory amounts;
        address liquidToken = ICurvePoolUSD(curvePool).coins(liquidTokenIndex);
        uint256 amount = _amount / 10**(18 - IERC20Metadata(liquidToken).decimals());
        amounts[liquidTokenIndex] = amount;
        
        if(_token == liquidToken){
            ICurvePoolUSD(curvePool).remove_liquidity_imbalance(
                amounts, 
                _amount * (10000 + slippage) / 10000
            );
            IERC20(_token).safeTransfer(_user, amount);
        }
        else{
            // We want to be save agains arbitragers so at any withraw contract checks 
            // how much will be burned curveLp by withrawing this amount in token with most liquidity
            // and passes this burned amount to get tokens
            uint256 toBurn = ICurvePoolUSD(curvePool).calc_token_amount(amounts, false);
            uint256 minAmountOut = _amount / 10**(18 - IERC20Metadata(_token).decimals());
            uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
            ICurvePoolUSD(curvePool).remove_liquidity_one_coin(
                    toBurn, 
                    int128(indexes[_token]), 
                    minAmountOut * (10000 - slippage) / 10000
                );
            uint256 toUser = IERC20(_token).balanceOf(address(this)) - balanceBefore;
            IERC20(_token).safeTransfer(_user, toUser);
        }
    }
    
    function getAdapterAmount() external view returns ( uint256 ) {
        uint256 curveLpAmount = IERC20(curveLp).balanceOf((address(this)));
        if(curveLpAmount != 0){
            address liquidToken = ICurvePoolUSD(curvePool).coins(liquidTokenIndex);
            uint256 amount = ICurvePoolUSD(curvePool).calc_withdraw_one_coin(curveLpAmount, int128(liquidTokenIndex));
            return amount  * 10 **(18 - ERC20(liquidToken).decimals());
        } else {
            return 0;
        }
    }

    function getCoreTokens() external view returns (address liquidToken, address primaryToken){
        return (
            ICurvePoolUSD(curvePool).coins(liquidTokenIndex), 
            ICurvePoolUSD(curvePool).coins(primaryTokenIndex)
        );
    }

    function changeLiquidTokenIndex(uint128 _newLiquidTokenIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
        liquidTokenIndex = _newLiquidTokenIndex;
    }

    function changePrimaryTokenIndex(uint64 _newPrimaryTokenIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
        primaryTokenIndex = _newPrimaryTokenIndex;
    }


    function setSlippage(uint64 _newSlippage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        slippage = _newSlippage;
    }
    function setWallet(address _newWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wallet = _newWallet;
    }

    /**
     * @dev admin function for removing funds from contract
     * @param _address address of the token being removed
     * @param _amount amount of the token being removed
     */
    function removeTokenByAddress(address _address, address _to, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(_address).safeTransfer(_to, _amount);
    }


    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }
    
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(upgradeStatus, "Adapter: Upgrade not allowed");
        upgradeStatus = false;
    }
}