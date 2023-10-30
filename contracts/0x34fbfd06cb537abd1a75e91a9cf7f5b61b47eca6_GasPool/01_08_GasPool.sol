// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Interfaces/IGasPool.sol";
import "./Interfaces/ITHUSDToken.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";


/**
 * The purpose of this contract is to hold THUSD tokens for gas compensation:
 * https://github.com/liquity/dev#gas-compensation
 * When a borrower opens a trove, an additional 50 THUSD debt is issued,
 * and 50 THUSD is minted and sent to this contract.
 * When a borrower closes their active trove, this gas compensation is refunded:
 * 50 THUSD is burned from the this contract's balance, and the corresponding
 * 50 THUSD debt on the trove is cancelled.
 * See this issue for more context: https://github.com/liquity/dev/issues/186
 */
contract GasPool is Ownable, CheckContract, IGasPool {
    
    address public troveManagerAddress;
    ITHUSDToken public thusdToken;
    
    function setAddresses(
        address _troveManagerAddress,
        address _thusdTokenAddress
    )
        external
        onlyOwner
    {
        checkContract(_troveManagerAddress);
        checkContract(_thusdTokenAddress);

        troveManagerAddress = _troveManagerAddress;
        thusdToken = ITHUSDToken(_thusdTokenAddress);

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit THUSDTokenAddressChanged(_thusdTokenAddress);

        _renounceOwnership();
    }

    function sendTHUSD(address _account, uint256 _amount) override external {
        require(msg.sender == troveManagerAddress, "GasPool: Caller is not the TroveManager");
        require(thusdToken.transfer(_account, _amount), "GasPool: sending thUSD failed");
    }

}