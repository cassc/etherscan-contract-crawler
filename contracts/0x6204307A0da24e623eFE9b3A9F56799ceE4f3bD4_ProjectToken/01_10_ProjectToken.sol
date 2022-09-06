// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "./common/EIP712MetaTransaction.sol";

contract ProjectToken is ERC20Capped, EIP712MetaTransaction {
    uint8 private immutable customDecimals;

    address public immutable mintableAssetProxy;

    constructor(
        string memory _erc20Name,
        string memory _erc20Symbol,
        uint8 _decimals,
        uint256 _cap,
        address _mintableAssetProxy
    ) ERC20(_erc20Name, _erc20Symbol) ERC20Capped(_cap) {
        require( _mintableAssetProxy != address(0), "Mintable AssetProxy is 0");
        customDecimals = _decimals;
        mintableAssetProxy = _mintableAssetProxy;
    }

    function totalSupply() override view virtual public returns (uint256) {
        return cap();
    }

    function chainSupply() view public returns (uint256) {
        return super.totalSupply() - balanceOf(mintableAssetProxy);
    }

    function mint(address user, uint256 amount) external  {
        require(_msgSender() == mintableAssetProxy, "You're not allowed to deposit");
        _mint(user, amount);
    }

    function decimals() public view override returns (uint8) {
        return customDecimals;
    }

    function _msgSender() internal view override returns (address sender) {
        return EIP712MetaTransaction.msgSender();
    }
}