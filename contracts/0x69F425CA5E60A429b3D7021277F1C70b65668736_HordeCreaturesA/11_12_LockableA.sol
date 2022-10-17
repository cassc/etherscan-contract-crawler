// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

uint64 constant MAX_INT = 2**64 - 1;

abstract contract LockableA is ERC721A {
    mapping(uint256 => LTS) private _lt;
    mapping(address => Cust) private _cust;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    string private LOCKED_BY_OWNER = "token is locked by owner";
    string private ONLY_CUSTODIAN = "lock can only be set by custodian";

    mapping(address => address[]) private _appAll;

    struct LTS {
        bool isLocked;
        uint256 lockedAt;
    }
    
    struct Cust {
        address custodian;
        uint256 lockedBalance;
        bool isAssigned;
    }

    function custodianOf(uint256 id)
        public
        view
        returns (Cust memory)
    {     
        address owner = ownerOf(id);
        return _cust[owner];
    }     

    function revokeApprovals(address holder) private {
    
        uint256 approvals = _appAll[holder].length;
        uint256 removals = 0;
        while (approvals > 0) {     
            address approved = _appAll[holder][approvals-1];  
            _operatorApprovals[holder][approved] = false;      
            emit ApprovalForAll(_msgSenderERC721A(), approved, false);      
            _appAll[holder].pop();         
            approvals--;   
            removals++;           
        }
    }

    function lockToken(uint256 id) public {        
        require(msg.sender == custodianOf(id).custodian, ONLY_CUSTODIAN);    
        address owner = ownerOf(id);
        revokeApprovals(owner);        
        _lt[id].isLocked = true;
        _lt[id].lockedAt = block.timestamp;
        _cust[owner].lockedBalance++;      
    }

    function unlockToken(uint256 id) public {        
        require(msg.sender == custodianOf(id).custodian, ONLY_CUSTODIAN);    
        address owner = ownerOf(id);
        _lt[id].isLocked = false;
        _lt[id].lockedAt = MAX_INT;
        _cust[owner].lockedBalance--;
    }    

    function _forceUnlock(uint256 id) internal virtual {  
        address owner = ownerOf(id);
        _lt[id].isLocked = false;
        _lt[id].lockedAt = MAX_INT;
        _cust[owner].lockedBalance--;
    }    
    function setCustodian(uint256 id, address custodianAddress) public {
        address owner = ownerOf(id);
        require(msg.sender == ownerOf(id), "custodian can only be set by owner");
        uint256 _lockedBalance = 0;
        if (_cust[owner].isAssigned) {
            for( uint256 i; i < totalSupply(); ++i ){
                if(_exists(i)){
                    if( _lt[i].isLocked){
                        _lockedBalance++;
                    }
                }
            }
        }
        Cust memory custodian = Cust(custodianAddress, _lockedBalance, true);
        _cust[owner] = custodian;
    }

    function isLocked(uint256 id)
        public
        view
        returns (bool)
    {     
        return _lt[id].isLocked;
    } 

    function lockedSince(uint256 id, uint256 since)
        public
        view
        returns (bool)
    {     
        return _lt[id].lockedAt <= since;
    }     

    function lockedBalance(address owner)
        public
        view
        returns (uint256)
    {     
        return _cust[owner].lockedBalance;
    } 

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }    
            
    function approve(address app, uint256 id) public virtual override payable {
        require(isLocked(id) != true, LOCKED_BY_OWNER);
        super.approve(app, id);
    }  

    function setApprovalForAll(address _op, bool _app) public virtual override {
        require(lockedBalance(_msgSenderERC721A()) < 1, LOCKED_BY_OWNER);
        require(_op != _msgSenderERC721A(), "cannot grant approval to self");
        
        _operatorApprovals[_msgSenderERC721A()][_op] = _app;
        emit ApprovalForAll(_msgSenderERC721A(), _op, _app);

        if (_app) {
            _appAll[msg.sender].push(_op);
        }
        super.setApprovalForAll(_op, _app);
    }   

    function transferFrom(
        address f,
        address t,
        uint256 id
    ) public virtual override payable {
        require(isLocked(id) != true, LOCKED_BY_OWNER);
        super.transferFrom(f, t, id);
    }

    function safeTransferFrom(
        address f,
        address t,
        uint256 id,
        bytes memory data
    ) public virtual override payable {        
        require(isLocked(id) != true, LOCKED_BY_OWNER);
        super.safeTransferFrom(f, t, id, data);
    }          
}