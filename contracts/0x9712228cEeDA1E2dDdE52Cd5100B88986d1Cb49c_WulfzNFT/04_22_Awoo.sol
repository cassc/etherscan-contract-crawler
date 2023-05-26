// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UtilityToken is ERC20("Awoo", "AWOO"), Ownable {
    event AwooBurn(address indexed user, uint256 amount);
    event AwooRewarded(address indexed user, uint256 amount);

    uint256 public constant TOTAL_SUPPLY_AWOO = 200000000 * 10**2;

    address private _wulfzAddr;
    address private _stakingAddr;

    constructor(address wulfzAddr_, address stakingAddr_) {
        _wulfzAddr = wulfzAddr_;
        _stakingAddr = stakingAddr_;
    }

    function decimals() public pure override returns (uint8) {
        return 2;
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == _wulfzAddr, "Only Wulfz Contract can call");
        _burn(_from, _amount);
        emit AwooBurn(_from, _amount);
    }

    function reward(address _to, uint256 _amount) external {
        require(msg.sender == _stakingAddr, "Only Staking Contract can call");
        if (_amount > 0) {
            require(
                (totalSupply() + _amount) < TOTAL_SUPPLY_AWOO,
                "MAX LIMIT SUPPLY EXCEEDED"
            );
            _mint(_to, _amount);
            emit AwooRewarded(_to, _amount);
        }
    }
}