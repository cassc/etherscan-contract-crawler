// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

import "@openzeppelin/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";


contract EthStakingCrowdsale is MintedCrowdsale, Ownable {

    uint256 private _minAmount;

    constructor(
        uint256 rate,    // rate in TKNbits
        address payable wallet,
        IERC20 token
    )
    Ownable()
    MintedCrowdsale()
    Crowdsale(rate, wallet, token)
    public
    {
      _minAmount = 100000000000000000;
    }

    function setMinAmount(uint256 minAmount) public onlyOwner {
        _minAmount = minAmount;
    }

    function minAmount() public view returns (uint256) {
        return _minAmount;
    }


    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "beneficiary is the zero address");
        require(weiAmount >= _minAmount, "Crowdsale: weiAmount amount is low");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }
}