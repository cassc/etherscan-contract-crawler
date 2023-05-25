// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IIchiV2.sol";

contract IchiV2 is IIchiV2 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // EIP-20 token name for this token
    string public constant override name = "ICHI";

    // EIP-20 token symbol for this token
    string public constant override symbol = "ICHI";

    // EIP-20 token decimals for this token
    uint8 public constant override decimals = 18;

    // ICHI V1 address
    address public immutable override ichiV1;

    // constant that represents 100%
    uint256 constant PERCENT = 100;

    // constant that represents difference in decimals between ICHI V1 and ICHI V2 tokens
    uint256 constant DECIMALS_DIFF = 1e9;

    // constant that represents address(0)
    address constant NULL_ADDRESS = address(0);

    // Total number of tokens in circulation
    // Initially capped at 5 million ICHI, another 5 million can be minted via swaps with ICHI V1
    // On top of it 2% extra (inflationary) tokens can be minted with 1 year intervals
    uint256 public override totalSupply = 5_000_000e18; 

    // Address which may mint inflationary tokens
    address public override minter;

    // The timestamp after which inflationary minting may occur
    uint256 public override mintingAllowedAfter;

    // Minimum time between inflationary mints
    uint32 public constant override minimumTimeBetweenMints = 1 days * 365;

    // Cap on the percentage of totalSupply that can be minted at each inflationary mint
    uint8 public constant override mintCap = 2;

    // ICHI V2 to ICHI V1 conversion fee (default is 0%)
    uint256 public override conversionFee = 0;

    // Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    // Official record of token balances for each account
    mapping (address => uint96) internal balances;

    // A record of each accounts delegate
    mapping (address => address) public override delegates;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public override checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) public override numCheckpoints;

    // The EIP-712 typehash for the contract's domain
    bytes32 public constant override DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant override DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant override PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    // A record of states for signing / validating signatures
    mapping (address => uint256) public override nonces;

    /**
     * @notice Construct a new ICHI token
     * @param account The initial account to grant 5 million tokens
     * @param minter_ The account with minting ability
     * @param ichi_v1_ ICHI V1 address
     * @param mintingAllowedAfter_ The timestamp after which inflationary minting may occur
     */
    constructor(address account, address minter_, address ichi_v1_, uint256 mintingAllowedAfter_) {
        require(mintingAllowedAfter_ >= block.timestamp, "IchiV2.constructor: minting can only begin after deployment");
        require(account != NULL_ADDRESS && minter_ != NULL_ADDRESS && ichi_v1_ != NULL_ADDRESS, "IchiV2.constructor: cannot init with zero addresses");

        balances[account] = uint96(totalSupply);
        ichiV1 = ichi_v1_;
        minter = minter_;
        mintingAllowedAfter = mintingAllowedAfter_;

        emit Transfer(NULL_ADDRESS, account, totalSupply);
        emit MinterChanged(NULL_ADDRESS, minter);
    }

    /**
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external override {
        require(msg.sender == minter, "IchiV2.setMinter: only the minter can change the minter address");
        require(minter_ != NULL_ADDRESS, "IchiV2.setMinter: cannot use zero address");
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param amount The number of tokens to be minted
     */
    function mint(address dst, uint256 amount) external override {
        require(msg.sender == minter, "IchiV2.mint: only the minter can mint");
        require(block.timestamp >= mintingAllowedAfter, "IchiV2.mint: minting not allowed yet");
        require(dst != NULL_ADDRESS, "IchiV2.mint: cannot transfer to the zero address");

        // record the mint
        mintingAllowedAfter = block.timestamp.add(minimumTimeBetweenMints);

        // mint the amount
        uint96 amount96 = safe96(amount, "IchiV2.mint: amount exceeds 96 bits");
        require(amount <= totalSupply.mul(mintCap).div(PERCENT), "IchiV2.mint: exceeded mint cap");
        totalSupply = uint256(safe96(totalSupply.add(amount), "IchiV2.mint: totalSupply exceeds 96 bits"));

        // transfer the amount to the recipient
        balances[dst] = add96(balances[dst], amount96, "IchiV2.mint: destination balance overflows");
        emit Transfer(NULL_ADDRESS, dst, amount);

        // move delegates
        _moveDelegates(NULL_ADDRESS, delegates[dst], amount96);
    }

    /**
     * @notice Change the ICHI V2 to ICHI V1 conversion fee
     * @param fee_ New conversion fee, 0-100%
     */
    function setConversionFee(uint256 fee_) external override {
        require(fee_ <= 100, "IchiV2.setConversionFee: fee must be <= 100");
        require(msg.sender == minter, "IchiV2.setConversionFee: only the minter can change the converson fee");
        conversionFee = fee_;
        emit ConversionFeeChanged(minter, fee_);
    }     

    /**
     * @notice Convert ICHI V1 tokens to ICHI V2 tokens
     * @param v1Amount The number of ICHI V1 tokens to be converted (using 9 decimals representation)
     */
    function convertToV2(uint256 v1Amount) external override {
        require(v1Amount > 0, "IchiV2.convertToV2: amount must be > 0");

        // convert 9 decimals ICHI V1 to 18 decimals ICHI V2
        uint256 v2Amount = v1Amount.mul(DECIMALS_DIFF);
        uint96 v2Amount96 = safe96(v2Amount, "IchiV2.convertToV2: amount exceeds 96 bits");

        // transfer ICHI V1 tokens in
        IERC20(ichiV1).safeTransferFrom(msg.sender, address(this), v1Amount);

        // increase ICHI V2 totalSupply
        totalSupply = totalSupply.add(v2Amount);

        // transfer the amount of ICHI V2 to the recipient
        balances[msg.sender] = add96(balances[msg.sender], v2Amount96, "IchiV2.convertToV2: transfer amount overflows");

        emit ConvertedToV2(msg.sender, v1Amount, v2Amount);
        emit Transfer(NULL_ADDRESS, msg.sender, v2Amount);

        // move delegates
        _moveDelegates(NULL_ADDRESS, delegates[msg.sender], v2Amount96);
    }

    /**
     * @notice Convert ICHI V2 tokens back to ICHI V1 tokens
     * @param v2Amount The number of ICHI V2 tokens to be converted (using 18 decimals representation)
     */
    function convertToV1(uint256 v2Amount) external override {
        require(v2Amount > 0, "IchiV2.convertToV1: amount must be > 0");
        uint96 v2Amount96 = safe96(v2Amount, "IchiV2.convertToV1: amount exceeds 96 bits");
        require(v2Amount96 <= balances[msg.sender], "IchiV2.convertToV1: insufficient V2 balance");

        // convert 18 decimals ICHI V2 to 9 decimals ICHI V2 and take off the conversion fee
        uint256 v1Amount = v2Amount.mul(PERCENT.sub(conversionFee)).div(DECIMALS_DIFF).div(PERCENT);
        require(v1Amount > 0, "IchiV2.convertToV1: amount is too small");

        // decrease ICHI V2 totalSupply
        totalSupply = totalSupply.sub(v2Amount);

        // burn the traded amount of ICHI V2
        balances[msg.sender] = sub96(balances[msg.sender], v2Amount96, "IchiV2.convertToV1: transfer amount overflows");

        // transfer ICHI V1 tokens to the user
        IERC20(ichiV1).safeTransfer(msg.sender, v1Amount);

        emit ConvertedToV1(msg.sender, v2Amount96, v1Amount);
        emit Transfer(msg.sender, NULL_ADDRESS, v2Amount96);

        // move delegates
        _moveDelegates(delegates[msg.sender], NULL_ADDRESS, v2Amount96);
    }   

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param _owner The address of the account holding the funds
     * @param _spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return uint256(allowances[_owner][_spender]);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param _spender The address of the account which may transfer tokens
     * @param _value The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address _spender, uint256 _value) external override returns (bool) {
        uint96 amount;
        if (_value == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_value, "IchiV2.approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][_spender] = amount;

        emit Approval(msg.sender, _spender, uint256(amount));
        return true;
    }

    /**
     * @notice Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     * @return domain separator
     */
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint256 rawAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "IchiV2.permit: amount exceeds 96 bits");
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != NULL_ADDRESS, "IchiV2.permit: invalid signature");
        require(signatory == owner, "IchiV2.permit: unauthorized");
        require(block.timestamp <= deadline, "IchiV2.permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, uint256(amount));
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param _owner The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address _owner) external view override returns (uint256) {
        return uint256(balances[_owner]);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param _to The address of the destination account
     * @param _value The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address _to, uint256 _value) external override returns (bool) {
        uint96 amount = safe96(_value, "IchiV2.transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, _to, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param _from The address of the source account
     * @param _to The address of the destination account
     * @param _value The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[_from][spender];
        uint96 amount96 = safe96(_value, "IchiV2.approve: amount exceeds 96 bits");

        if (spender != _from && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount96, "IchiV2.transferFrom: transfer amount exceeds spender allowance");
            allowances[_from][spender] = newAllowance;

            emit Approval(_from, spender, uint256(newAllowance));
        }

        _transferTokens(_from, _to, amount96);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public override {
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
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public override {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != NULL_ADDRESS, "IchiV2.delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "IchiV2.delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "IchiV2.delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view override returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view override returns (uint96) {
        require(blockNumber < block.number, "IchiV2.getPriorVotes: not yet determined");

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

    /**
     * @notice Delegate votes from `delegator` to `delegatee`
     * @param delegator The address of the delegator
     * @param delegatee The address to delegate votes to
     */
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != NULL_ADDRESS, "IchiV2._transferTokens: cannot transfer from the zero address");
        require(dst != NULL_ADDRESS, "IchiV2._transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "IchiV2._transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "IchiV2._transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    /**
     * @notice Move delegate votes from `delegator` to `delegatee`
     * @param srcRep The address of the delegator
     * @param dstRep The address to delegate votes to
     * @param amount The number of tokens to delegate
     */
    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != NULL_ADDRESS) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "IchiV2._moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != NULL_ADDRESS) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "IchiV2._moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * @notice Create new votes checkpoint for a `delegatee`
     * @param delegatee The address of the delegatee
     * @param nCheckpoints Current number of checkpoints for the `delegatee`
     * @param oldVotes Old number of votes
     * @param newVotes New number of votes
     */
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "IchiV2._writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, uint256(oldVotes), uint256(newVotes));
    }

    /**
     * @notice safe conversion to uint32
     * @param n number to convert
     * @param errorMessage error raised during the conversion
     * @return converted unit32 number
     */
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * @notice safe conversion to uint96
     * @param n number to convert
     * @param errorMessage error raised during the conversion
     * @return converted unit96 number
     */
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    /**
     * @notice safe addition for uint96
     * @param a number to add
     * @param b number to add
     * @param errorMessage error raised during the conversion
     * @return the result of the addition
     */
    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    /**
     * @notice safe subtraction for uint96
     * @param a initial number
     * @param b number to subtract
     * @param errorMessage error raised during the conversion
     * @return the result of the subtraction
     */
    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @notice returns the chain ID
     * @return chain ID
     */
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}