// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@kyber.network/utils-sc/contracts/Withdrawable.sol";
import "@kyber.network/utils-sc/contracts/Utils.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./ISwap.sol";

abstract contract BaseSwap is ISwap, Withdrawable, Utils {
    using SafeERC20 for IERC20Ext;
    using SafeMath for uint256;

    uint256 internal constant MAX_AMOUNT = type(uint256).max;
    address public proxyContract;

    event UpdatedproxyContract(address indexed _oldProxyImpl, address indexed _newProxyImpl);

    modifier onlyProxyContract() {
        require(msg.sender == proxyContract, "only swap impl");
        _;
    }

    constructor(address _admin) Withdrawable(_admin) {}

    receive() external payable {}

    function updateProxyContract(address _proxyContract) external onlyAdmin {
        require(_proxyContract != address(0), "invalid swap impl");
        emit UpdatedproxyContract(proxyContract, _proxyContract);
        proxyContract = _proxyContract;
    }

    // Swap contracts don't keep funds. It's safe to set the max allowance
    function safeApproveAllowance(address spender, IERC20Ext token) internal {
        if (token != ETH_TOKEN_ADDRESS && token.allowance(address(this), spender) == 0) {
            token.safeApprove(spender, MAX_ALLOWANCE);
        }
    }
}