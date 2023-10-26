// SPDX-License-Identifier: MIT
/*
                                           +##*:                                          
                                         .######-                                         
                                        .########-                                        
                                        *#########.                                       
                                       :##########+                                       
                                       *###########.                                      
                                      :############=                                      
                   *###################################################.                  
                   :##################################################=                   
                    .################################################-                    
                     .*#############################################-                     
                       =##########################################*.                      
                        :########################################=                        
                          -####################################=                          
                            -################################+.                           
               =##########################################################*               
               .##########################################################-               
                .*#######################################################:                
                  =####################################################*.                 
                   .*#################################################-                   
                     -##############################################=                     
                       -##########################################=.                      
                         :+####################################*-                         
           *###################################################################:          
           =##################################################################*           
            :################################################################=            
              =############################################################*.             
               .*#########################################################-               
                 :*#####################################################-                 
                   .=################################################+:                   
                      -+##########################################*-.                     
     .+*****************###########################################################*:     
      +############################################################################*.     
       :##########################################################################=       
         -######################################################################+.        
           -##################################################################+.          
             -*#############################################################=             
               :=########################################################+:               
                  :=##################################################+-                  
                     .-+##########################################*=:                     
                         .:=*################################*+-.                         
                              .:-=+*##################*+=-:.                              
                                     .:=*#########+-.                                     
                                         .+####*:                                         
                                           .*#:    */
pragma solidity 0.8.18;

import {BaseProtocolProxy} from "../base/BaseProtocolProxy.sol";
import {IInvest} from "../interfaces/Invest/IInvest.sol";
import {ISDai} from "../interfaces/Invest/ISDai.sol";
import {ILido} from "../interfaces/Invest/ILido.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {IWstETH} from "../interfaces/Invest/IWstETH.sol";

/**
 * @title Invest proxy contract
 * @author Pino development team
 * @notice Interacts with Lido and SavingsDai
 */
