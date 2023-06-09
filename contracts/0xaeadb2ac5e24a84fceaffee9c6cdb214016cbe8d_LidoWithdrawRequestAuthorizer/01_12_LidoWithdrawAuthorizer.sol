pragma solidity ^0.8.19;

import "BaseACL.sol";

contract LidoWithdrawRequestAuthorizer is BaseACL {
    bytes32 public constant NAME = "LidoWithdrawRequestAuthorizer";
    uint256 public constant VERSION = 1;

    address public constant WithdrawQuene = 0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1;

    constructor(address owner, address caller) BaseACL(owner, caller) {}

    function requestWithdrawals(uint256[] calldata _amounts, address _owner) external view {
        if (_owner != address(0)) {
            _checkRecipient(_owner);
        }
    }

    function requestWithdrawalsWstETH(uint256[] calldata _amounts, address _owner) external view {
        if (_owner != address(0)) {
            _checkRecipient(_owner);
        }
    }

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](1);
        _contracts[0] = WithdrawQuene;
    }
}