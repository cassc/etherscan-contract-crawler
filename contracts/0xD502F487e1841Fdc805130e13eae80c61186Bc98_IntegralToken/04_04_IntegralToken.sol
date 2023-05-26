// SPDX-License-Identifier: GPL-3.0-or-later

// CODE COPIED FROM COMPOUND PROTOCOL (https://github.com/compound-finance/compound-protocol/tree/b9b14038612d846b83f8a009a82c38974ff2dcfe)

// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// CODE WAS SLIGHTLY MODIFIED

// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IIntegralToken.sol';
import 'SafeMath.sol';
import 'Votes.sol';

contract IntegralToken is IIntegralToken, Votes {
    using SafeMath for uint256;
    using SafeMath for uint96;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event OwnerSet(address indexed owner);
    event MinterSet(address indexed account, bool isMinter);
    event BurnerSet(address indexed account, bool isBurner);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event DelegatesChanged(address indexed account, address indexed oldDelegate, address indexed newDelegate);
    event BlacklistedSet(address indexed account, bool isBlacklisted);

    string public constant name = 'Integral';
    string public constant symbol = 'ITGR';
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    address public owner;

    mapping(address => bool) public isMinter;
    mapping(address => bool) public isBurner;
    mapping(address => uint96) internal balances;
    mapping(address => mapping(address => uint96)) internal allowances;
    mapping(address => address) public delegates;
    mapping(address => uint256) public nonces;
    mapping(address => bool) public isBlacklisted;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address newDelegate,uint256 nonce,uint256 expiry)');

    constructor(address account, uint256 _initialAmount) {
        owner = msg.sender;
        isMinter[msg.sender] = true;
        isBurner[msg.sender] = true;
        _mint(account, _initialAmount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address account, address spender) external view returns (uint256) {
        return allowances[account][spender];
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, 'IT_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setMinter(address account, bool _isMinter) external {
        require(msg.sender == owner, 'IT_FORBIDDEN');
        isMinter[account] = _isMinter;
        emit MinterSet(account, _isMinter);
    }

    function mint(address to, uint256 _amount) external override {
        require(isMinter[msg.sender], 'IT_ONLY_WHITELISTED');
        require(!isBlacklisted[msg.sender] && !isBlacklisted[to], 'IT_BLACKLISTED');
        _mint(to, _amount);
    }

    function _mint(address to, uint256 _amount) internal {
        uint96 amount = safe96(_amount);
        totalSupply = totalSupply.add(_amount);
        balances[to] = balances[to].add96(amount);
        emit Transfer(address(0), to, _amount);

        _updateVotes(address(0), getDelegate(to), amount);
    }

    function setBurner(address account, bool _isBurner) external {
        require(msg.sender == owner, 'IT_FORBIDDEN');
        isBurner[account] = _isBurner;
        emit BurnerSet(account, _isBurner);
    }

    function burn(uint256 _amount) external {
        require(isBurner[address(0)] || isBurner[msg.sender], 'IT_ONLY_WHITELISTED');
        require(!isBlacklisted[msg.sender], 'IT_BLACKLISTED');
        uint96 amount = safe96(_amount);
        totalSupply = totalSupply.sub(_amount, 'IT_INVALID_BURN_AMOUNT');
        balances[msg.sender] = balances[msg.sender].sub96(amount);
        emit Transfer(msg.sender, address(0), _amount);

        _updateVotes(getDelegate(msg.sender), address(0), amount);
    }

    function approve(address spender, uint256 _amount) external returns (bool) {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[spender], 'IT_BLACKLISTED');
        uint96 amount = _amount == uint256(-1) ? uint96(-1) : safe96(_amount);
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address account,
        address spender,
        uint96 amount
    ) internal {
        require(account != address(0) && spender != address(0), 'IT_ADDRESS_ZERO');
        allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function increaseAllowance(address spender, uint256 _extraAmount) external returns (bool) {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[spender], 'IT_BLACKLISTED');
        uint96 extraAmount = safe96(_extraAmount);
        _approve(msg.sender, spender, allowances[msg.sender][spender].add96(extraAmount));
        return true;
    }

    function decreaseAllowance(address spender, uint256 _subtractedAmount) external returns (bool) {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[spender], 'IT_BLACKLISTED');
        uint96 subtractedAmount = safe96(_subtractedAmount);
        uint96 currentAmount = allowances[msg.sender][spender];
        require(currentAmount >= subtractedAmount, 'IT_CANNOT_DECREASE');
        _approve(msg.sender, spender, currentAmount.sub96(subtractedAmount));
        return true;
    }

    function transfer(address to, uint256 _amount) external returns (bool) {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[to], 'IT_BLACKLISTED');
        uint96 amount = safe96(_amount);
        _transferTokens(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 _amount
    ) external returns (bool) {
        address spender = msg.sender;
        require(!isBlacklisted[spender] && !isBlacklisted[from] && !isBlacklisted[to], 'IT_BLACKLISTED');
        uint96 amount = safe96(_amount);
        uint96 spenderAllowance = allowances[from][spender];
        if (spender != from && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = spenderAllowance.sub96(amount);
            _approve(from, spender, newAllowance);
        }
        _transferTokens(from, to, amount);
        return true;
    }

    function _transferTokens(
        address from,
        address to,
        uint96 amount
    ) internal {
        require(to != address(0), 'IT_INVALID_TO');
        balances[from] = balances[from].sub96(amount);
        balances[to] = balances[to].add96(amount);
        emit Transfer(from, to, amount);
        _updateVotes(getDelegate(from), getDelegate(to), amount);
    }

    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
        return _getPriorVotes(account, blockNumber);
    }

    function getDelegate(address account) public view returns (address) {
        return delegates[account] == address(0) ? account : delegates[account];
    }

    function delegate(address newDelegate) external {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[newDelegate], 'IT_BLACKLISTED');
        require(newDelegate != address(0), 'IT_INVALID_DELEGATE');
        _delegateFrom(msg.sender, newDelegate);
    }

    function _delegateFrom(address from, address newDelegate) internal {
        address oldDelegate = getDelegate(from);
        uint96 delegatorBalance = balances[from];
        delegates[from] = newDelegate;

        emit DelegatesChanged(from, oldDelegate, newDelegate);

        _updateVotes(oldDelegate, newDelegate, delegatorBalance);
    }

    function delegateWithSignature(
        address newDelegate,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[newDelegate], 'IT_BLACKLISTED');
        require(block.timestamp <= expiry, 'IT_SIGNATURE_EXPIRED');
        require(newDelegate != address(0), 'IT_INVALID_DELEGATE');
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, newDelegate, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'IT_INVALID_SIGNATURE');
        require(nonce == nonces[signatory]++, 'IT_INVALID_NONCE');
        _delegateFrom(signatory, newDelegate);
    }

    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, 'IT_EXCEEDS_96_BITS');
        return uint96(n);
    }

    function getChainId() public pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function setBlacklisted(address account, bool _isBlacklisted) external {
        require(msg.sender == owner, 'IT_FORBIDDEN');
        isBlacklisted[account] = _isBlacklisted;
        emit BlacklistedSet(account, _isBlacklisted);
    }
}