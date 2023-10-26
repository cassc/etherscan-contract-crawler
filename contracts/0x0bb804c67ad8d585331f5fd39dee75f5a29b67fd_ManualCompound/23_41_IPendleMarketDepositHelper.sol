// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "../../libraries/MarketApproxLib.sol";
import "../../libraries/ActionBaseMintRedeem.sol";

interface IPendleMarketDepositHelper {
    function totalStaked(address _market) external view returns (uint256);
    function balance(address _market, address _address) external view returns (uint256);
    function depositMarket(address _market, uint256 _amount) external;
    function depositMarketFor(address _market, address _for, uint256 _amount) external;
    function withdrawMarket(address _market, uint256 _amount) external;
    function withdrawMarketWithClaim(address _market, uint256 _amount, bool _doClaim) external;
    function harvest(address _market, uint256 _minEthToRecieve) external;
    function setPoolInfo(address poolAddress, address rewarder, bool isActive) external;
    function setOperator(address _address, bool _value) external;
    function setmasterPenpie(address _masterPenpie) external;
}