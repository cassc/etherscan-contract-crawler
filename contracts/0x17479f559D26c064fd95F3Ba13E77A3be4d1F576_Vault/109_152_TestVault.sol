// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// helpers
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

// interfaces
import { IVault } from "../../interfaces/opty/IVault.sol";

contract TestVault {
    using SafeMath for uint256;

    function deposit(
        IVault _vault,
        ERC20 _token,
        uint256 _amountUT,
        bytes calldata _permit,
        bytes32[] calldata _accountsProof
    ) external {
        _token.transferFrom(msg.sender, address(this), _amountUT);
        _token.approve(address(_vault), _amountUT);
        _vault.userDepositVault(msg.sender, _amountUT, _permit, _accountsProof);
    }

    function withdraw(
        IVault _vault,
        uint256 _amountVT,
        bytes32[] calldata _accountsProof
    ) external {
        _vault.userWithdrawVault(msg.sender, _amountVT, _accountsProof);
    }

    function withdrawERC20(ERC20 _token, address _recipient) external {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }

    function withdrawETH(address payable _recipient) external {
        _recipient.transfer(payable(address(this)).balance);
    }

    function testUserDepositPermitted(
        IVault _vault,
        uint256 _valueUT,
        bytes32[] calldata _accountsProof
    ) external view returns (bool, string memory) {
        uint256 _depositFee = _vault.calcDepositFeeUT(_valueUT);
        return _vault.userDepositPermitted(address(this), true, _valueUT.sub(_depositFee), _depositFee, _accountsProof);
    }
}