// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./IERC20.sol";

interface ICrowdSaleMinimalProxy {
    
    function init(
        IERC20 _tokenAddress,
        IERC20[] calldata _inputToken,
        uint256 _amount,
        uint256[] calldata _rate,
        bytes memory _crowdsaleTimings,
        bytes memory _whitelist,
        address _owner        
    ) external;

}