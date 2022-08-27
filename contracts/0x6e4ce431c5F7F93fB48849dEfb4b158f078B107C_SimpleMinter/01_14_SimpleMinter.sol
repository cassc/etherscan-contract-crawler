// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./libs/BaseMinter.sol";

/**
 * @title SimpleMinter
 * SimpleMinter - a configurable simple minter for static NFTs
 */
contract SimpleMinter is BaseMinter {
    using Counters for Counters.Counter;

    uint256 internal _maxReserve = 10;

    constructor(string memory name, string memory symbol) BaseMinter(name, symbol)
    { }

    /*
    *  Owner methods
    */
    function setMaxReserve(uint256 _val) external onlyOwner
    {
        _maxReserve = _val;
    }

    function maxReserve() external view onlyOwner returns (uint256)
    {
        return _maxReserve;
    }

    function gift(address _to, uint256 _amount) external virtual onlyOwner {
        require( _amount <= _maxReserve, "Over reserved amount" );
        require( _amount+totalSupply() <= maxSupply, "Over supply amount" );

        for(uint256 i; i < _amount; i++){
            uint256 newItemId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(_to, newItemId);
        }

        _maxReserve -= _amount;
    }

    /*
    *  Public methods
    */

    function mint() public payable whenRunning {
        uint256 newItemId = _nextTokenId.current();

        require( newItemId < maxSupply - _maxReserve, "Over maximum supply" );
        require( msg.value >= price, "Not enough ether" );

        _nextTokenId.increment();
        _safeMint(_msgSender(), newItemId);
    }

}