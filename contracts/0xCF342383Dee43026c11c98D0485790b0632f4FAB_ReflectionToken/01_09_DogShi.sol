// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ReflectionToken is IERC20, Context, Ownable {
    using Address for address;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    mapping(address => uint256) private _userShares;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalShare;
    uint256 private NAV;
    uint256 private LastRewardBlock;
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    
    mapping(address => uint256) private _lastRewards;
    mapping (address => bool) private _isExcluded; // Accounts to not receive rewards
    address[] private _excluded; // Accounts which do not receive rewards
    mapping(address => uint256) private _excludedBalance;

    uint256 internal constant maxSupply = 21 * 10 ** 24;
    uint256 internal constant liquiditySupply = maxSupply * 10 / 100;
    uint256 internal constant ryoshiSupply = maxSupply * 50 / 100;
    uint256 internal constant contractSupply = maxSupply - liquiditySupply - ryoshiSupply;
    uint256[] public halvingBlock = [19686542,30109852,40533162]; //mainnet

    uint256 startBlock;

    uint256 holderRewardPerBlock;
    uint256 liquidityRewardPerBlock;
    uint256 totalRewardForHolder;

    bool isActivated;
    uint256 activateTime;
    uint256 totalRewardByDAO;
    uint256 lastRewardBlockByVoting;

    address liquidityAddress;
    mapping(address => uint256) private _liquidityBlock;
    uint256 liquidityLastRewardBlock;
    uint256 liquidityAccTokensPerShare;
    mapping( address=> uint256) private rewardDebts;
    address previousLiquidityAdder;
    address votingContract;
    uint256 totalDistributedRewardByVoting;

    constructor(
        string memory tname,
        string memory tsymbol
    ) {
        _name = tname;
        _symbol = tsymbol;
        _mint(0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08, ryoshiSupply);
        _mint( address(this), contractSupply);
        _mint( _msgSender(), liquiditySupply);

        setExclude(address(this)); //no rewards for deployer
        setExclude(0xdEAD000000000000000042069420694206942069); //no rewards to dead wallet
        setExclude(0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08); //no additional rewards to Ryoshi

        totalRewardForHolder = contractSupply * 20 / 100;
        totalRewardByDAO = totalRewardForHolder;

        isActivated = false;
        activateTime = 0;
    }

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    function getCurrentSnapshotId() external view virtual returns (uint256) {
        return _getCurrentSnapshotId();
    }

    function snapshot() external returns (uint256) {
        require(_msgSender() == votingContract);
        return _snapshot();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
    
    function getRewardPerBlock( uint256 currentBlock, uint256 totalReward) internal view returns(uint256){
        uint256 rewardPerBlock = 0;
        uint256 totalBlock = 0;
        uint256 halving = 1;
        if( isActivated == false) return 0;
        for( uint i = 0; i < halvingBlock.length;i++) {
            if( currentBlock < halvingBlock[i]) {
                totalBlock += ((halvingBlock[i] - currentBlock)/halving);
            }
            halving *= 2;
        }
        if( totalBlock == 0 ) return 0;
        rewardPerBlock = totalReward / totalBlock;
        return rewardPerBlock;
    }

    function setExclude(address user) public onlyOwner {
        require(_isExcluded[user]==false,"already excluded!");
        _excludedBalance[user] = balanceOf(user);
        _excluded.push(user);
        _isExcluded[user] = true;
        NAV -= _excludedBalance[user];
        _totalShare -= _userShares[user];
        _userShares[user] = 0;
    }

    function setLiquidityAddress(address liquidity) public onlyOwner {
        liquidityAddress = liquidity;
        setExclude(liquidity);
    }

    function setVotingContractAddress(address _votingContract) public onlyOwner {
        votingContract = _votingContract;
    }

    function activateHolderReward() public onlyOwner {
        startBlock = block.number;
        isActivated = true;
        holderRewardPerBlock = getRewardPerBlock(startBlock,totalRewardForHolder);
        liquidityRewardPerBlock = holderRewardPerBlock * 3;
        activateTime = block.number;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        if(_isExcluded[account]) {
            if( account == address(this)) {
                return _excludedBalance[account] - totalUsedAmount();
            }
            return _excludedBalance[account];
        }
        uint256 balance = getRewardOfLiquidityUser(account);
        if( _totalShare == 0 ) return balance;
        uint curNAV = NAV;
        if( block.number > LastRewardBlock) {
            curNAV += getTokensReward();
        }
        balance += (curNAV * _userShares[account] / _totalShare);
        return balance;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function addingDecimal() public view returns (uint256) {
        return 10**_decimals;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);
        
        if( _isExcluded[from] && !_isExcluded[to] ) {
            _transferFromExcluded(from, to, amount);
        } else if( !_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, amount);
        } else if( !_isExcluded[from] && !_isExcluded[to]) {
            _transferStandard(from, to, amount);
        } else if(_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function distributeRewardByVoting(address _receiver, uint256 _amount) public {
        require(_msgSender() == votingContract,"only voting contract can call this function");
        uint256 amount = getPendingRewardByVoting();
        require(_amount > 0 && _amount <= amount, "Can't distribute this amount");
        _transfer( address(this), _receiver, _amount);
        totalDistributedRewardByVoting += _amount;
        lastRewardBlockByVoting = block.number;
    }

    function getPendingRewardByVoting() public view returns(uint256) {
        return getRewardAmount(holderRewardPerBlock, startBlock,block.number) - totalDistributedRewardByVoting;
    }

    function totalUsedAmount() internal view returns(uint256) {
        uint rewardPerBlock = getRewardPerBlock(startBlock, totalRewardForHolder * 4);
        uint totalUsed = getRewardAmount(rewardPerBlock, startBlock, block.number);
        return totalUsed;
    }

    function totalDistributedReward() public view returns(uint256) {
        uint totalUsed = totalUsedAmount();
        totalUsed += totalDistributedRewardByVoting;
        return totalUsed;
    }

    function getRewardAmount(uint rewardPerBlock, uint firstBlock, uint lastBlock) internal view returns(uint) {
        uint i = 0;
        if( firstBlock < startBlock) firstBlock = startBlock;
        if( lastBlock <= firstBlock) return 0;
        if( rewardPerBlock == 0) return 0;
        
        for( i = 0; i < halvingBlock.length; i++ ) {
            if( firstBlock < halvingBlock[i]) break;
            rewardPerBlock /= 2;
        }
        if(i == halvingBlock.length) {
            return 0;
        }
        uint256 totalReward = 0;
        for( uint j = i; j < halvingBlock.length; j++) {
            if( lastBlock < halvingBlock[j]) {
                totalReward += rewardPerBlock*(lastBlock-firstBlock);
                break;
            }
            totalReward += rewardPerBlock*(halvingBlock[j]-firstBlock);
            firstBlock = halvingBlock[j];
            rewardPerBlock /= 2;
        }
        return totalReward;        
    }

    function getTokensReward() public view returns(uint256) {
        return getRewardAmount(holderRewardPerBlock, LastRewardBlock, block.number);
    }

    function getRewardOfLiquidityUser(address user) public view returns(uint256) {
        uint256 accTokensPerShare = liquidityAccTokensPerShare;
        if(liquidityAddress == address(0)) return 0;
        uint256 lpSupply = IERC20(liquidityAddress).totalSupply();
        uint256 lpBalance = IERC20(liquidityAddress).balanceOf(user);
        uint256 curBlock = block.number;
        uint256 finalBlock = halvingBlock[halvingBlock.length-1];
        if( curBlock > finalBlock) curBlock = finalBlock;
        if (curBlock > liquidityLastRewardBlock && lpSupply != 0) {
            uint256 tokensReward = getLiquidityTokensReward();
            accTokensPerShare += (tokensReward * addingDecimal() / lpSupply);
        }
        uint256 rewardDebt = rewardDebts[user];
        if( user == previousLiquidityAdder)
            rewardDebt = lpBalance * liquidityAccTokensPerShare / addingDecimal();
        return lpBalance * accTokensPerShare / addingDecimal() - rewardDebt;
    }

    function getLiquidityTokensReward() public view returns(uint256) {
        return getRewardAmount(liquidityRewardPerBlock, liquidityLastRewardBlock, block.number);
    }

    function _transferStandard(address from, address to, uint256 amount) private {
        NAV += getTokensReward();
        uint valuePerShare = NAV * addingDecimal() / _totalShare;
        uint shareAmount = amount * addingDecimal() / valuePerShare;
        _userShares[from] -= shareAmount;
        _userShares[to] += shareAmount;
        LastRewardBlock = block.number;
    }

    function _transferFromExcluded(address from, address to, uint256 amount) private {
        NAV += getTokensReward();
        uint valuePerShare = NAV * addingDecimal() / _totalShare;
        uint shareAmount = amount * addingDecimal() / valuePerShare;
        NAV += amount;
        _excludedBalance[from] -= amount;
        _userShares[to] += shareAmount;
        _totalShare += shareAmount;
        LastRewardBlock = block.number;
        if( from == liquidityAddress) {
            uint256 liquidityTotalSupply = IERC20(liquidityAddress).totalSupply();
            if( liquidityLastRewardBlock == 0) {
                previousLiquidityAdder = to;
                liquidityLastRewardBlock = block.number;
            } else if( block.number > liquidityLastRewardBlock){
                uint256 previousBalance = IERC20(liquidityAddress).balanceOf(previousLiquidityAdder);
                rewardDebts[previousLiquidityAdder] = previousBalance * liquidityAccTokensPerShare;
                liquidityAccTokensPerShare += getLiquidityTokensReward() / liquidityTotalSupply;
                uint256 toUNIBalance = IERC20(liquidityAddress).balanceOf(to);
                uint256 toPendingBalance = liquidityAccTokensPerShare * toUNIBalance / addingDecimal() - rewardDebts[to];
                if( toPendingBalance > 0) {
                    _userShares[to] += (toPendingBalance * addingDecimal() / valuePerShare);
                }
                liquidityLastRewardBlock = block.number;
                previousLiquidityAdder = to;
            }
        }
    }

    function _transferToExcluded(address from, address to, uint256 amount) private {
        NAV += getTokensReward();
        uint valuePerShare = NAV * addingDecimal() / _totalShare;
        uint shareAmount = amount * addingDecimal() / valuePerShare;
        NAV -= amount;
        _userShares[from] -= shareAmount;
        _excludedBalance[to] += amount;
        _totalShare -= shareAmount;
        LastRewardBlock = block.number;
        if( to == liquidityAddress) {
            uint256 liquidityTotalSupply = IERC20(liquidityAddress).totalSupply();
            if( liquidityLastRewardBlock == 0) {
                previousLiquidityAdder = from;
                liquidityLastRewardBlock = block.number;
            } else if( block.number > liquidityLastRewardBlock){
                uint256 previousBalance = IERC20(liquidityAddress).balanceOf(previousLiquidityAdder);
                rewardDebts[previousLiquidityAdder] = previousBalance * liquidityAccTokensPerShare;
                liquidityAccTokensPerShare += getLiquidityTokensReward() / liquidityTotalSupply;
                uint256 fromUNIBalance = IERC20(liquidityAddress).balanceOf(from);
                uint256 fromPendingBalance = liquidityAccTokensPerShare * fromUNIBalance / addingDecimal() - rewardDebts[from];
                if( fromPendingBalance > 0) {
                    _userShares[from] += (fromPendingBalance * addingDecimal() / valuePerShare);
                }
                liquidityLastRewardBlock = block.number;
                previousLiquidityAdder = from;
            }
        }
    }

    function _transferBothExcluded(address from, address to, uint256 amount) private {
        _excludedBalance[from] -= amount;
        _excludedBalance[to] += amount;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        if( _totalShare == 0 ) {
            NAV += amount;
            _userShares[account] += addingDecimal();
            _totalShare += addingDecimal();
        } else {
            NAV += getTokensReward();
            uint valuePerShare = NAV * addingDecimal() / _totalShare;
            uint shareAmount = amount * addingDecimal() / valuePerShare;
            _userShares[account] += shareAmount;
            _totalShare += shareAmount;
            NAV += amount;
        }
        LastRewardBlock = block.number;
        

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        NAV += getTokensReward();
        uint valuePerShare = NAV * addingDecimal() / _totalShare;
        uint shareAmount = amount * addingDecimal() / valuePerShare;
        _userShares[account] -= shareAmount;
        _totalShare -= shareAmount;
        NAV -= amount;
        LastRewardBlock = block.number;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}