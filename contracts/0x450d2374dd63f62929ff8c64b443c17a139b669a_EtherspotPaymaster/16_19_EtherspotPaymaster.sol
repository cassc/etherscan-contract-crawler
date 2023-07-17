// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../src/paymaster/EtherspotPaymaster.sol";

contract $EtherspotPaymaster is EtherspotPaymaster {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event return$_validatePaymasterUserOp(bytes context, uint256 validationData);

    constructor(IEntryPoint _entryPoint) EtherspotPaymaster(_entryPoint) {}

    function $_debitSponsor(address _sponsor,uint256 _amount) external {
        super._debitSponsor(_sponsor,_amount);
    }

    function $_creditSponsor(address _sponsor,uint256 _amount) external {
        super._creditSponsor(_sponsor,_amount);
    }

    function $_pack(UserOperation calldata userOp) external pure returns (bytes32 ret0) {
        (ret0) = super._pack(userOp);
    }

    function $_validatePaymasterUserOp(UserOperation calldata userOp,bytes32 arg1,uint256 requiredPreFund) external returns (bytes memory context, uint256 validationData) {
        (context, validationData) = super._validatePaymasterUserOp(userOp,arg1,requiredPreFund);
        emit return$_validatePaymasterUserOp(context, validationData);
    }

    function $_postOp(IPaymaster.PostOpMode mode,bytes calldata context,uint256 actualGasCost) external {
        super._postOp(mode,context,actualGasCost);
    }

    function $_check(address _sponsor,address _account) external view returns (bool ret0) {
        (ret0) = super._check(_sponsor,_account);
    }

    function $_add(address _account) external {
        super._add(_account);
    }

    function $_addBatch(address[] calldata _accounts) external {
        super._addBatch(_accounts);
    }

    function $_remove(address _account) external {
        super._remove(_account);
    }

    function $_removeBatch(address[] calldata _accounts) external {
        super._removeBatch(_accounts);
    }

    function $_requireFromEntryPoint() external {
        super._requireFromEntryPoint();
    }

    function $_checkOwner() external view {
        super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}