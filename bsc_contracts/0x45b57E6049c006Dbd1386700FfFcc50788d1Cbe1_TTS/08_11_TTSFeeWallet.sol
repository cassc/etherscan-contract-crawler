// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TTSFeeWallet is Ownable {
    bool private flag;
    modifier onlyOnce() {
        require(flag == false, "Function has already called once");
        _;
    }

    constructor() {}

    function giveApproveForever(address _contractAddress) external onlyOwner onlyOnce {
        flag = true;
        IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56).approve(_contractAddress, 2**256 - 1);
    }
}