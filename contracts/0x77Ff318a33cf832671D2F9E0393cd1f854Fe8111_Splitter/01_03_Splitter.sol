// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import "IERC20.sol";
import "EnumerableSet.sol";
interface ICurveFi {
    function exchange(
        // CRV-ETH and CVX-ETH
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth
    ) external returns (uint);
}
interface IGauge {
    struct VotedSlope {
        uint slope;
        uint power;
        uint end;
    }
    struct Point {
        uint bias;
        uint slope;
    }
    function vote_user_slopes(address, address) external view returns (VotedSlope memory);
    function last_user_vote(address, address) external view returns (uint);
    function points_weight(address, uint256) external view returns (Point memory);
    function checkpoint_gauge(address) external;
    function time_total() external view returns (uint);
}

interface IStrategy {
    function estimatedTotalAssets() external view returns (uint);
    function rewardsContract() external view returns (address);
}

interface IRewards {
    function getReward(address, bool) external;
}

interface IYCRV {
    function mint(uint, address) external;
}

contract Splitter {
    using EnumerableSet for EnumerableSet.AddressSet;
    event Split(uint yearnAmount, uint keep, uint templeAmount, uint period);
    event PeriodUpdated(uint period, uint globalBias, uint userBias);
    event YearnUpdated(address recipient, uint keepCRV);
    event TempleUpdated(address recipient);
    event ShareUpdated(uint share);
    event PendingShareUpdated(address setter, uint share);
    event Sweep(address sweeper, address token, uint amount);
    event ApprovedCaller(address admin, address caller);
    event RemovedCaller(address admin, address caller);

    struct Yearn{
        address recipient;
        address voter;
        address admin;
        uint share;
        uint keepCRV;
    }
    struct Period{
        uint period;
        uint globalBias;
        uint userBias;
    }

    uint internal constant precision = 10_000;
    uint internal constant WEEK = 7 days;
    ICurveFi internal constant cvxeth = ICurveFi(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    ICurveFi internal constant crveth = ICurveFi(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511); // use curve's new CRV-ETH crypto pool to sell our CRV
    IERC20 internal constant cvx = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 internal constant crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 internal constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IYCRV internal constant ycrv = IYCRV(0xFCc5c47bE19d06BF83eB04298b026F81069ff65b);
    IERC20 public constant liquidityPool = IERC20(0xdaDfD00A2bBEb1abc4936b1644a3033e1B653228);
    IGauge public constant gaugeController = IGauge(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);
    address public constant gauge = 0x8f162742a7BCDb87EB52d83c687E43356055a68B;
    mapping(address => uint) public pendingShare; 
    Yearn public yearn;
    Period public period;
    address public strategy;
    address public templeRecipient = 0xE97CB3a6A0fb5DA228976F3F2B8c37B6984e7915;
    EnumerableSet.AddressSet private approvedCallers;
    
    constructor() public {
        crv.approve(address(ycrv), type(uint).max);
        cvx.approve(address(cvxeth), type(uint).max);
        weth.approve(address(crveth), type(uint).max);
        approvedCallers.add(0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52); // Yearn
        approvedCallers.add(0xE97CB3a6A0fb5DA228976F3F2B8c37B6984e7915); // Temple
        yearn = Yearn(
            address(0x93A62dA5a14C80f265DAbC077fCEE437B1a0Efde), // recipient
            address(0xF147b8125d2ef93FB6965Db97D6746952a133934), // voter
            address(0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52), // admin
            8_000, // share of profit (initial terms of deal)
            0 // Yearn's discretionary % of CRV to lock to yCRV on each split
        );
    }

    function split() external {
        require(isApprovedCaller(msg.sender) || msg.sender == strategy, "!approved");
        _split();
    }

    function _split() internal {
        address _strategy = strategy; // Put strategy address into memory.
        if(_strategy == address(0)) return;
        IRewards(IStrategy(strategy).rewardsContract()).getReward(strategy, true);
        uint bal = cvx.balanceOf(strategy);
        if (bal > 0) {
            cvx.transferFrom(strategy, address(this), bal);
            _sellCvx(bal);
            uint bought = _buyCRV();
            crv.transfer(_strategy, bought); // Transfer back to the strat
        }
        uint crvBalance = crv.balanceOf(_strategy);
        if (crvBalance == 0) {
            emit Split(0, 0, 0, period.period);
            return;
        }
        crv.transferFrom(strategy, address(this), crvBalance);
        _updatePeriod();
        (uint yRatio, uint tRatio) = _computeSplitRatios();
        if (yRatio == 0) {
            crv.transfer(templeRecipient, crvBalance);
            emit Split(0, 0, crvBalance, period.period);
            return;
        }
        uint yearnAmount = crvBalance * yRatio / precision;
        uint templeAmount = crvBalance * tRatio / precision;
        uint keep = yearnAmount * yearn.keepCRV / precision;
        if (keep > 0) {
            ycrv.mint(keep, yearn.recipient);
        }
        crv.transfer(yearn.recipient, yearnAmount - keep);
        crv.transfer(templeRecipient, templeAmount);
        emit Split(yearnAmount, keep, templeAmount, period.period);
    }

    function updatePeriod() external {
        _updatePeriod();
    }

    // @dev updates all period data to present week
    function _updatePeriod() internal {
        uint activePeriod = block.timestamp / WEEK * WEEK;
        if (activePeriod == period.period) return;
        period.period = activePeriod;
        gaugeController.checkpoint_gauge(gauge);
        IGauge.VotedSlope memory vs = gaugeController.vote_user_slopes(yearn.voter, gauge);
        uint userBias = calcBias(vs.slope, vs.end);
        uint globalBias = gaugeController.points_weight(gauge, activePeriod).bias;
        period.userBias = userBias;
        period.globalBias = globalBias;
        emit PeriodUpdated(activePeriod, userBias, globalBias);
    }

    function _computeSplitRatios() internal view returns (uint yRatio, uint tRatio) {
        uint userBias = period.userBias;
        if(userBias == 0) return (0, 10_000);
        uint relativeBias = period.globalBias == 0 ? 0 : userBias * precision / period.globalBias;
        uint lpSupply = liquidityPool.totalSupply();
        if (lpSupply == 0) return (10_000, 0); // @dev avoid div by 0
        uint gaugeDominance = 
            IStrategy(strategy).estimatedTotalAssets() 
            * precision 
            / lpSupply;
        if (gaugeDominance == 0) return (10_000, 0); // @dev avoid div by 0
        yRatio = 
            relativeBias
            * yearn.share
            / gaugeDominance;
        // Should not return > 100%
        if (yRatio > 10_000){
            return (10_000, 0);
        }
        tRatio = precision - yRatio;
    }

    // @dev Estimate only. 
    // @dev Only measures against strategy's current CRV balance, and will be inaccurate if period data is stale.
    function estimateSplit() external view returns (uint ySplit, uint tSplit) {
        (uint y, uint t) = _computeSplitRatios();
        uint bal = crv.balanceOf(strategy);
        ySplit = bal * y / precision;
        tSplit = bal - ySplit;
    }

    /// @dev Compute bias from slope and lock end
    /// @param _slope User's slope
    /// @param _end Timestamp of user's lock end
    function calcBias(uint _slope, uint _end) internal view returns (uint) {
        uint current = (block.timestamp / WEEK) * WEEK;
        if (current + WEEK >= _end) return 0;
        return _slope * (_end - current);
    }

    // @dev Estimate only.
    function estimateSplitRatios() external view returns (uint ySplit, uint tSplit) {
        (ySplit, tSplit) = _computeSplitRatios();
    }

    // Sells our CRV and CVX on Curve, then WETH -> stables together on UniV3
    function _sellCvx(uint _amount) internal {
        if (_amount > 1e17) {
            // don't want to swap dust or we might revert
            cvxeth.exchange(1, 0, _amount, 0, false);
        }
    }

    function _buyCRV() internal returns (uint) {
        uint256 _wethBalance = weth.balanceOf(address(this));
        if (_wethBalance > 1e15) {
            // don't want to swap dust or we might revert
            return crveth.exchange(0, 1, _wethBalance, 0, false);
        }
        return 0;
    }

    function setStrategy(address _strategy) external {
        require(msg.sender == yearn.admin);
        strategy = _strategy;
    }

    // @notice For use by yearn only to update discretionary values
    // @dev Other values in the struct are either immutable or require agreement by both parties to update.
    function setYearn(address _recipient, uint _keepCRV) external {	
        require(msg.sender == yearn.admin);	
        require(_keepCRV <= 10_000, "TooHigh");	
        address recipient = yearn.recipient;	
        if(recipient != _recipient){	
            pendingShare[recipient] = 0;	
            yearn.recipient = _recipient;	
        }	
        yearn.keepCRV = _keepCRV;	
        emit YearnUpdated(_recipient, _keepCRV);	
    }

    function setTemple(address _recipient) external {	
        address recipient = templeRecipient;	
        require(msg.sender == recipient);	
        if(recipient != _recipient){	
            pendingShare[recipient] = 0;	
            templeRecipient = _recipient;	
            emit TempleUpdated(_recipient);	
        }	
    }

    // @notice update share if both parties agree.
    function updateYearnShare(uint _share) external {
        require(_share <= 10_000 && _share != 0, "OutOfRange");
        require(msg.sender == yearn.admin || msg.sender == templeRecipient);
        if(msg.sender == yearn.admin && pendingShare[msg.sender] != _share){
            pendingShare[msg.sender] = _share;
            emit PendingShareUpdated(msg.sender, _share);
            if (pendingShare[templeRecipient] == _share) {
                yearn.share = _share;
                emit ShareUpdated(_share);
            }
        }
        else if(msg.sender == templeRecipient && pendingShare[msg.sender] != _share){
            pendingShare[msg.sender] = _share;
            emit PendingShareUpdated(msg.sender, _share);
            if (pendingShare[yearn.admin] == _share) {
                yearn.share = _share;
                emit ShareUpdated(_share);
            }
        }
    }

    function sweep(address _token) external {
        require(msg.sender == templeRecipient || msg.sender == yearn.admin);
        IERC20 token = IERC20(_token);
        uint amt = token.balanceOf(address(this));
        token.transfer(msg.sender, amt);
        emit Sweep(msg.sender, _token, amt);
    }

    /// @notice Allow owner to add address to blacklist, preventing them from claiming
    /// @dev Any vote weight address added
    function addApprovedCaller(address _caller) external {
        require(msg.sender == yearn.admin || msg.sender == templeRecipient, "!admin");
        if (approvedCallers.add(_caller)) emit ApprovedCaller(msg.sender, _caller);
    }

    /// @notice Allow owner to remove address from blacklist
    function removeApprovedCaller(address _caller) external {
        require(msg.sender == yearn.admin || msg.sender == templeRecipient, "!admin");
        if (approvedCallers.remove(_caller)) emit RemovedCaller(msg.sender, _caller);
    }

    /// @notice Check if address is approved to call split
    function isApprovedCaller(address caller) public view returns (bool) {
        return approvedCallers.contains(caller);
    }

    /// @dev Helper function, if possible, avoid using on-chain as list can grow unbounded
    function getApprovedCallers() public view returns (address[] memory _callers) {
        _callers = new address[](approvedCallers.length());
        for (uint i; i < approvedCallers.length(); i++) {
            _callers[i] = approvedCallers.at(i);
        }
    }

}