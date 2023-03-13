// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swap is ReentrancyGuard, Ownable {
    uint256 public rateAB;
    bool public isActive;
    address public tokenA;
    address public tokenB;

    mapping (address => uint256) public depositUsers;
    mapping (address => uint256) public withdrawUsers;

    event Convert(address indexed account, uint256 amountA, uint256 amountB);

    constructor(address _tokenA, address _tokenB) {
      tokenA = _tokenA;
      tokenB = _tokenB;
      rateAB = 1000;
    }
    
    function setTokens(address _tokenA, address _tokenB) external onlyOwner {
      tokenA = _tokenA;
      tokenB = _tokenB;
    }

    function setStatus(bool _status) external onlyOwner {
      isActive = _status;
    }

    function setRate(uint256 _rateAB) external onlyOwner {
      require(_rateAB > 0, "Swap: rateAB need > 0");
      rateAB = _rateAB;
    }

    function swap(uint256 _amountA) external {
      require(isActive, "Swap: not active");
      require(_amountA > 0, "Swap: _amountA need > 0");

      IERC20(tokenA).transferFrom(msg.sender, address(this), _amountA);
      uint256 convertedAmount = (_amountA * 10 ** 10) / rateAB;
      require(IERC20(tokenB).balanceOf(address(this)) >= convertedAmount, "Insufficient Token B balance");
      IERC20(tokenB).transfer(msg.sender, convertedAmount);

      depositUsers[msg.sender] += _amountA;
      withdrawUsers[msg.sender] += convertedAmount;

      emit Convert(msg.sender, _amountA, convertedAmount);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverFungibleTokens(address _token) external onlyOwner {
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, "Operations: No token to recover");

        IERC20(_token).transfer(address(msg.sender), amountToRecover);
    }
}