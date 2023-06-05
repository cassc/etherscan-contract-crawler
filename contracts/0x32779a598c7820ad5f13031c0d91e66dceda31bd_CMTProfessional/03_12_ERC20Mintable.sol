// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract ERC20Mintable is ERC20 {
    bool private _mintingFinished = false;

    event MintFinished();
    modifier canMint() {
        require(!_mintingFinished, "ERC20Mintable: minting is finished");
        _;
    }

    function mintingFinished() external view returns (bool) {
        return _mintingFinished;
    }

    function mint(address account, uint256 amount) external canMint {
        _mint(account, amount);
    }

    function finishMinting() external canMint {
        _finishMinting();
    }

    function _finishMinting() internal virtual {
        _mintingFinished = true;

        emit MintFinished();
    }
}