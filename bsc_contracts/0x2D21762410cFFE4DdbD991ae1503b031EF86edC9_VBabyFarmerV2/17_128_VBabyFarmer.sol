// SPDX-License-Identifier: MIT

pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IVBabyOwner.sol';
import '../interfaces/IMasterChef.sol';
import '../interfaces/IBabyToken.sol';

contract VBabyFarmer is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IBabyToken;

    uint constant public PERCENT_BASE = 1e6;

    IMasterChef immutable public masterChef;
    IBabyToken immutable public babyToken;
    IVBabyOwner immutable public vBabyOwner;
    mapping(address => bool) public operators;

    modifier onlyOperator() {
        require(operators[msg.sender], "only the operator can do this");
        _;
    }

    constructor(IMasterChef _masterChef, IVBabyOwner _vBabyOwner) {
        masterChef = _masterChef;
        vBabyOwner = _vBabyOwner;
        babyToken = _vBabyOwner.babyToken();
    }

    function addOperator(address _operator) external onlyOwner {
        operators[_operator] = true;
    }

    function delOperator(address _operator) external onlyOwner {
        operators[_operator] = false;
    }

    function _repay() internal {
        (uint amount, ) = masterChef.userInfo(0, address(this));
        if (amount > 0) {
            masterChef.leaveStaking(amount);
        }
        uint balance = babyToken.balanceOf(address(this));
        if (balance > 0) {
            babyToken.approve(address(vBabyOwner), balance);
            vBabyOwner.repay(balance);
        }
    }

    function repay() public onlyOwner {
        _repay();
    }

    function _borrow() internal {
        vBabyOwner.borrow();
        uint balance = babyToken.balanceOf(address(this));
        uint pending = masterChef.pendingCake(0, address(this));
        uint amount = balance.add(pending);
        if (amount > 0) {
            babyToken.approve(address(masterChef), amount);
            masterChef.enterStaking(amount);
        }
    }

    function borrow() public onlyOwner {
        _borrow();
    }

    function doHardWork() external onlyOperator {
        _repay();
        _borrow();
    }

    function contractCall(address _contract, bytes memory _data) public onlyOwner {
        (bool success, ) = _contract.call(_data);
        require(success, "response error");
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    function masterChefCall(bytes memory _data) external onlyOwner {
        contractCall(address(masterChef), _data);
    }

    function babyTokenCall(bytes memory _data) external onlyOwner {
        contractCall(address(babyToken), _data);
    }

    function vBabyOwnerCall(bytes memory _data) external onlyOwner {
        contractCall(address(vBabyOwner), _data);
    }

}