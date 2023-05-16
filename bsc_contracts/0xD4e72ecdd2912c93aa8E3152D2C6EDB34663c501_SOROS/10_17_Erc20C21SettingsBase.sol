// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";

contract Erc20C21SettingsBase is
Ownable
{
    // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    // 115792089237316195423570985008687907853269984665640564039457584007913129639935
    uint256 internal constant maxUint256 = type(uint256).max;
    address internal constant addressPinksaleBnbLock = address(0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE);
    address internal constant addressPinksaleEthLock = address(0x71B5759d73262FBb223956913ecF4ecC51057641);
    address internal constant addressPinksaleArbLock = address(0xeBb415084Ce323338CFD3174162964CC23753dFD);
    // address internal constant addressUnicryptLock = address(0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214);
    address internal constant addressNull = address(0x0);
    address internal constant addressDead = address(0xdead);

    //    address internal addressWrap;
    //    address internal addressLiquidity;

    //    address public addressMarketing;

    //    address public addressRewardToken;
    //    address public addressPoolToken;

    //    address internal addressWETH;

    //    address internal addressArbitrumCamelotRouter = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

    //    function setAddressMarketing(address addressMarketing_)
    //    external
    //    onlyOwner
    //    {
    //        addressMarketing = addressMarketing_;
    //    }
    //
    //    function setAddressLiquidity(address addressLiquidity_)
    //    external
    //    onlyOwner
    //    {
    //        addressLiquidity = addressLiquidity_;
    //    }
}