// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Members is Ownable{
    struct Member {
        address wallet;
        bool    enabled;
        bool    whiteList;
        bool    exists;
    }

    struct Range {
        uint32   size;
        Limits[] limits;
    }

    struct Limits {
        uint64 rate;
        uint64 min;
        uint64 max;
    }

    struct Commission {
        uint128 base;
        uint128 quote;
    }

    struct Referrer {
        Member      member;
        Range       range;
        Commission  commission;
    }

    uint256 internal constant DEFAULT_REFERRER = 0;

    // memberid => range[]
    mapping (uint256 => Range)      _ranges;
    // memberid => member[]
    mapping (uint256 => Member)     _members;
    // memberid => commission
    mapping (uint256 => Commission) _commissions;
    // memberid => whitelisted addresses
    mapping (uint256 => mapping(address => bool))  _whiteListed;
    // memberids
    uint256[] _memberIds;


    constructor() {
    }

    function setRange(uint256 memberId, uint32 size, Limits[] memory limits) 
    public 
    onlyOwner
    {
        require(_members[memberId].exists   == true,  "Member doesn't exists");
        require(_ranges[memberId].size      == 0,     "Range already exists");
        Range storage range = _ranges[memberId] ;
        for(uint32 i=0; i<size;i++){
            range.limits.push(limits[i]);
        }
        range.size = size;
    }

    function dropRange(uint256 memberId) 
    public 
    onlyOwner
    {
        delete _ranges[memberId];
    }

    function getRange(uint256 memberId)
    internal view 
    returns(Range memory) 
    {
        return _ranges[memberId];
    }

    function setCommission(uint256 memberId, uint128 base, uint128 quote) 
    public 
    onlyOwner
    {
        _commissions[memberId] = Commission(base, quote);
    }

    function dropComission(uint256 memberId) 
    public 
    onlyOwner 
    {
        delete _commissions[memberId];
    }

    function getCommission(uint256 memberId) 
    internal view 
    returns(Commission memory) 
    {
        return _commissions[memberId];
    }

    function setMember(uint256 memberId, Member memory member, Range memory range, Commission memory commission) 
    public
    onlyOwner 
    {
        require(_members[memberId].exists == false, "Member exists");
        Member storage _member = _members[memberId];
        _member.wallet = member.wallet;
        _member.enabled = member.enabled;
        _member.whiteList = member.whiteList;
        _member.exists = true;
        setRange(memberId, range.size, range.limits);
        setCommission(memberId, commission.base, commission.quote);
        _memberIds.push(memberId);
    }

    function dropMember(uint256 memberId) 
    public  
    onlyOwner
    {
        if(_memberExists(memberId)) {
            for(uint256 i=0; i<_memberIds.length; i++)
            {
                if(memberId == _memberIds[i])
                {
                    _memberIds[i] = _memberIds[_memberIds.length -1];
                    _memberIds.pop();
                    delete _members[memberId];
                    dropRange(memberId);
                    dropComission(memberId);
                }
            }
        }
    }

    function _getMember(uint256 memberId) 
    internal view 
    returns (Referrer memory)
    {
        Member memory _member           = _members[memberId];
        Range  memory _range            = _ranges[memberId];
        Commission memory _commission   = _commissions[memberId];
        return Referrer(_member, _range, _commission);
    }

    function getMember(uint256 memberId)
    public view 
    onlyOwner
    _whenMemberExists(memberId)
    returns(Referrer memory)
    {
        return _getMember(memberId);
    }

    function getMembers()
    external view 
    onlyOwner
    returns(uint256[] memory) 
    {
        return _memberIds;
    }

    function getMemberOrDefault(uint256 memberId) 
    internal view 
    returns (Referrer memory)
    {
        Referrer memory ref = _getMember(memberId);
        if (!ref.member.exists) {
            return _getMember(DEFAULT_REFERRER);
        }
        return ref;
    }

    function setWhiteListed(uint256 memberId, address beneficiary) 
    public 
    onlyOwner
    {
        _whiteListed[memberId][beneficiary] = true;
    }

    function dropWhiteListed(uint256 memberId, address beneficiary) 
    public 
    onlyOwner
    {
        delete _whiteListed[memberId][beneficiary];
    }

    function isWhiteListed(uint256 memberId, address beneficiary) 
    public view 
    returns(bool) 
    {
        return _whiteListed[memberId][beneficiary];
    }

    function _memberExists(uint256 memberId) 
    private view 
    returns (bool) 
    {
        for(uint256 i=0; i<_memberIds.length; i++){
            if( memberId == _memberIds[i])
                return true;
        }
        return false;
    }

    modifier _whenMemberExists(uint256 memberId) {
        require(_members[memberId].exists == true, "Member doesn't exists");
        _;
    }

    modifier _whenRangeExists(uint256 memberId) {
        require(_ranges[memberId].size    != 0,    "Range doesn't exists");
        _;
    }
}