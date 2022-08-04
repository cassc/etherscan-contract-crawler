// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../interfaces/curve/mainnet/ICurvePoolEUR.sol";

contract EurCurveAdapterMainnet is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using Address for address;
    using SafeERC20 for IERC20;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public constant agEUR = 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8;
    address public constant EURT = 0xC581b735A1688071A1746c968e0798D642EDE491;
    address public constant EURS = 0xdB25f211AB05b1c97D595516F45794528a807ad8;
    address public constant curvePool = 0xb9446c4Ef5EBE66268dA6700D26f96273DE3d571;
    address public wallet;
    bool public upgradeStatus;
    uint64 public slippage;

    uint64 public primaryTokenIndex;
    uint128 public liquidTokenIndex;

    mapping(address => uint128) public indexes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // 0 = agEUR-18dec, 1 = EURT-16ec , 2 = EURS-2dec
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

        indexes[agEUR] = 0;
        indexes[EURT] = 1;
        indexes[EURS] = 2;

        liquidTokenIndex = 2;
        primaryTokenIndex = 1;
    }

    function adapterApproveAll() external onlyRole(DEFAULT_ADMIN_ROLE){
        IERC20(agEUR).safeApprove(curvePool, type(uint256).max);
        IERC20(EURT).safeApprove(curvePool, type(uint256).max);
        IERC20(EURS).safeApprove(curvePool, type(uint256).max);
        IERC20(curvePool).safeApprove(curvePool, type(uint256).max);
    }

    /// @notice When called by liquidity handler, moves some funds to the Gnosis multisig and others into a LP to be kept as a 'buffer'
    /// @param _token Deposit token address (eg. USDC)
    /// @param _fullAmount Full amount deposited in 10**18 called by liquidity handler
    /// @param _leaveInPool  Amount to be left in the LP rather than be sent to the Gnosis wallet (the "buffer" amount)
    function deposit(address _token, uint256 _fullAmount, uint256 _leaveInPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 toSend = _fullAmount - _leaveInPool;
        address primaryToken = ICurvePoolEUR(curvePool).coins(primaryTokenIndex);
        if(_token == primaryToken){
            if (toSend != 0) {
                IERC20(primaryToken).safeTransfer(wallet, toSend / 10**(18 - IERC20Metadata(primaryToken).decimals()));
            }
            if (_leaveInPool != 0) {
                uint256[3] memory amounts;
                amounts[primaryTokenIndex] = _leaveInPool / 10**(18 - IERC20Metadata(primaryToken).decimals());
                ICurvePoolEUR(curvePool).add_liquidity(amounts, 0);
            }
        }
        else{
            uint256[3] memory amounts;
            amounts[indexes[_token]] = _fullAmount / 10**(18 - IERC20Metadata(_token).decimals());

            uint256 lpAmount = ICurvePoolEUR(curvePool).add_liquidity(amounts, 0);
            delete amounts;
            if (toSend != 0) {
                toSend = toSend / 10**(18 - IERC20Metadata(primaryToken).decimals());
                amounts[primaryTokenIndex] = toSend;
                ICurvePoolEUR(curvePool).remove_liquidity_imbalance(
                            amounts, 
                            lpAmount * (10000+slippage)/10000);
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
        address liquidToken = ICurvePoolEUR(curvePool).coins(liquidTokenIndex);
        uint256 amount = _amount / 10**(18 - IERC20Metadata(liquidToken).decimals());
        amounts[liquidTokenIndex] = amount;
        
        if(_token == liquidToken){
            ICurvePoolEUR(curvePool).remove_liquidity_imbalance(
                amounts, 
                _amount * (10000 + slippage) / 10000
            );
            IERC20(_token).safeTransfer(_user, amount);
        }
        else{
            // We want to be save agains arbitragers so at any withraw contract checks 
            // how much will be burned curveLp by withrawing this amount in token with most liquidity
            // and passes this burned amount to get tokens
            uint256 toBurn = ICurvePoolEUR(curvePool).calc_token_amount(amounts, false);
            uint256 minAmountOut = _amount / 10**(18 - IERC20Metadata(_token).decimals());
            uint256 toUser = ICurvePoolEUR(curvePool).remove_liquidity_one_coin(
                    toBurn, 
                    int128(indexes[_token]), 
                    minAmountOut * (10000 - slippage) / 10000
                );
            IERC20(_token).safeTransfer(_user, toUser);
        }
    }
    

    function getAdapterAmount() external view returns ( uint256 ) {
        uint256 curveLpAmount = IERC20(curvePool).balanceOf((address(this)));
        if(curveLpAmount != 0){
            address liquidToken = ICurvePoolEUR(curvePool).coins(liquidTokenIndex);
            uint256 amount = ICurvePoolEUR(curvePool).calc_withdraw_one_coin(curveLpAmount, int128(liquidTokenIndex));
            return amount  * 10 **(18 - IERC20Metadata(liquidToken).decimals());
        } else {
            return 0;
        }
    }

    function getCoreTokens() external view returns (address liquidToken, address primaryToken){
        return (
            ICurvePoolEUR(curvePool).coins(liquidTokenIndex), 
            ICurvePoolEUR(curvePool).coins(primaryTokenIndex)
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