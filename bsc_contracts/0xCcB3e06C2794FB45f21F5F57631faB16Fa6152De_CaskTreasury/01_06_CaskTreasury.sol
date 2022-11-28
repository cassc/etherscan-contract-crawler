// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Updated Convex TreasuryFunds (https://github.com/convex-eth/platform/blob/main/contracts/contracts/TreasuryFunds.sol)

Changes:
- update to solidity 0.8
- use openzeppelin ownable
- add claim method to get vested/rewarded tokens from contracts
*/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface IClaimable {
    function claim() external;
}

contract CaskTreasury is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    event WithdrawTo(address indexed _to, address _asset, uint256 _amount);

    function withdrawTo(
        address _to,
        address _asset,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_asset).safeTransfer(_to, _amount);
        emit WithdrawTo(_to, _asset, _amount);
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns(bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);

        return (success, result);
    }

    function claim(
        address _contract
    ) external onlyOwner {
        IClaimable(_contract).claim();
    }

}