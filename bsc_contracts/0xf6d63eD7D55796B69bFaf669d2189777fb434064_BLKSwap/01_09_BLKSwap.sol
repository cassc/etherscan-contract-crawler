//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

pragma solidity ^0.8.13;

contract BLKSwap is Ownable {
    using SafeMath for uint256;

    mapping(address => address) public tokenOracles;

    event SwapIntoBLK(address indexed account, address tokenIn, uint256 depositedAmount, uint256 price, uint decimals);
    event AddedToTokenOracles(address indexed account, address oracleAddress);
    event RemovedFromTokenOracles(address indexed account, address oracleAddress);

    constructor(address _ethOracle) {
        tokenOracles[address(0)] = _ethOracle;
    }

    function getTokenOracle(address _token) public view returns (address) {
        return tokenOracles[_token];
    }


    function addOrChangeTokenOracle(address _newToken, address _newTokenOracle) public onlyOwner() {
        tokenOracles[_newToken] = _newTokenOracle;
        emit AddedToTokenOracles(_newToken, _newTokenOracle);
    }

    function removeTokenOracle(address _toBeRemoved) public onlyOwner() {
        tokenOracles[_toBeRemoved] = address(0);
        emit RemovedFromTokenOracles(_toBeRemoved, address(0));
    }

    function getPriceFromOracle(address _token) public view returns (uint256) {
        address oracle = tokenOracles[_token];
        if(oracle != address(0)) {
            (, int256 latestPrice, , , ) = AggregatorV3Interface(oracle).latestRoundData();
            uint256 tokenDecimals;
            if(_token == address(0)) {
                tokenDecimals = 18;
            } else {
                tokenDecimals = ERC20(_token).decimals();
            }
            uint256 oracleDecimals = AggregatorV3Interface(oracle).decimals();
            uint256 diffDecimals = tokenDecimals - oracleDecimals;
            uint256 latestPriceConverted = uint256(latestPrice) * 10 ** diffDecimals;
            return latestPriceConverted;
        } else {
            return 0;
        }
    }

    function estimateTokenIn(address _token, uint256 _amount) public view returns (uint256) {
        uint decimalsToken = ERC20(_token).decimals();
        return _amount.mul(getPriceFromOracle(_token)).div(10**decimalsToken);
    }

    function estimateEthIn(uint256 _amount) public view returns (uint256) {
        return _amount.mul(getPriceFromOracle(address(0))).div(10**18);
    }

    function swapTokenIn(address _token, uint256 _amount) public {
        require(_amount > 0, "BLKSwap: amount must be greater than 0");
        ERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit SwapIntoBLK(msg.sender, _token, _amount, getPriceFromOracle(_token), ERC20(_token).decimals());
    }

    function swapEthIn() public payable {
        require(msg.value > 0, "BLKSwap: amount must be greater than 0");
        address nativeOracle = getTokenOracle(address(0));
        emit SwapIntoBLK(msg.sender, address(0), msg.value, getPriceFromOracle(address(0)), AggregatorV3Interface(nativeOracle).decimals());
    }

    function withdrawEth() public onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address _token) public onlyOwner() {
        ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
    }

}