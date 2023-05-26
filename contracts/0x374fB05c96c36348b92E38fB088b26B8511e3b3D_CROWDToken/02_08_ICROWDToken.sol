// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HasMinters is Ownable {
    event MinterAdded(address indexed _minter);
    event MinterRemoved(address indexed _minter);

    address[] public minters;
    mapping(address => bool) public minter;

    modifier onlyMinter() {
        require(minter[msg.sender], "invalid minter");
        _;
    }

    function addMinters(address[] memory _addedMinters) public onlyOwner {
        address _minter;

        for (uint256 i = 0; i < _addedMinters.length; i++) {
            _minter = _addedMinters[i];

            if (!minter[_minter]) {
                minters.push(_minter);
                minter[_minter] = true;
                emit MinterAdded(_minter);
            }
        }
    }

    function removeMinters(address[] memory _removedMinters) public onlyOwner {
        address _minter;

        for (uint256 it = 0; it < _removedMinters.length; it++) {
            _minter = _removedMinters[it];

            if (minter[_minter]) {
                minter[_minter] = false;
                emit MinterRemoved(_minter);
            }
        }

        uint256 i = 0;

        while (i < minters.length) {
            _minter = minters[i];

            if (!minter[_minter]) {
                minters[i] = minters[minters.length - 1];
                delete minters[minters.length - 1];
                // minters.length--;
            } else {
                i++;
            }
        }
    }

    function isMinter(address _addr) public view returns (bool) {
        return minter[_addr];
    }
}

abstract contract ICROWDToken is ERC20, Pausable, Ownable, HasMinters {
    uint256 private _maxSupply;

    function setMaxSupply(uint256 amount) internal onlyOwner {
        _maxSupply = amount;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function mint(address to, uint256 amount) public virtual onlyMinter {
        require(totalSupply() + amount <= _maxSupply, "over maxSupply");
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function stop() public onlyOwner {
        _pause();
    }

    function start() public onlyOwner {
        _unpause();
    }
}