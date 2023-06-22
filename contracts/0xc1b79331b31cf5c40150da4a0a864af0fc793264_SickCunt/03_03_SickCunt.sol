pragma solidity ^0.8.13;
// SPDX-License-Identifier: ZYZZ LICENSED (UNLICENSED)

//                                 *((///(*
//                                 /,,*,#(/
//                                (,,,*#*,
//                               (,,,/(*,
//                             (/,,,,,,,
//                      #&%(%&&,,,,,,,,
//                     ((##%*##*,,,,,*
//                    ****#%,(&(,,,,,
//                     ,,,,,**,,,,,,,,     *#
//                    .,,,,,.,,,,///*,,,******
//                    %*.....,,,,,,,,,,
//                  %%%%#**,,,,,.
//                /%%%%%#//,,*
//               %%%%%##//,**
//             *&&&&&%#(/*(*
//            &&&&&&##(/***
//           @&&&&%#(//***
//          @&&&%##(//*///
//         &&&&%##(/(//**/                                  #         /&
//       &&&&&%%####(****                                     (%%&&&&&&@@&%
//      %%%%%%%##((******                                       /#,(%%(%&&&&%
//      #%%%%#((//**,,,*                                          ,,,,*(#&&%&@&,
//      ###((((((/*,,,,                                              **///*(&&@@@&%
//     /#((((##(//*,,,                                               /%/,,*((%&@@@&&
//     (%&%(((#%%#*,*,                         &&& ,* ,              ***,,*/#%#%@@@@&&#
//    (#%&&&&&&&%#%&(                        @@%(*****,***/(**/*    *,,,,, ,/%%%%&@@@@@&#
//    *(#%&&&&%&&&&&&&%                    /*(*,*(%%%%#/,..,**,,*             (##%&&@@@@@&%
//     (##%%&&&&&&&&%#%%                   ,,%&&&#**/(#%%#/*.,,,**              #%%&&&@@@@&&&.
//     ((##%%&%%%%%%%%###                 /(#*#%#/(/#(#%(##*,,,,,*               /%%&&@@@@@@&%&/
//    ,((##########%%%##((               /,#&&#/#&&&&&&%%#/*,.,,,,                ,#%&&&&&&&%%%#%
//    ,############%%%##((              (&#%&&#%&&@@@&%%%(**..,..,*                /(##%%%&%#######
//    (##%%%%########%%(/*             #%##%%%&&&%&&&&%%(*,....,,,*                 **/(#%##%&#(####
//     (###############(**             #(((//(((###%%%###/*,...,,,*                  ///(####(((%####/
//     */(########(###(**(%&          ./..,,,,,,,,,*/////*,,*...,.,*                  (((//##((((((####
//      */(((######((((/#%%&&@%       *,,,.,,,,,,,.....,,.......,,,*                  (///////(%##(((((
//      *,**//((#####//(&&&&%&&&&      ,,,,,.....,,,..,,,,,.....,*,                   #(///////((##(/**
//       *,,,**/(####%#%&@&&&&&&&%     ((,,,/#%#(//**,,,,,....,,,*             %%%%%%#(((//((###(/*,,,*
//         ,,**/((#%##%%&@@@&&%%%##   (%%%%##(/(((((##(/*,.,,,,,*          %%%#%%&%####(##%%###/*,,,,*/
//          ,,/(##((###%&&@@@&&&%%#(((##%%&%%%%##((##(/**,.....         .#%###%#%&%(#%#%(/((/,,,,,,,,
//           */((##(#&#%%&&&&&&&&&%%###%&&&&%%%%#&%#(//*,,...*       %%#%%##((/(#%#%#(//(**,...,,,*
//            /(&&&&&##%%&&&&&&&&&&&%%%&&&%###%&%(((//*/***   ##%#%%#(#((#((//(##((/(//*,,.,..,,,*
//           &%&@@@%#(##%%&&&&&&&@&@&&&%%&%#%%&%#(((//(((%(%####&##((/(///*(((//#(//(**,...,,,,,
//           %%&@&%%#(###%%&&&&&&&&&&&&%%#%%&&&&&&&&&&&&&##%#%%%#%((/*(####/(((//((/*,,,..,,,,,
//          (##&&&&&%(####%%%&&&&&%%%#####%&&&&&&&&&&&&&&&&%%%%%#((/,.##(*****//***,.....,,,*
//          ###%%%&%%###%%%%%#%%&&&%%%%##&&%%%&&&&&&&&&&%%%%%#/***....,,,,,..,..,........,
//           (#%%%%%%####%%%%##%%%%%%%#%&&&&&&&&%&&&%%%%%%##((/*,.....,////,,,........,
//           (#%%%%&%%#####%%%%%%%%%%%%&&&&&&&&&&%%%%%####(((/**,.,..,#/,.........,
//           ##%&&&%%##(/(##%%%%&&&&%%%&%&&&&&%%%%#%#####((//*,..,**#%#/*.....,
//           /#%&&&%%%#///##%%%%%&&&%%%%%%&&%%%#####(((((((//*,,,*/(###/*,,,
//           /###%#%%%%%#####%%%%%%%%#%%%%%%%#####((/////(///*,,,(#((//**/
//           *(#%%#(#%%%###########((####%%%#####(((***//((/*,,,(#(///*,*
//            (/(#%%##%%%##((###%#/*(((#####%#####((((((((////((#(//*,,*
//            /((/(((((##%%&%((//((%&%%(%%#########(((##(((((((///*,,,,
//            */(##(#%&%###%&&&&&@@&@@@&(((##%%%%##(#((*,*///*****,,,
//             (,//((##%%%#%%%%&&&&&&@&&&&&&%#((////***((((//*****,
//             ((#%#(##(##((##%%#(/(##%%########((((##(/*******,,*
//              //((((//(#%%%%%##((#(##%###(((//(((((/*,,.....,,,
//             .///(((//########((####%%%%%##((//****/////*,..,,
//             .//*/////((////((((#((((((####((((//////**,,,..*
//              *//*,,,//**///***///**,****///(//****,********
//              .,,**,,,***(##(((/((((####(/****,,,((/*******
//               ,,***,,,**//((((((((((((((((/***///*****////
//               ,*****,,,,,,*///((///*/*///*/*********////((
//                *****,,,,,,.,***/****///*,,,,*****///((((###
//                ******,,,**/(((##((((((((((//////((((/(((###(
//                ****///*,,/*/(((((*((#(((/////*//////(((((((/
//                ,****//*,,,***/(((((/(///******///////(((//**
//                 *******,,*,,**//////*,,,***//(((/((/*********
//                ./,,,*///*,,***********/*//*///////////*///*/(,
//               ,/((((**////*,******////////*/////(///*/((//////
//             ,,(#((((((/*/((/***********/*///(((/////##(((////%/,
//           ,...,/#%&&%##/**/(/*/////////*////////*(##%#((##((&/**
//          ....,,,,///(%&&&(**((//*//*/////////*,/##%%%#(((&&(**.,,
//          ......,****/**//**/((//************.,(##((//*///*,**,,,,,
//          ,.......*////*/,/***/**//***,*////*////*///******,******,,
//         ,..........,//**///*,.**,//.****/////*///////(/*//////....,
//        ... ...........*/*,*//*,///**/*/////////**,.**,**..,*,.. .,,
//    .(*.....      ............,///*.,./****,.   ....,,*/,  .  ...,.
//      ,*,....        .  ...    ...         ............... .......
//      *,*/,...                            .....   .....  .        .
//    /((/*.,/**/*                 .,       .....   .            ....
//   /(/////*.    .                                          .......
//  */////****,.                                           ... .....

