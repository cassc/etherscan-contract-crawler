/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

pragma solidity 0.8.6;

interface ERC20 {
  function balanceOf(address) external view returns (uint);
}

// contract meant for simulations only
contract ERC20BalanceProbeUtils {
    mapping(address => mapping(address => uint256)) snapshotBalance;

    function snapshot(address token, address account) external {
        snapshotBalance[token][account] = ERC20(token).balanceOf(account);
    }

    function measure(address token, address account) public view returns (uint256 diff) {
        diff = ERC20(token).balanceOf(account) - snapshotBalance[token][account];
    }

    function assertDiff(address token, address account, uint256 expectedDiff) external view {
        uint diff = measure(token, account);
        require(diff == expectedDiff, "wrong diff");
    }
}