// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract KeyfiToken is IERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "KeyFi Token";
    string public constant symbol = "KEYFI";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply = 10000000e18;

    mapping (address => mapping (address => uint256)) internal allowances;
    mapping (address => uint256) internal balances;
    mapping (address => address) public delegates;


    address public minter;
    uint256 public mintingAllowedAfter;
    uint32 public minimumMintGap = 1 days * 365;
    uint8 public mintCap = 2;

    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    mapping (address => mapping (uint256 => Checkpoint)) public checkpoints;    
    mapping (address => uint256) public numCheckpoints;
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => uint) public nonces;

    event MinterChanged(address minter, address newMinter);
    event MinimumMintGapChanged(uint32 previousMinimumGap, uint32 newMinimumGap);
    event MintCapChanged(uint8 previousCap, uint8 newCap);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);    
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    constructor(address account, address _minter, uint256 _mintingAllowedAfter) {
        balances[account] = totalSupply;
        minter = _minter;
        mintingAllowedAfter = _mintingAllowedAfter;
        
        emit Transfer(address(0), account, totalSupply);
        emit MinterChanged(address(0), minter);
    }

    /**
     * @dev Change the minter address
     * @param _minter The address of the new minter
     */
    function setMinter(address _minter) 
        external 
        onlyOwner
    {
        emit MinterChanged(minter, _minter);
        minter = _minter;
    }

    function setMintCap(uint8 _cap) 
        external 
        onlyOwner 
    {
        emit MintCapChanged(mintCap, _cap);
        mintCap = _cap;
    }

    function setMinimumMintGap(uint32 _gap) 
        external
        onlyOwner
    {
        emit MinimumMintGapChanged(minimumMintGap, _gap);
        minimumMintGap = _gap;
    }

    function mint(address _to, uint256 _amount) 
        external 
    {
        require(msg.sender == minter, "KeyfiToken::mint: only the minter can mint");
        require(block.timestamp >= mintingAllowedAfter, "KeyfiToken::mint: minting not allowed yet");
        require(_to != address(0), "KeyfiToken::mint: cannot transfer to the zero address");
        require(_amount <= (totalSupply.mul(mintCap)).div(100), "KeyfiToken::mint: exceeded mint cap");

        mintingAllowedAfter = (block.timestamp).add(minimumMintGap);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        _moveDelegates(address(0), delegates[_to], _amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) 
        public
        view 
        override 
        returns (uint256) 
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) 
        public 
        override
        returns (bool) 
    {
        require(spender != address(0), "KeyfiToken: cannot approve zero address");

        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) 
        external 
        view 
        override 
        returns (uint256) 
    {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) 
        external 
        override
        returns (bool) 
    {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) 
        external 
        override
        returns (bool) 
    {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = sub256(spenderAllowance, amount, "KeyfiToken::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) 
        external 
    {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) 
        external 
    {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "KeyfiToken::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "KeyfiToken::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "KeyfiToken::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) 
        external 
        view 
        returns (uint256) 
    {
        uint256 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) 
        external 
        view 
        returns (uint256) 
    {
        require(blockNumber < block.number, "KeyfiToken::getPriorVotes: not yet determined");

        uint256 nCheckpoints = numCheckpoints[account];
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

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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

    function _delegate(address delegator, address delegatee) 
        internal 
    {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint256 amount) 
        internal 
    {
        require(src != address(0), "KeyfiToken::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "KeyfiToken::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub256(balances[src], amount, "KeyfiToken::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add256(balances[dst], amount, "KeyfiToken::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) 
        internal 
    {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = sub256(srcRepOld, amount, "KeyfiToken::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = add256(dstRepOld, amount, "KeyfiToken::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) 
        internal 
    {
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(block.number, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function add256(uint256 a, uint256 b, string memory errorMessage) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;  
    }

    function sub256(uint256 a, uint256 b, string memory errorMessage) 
        internal 
        pure 
        returns (uint256) 
    {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount)
        internal 
    {
        require(account != address(0), "ERC20: burn from the zero address");

        balances[account] = balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        
        _moveDelegates(delegates[account], address(0), amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     */
    function burn(uint256 amount) 
        external 
        returns (bool)
    {
        _burn(msg.sender, amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) 
        external
        returns (bool)
    {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[account][spender];

        if (spender != account && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = sub256(spenderAllowance, amount, "KeyfiToken::burnFrom: burn amount exceeds spender allowance");
            allowances[account][spender] = newAllowance;

            emit Approval(account, spender, newAllowance);
        }

        _burn(account, amount);
        return true;
    }
}