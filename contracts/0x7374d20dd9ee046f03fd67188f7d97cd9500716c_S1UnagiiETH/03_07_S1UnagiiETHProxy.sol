// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IUnagii.sol";


contract S1UnagiiETHProxy {
    address public deployer;
    address public UnagiiEthVault;
    address public UnagiiEthV3;

    constructor(
        address _deployer,
        address _UnagiiEthVault,
        address _UnagiiEthV3
    ) {
        deployer = _deployer;
        UnagiiEthVault = _UnagiiEthVault;
        UnagiiEthV3 = _UnagiiEthV3;

        IERC20(_UnagiiEthV3).approve(UnagiiEthVault, 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function depositETHWithMin(uint256 _min) external payable onlyDeployer {
        IUnagii(UnagiiEthVault).safeDepositETH{value: msg.value}(address(this), _min);
    }

    function withdrawWithMax(uint256 _amount, uint256 _max) external onlyDeployer {
        IUnagii(UnagiiEthVault).safeRedeemETH(
            _amount,
            deployer,
            address(this),
            _max
        );
    }

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