// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Pepeable is Context {
    address private pepe;

    event OwnershipTransferred(address indexed previousPepe, address indexed newPepe);

    constructor() {
        _transferPepeship(_msgSender());
    }

    modifier onlyPepe() {
        _checkPepe();
        _;
    }

    function owner() public view virtual returns (address) {
        return pepe;
    }

    function _checkPepe() internal view virtual {
        require(owner() == _msgSender(), "Pepeable: caller is not Pepe");
    }

    function renouncePepeship() public virtual onlyPepe {
        _transferPepeship(address(0));
    }
    
    function transferPepeship(address _pepe) public virtual onlyPepe {
        require(_pepe != address(0), "Pepeable: new owner is the zero address");
        _transferPepeship(_pepe);
    }

    function _transferPepeship(address _pepe) internal virtual {
        address oldPepe = pepe;
        pepe = _pepe;
        emit OwnershipTransferred(oldPepe, pepe);
    }
}