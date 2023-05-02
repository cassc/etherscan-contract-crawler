pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITap.sol";
import "./interfaces/IFundraisingController.sol";
import "./interfaces/IBatchedBancor.sol";



contract Tap is ITap, Ownable  {
    using SafeMath  for uint256;


    uint256 public constant PCT_BASE = 10 ** 18; // 0% = 0; 1% = 10 ** 16; 100% = 10 ** 18

    IFundraisingController       public controller;
    IBatchedBancor               public batchedBan;
    address                      public beneficiary;
    address                      public dao;
    uint256                      public batchBlocks;
    uint256                      public maximumTapRateIncreasePct;
    uint256                      public maximumTapFloorDecreasePct;

    mapping (address => uint256) public tappedAmounts;
    mapping (address => uint256) public rates;
    mapping (address => uint256) public floors;
    mapping (address => uint256) public lastTappedAmountUpdates; // batch ids [block numbers]
    mapping (address => uint256) public lastTapUpdates;  // timestamps

    event UpdateBeneficiary               (address indexed beneficiary);
    event UpdateMaximumTapRateIncreasePct (uint256 maximumTapRateIncreasePct);
    event UpdateMaximumTapFloorDecreasePct(uint256 maximumTapFloorDecreasePct);
    event AddTappedToken                  (address indexed token, uint256 rate, uint256 floor);
    event RemoveTappedToken               (address indexed token);
    event UpdateTappedToken               (address indexed token, uint256 rate, uint256 floor);
    event ResetTappedToken                (address indexed token);
    event UpdateTappedAmount              (address indexed token, uint256 tappedAmount);
    event Withdraw                        (address indexed token, uint256 amount);


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyDAO() {
        require(dao == msg.sender, "DAO: caller is not the DAO");
        _;
    }

    /***** external functions *****/

    /**
     * @notice Initialize tap
     * @param _beneficiary                The address of the beneficiary [to whom funds are to be withdrawn]
     * @param _batchBlocks                The number of blocks batches are to last
     * @param _maximumTapRateIncreasePct  The maximum tap rate increase percentage allowed [in PCT_BASE]
     * @param _maximumTapFloorDecreasePct The maximum tap floor decrease percentage allowed [in PCT_BASE]
    */
    constructor (
        address _dao,
        address _beneficiary,
        uint256 _batchBlocks,
        uint256 _maximumTapRateIncreasePct,
        uint256 _maximumTapFloorDecreasePct
    )
        public
    {

        require(_beneficiaryIsValid(_beneficiary), "Invalid Beneficiary");
        require(_batchBlocks != 0, "Batch Block cannot equal zero");
        require(_maximumTapFloorDecreasePctIsValid(_maximumTapFloorDecreasePct), "Invalid Floor Decrease");

        beneficiary = _beneficiary;
        batchBlocks = _batchBlocks;
        maximumTapRateIncreasePct = _maximumTapRateIncreasePct;
        maximumTapFloorDecreasePct = _maximumTapFloorDecreasePct;
        dao = _dao;
    }

    function setUpTap(
      IFundraisingController _controller,
      IBatchedBancor _batchedBan
      ) public onlyOwner {
        controller = _controller;
        batchedBan = _batchedBan;
        transferOwnership(address(_controller));
      }

    /**
     * @notice Update beneficiary to `_beneficiary`
     * @param _beneficiary The address of the new beneficiary [to whom funds are to be withdrawn]
    */
    function updateBeneficiary(address _beneficiary) external onlyOwner override {
        require(_beneficiaryIsValid(_beneficiary), "Invalid Beneficiary");

        _updateBeneficiary(_beneficiary);
    }

    /**
     * @notice Update maximum tap rate increase percentage to `@formatPct(_maximumTapRateIncreasePct)`%
     * @param _maximumTapRateIncreasePct The new maximum tap rate increase percentage to be allowed [in PCT_BASE]
    */
    function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) external onlyOwner override {
        _updateMaximumTapRateIncreasePct(_maximumTapRateIncreasePct);
    }

    /**
     * @notice Update maximum tap floor decrease percentage to `@formatPct(_maximumTapFloorDecreasePct)`%
     * @param _maximumTapFloorDecreasePct The new maximum tap floor decrease percentage to be allowed [in PCT_BASE]
    */
    function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) external onlyOwner override {
        require(_maximumTapFloorDecreasePctIsValid(_maximumTapFloorDecreasePct), "Invalid floor decrease");

        _updateMaximumTapFloorDecreasePct(_maximumTapFloorDecreasePct);
    }

    /**
     * @notice Add tap for `_token.symbol(): string` with a rate of `@tokenAmount(_token, _rate)` per block and a floor of `@tokenAmount(_token, _floor)`
     * @param _token The address of the token to be tapped
     * @param _rate  The rate at which that token is to be tapped [in wei / block]
     * @param _floor The floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function addTappedToken(address _token, uint256 _rate, uint256 _floor) external onlyOwner override {
        require(!_tokenIsTapped(_token), "Token is already tapped");
        require(_tapRateIsValid(_rate), "Invalid tap rate");

        _addTappedToken(_token, _rate, _floor);
    }

    /**
     * @notice Remove tap for `_token.symbol(): string`
     * @param _token The address of the token to be un-tapped
    */
    function removeTappedToken(address _token) external onlyOwner {
        require(_tokenIsTapped(_token), "Token is not tapped");

        _removeTappedToken(_token);
    }

    /**
     * @notice Update tap for `_token.symbol(): string` with a rate of `@tokenAmount(_token, _rate)` per block and a floor of `@tokenAmount(_token, _floor)`
     * @param _token The address of the token whose tap is to be updated
     * @param _rate  The new rate at which that token is to be tapped [in wei / block]
     * @param _floor The new floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function updateTappedToken(address _token, uint256 _rate, uint256 _floor) external onlyOwner override {
        require(_tokenIsTapped(_token), "Token is not tapped");
        require(_tapRateIsValid(_rate), "Invalid tap rate");
        require(_tapUpdateIsValid(_token, _rate, _floor), "Invalid tap update");

        _updateTappedToken(_token, _rate, _floor);
    }

    /**
     * @notice Reset tap timestamps for `_token.symbol(): string`
     * @param _token The address of the token whose tap timestamps are to be reset
    */
    function resetTappedToken(address _token) external onlyOwner override {
        require(_tokenIsTapped(_token), "Token is not tapped");

        _resetTappedToken(_token);
    }

    /**
     * @notice Update tapped amount for `_token.symbol(): string`
     * @param _token The address of the token whose tapped amount is to be updated
    */
    function updateTappedAmount(address _token) external override {
        require(_tokenIsTapped(_token), "Token is not tapped");

        _updateTappedAmount(_token);
    }

    /**
     * @notice Transfer about `@tokenAmount(_token, self.getMaximalWithdrawal(_token): uint256)` from `self.reserve()` to `self.beneficiary()`
     * @param _token The address of the token to be transfered
    */
    function withdraw(address _token, uint _amount) external onlyDAO override {
        require(_tokenIsTapped(_token), "Token is not tapped");
        require(_amount > 0, "Withdraw amount is zero");

        _withdraw(_token, _amount);
    }

    /***** public view functions *****/

    function getMaximumWithdrawal(address _token) public view override returns (uint256) {
        return _tappedAmount(_token);
    }

    function getRates(address _token) public view override returns (uint256) {
        return rates[_token];
    }

    /***** internal functions *****/

    /* computation functions */

    function _currentBatchId() internal view returns (uint256) {
        return (block.number.div(batchBlocks)).mul(batchBlocks);
    }

    function _tappedAmount(address _token) internal view returns (uint256) {
        uint256 toBeKept = controller.collateralsToBeClaimed(_token).add(floors[_token]);
          IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(batchedBan));
        uint256 flow = (_currentBatchId().sub(lastTappedAmountUpdates[_token])).mul(rates[_token]);
        uint256 tappedAmount = tappedAmounts[_token].add(flow);
        /**
         * whatever happens enough collateral should be
         * kept in the reserve pool to guarantee that
         * its balance is kept above the floor once
         * all pending sell orders are claimed
        */

        /**
         * the reserve's balance is already below the balance to be kept
         * the tapped amount should be reset to zero
        */
        if (balance <= toBeKept) {
            return 0;
        }

        /**
         * the reserve's balance minus the upcoming tap flow would be below the balance to be kept
         * the flow should be reduced to balance - toBeKept
        */
        if (balance <= toBeKept.add(tappedAmount)) {
            return balance.sub(toBeKept);
        }

        /**
         * the reserve's balance minus the upcoming flow is above the balance to be kept
         * the flow can be added to the tapped amount
        */
        return tappedAmount;
    }

    /* check functions */

    function _beneficiaryIsValid(address _beneficiary) internal pure returns (bool) {
        return _beneficiary != address(0);
    }

    function _maximumTapFloorDecreasePctIsValid(uint256 _maximumTapFloorDecreasePct) internal pure returns (bool) {
        return _maximumTapFloorDecreasePct <= PCT_BASE;
    }


    function _tokenIsTapped(address _token) internal view returns (bool) {
        return rates[_token] != uint256(0);
    }

    function _tapRateIsValid(uint256 _rate) internal pure returns (bool) {
        return _rate != 0;
    }

    function _tapUpdateIsValid(address _token, uint256 _rate, uint256 _floor) internal view returns (bool) {
        return _tapRateUpdateIsValid(_token, _rate) && _tapFloorUpdateIsValid(_token, _floor);
    }

    function _tapRateUpdateIsValid(address _token, uint256 _rate) internal view returns (bool) {
        uint256 rate = rates[_token];

        if (_rate <= rate) {
            return true;
        }

        if (now < lastTapUpdates[_token] + 30 days) {
            return false;
        }

        if (_rate.mul(PCT_BASE) <= rate.mul(PCT_BASE.add(maximumTapRateIncreasePct))) {
            return true;
        }

        return false;
    }

    function _tapFloorUpdateIsValid(address _token, uint256 _floor) internal view returns (bool) {
        uint256 floor = floors[_token];

        if (_floor >= floor) {
            return true;
        }

        if (now < lastTapUpdates[_token] + 30 days) {
            return false;
        }

        if (maximumTapFloorDecreasePct >= PCT_BASE) {
            return true;
        }

        if (_floor.mul(PCT_BASE) >= floor.mul(PCT_BASE.sub(maximumTapFloorDecreasePct))) {
            return true;
        }

        return false;
    }

    /* state modifying functions */

    function _updateTappedAmount(address _token) internal returns (uint256) {
        uint256 tappedAmount = _tappedAmount(_token);
        lastTappedAmountUpdates[_token] = _currentBatchId();
        tappedAmounts[_token] = tappedAmount;

        emit UpdateTappedAmount(_token, tappedAmount);

        return tappedAmount;
    }

    function _updateBeneficiary(address _beneficiary) internal {
        beneficiary = _beneficiary;

        emit UpdateBeneficiary(_beneficiary);
    }

    function _updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) internal {
        maximumTapRateIncreasePct = _maximumTapRateIncreasePct;

        emit UpdateMaximumTapRateIncreasePct(_maximumTapRateIncreasePct);
    }

    function _updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) internal {
        maximumTapFloorDecreasePct = _maximumTapFloorDecreasePct;

        emit UpdateMaximumTapFloorDecreasePct(_maximumTapFloorDecreasePct);
    }

    function _addTappedToken(address _token, uint256 _rate, uint256 _floor) internal {
        /**
         * NOTE
         * 1. if _token is tapped in the middle of a batch it will
         * reach the next batch faster than what it normally takes
         * to go through a batch [e.g. one block later]
         * 2. this will allow for a higher withdrawal than expected
         * a few blocks after _token is tapped
         * 3. this is not a problem because this extra amount is
         * static [at most rates[_token] * batchBlocks] and does
         * not increase in time
        */
        rates[_token] = _rate;
        floors[_token] = _floor;
        lastTappedAmountUpdates[_token] = _currentBatchId();
        lastTapUpdates[_token] = now;

        emit AddTappedToken(_token, _rate, _floor);
    }

    function _removeTappedToken(address _token) internal {
        delete tappedAmounts[_token];
        delete rates[_token];
        delete floors[_token];
        delete lastTappedAmountUpdates[_token];
        delete lastTapUpdates[_token];

        emit RemoveTappedToken(_token);
    }

    function _updateTappedToken(address _token, uint256 _rate, uint256 _floor) internal {
        /**
         * NOTE
         * withdraw before updating to keep the reserve
         * actual balance [balance - virtual withdrawal]
         * continuous in time [though a floor update can
         * still break this continuity]
        */
        uint256 amount = _updateTappedAmount(_token);
        if (amount > 0) {
            _withdraw(_token, amount);
        }

        rates[_token] = _rate;
        floors[_token] = _floor;
        lastTapUpdates[_token] = now;

        emit UpdateTappedToken(_token, _rate, _floor);
    }

    function _resetTappedToken(address _token) internal {
        tappedAmounts[_token] = 0;
        lastTappedAmountUpdates[_token] = _currentBatchId();
        lastTapUpdates[_token] = now;

        emit ResetTappedToken(_token);
    }

    function _withdraw(address _token, uint256 _amount) internal {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(batchedBan));
        require(balance > _amount);
        batchedBan.transfer(_token, _amount); // vault contract's transfer method already reverts on error

        emit Withdraw(_token, _amount);
    }
}