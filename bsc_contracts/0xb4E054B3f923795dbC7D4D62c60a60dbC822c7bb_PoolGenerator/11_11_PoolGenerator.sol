// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Pool.sol";
import "./interfaces/IPoolFactory.sol";

contract PoolGenerator is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IPoolFactory public factory;
    address public devaddr;
    uint256 public tokenFee = 50;
    uint256 public ethFee;

    constructor(IPoolFactory _factory, address _devAddr, uint256 _ethFee) {
        factory = _factory;
        devaddr = _devAddr;
        ethFee = _ethFee;
    }

    function setTokenFee(uint256 _tokenFee) external onlyOwner {
        tokenFee = _tokenFee;
    }

    function setEthFee(uint256 _ethFee) external onlyOwner {
        ethFee = _ethFee;
    }

    function setDev(address _devaddr) external onlyOwner {
        devaddr = _devaddr;
    }

    function createPool(
        address _rewardToken,
        address _lpToken,
        uint256 _aprPercent,
        uint256 _amount,
        uint256 _lockPeriod,
        uint256 _bonus,
        uint256 _bonusEndBlock
    ) external payable returns (address) {
        require(msg.value >= ethFee, "Insufficient amount");

        Pool newPool = new Pool(
            _lpToken,
            _rewardToken,
            msg.sender,
            _aprPercent,
            _lockPeriod,
            _bonus,
            _bonusEndBlock
        );
        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            devaddr,
            _amount.mul(tokenFee).div(1000)
        );
        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            address(newPool),
            _amount.mul(1000 - tokenFee).div(1000)
        );

        factory.registerPool(address(newPool));
        return address(newPool);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient amount");
        (bool success, ) = payable(devaddr).call{value: balance}("");
        require(success, "Failed fee transfer");
    }

    receive() external payable {}
}