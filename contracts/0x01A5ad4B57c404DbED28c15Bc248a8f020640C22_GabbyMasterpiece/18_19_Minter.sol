// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Minter is Ownable {
    address private _superMinter;
    mapping(address => uint256) private _minters;

    modifier onlyMinter(uint256 _amount) {
        _checkMinter(_amount);
        _;
    }

    // constructor() {
    //     setSuperMinter(_msgSender());
    // }

    function superMinter() public view returns (address) {
        return _superMinter;
    }

    function minters(address account_) public view returns (uint256) {
        return _minters[account_];
    }

    function _checkMinter(uint256 amount_) internal view virtual {
        require(amount_ > 0, "M: missing amount");

        address sender = _msgSender();
        if (sender != _superMinter) {
            require(_minters[sender] >= amount_, "Minter: insufficient quota");
        }
    }

    function _spendQuota(uint256 amount_) internal {
        address sender = _msgSender();
        if (sender == _superMinter) {
            return;
        }

        _checkMinter(amount_);

        unchecked {
            _minters[sender] -= amount_;
        }
    }

    // function _spendQuota(address _spender, uint256 _amount) internal {
    //     require(_amount > 0, "M: missing amount");
    //     uint256 currentQuota = minters[_spender];
    //     require(currentQuota >= _amount, "M: insufficient quota");

    //     unchecked {
    //         minters[_spender] = currentQuota - _amount;
    //     }
    // }

    function setSuperMinter(address newSuperMinter_) public onlyOwner {
        _superMinter = newSuperMinter_;
    }

    function setMinter(address _spender, uint _amount) public onlyOwner {
        _minters[_spender] = _amount;
    }

    function setMinterBatch(address[] calldata _spenders, uint256[] calldata _amount) public onlyOwner {
        require(_spenders.length == _amount.length, "");

        for (uint i; i < _spenders.length; i++) {
            _minters[_spenders[i]] = _amount[i];
        }
    }
}