// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IAllowedERC20s.sol";
import "../utils/Ownable.sol";

contract AllowedERC20s is Ownable, IAllowedERC20s {

    mapping(address => bool) private erc20Permits;

    event ERC20Permit(address indexed erc20Contract, bool isPermitted);

    constructor(address _admin, address[] memory _allowedERC20s) Ownable(_admin) {
        for (uint256 i = 0; i < _allowedERC20s.length; i++) {
            _setERC20Permit(_allowedERC20s[i], true);
        }
    }

    function setERC20Permit(address _erc20, bool _permit) external onlyOwner {
        _setERC20Permit(_erc20, _permit);
    }

    function setERC20Permits(address[] memory _erc20s, bool[] memory _permits) external onlyOwner {
        require(_erc20s.length == _permits.length, "setERC20Permits function information arity mismatch");

        for (uint256 i = 0; i < _erc20s.length; i++) {
            _setERC20Permit(_erc20s[i], _permits[i]);
        }
    }

    function isERC20Permitted(address _erc20) external view override returns (bool) {
        return erc20Permits[_erc20];
    }

    function _setERC20Permit(address _erc20, bool _permit) internal {
        require(_erc20 != address(0), "erc20 is zero address");

        erc20Permits[_erc20] = _permit;

        emit ERC20Permit(_erc20, _permit);
    }
}