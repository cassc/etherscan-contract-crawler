// SPDX-License-Identifier: MIT
/*
_____   ______________________   ____________________________   __
___  | / /__  ____/_  __ \__  | / /__  __ \__    |___  _/__  | / /
__   |/ /__  __/  _  / / /_   |/ /__  /_/ /_  /| |__  / __   |/ / 
_  /|  / _  /___  / /_/ /_  /|  / _  _, _/_  ___ |_/ /  _  /|  /  
/_/ |_/  /_____/  \____/ /_/ |_/  /_/ |_| /_/  |_/___/  /_/ |_/  
 ___________________________________________________________ 
  S Y N C R O N A U T S: The Bravest Souls in the Metaverse

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAffiliate {
    function signUpWithPromo(address _userToRegister, address _affliateOwner)
        external;

    function getAffiliateOwner(address _user) external view returns (address);

    function returnFeeAfterAffiliateAllocation(uint256 _amount)
        external
        view
        returns (uint256);

    function setHasTransacted(address _user) external;

    function splitFeeWithAffiliate(
        IERC20 _payToken,
        uint256 _feeAmount,
        address _user_to_check_affiliate,
        address _feeSender,
        address _feeReceipient,
        uint256 _maxFeeCalculation
    ) external;

    function splitFeeWithAffiliateETH(
        uint256 _feeAmount,
        address _user_to_check_affiliate,
        address _feeReceipient,
        uint256 _maxFeeCalculation
    ) external;
}