// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
abstract contract WithLimitedSupply {
    using Counters for Counters.Counter;
    event SupplyChanged(uint256 indexed supply);
    Counters.Counter private _tokenCount;
    uint256 private _totalSupply;
    constructor (uint256 totalSupply_) {
        _totalSupply = totalSupply_;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function tokenCount() public view returns (uint256) {
        return _tokenCount.current();
    }
    function availableTokenCount() public view returns (uint256) {
        return totalSupply() - tokenCount();
    }
    function nextToken() internal virtual returns (uint256) {
        uint256 token = _tokenCount.current();
        _tokenCount.increment();
        return token;
    }

    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "No more tokens available");
        _;
    }

    modifier ensureAvailabilityFor(uint256 amount) {
        require(availableTokenCount() >= amount, "Requested number of tokens not available");
        _;
    }

    function _setSupply(uint256 _supply) internal virtual {
        require(_supply > tokenCount(), "Can't set the supply to less than the current token count");
        _totalSupply = _supply;
        emit SupplyChanged(totalSupply());
    }
}