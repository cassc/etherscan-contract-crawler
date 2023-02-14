// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
interface IFee {
    function payFee(
        uint256 _tokenType
    ) external payable;
}
contract SimpleToken is ERC20 {
    IFee public constant feeContract = IFee(0xfd6439AEfF9d2389856B7486b9e74a6DacaDcDCe);
    uint8 private _decimals;
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) payable {
        feeContract.payFee{value: msg.value}(0);   
        _decimals=__decimals;
        _mint(msg.sender, _totalSupply);
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}