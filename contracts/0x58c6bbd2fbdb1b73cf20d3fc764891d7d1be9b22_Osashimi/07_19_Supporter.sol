// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Supportable is Context {
    address private _supporter;

    event SupportershipTransferred(address indexed previousSupporter, address indexed newSupporter);

    constructor() {
        _transferSupportership(_msgSender());
    }

    function supporter() public view virtual returns (address) {
        return _supporter;
    }

    modifier onlySupporter()
    {
        require(supporter() == _msgSender(), "Ownable: caller is not the Supporter");
        _;
    }

    function renounceSupportership() public virtual onlySupporter {
        _transferSupportership(address(0));
    }

    function transferSupportership(address newSupporter) public virtual onlySupporter {
        require(newSupporter != address(0), "Ownable: new Supporter is the zero address");
        _transferSupportership(newSupporter);
    }

    function _transferSupportership(address newSupporter) internal virtual {
        address oldSupporter = _supporter;
        _supporter = newSupporter;
        emit SupportershipTransferred(oldSupporter, newSupporter);
    }
}