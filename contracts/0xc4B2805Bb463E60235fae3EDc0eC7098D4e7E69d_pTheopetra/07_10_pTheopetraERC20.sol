// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import "../Interfaces/IStakedTHEOToken.sol";

import "../Types/ERC20Permit.sol";
import "../Types/TheopetraAccessControlled.sol";

contract pTheopetra is IStakedTHEOToken, ERC20Permit, TheopetraAccessControlled {
    using SafeMath for uint256;

    modifier onlyStakingContract() {
        require(msg.sender == stakingContract, "UNAUTHORIZED");
        _;
    }

    address public stakingContract;
    address public initializer;

    event LogSupply(uint256 indexed epoch, uint256 timestamp, uint256 totalSupply);
    event LogRebase(uint256 indexed epoch, uint256 rebase, uint256 index);
    event LogStakingContractUpdated(address stakingContract);
    event SetIndex(uint256 index);

    struct Rebase {
        uint256 epoch;
        uint256 rebase; // 18 decimals
        uint256 totalStakedBefore;
        uint256 totalStakedAfter;
        uint256 amountRebased;
        uint256 index;
        uint256 blockNumberOccured;
    }
    Rebase[] public rebases;

    uint256 public INDEX;

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5000000 * 10**9;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1

    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedValue;

    address public treasury;

    constructor(address _authority)
        ERC20("Platinum Staked Theo", "pTHEO", 9)
        ERC20Permit()
        TheopetraAccessControlled(ITheopetraAuthority(_authority))
    {
        initializer = msg.sender;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    }

    function initialize(address stakingContract_) external returns (bool) {
        require(msg.sender == initializer, "UNAUTHORIZED");
        require(stakingContract_ != address(0), "stakingContract cannot be the zero address");
        stakingContract = stakingContract_;
        _gonBalances[stakingContract] = TOTAL_GONS;

        emit Transfer(address(0x0), stakingContract, _totalSupply);
        emit LogStakingContractUpdated(stakingContract_);

        initializer = address(0);
        return true;
    }

    function setIndex(uint256 _INDEX) external onlyGuardian returns (bool) {
        require(INDEX == 0, "Index already set");
        INDEX = gonsForBalance(_INDEX);
        emit SetIndex(INDEX);
        return true;
    }

    /**
        @notice increases sTHEO supply to increase staking balances relative to profit_
        @param profit_ uint256
        @return uint256
     */
    function rebase(uint256 profit_, uint256 epoch_) external override onlyStakingContract returns (uint256) {
        uint256 rebaseAmount;
        uint256 circulatingSupply_ = circulatingSupply();

        if (profit_ == 0) {
            emit LogSupply(epoch_, block.timestamp, _totalSupply);
            emit LogRebase(epoch_, 0, index());
            return _totalSupply;
        } else if (circulatingSupply_ > 0) {
            rebaseAmount = profit_.mul(_totalSupply).div(circulatingSupply_);
        } else {
            rebaseAmount = profit_;
        }

        _totalSupply = _totalSupply.add(rebaseAmount);

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _storeRebase(circulatingSupply_, profit_, epoch_);

        return _totalSupply;
    }

    /**
        @notice emits event with data about rebase
        @param previousCirculating_ uint
        @param profit_ uint
        @param epoch_ uint
        @return bool
     */
    function _storeRebase(
        uint256 previousCirculating_,
        uint256 profit_,
        uint256 epoch_
    ) internal returns (bool) {
        uint256 rebasePercent = previousCirculating_ > 0 ? profit_.mul(1e18).div(previousCirculating_) : 0;

        rebases.push(
            Rebase({
                epoch: epoch_,
                rebase: rebasePercent, // 18 decimals
                totalStakedBefore: previousCirculating_,
                totalStakedAfter: circulatingSupply(),
                amountRebased: profit_,
                index: index(),
                blockNumberOccured: block.number
            })
        );

        emit LogSupply(epoch_, block.timestamp, _totalSupply);
        emit LogRebase(epoch_, rebasePercent, index());

        return true;
    }

    function balanceOf(address who) public view override(IStakedTHEOToken, ERC20) returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function gonsForBalance(uint256 amount) public view override returns (uint256) {
        return amount.mul(_gonsPerFragment);
    }

    function balanceForGons(uint256 gons) public view override returns (uint256) {
        return gons.div(_gonsPerFragment);
    }

    // Staking contract holds excess sTHEO
    function circulatingSupply() public view override returns (uint256) {
        return _totalSupply.sub(balanceOf(stakingContract));
    }

    function index() public view override returns (uint256) {
        return balanceForGons(INDEX);
    }

    function transfer(address to, uint256 value) external override(ERC20, IERC20) returns (bool) {
        uint256 gonValue = gonsForBalance(value);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender) public view override(ERC20, IERC20) returns (uint256) {
        return _allowedValue[owner_][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override(ERC20, IERC20) returns (bool) {
        _allowedValue[from][msg.sender] = _allowedValue[from][msg.sender].sub(value);
        emit Approval(from, msg.sender, _allowedValue[from][msg.sender]);

        uint256 gonValue = gonsForBalance(value);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value) external override(ERC20, IERC20) returns (bool) {
        _allowedValue[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // What gets called in a permit
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual override {
        _allowedValue[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        _allowedValue[msg.sender][spender] = _allowedValue[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedValue[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        uint256 oldValue = _allowedValue[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedValue[msg.sender][spender] = 0;
        } else {
            _allowedValue[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedValue[msg.sender][spender]);
        return true;
    }
}