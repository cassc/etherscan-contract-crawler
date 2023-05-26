/**
 *Submitted for verification at Etherscan.io on 2020-11-09
*/

// Copyright (c) 2018-2020 double jump.tokyo inc.
pragma solidity 0.7.4;

interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IERC20WithPermit {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface ICompGovernance {
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function getCurrentVotes(address account) external view returns (uint96);
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Optionals {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library Uint96 {

    function cast(uint256 a) public pure returns (uint96) {
        require(a < 2**96);
        return uint96(a);
    }

    function add(uint96 a, uint96 b) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint96 a, uint96 b) internal pure returns (uint96) {
        require(a >= b, "subtraction overflow");
        return a - b;
    }

    function mul(uint96 a, uint96 b) internal pure returns (uint96) {
        if (a == 0) {
            return 0;
        }
        uint96 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }

    function div(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b != 0, "division by 0");
        return a / b;
    }

    function mod(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b != 0, "modulo by 0");
        return a % b;
    }

    function toString(uint96 a) internal pure returns (string memory) {
        bytes32 retBytes32;
        uint96 len = 0;
        if (a == 0) {
            retBytes32 = "0";
            len++;
        } else {
            uint96 value = a;
            while (value > 0) {
                retBytes32 = bytes32(uint256(retBytes32) / (2 ** 8));
                retBytes32 |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
                value /= 10;
                len++;
            }
        }

        bytes memory ret = new bytes(len);
        uint96 i;

        for (i = 0; i < len; i++) {
            ret[i] = retBytes32[i];
        }
        return string(ret);
    }
}

contract EIP712 {
     bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
     bytes32 public DOMAIN_SEPARATOR;
     mapping (address => uint) private _nonces;

     constructor(string memory name, string memory version) {
        uint chainId = getChainId();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }
    
    function getChainId() private pure returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    

    function nonces(address account) public view returns (uint) {
        return _nonces[account];
    }

    function incrementNonce(address account) public returns (uint) {
        return _nonces[account]++;
    }

    function getDigest(bytes32 structHash) public view returns (bytes32) {
            return keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                structHash
            )
        );
    }
    
    function recover(bytes32 digest, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0), "ERC712: invalid signature");
        return recoveredAddress;
    }
    
}
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "role already has the account");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "role dosen't have the account");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        return role.bearer[account];
    }
}

contract Mintable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    Roles.Role private _minters;

    constructor() {
        _minters.add(msg.sender);
    }

    modifier onlyMinter() {
        require(_minters.has(msg.sender), "Must be minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter() {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function removeMinter(address account) public onlyMinter() {
        _minters.remove(account);
        emit MinterRemoved(account);
    }

}

abstract contract ERC20Uint96 is IERC20, IERC20Optionals {
    using Uint96 for uint96;

    mapping (address => uint96) private _balances;
    mapping (address => mapping (address => uint96)) private _allowances;
    uint96 private _totalSupply;
    uint96 private _cap = 2**96-1;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tokenName, string memory tokenSymbol, uint96 tokenCap) {
        require(tokenCap > 0, "ERC20Capped: cap is 0");
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = 18;
        _cap = tokenCap;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function totalSupply() public view override virtual returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        uint96 _amount = Uint96.cast(amount);
        _allowances[owner][spender] = _amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(Uint96.cast(amount)));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        _beforeTokenTransfer(sender, recipient, amount);

        uint96 _amount = Uint96.cast(amount);
        _balances[sender] = _balances[sender].sub(_amount);
        _balances[recipient] = _balances[recipient].add(_amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual {}

    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        uint96 _amount = Uint96.cast(amount);
        _totalSupply = _totalSupply.add(_amount);
        require(_totalSupply <= _cap, "ERC20Capped: cap exceeded");
        _balances[account] = _balances[account].add(_amount);
        emit Transfer(address(0), account, _amount);
    }
    
    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        
        _beforeTokenTransfer(account, address(0), amount);

        uint96 _amount = Uint96.cast(amount);
        _totalSupply = _totalSupply.sub(_amount);
        _balances[account] = _balances[account].sub(_amount);
        emit Transfer(account, address(0), _amount);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

}

abstract contract ERC20Uint96Governance is EIP712, ERC20Uint96, ICompGovernance {
    using Uint96 for uint96;
    
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => address) public delegates;
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;

    constructor() {
    }
    
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        _moveDelegates(delegates[sender], delegates[recipient], Uint96.cast(amount));
        super._beforeTokenTransfer(sender, recipient, amount);
    }

    function delegate(address delegatee) public override {
        return _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) public override {
        require(block.timestamp <= deadline, "ERC20Governance: signature expired");
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, deadline));
        bytes32 digest = getDigest(structHash);
        address signatory = recover(digest, v, r, s);
        require(nonce == incrementNonce(delegatee), "ERC20Governance: invalid nonce");
        return _delegate(signatory, delegatee);
    }

    function getCurrentVotes(address account) external view override returns (uint96)  {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber) public view override returns (uint96) {
        require(blockNumber < block.number, "Comp::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) private {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = _balanceOf(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) private {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) private {
        require(block.number < 2**32, "ERC20Governance: block number exceeds 32 bits");
        uint32 blockNumber = uint32(block.number);

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    
    function _balanceOf(address account) private view returns (uint96) {
        return Uint96.cast(super.balanceOf(account));
    }
}

contract MCHCoin is ERC20Uint96Governance, IERC20Permit, Mintable {
    using Uint96 for uint96;
    
    // 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor()
        ERC20Uint96("MCHCoin","MCHC", 50000000 * 10**18)
        EIP712("MCHCoin","1") {
    }

    uint256 public offchainIssued;

    function setOffchainIssued(uint256 _new) external onlyMinter {
        offchainIssued = _new;
    }

    function onchainIssued() external view returns (uint256) {
        return super.totalSupply();
    }

    function totalSupply() public override view returns (uint256) {
        if (offchainIssued != 0) {
            return offchainIssued;
        }
        return super.totalSupply();
    }

    function mintTo(address account, uint amount) external onlyMinter returns (bool)  {
        _mint(account, amount);
        return true;
    }

    function burn(uint amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address account, uint amount) external returns (bool) {
        uint96 allowance = Uint96.cast(allowance(account, msg.sender));
        uint256 decreasedAllowance = allowance.sub(Uint96.cast(amount));
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'ERC20Permit: EXPIRED');
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, incrementNonce(owner), deadline));
        bytes32 digest = getDigest(structHash);
        address recoveredAddress = recover(digest, v, r, s);
        require(recoveredAddress == owner, 'ERC20Permit: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}