// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IBaseHelioswapFactory.sol";
import "../libraries/HelioswapConstants.sol";
import "../libraries/SafeCast.sol";

abstract contract BaseHelioswap is ERC20, Ownable, ReentrancyGuard {
    using SafeCast for uint256;

    event SlippageFeeUpdate(address indexed user, uint256 slippageFee, bool isDefault, uint256 amount);
    event DecayPeriodUpdate(address indexed user, uint256 decayPeriod, bool isDefault, uint256 amount);

    IBaseHelioswapFactory public baseHelioswapFactory;
    uint256 private _fee;
    uint256 private _slippageFee;
    uint256 private _decayPeriod;

    constructor(IBaseHelioswapFactory _baseHelioswapFactory) internal {
        baseHelioswapFactory = _baseHelioswapFactory;
        _fee = baseHelioswapFactory.defaultFee().toUint104();
        _slippageFee = baseHelioswapFactory.defaultSlippageFee().toUint104();
        _decayPeriod = baseHelioswapFactory.defaultDecayPeriod().toUint104();
    }

    function setBaseHelioswapFactory(IBaseHelioswapFactory newBaseHelioswapFactory) external onlyOwner {
        baseHelioswapFactory = newBaseHelioswapFactory;
    }

    function fee() public view returns(uint256) {
        return _fee;
    }

    function slippageFee() public view returns(uint256) {
        return _slippageFee;
    }

    function decayPeriod() public view returns(uint256) {
        return _decayPeriod;
    }
}