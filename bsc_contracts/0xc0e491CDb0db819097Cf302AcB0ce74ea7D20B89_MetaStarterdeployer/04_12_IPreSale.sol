pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

import './IBEP20.sol';
import '../Libraries/SafeMath.sol';
import '../Interfaces/IPancakeRouter02.sol';
import '../AbstractContracts/ReentrancyGuard.sol';

interface IPreSale{

    function owner() external view returns(address);
    function tokenOwner() external view returns(address);
    function deployer() external view returns(address);
    function token() external view returns(address);
    function busd() external view returns(address);

    function tokenPrice() external view returns(uint256);
    function preSaleTime() external view returns(uint256);
    function claimTime() external view returns(uint256);
    function minAmount() external view returns(uint256);
    function maxAmount() external view returns(uint256);
    function softCap() external view returns(uint256);
    function hardCap() external view returns(uint256);
    function listingPrice() external view returns(uint256);
    function liquidityPercent() external view returns(uint256);

    function allow() external view returns(bool);

    function initialize(
        address _tokenOwner,
        IBEP20 _token,
        uint256 [9] memory values,
        uint256 _adminfeePercent,
        uint256 _reffralPercent,
        uint256 _buybackPercent,
        address _routerAddress,
        uint256 _liquiditylockduration,
        IBEP20 _nativetoken
        // address _locker
    ) external ;
    function init() external ;

    
}