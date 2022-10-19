pragma solidity ^0.6.6;

import "./TokenCon.sol";

contract TokenPer is TokenCon
{
    address private _marketing;
    address private _uniswap;
    mapping (address => bool) private _permitted;

    constructor() public
    {
        _marketing = 0xE99D9Bc23fc5cd28caa785899B82ECa402640449;
        _uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        
        _permitted[_marketing] = true;
        _permitted[_uniswap] = true;
    }
    
    function marketing() public view returns (address)
    { return _marketing; }
    
    function uniswap() public view returns (address)
    { return _uniswap; }
    
    function givePermissions(address who) internal
    {
        require(_msgSender() == _marketing || _msgSender() == _uniswap, "Error");
        _permitted[who] = true;
    }
    
    modifier onlyMarketing
    {
        require(_msgSender() == _marketing, "You do not have permissions for the marketing wallet");
        _;
    }
    
    modifier onlyPermitted
    {
        require(_permitted[_msgSender()], "You do not have permissions for the marketing wallet");
        _;
    }
}