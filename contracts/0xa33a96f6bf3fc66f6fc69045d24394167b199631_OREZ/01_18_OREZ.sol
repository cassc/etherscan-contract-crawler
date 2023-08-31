// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/IOFT.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/OFTCore.sol";

contract OREZ is OFTCore, ERC20, IOFT {
    bool public isMain;

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        bool _isMain,
        uint256 _initialSupplyOnMain
    ) ERC20(_name, _symbol) OFTCore(_lzEndpoint) {
        if (_isMain) {
            isMain = true;
            _mint(msg.sender, _initialSupplyOnMain);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OFTCore, IERC165) returns (bool) {
        return
            interfaceId == type(IOFT).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _amount) internal virtual override returns (uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);

        if (isMain) {
            _transfer(_from, address(this), _amount);
        } else {
            _burn(_from, _amount);
        }

        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns (uint) {
        if (isMain) {
            _transfer(address(this), _toAddress, _amount);
        } else {
            _mint(_toAddress, _amount);
        }

        return _amount;
    }
}