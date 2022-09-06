// SPDX-License-Identifier: UNLICENSED
/// @title FeeLockable
/// @notice stores the fee payee and amount, letting the owner only change it, and alows to lock them for changes
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FeeLockable is Ownable {
    uint _feeAmount = 0;
    address public feePayee;
    bool public isChangeFeeAmountDisabled = false;
    bool public isChangeFeePayeeDisabled = false;

    // Irreversible.
    function disableChangeFeeAmount() public onlyOwner {
        isChangeFeeAmountDisabled = true;
    }

    function feeAmount() public view virtual returns(uint) {
        return _feeAmount;
    }

    // Irreversible.
    function disableChangeFeePayee() public onlyOwner {
        isChangeFeePayeeDisabled = true;
    }

    function setFeeAmount(uint __feeAmount) public onlyOwner {
        require(!isChangeFeeAmountDisabled, "Disabled");
        _feeAmount = __feeAmount;
    }

    function setFeePayee(address _feePayee) public onlyOwner {
        require(!isChangeFeePayeeDisabled, "Disabled");
        feePayee = _feePayee;
    }


}