import "./Owned.sol";
import "./ERC20.sol";

contract SickCunt is ERC20, Owned {
    /*/////////////////////////////////////////////////
                      ERRORS + EVENTS
    /////////////////////////////////////////////////*/

    event TaxPaused(bool paused);
    event TaxTimeSet(uint256 startTime, uint256 endTime);

    /*/////////////////////////////////////////////////
                            STATE 
    /////////////////////////////////////////////////*/

    /// @notice tax percent (x 100). MK677 doesn't pay for itself
    uint256 public constant taxPct = 500;

    /// @notice Gotta tip the plug brah
    address public MK677_PLUG;

    /// @notice whitelist for tax avoiding senders
    mapping(address => bool) noTaxWhitelisted;

    /// @notice start time of tax period
    uint256 public startTime;

    /// @notice end time of tax period
    uint256 public endTime;

    /// @notice Flag to pause tax during tax period
    bool public taxActive;

    constructor(
        uint256 _totalSuply,
        address _owner,
        address _tax_receiver
    ) Owned(_owner) {
        /// only time _mint is called
        _mint(_owner, _totalSuply);

        taxActive = true;
        owner = _owner;
        MK677_PLUG = _tax_receiver;

        /// initial tax period is 1 hour post deployment
        _setTaxTime(block.timestamp, block.timestamp + 1 hours);

        /// initial tax free sender whitelist
        noTaxWhitelisted[_owner] = true;
        noTaxWhitelisted[_tax_receiver] = true;
    }

    /*//////////////////////////////////////////////////////////////
                             ERC20 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Name of the token.
    function name() public pure override returns (string memory) {
        return "Sick Cunt Money";
    }

    /// @notice Symbol of the token.
    function symbol() public pure override returns (string memory) {
        return "SIKCNT";
    }

    /**
     * @notice Custom implementation of transfer function accounting for tax
     * @dev THIS SPECIFIC IMPLEMENTATION IS MORE GAS WITH SOLADY THAN SOLMATE BUT WE MUST USE SOLADY
     * IF YOU ARENT USING CUSTOM LOGIC, WHY ARENT YOU USING SOLADY?
     * @param to Address to credit tokens
     * @param amount Amount of tokens to transfer
     */
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 taxAmount = calculateTax(amount, to);
        _transfer(msg.sender, to, amount - taxAmount);

        if (taxAmount > 0) {
            _transfer(msg.sender, MK677_PLUG, taxAmount);
        }
        return true;
    }

    /**
     * @notice Cusotm implementation of transferFrom function accounting for tax
     * @dev THIS SPECIFIC IMPLEMENTATION IS MORE GAS WITH SOLADY THAN SOLMATE BUT WE MUST USE SOLADY
     * IF YOU ARENT USING CUSTOM LOGIC, WHY ARENT YOU USING SOLADY?
     * @param from Account sending tokens
     * @param to Account receiving tokens
     * @param amount Amount of tokens to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 _allowance = allowance(from, msg.sender);
        if (amount > _allowance) revert InsufficientAllowance();

        uint256 taxAmount = calculateTax(amount, to);
        _transfer(from, to, amount - taxAmount);

        if (taxAmount > 0) {
            _transfer(from, MK677_PLUG, taxAmount);
        }
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function pauseTax(bool paused) external onlyOwner {
        taxActive = !paused;
        emit TaxPaused(paused);
    }

    function setTaxTime(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        _setTaxTime(_startTime, _endTime);
    }

    function toggleNoTaxWhitelist(
        address account,
        bool taxFree
    ) external onlyOwner {
        noTaxWhitelisted[account] = taxFree;
    }

    function changeTaxReceiver(address newReceiver) external onlyOwner {
        MK677_PLUG = newReceiver;
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _setTaxTime(uint256 _startTime, uint256 _endTime) internal {
        if (block.timestamp > _endTime) revert("bad time range");
        if (_startTime > _endTime) revert("bad time range");

        startTime = _startTime;
        endTime = _endTime;

        emit TaxTimeSet(_startTime, _endTime);
    }

    function inTimeRange() internal view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function calculateTax(
        uint256 amount,
        address to
    ) internal view returns (uint256 taxAmount) {
        if (
            taxActive &&
            inTimeRange() &&
            !noTaxWhitelisted[msg.sender] &&
            !noTaxWhitelisted[to]
        ) {
            taxAmount = (amount * taxPct) / 10000;
        }
    }
}
