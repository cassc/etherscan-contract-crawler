// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract PeperiumToken is ERC20 {
    address private owner;
    address private marketingWallet;
    address private developerWallet;

    uint256 private constant INITIAL_SUPPLY = 100000000000 * 10 ** 18;
    uint256 public marketingFee;
    uint256 public developerFee;

    constructor(address _owner, address _marketingWallet, address _developerWallet) ERC20("Peperium", "PEPER") {
        owner = _owner = 0x9d45c58b58D1d55940aaD9df6A74E90cC05cf579;
        marketingWallet = _marketingWallet = 0x9d45c58b58D1d55940aaD9df6A74E90cC05cf579;
        developerWallet = _developerWallet = 0x9d45c58b58D1d55940aaD9df6A74E90cC05cf579;
        marketingFee = 3;
        developerFee = 2;

        _mint(owner, INITIAL_SUPPLY);
        _approve(owner, address(this), type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        _updateFees(amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);
        _updateFees(amount);
        return true;
    }

    function setMarketingFee(uint256 _marketingFee) public {
        require(msg.sender == owner, "Only owner can update marketing fee");
        marketingFee = _marketingFee;
    }

    function setDeveloperFee(uint256 _developerFee) public {
        require(msg.sender == owner, "Only owner can update developer fee");
        developerFee = _developerFee;
    }

    function _updateFees(uint256 amount) private {
        uint256 totalFee = marketingFee + developerFee;
        if (totalFee > 0) {
            uint256 marketingAmount = (amount * marketingFee) / totalFee;
            uint256 developerAmount = amount - marketingAmount;
            _transfer(_msgSender(), marketingWallet, marketingAmount);
            _transfer(_msgSender(), developerWallet, developerAmount);
        }
    }
}
