pragma solidity 0.8.6;


import "IERC777.sol";
import "ReentrancyGuard.sol";
import "IERC777Recipient.sol";
import "IERC1820Registry.sol";
import "IStakeManager.sol";
import "IOracle.sol";
import "Shared.sol";


contract StakeManager is IStakeManager, Shared, ReentrancyGuard, IERC777Recipient {

    uint public constant STAN_STAKE = 10000 * _E_18;
    uint public constant BLOCKS_IN_EPOCH = 100;
    bytes private constant _stakingIndicator = "staking";

    IOracle private immutable _oracle;
    // AUTO ERC777
    IERC777 private _AUTO;
    bool private _AUTOSet = false;
    IERC1820Registry constant private _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256('ERC777TokensRecipient');
    uint private _totalStaked = 0;
    // Needed so that receiving AUTO is rejected unless it's indicated
    // that's it's used for staking and therefore not an accident (protect users)
    Executor private _executor;
    mapping(address => uint) private _stakerToStakedAmount;
    address[] private _stakes;


    // Pasted for convenience here, defined in IStakeManager
    // struct Executor{
    //     address addr;
    //     uint96 forEpoch;
    // }


    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);


    constructor(IOracle oracle) {
        _oracle = oracle;
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }


    function setAUTO(IERC777 AUTO) external {
        require(!_AUTOSet, "SM: AUTO already set");
        _AUTOSet = true;
        _AUTO = AUTO;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getOracle() external view override returns (IOracle) {
        return _oracle;
    }

    function getAUTOAddr() external view override returns (address) {
        return address(_AUTO);
    }

    function getTotalStaked() external view override returns (uint) {
        return _totalStaked;
    }

    function getStake(address staker) external view override returns (uint) {
        return _stakerToStakedAmount[staker];
    }

    function getStakes() external view override returns (address[] memory) {
        return _stakes;
    }

    function getStakesLength() external view override returns (uint) {
        return _stakes.length;
    }

    function getStakesSlice(uint startIdx, uint endIdx) external view override returns (address[] memory) {
        address[] memory slice = new address[](endIdx - startIdx);
        uint sliceIdx = 0;
        for (uint stakeIdx = startIdx; stakeIdx < endIdx; stakeIdx++) {
            slice[sliceIdx] = _stakes[stakeIdx];
            sliceIdx++;
        }

        return slice;
    }

    function getCurEpoch() public view override returns (uint96) {
        return uint96((block.number / BLOCKS_IN_EPOCH) * BLOCKS_IN_EPOCH);
    }

    function getExecutor() external view override returns (Executor memory) {
        return _executor;
    }

    function isCurExec(address addr) external view override returns (bool) {
        // So that the storage is only loaded once
        Executor memory ex = _executor;
        if (ex.forEpoch == getCurEpoch()) {
            if (ex.addr == addr) {
                return true;
            } else {
                return false;
            }
        }
        // If there're no stakes, allow anyone to be the executor so that a random
        // person can bootstrap the network and nobody needs to be sent any coins
        if (_stakes.length == 0) { return true; }

        return false;
    }

    function getUpdatedExecRes() public view override returns (uint96 epoch, uint randNum, uint idxOfExecutor, address exec) {
        epoch = getCurEpoch();
        // So that the storage is only loaded once
        uint stakesLen = _stakes.length;
        // If the executor is out of date and the system already has stake,
        // choose a new executor. This will do nothing if the system is starting
        // and allow someone to stake without needing there to already be existing stakes
        if (_executor.forEpoch != epoch && stakesLen > 0) {
            // -1 because blockhash(seed) in Oracle will return 0x00 if the
            // seed == this block's height
            randNum = _oracle.getRandNum(epoch - 1);
            idxOfExecutor = randNum % stakesLen;
            exec = _stakes[idxOfExecutor];
        }
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Staking                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function updateExecutor() external override nonReentrant noFish returns (uint, uint, uint, address) {
        return _updateExecutor();
    }

    function isUpdatedExec(address addr) external override nonReentrant noFish returns (bool) {
        // So that the storage is only loaded once
        Executor memory ex = _executor;
        if (ex.forEpoch == getCurEpoch()) {
            if (ex.addr == addr) {
                return true;
            } else {
                return false;
            }
        } else {
            (, , , address exec) = _updateExecutor();
            if (exec == addr) { return true; }
        }
        if (_stakes.length == 0) { return true; }

        return false;
    }

    // The 1st stake/unstake of an epoch shouldn't change the executor, otherwise
    // a staker could precalculate the effect of how much they stake in order to
    // game the staker selection algo
    function stake(uint numStakes) external nzUint(numStakes) nonReentrant updateExec noFish override {
        uint amount = numStakes * STAN_STAKE;
        _stakerToStakedAmount[msg.sender] += amount;
        // So that the storage is only loaded once
        IERC777 AUTO = _AUTO;

        // Deposit the coins
        uint balBefore = AUTO.balanceOf(address(this));
        AUTO.operatorSend(msg.sender, address(this), amount, "", _stakingIndicator);
        // This check is a bit unnecessary, but better to be paranoid than r3kt
        require(AUTO.balanceOf(address(this)) - balBefore == amount, "SM: transfer bal check failed");

        for (uint i; i < numStakes; i++) {
            _stakes.push(msg.sender);
        }

        _totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint[] calldata idxs) external nzUintArr(idxs) nonReentrant updateExec noFish override {
        uint amount = idxs.length * STAN_STAKE;
        require(amount <= _stakerToStakedAmount[msg.sender], "SM: not enough stake, peasant");

        for (uint i = 0; i < idxs.length; i++) {
            require(_stakes[idxs[i]] == msg.sender, "SM: idx is not you");
            require(idxs[i] < _stakes.length, "SM: idx out of bounds");
            // Update stakes by moving the last element to the
            // element we're wanting to delete (so it doesn't leave gaps, which is
            // necessary for the _updateExecutor algo)
            _stakes[idxs[i]] = _stakes[_stakes.length-1];
            _stakes.pop();
        }
        
        _stakerToStakedAmount[msg.sender] -= amount;
        _AUTO.send(msg.sender, amount, _stakingIndicator);
        _totalStaked -= amount;
        emit Unstaked(msg.sender, amount);
    }

    function _updateExecutor() private returns (uint96 epoch, uint randNum, uint idxOfExecutor, address exec) {
        (epoch, randNum, idxOfExecutor, exec) = getUpdatedExecRes();
        if (exec != _ADDR_0) {
            _executor = Executor(exec, epoch);
        }
    }

    modifier updateExec() {
        // Need to update executor at the start of stake/unstake as opposed to the
        // end of the fcns because otherwise, for the 1st stake/unstake tx in an
        // epoch, someone could influence the outcome of the executor by precalculating
        // the outcome based on how much they stake and unfairly making themselves the executor
        _updateExecutor();
        _;
    }

    // Ensure the contract is fully collateralised every time
    modifier noFish() {
        _;
        // >= because someone could send some tokens to this contract and disable it if it was ==
        require(_AUTO.balanceOf(address(this)) >= _totalStaked, "SM: something fishy here");
    }

    function tokensReceived(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external override {
        require(msg.sender == address(_AUTO), "SM: non-AUTO token");
        require(keccak256(_operatorData) == keccak256(_stakingIndicator), "SM: sending by mistake");
    }

}