contract Invest is IInvest, BaseProtocolProxy {
    address public immutable dai;
    ISDai public immutable sdai;
    ILido public immutable steth;
    IWstETH public immutable wsteth;

    /**
     * @notice Lido proxy contract
     * @param _permit2 Permit2 contract address
     * @param _weth WETH9 contract address
     * @param _stETH StETH contract address
     * @param _wstETH WstETH contract address
     * @param _sDai Savings Dai contract address
     */
    constructor(address _permit2, address _weth, ILido _stETH, IWstETH _wstETH, ISDai _sDai)
        payable
        BaseProtocolProxy(_permit2, _weth)
    {
        sdai = _sDai;
        steth = _stETH;
        wsteth = _wstETH;
        dai = _sDai.dai();
    }

    /**
     * @notice Sends ETH to the Lido protocol and transfers ST_ETH to the recipient
     * @param _proxyFeeInWei Fee of the proxy contract
     * @param _recipient The destination address that will receive ST_ETH
     * @return stethAmount Amount of ST_ETH token that is being transferred to the recipient
     */
    function ethToStETH(address _recipient, uint256 _proxyFeeInWei)
        external
        payable
        nonETHReuse
        returns (uint256 stethAmount)
    {
        address _steth = address(steth);

        // Get StETH by paying ETH
        stethAmount = ILido(_steth).submit{value: msg.value - _proxyFeeInWei}(msg.sender);

        // Recipient receives StETH shares
        sweepStETH(_recipient);

        emit Deposit(msg.sender, _recipient, ETH, _steth, msg.value - _proxyFeeInWei);
    }

    /**
     * @notice Converts ETH to WST_ETH and transfers WST_ETH to the recipient
     * @param _proxyFeeInWei Fee of the proxy contract
     * @param _recipient The destination address that will receive WST_ETH
     */
    function ethToWstETH(address _recipient, uint256 _proxyFeeInWei) external payable nonETHReuse {
        address _wsteth = address(wsteth);

        // Get WstETH by paying ETH
        _sendETH(_wsteth, msg.value - _proxyFeeInWei);

        // Recipient receives WstETH shares
        sweepToken(IWstETH(_wsteth), _recipient);

        emit Deposit(msg.sender, _recipient, ETH, _wsteth, msg.value - _proxyFeeInWei);
    }

    /**
     * @notice Submits WETH to Lido protocol and transfers ST_ETH to the recipient
     * @param _amount Amount of WETH to submit to ST_ETH contract
     * @param _recipient The destination address that will receive ST_ETH
     * @dev For security reasons, it is not possible to run functions
     * inside of this function separately through a multicall
     * @return stethAmount Amount of ST_ETH token that is being transferred to msg.sender
     */
    function wethToStETH(uint256 _amount, address _recipient)
        external
        payable
        nonETHReuse
        returns (uint256 stethAmount)
    {
        address _weth = address(weth);
        address _steth = address(steth);

        // StETH works with ETH, so WETH needs to be unwrapped
        IWETH9(_weth).withdraw(_amount);

        // Get StETH by paying ETH
        stethAmount = ILido(_steth).submit{value: _amount}(msg.sender);

        // Recipient receives StETH shares
        sweepStETH(_recipient);

        emit Deposit(msg.sender, _recipient, _weth, _steth, _amount);
    }

    /**
     * @notice Submits WETH to Lido protocol and transfers WST_ETH to msg.sender
     * @param _amount Amount of WETH to submit to get WST_ETH
     * @param _recipient The destination address that will receive WST_ETH
     */
    function wethToWstETH(uint256 _amount, address _recipient) external payable nonETHReuse {
        address _weth = address(weth);
        address _wsteth = address(wsteth);

        // WstETH works with ETH, so WETH needs to be unwrapped
        IWETH9(_weth).withdraw(_amount);

        // Get WstETH by paying ETH
        _sendETH(_wsteth, _amount);

        // Recipient receives WstETH
        sweepToken(IWstETH(_wsteth), _recipient);

        emit Deposit(msg.sender, _recipient, _weth, _wsteth, _amount);
    }

    /**
     * @notice Wraps ST_ETH to WST_ETH and transfers it to msg.sender
     * @param _amount Amount to convert to WST_ETH
     * @param _recipient The destination address that will receive WST_ETH
     * @return wrapped The amount of wrapped WstETH token
     */
    function stETHToWstETH(uint256 _amount, address _recipient) external payable returns (uint256 wrapped) {
        address _wsteth = address(wsteth);

        // Uses StETH shares of the proxy to get WstETH
        wrapped = IWstETH(_wsteth).wrap(_amount);

        // Recipient receives WstETH
        sweepToken(IWstETH(wsteth), _recipient);

        emit Deposit(msg.sender, _recipient, address(steth), _wsteth, _amount);
    }

    /**
     * @notice Unwraps WST_ETH to ST_ETH and transfers it to the recipient
     * @param _amount Amount of WstETH to unwrap
     * @param _recipient The destination address that will receive StETH
     * @return unwrapped The amount of StETH unwrapped
     */
    function wstETHToStETH(uint256 _amount, address _recipient) external payable returns (uint256 unwrapped) {
        address _wsteth = address(wsteth);

        // Uses WstETH in the proxy contract to get StETH
        unwrapped = IWstETH(_wsteth).unwrap(_amount);

        // Recipient receives StETH
        sweepStETH(_recipient);

        emit Deposit(msg.sender, _recipient, _wsteth, address(steth), _amount);
    }

    /**
     * @notice Transfers DAI to SavingsDai and transfers SDai to the recipient
     * @param _amount Amount of DAI to deposit
     * @param _recipient The destination address that will receive SDAI
     * @return deposited Returns the amount of shares that recipient received after deposit
     */
    function daiToSDai(uint256 _amount, address _recipient) external payable returns (uint256 deposited) {
        address _sdai = address(sdai);

        // Uses the DAI inside the proxy contract to get SDAI
        deposited = ISDai(_sdai).deposit(_amount, _recipient);

        emit Deposit(msg.sender, _recipient, address(dai), _sdai, _amount);
    }

    /**
     * @notice Transfers SDAI to SavingsDai and transfers Dai to the recipient
     * @param _amount Amount of SDAI to withdraw
     * @param _recipient The destination address that will receive DAI
     * @return withdrew Returns the amount of shares that were burned
     */
    function sDaiToDai(uint256 _amount, address _recipient) external payable returns (uint256 withdrew) {
        address _sdai = address(sdai);

        // Uses SDAI token inside the proxy contract to get DAI
        withdrew = ISDai(_sdai).withdraw(_amount, _recipient, address(this));

        emit Deposit(msg.sender, _recipient, _sdai, address(dai), _amount);
    }

    /**
     * @notice Sweeps all ST_ETH tokens of the contract based on shares to msg.sender
     * @dev This function uses sharesOf instead of balanceOf to transfer 100% of tokens
     */
    function sweepStETH(address _recipient) internal {
        // Recipient receives StETH shares
        steth.transferShares(_recipient, steth.sharesOf(address(this)));
    }
}