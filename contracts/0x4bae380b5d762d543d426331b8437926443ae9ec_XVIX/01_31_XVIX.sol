//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";

import "./interfaces/IXVIX.sol";
import "./interfaces/IFloor.sol";


contract XVIX is IERC20, IXVIX {
    using SafeMath for uint256;

    struct TransferConfig {
        bool active;
        uint256 senderBurnBasisPoints;
        uint256 senderFundBasisPoints;
        uint256 receiverBurnBasisPoints;
        uint256 receiverFundBasisPoints;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant MAX_FUND_BASIS_POINTS = 20; // 0.2%
    uint256 public constant MAX_BURN_BASIS_POINTS = 500; // 5%

    uint256 public constant MIN_REBASE_INTERVAL = 30 minutes;
    uint256 public constant MAX_REBASE_INTERVAL = 1 weeks;
    // cap the max intervals per rebase to avoid uint overflow errors
    uint256 public constant MAX_INTERVALS_PER_REBASE = 10;
    uint256 public constant MAX_REBASE_BASIS_POINTS = 500; // 5%

    // cap the normalDivisor to avoid uint overflow errors
    // the normalDivisor will be reached about 20 years after the first rebase
    uint256 public constant MAX_NORMAL_DIVISOR = 10**23;
    uint256 public constant SAFE_DIVISOR = 10**8;

    string public constant name = "XVIX";
    string public constant symbol = "XVIX";
    uint8 public constant decimals = 18;

    string public website = "https://xvix.finance/";

    address public gov;
    address public minter;
    address public floor;
    address public distributor;
    address public fund;

    uint256 public _normalSupply;
    uint256 public _safeSupply;
    uint256 public override maxSupply;

    uint256 public normalDivisor = 10**8;
    uint256 public rebaseInterval = 1 hours;
    uint256 public rebaseBasisPoints = 2; // 0.02%
    uint256 public nextRebaseTime = 0;

    uint256 public defaultSenderBurnBasisPoints = 0;
    uint256 public defaultSenderFundBasisPoints = 0;
    uint256 public defaultReceiverBurnBasisPoints = 43; // 0.43%
    uint256 public defaultReceiverFundBasisPoints = 7; // 0.07%

    uint256 public govHandoverTime;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    // msg.sender => transfer config
    mapping (address => TransferConfig) public transferConfigs;

    // balances in safe addresses do not get rebased
    mapping (address => bool) public safes;

    event Toast(address indexed account, uint256 value, uint256 maxSupply);
    event FloorPrice(uint256 capital, uint256 supply);
    event Rebase(uint256 normalDivisor, uint256 nextRebaseTime);
    event GovChange(address gov);
    event CreateSafe(address safe, uint256 balance);
    event DestroySafe(address safe, uint256 balance);
    event RebaseConfigChange(uint256 rebaseInterval, uint256 rebaseBasisPoints);
    event DefaultTransferConfigChange(
        uint256 senderBasisPoints,
        uint256 senderFundBasisPoints,
        uint256 receiverBurnBasisPoints,
        uint256 receiverFundBasisPoints
    );
    event SetTransferConfig(
        address indexed msgSender,
        uint256 senderBasisPoints,
        uint256 senderFundBasisPoints,
        uint256 receiverBurnBasisPoints,
        uint256 receiverFundBasisPoints
    );
    event ClearTransferConfig(address indexed msgSender);

    modifier onlyGov() {
        require(msg.sender == gov, "XVIX: forbidden");
        _;
    }

    // the govHandoverTime should be set to a time after XLGE participants can
    // withdraw their funds
    modifier onlyAfterHandover() {
        require(block.timestamp > govHandoverTime, "XVIX: handover time has not passed");
        _;
    }

    modifier enforceMaxSupply() {
        _;
        require(totalSupply() <= maxSupply, "XVIX: max supply exceeded");
    }

    constructor(uint256 _initialSupply, uint256 _maxSupply, uint256 _govHandoverTime) public {
        gov = msg.sender;
        govHandoverTime = _govHandoverTime;
        maxSupply = _maxSupply;
        _mint(msg.sender, _initialSupply);
        _setNextRebaseTime();
    }

    function setGov(address _gov) public onlyGov {
        gov = _gov;
        emit GovChange(_gov);
    }

    function setWebsite(string memory _website) public onlyGov {
        website = _website;
    }

    function setMinter(address _minter) public onlyGov {
        require(minter == address(0), "XVIX: minter already set");
        minter = _minter;
    }

    function setFloor(address _floor) public onlyGov {
        require(floor == address(0), "XVIX: floor already set");
        floor = _floor;
    }

    function setDistributor(address _distributor) public onlyGov {
        require(distributor == address(0), "XVIX: distributor already set");
        distributor = _distributor;
    }

    function setFund(address _fund) public onlyGov {
        fund = _fund;
    }

    function createSafe(address _account) public onlyGov enforceMaxSupply {
        require(!safes[_account], "XVIX: account is already a safe");
        safes[_account] = true;

        uint256 balance = balances[_account];
        _normalSupply = _normalSupply.sub(balance);

        uint256 safeBalance = balance.mul(SAFE_DIVISOR).div(normalDivisor);
        balances[_account] = safeBalance;
        _safeSupply = _safeSupply.add(safeBalance);

        emit CreateSafe(_account, balanceOf(_account));
    }

    // onlyAfterHandover guards against a possible gov attack vector
    // since XLGE participants have their funds locked for one month,
    // it is possible for gov to create a safe address and keep
    // XVIX tokens there while destroying all other safes
    // this would raise the value of the tokens kept in the safe address
    //
    // with the onlyAfterHandover modifier this attack can only be attempted
    // after XLGE participants are able to withdraw their funds
    // this would make it difficult for the attack to be profitable
    function destroySafe(address _account) public onlyGov onlyAfterHandover enforceMaxSupply {
        require(safes[_account], "XVIX: account is not a safe");
        safes[_account] = false;

        uint256 balance = balances[_account];
        _safeSupply = _safeSupply.sub(balance);

        uint256 normalBalance = balance.mul(normalDivisor).div(SAFE_DIVISOR);
        balances[_account] = normalBalance;
        _normalSupply = _normalSupply.add(normalBalance);

        emit DestroySafe(_account, balanceOf(_account));
    }

    function setRebaseConfig(
        uint256 _rebaseInterval,
        uint256 _rebaseBasisPoints
    ) public onlyGov onlyAfterHandover {
        require(_rebaseInterval >= MIN_REBASE_INTERVAL, "XVIX: rebaseInterval below limit");
        require(_rebaseInterval <= MAX_REBASE_INTERVAL, "XVIX: rebaseInterval exceeds limit");
        require(_rebaseBasisPoints <= MAX_REBASE_BASIS_POINTS, "XVIX: rebaseBasisPoints exceeds limit");

        rebaseInterval = _rebaseInterval;
        rebaseBasisPoints = _rebaseBasisPoints;

        emit RebaseConfigChange(_rebaseInterval, _rebaseBasisPoints);
    }

    function setDefaultTransferConfig(
        uint256 _senderBurnBasisPoints,
        uint256 _senderFundBasisPoints,
        uint256 _receiverBurnBasisPoints,
        uint256 _receiverFundBasisPoints
    ) public onlyGov onlyAfterHandover {
        _validateTransferConfig(
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );

        defaultSenderBurnBasisPoints = _senderBurnBasisPoints;
        defaultSenderFundBasisPoints = _senderFundBasisPoints;
        defaultReceiverBurnBasisPoints = _receiverBurnBasisPoints;
        defaultReceiverFundBasisPoints = _receiverFundBasisPoints;

        emit DefaultTransferConfigChange(
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );
    }

    function setTransferConfig(
        address _msgSender,
        uint256 _senderBurnBasisPoints,
        uint256 _senderFundBasisPoints,
        uint256 _receiverBurnBasisPoints,
        uint256 _receiverFundBasisPoints
    ) public onlyGov {
        require(_msgSender != address(0), "XVIX: cannot set zero address");
        _validateTransferConfig(
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );

        transferConfigs[_msgSender] = TransferConfig(
            true,
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );

        emit SetTransferConfig(
            _msgSender,
            _senderBurnBasisPoints,
            _senderFundBasisPoints,
            _receiverBurnBasisPoints,
            _receiverFundBasisPoints
        );
    }

    function clearTransferConfig(address _msgSender) public onlyGov onlyAfterHandover {
        delete transferConfigs[_msgSender];
        emit ClearTransferConfig(_msgSender);
    }

    function rebase() public override returns (bool) {
        if (block.timestamp < nextRebaseTime) { return false; }
        // calculate the number of intervals that have passed
        uint256 timeDiff = block.timestamp.sub(nextRebaseTime);
        uint256 intervals = timeDiff.div(rebaseInterval).add(1);

        // the multiplier is calculated as (~10000)^intervals
        // the max value of intervals is capped at 10 to avoid uint overflow errors
        // 2^256 has 77 digits
        // 10,000^10 has 40
        // MAX_NORMAL_DIVISOR has 23 digits
        if (intervals > MAX_INTERVALS_PER_REBASE) {
            intervals = MAX_INTERVALS_PER_REBASE;
        }

        _setNextRebaseTime();

        if (rebaseBasisPoints == 0) { return false; }

        uint256 multiplier = BASIS_POINTS_DIVISOR.add(rebaseBasisPoints) ** intervals;
        uint256 divider = BASIS_POINTS_DIVISOR ** intervals;

        uint256 nextDivisor = normalDivisor.mul(multiplier).div(divider);
        if (nextDivisor > MAX_NORMAL_DIVISOR) {
            return false;
        }

        normalDivisor = nextDivisor;
        emit Rebase(normalDivisor, nextRebaseTime);

        return true;
    }

    function mint(address _account, uint256 _amount) public override returns (bool) {
        require(msg.sender == minter, "XVIX: forbidden");
        _mint(_account, _amount);
        return true;
    }

    // permanently remove tokens from circulation by reducing maxSupply
    function toast(uint256 _amount) public override returns (bool) {
        require(msg.sender == distributor, "XVIX: forbidden");
        if (_amount == 0) { return false; }

        _burn(msg.sender, _amount);
        maxSupply = maxSupply.sub(_amount);
        emit Toast(msg.sender, _amount, maxSupply);

        return true;
    }

    function burn(address _account, uint256 _amount) public override returns (bool) {
        require(msg.sender == floor, "XVIX: forbidden");
        _burn(_account, _amount);
        return true;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        if (safes[_account]) {
            return balances[_account].div(SAFE_DIVISOR);
        }

        return balances[_account].div(normalDivisor);
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        rebase();
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "XVIX: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        rebase();
        return true;
    }

    function normalSupply() public view returns (uint256) {
        return _normalSupply.div(normalDivisor);
    }

    function safeSupply() public view returns (uint256) {
        return _safeSupply.div(SAFE_DIVISOR);
    }

    function totalSupply() public view override returns (uint256) {
        return normalSupply().add(safeSupply());
    }

    function _validateTransferConfig(
        uint256 _senderBurnBasisPoints,
        uint256 _senderFundBasisPoints,
        uint256 _receiverBurnBasisPoints,
        uint256 _receiverFundBasisPoints
    ) private pure {
        require(_senderBurnBasisPoints <= MAX_BURN_BASIS_POINTS, "XVIX: senderBurnBasisPoints exceeds limit");
        require(_senderFundBasisPoints <= MAX_FUND_BASIS_POINTS, "XVIX: senderFundBasisPoints exceeds limit");
        require(_receiverBurnBasisPoints <= MAX_BURN_BASIS_POINTS, "XVIX: receiverBurnBasisPoints exceeds limit");
        require(_receiverFundBasisPoints <= MAX_FUND_BASIS_POINTS, "XVIX: receiverFundBasisPoints exceeds limit");
    }

    function _setNextRebaseTime() private {
        uint256 roundedTime = block.timestamp.div(rebaseInterval).mul(rebaseInterval);
        nextRebaseTime = roundedTime.add(rebaseInterval);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "XVIX: transfer from the zero address");
        require(_recipient != address(0), "XVIX: transfer to the zero address");

        (uint256 senderBurn,
         uint256 senderFund,
         uint256 receiverBurn,
         uint256 receiverFund) = _getTransferConfig();

        // increase senderAmount based on senderBasisPoints
        uint256 senderAmount = _amount;
        uint256 senderBasisPoints = senderBurn.add(senderFund);
        if (senderBasisPoints > 0) {
            uint256 senderTax = _amount.mul(senderBasisPoints).div(BASIS_POINTS_DIVISOR);
            senderAmount = senderAmount.add(senderTax);
        }

        // decrease receiverAmount based on receiverBasisPoints
        uint256 receiverAmount = _amount;
        uint256 receiverBasisPoints = receiverBurn.add(receiverFund);
        if (receiverBasisPoints > 0) {
            uint256 receiverTax = _amount.mul(receiverBasisPoints).div(BASIS_POINTS_DIVISOR);
            receiverAmount = receiverAmount.sub(receiverTax);
        }

        _decreaseBalance(_sender, senderAmount);
        _increaseBalance(_recipient, receiverAmount);

        emit Transfer(_sender, _recipient, receiverAmount);

        // increase fund balance based on fundBasisPoints
        uint256 fundBasisPoints = senderFund.add(receiverFund);
        uint256 fundAmount = _amount.mul(fundBasisPoints).div(BASIS_POINTS_DIVISOR);
        if (fundAmount > 0) {
            _increaseBalance(fund, fundAmount);
            emit Transfer(_sender, fund, fundAmount);
        }

        // emit burn event
        uint256 burnAmount = senderAmount.sub(receiverAmount).sub(fundAmount);
        if (burnAmount > 0) {
            emit Transfer(_sender, address(0), burnAmount);
        }

        _emitFloorPrice();
    }

    function _getTransferConfig() private view returns (uint256, uint256, uint256, uint256) {
        uint256 senderBurn = defaultSenderBurnBasisPoints;
        uint256 senderFund = defaultSenderFundBasisPoints;
        uint256 receiverBurn = defaultReceiverBurnBasisPoints;
        uint256 receiverFund = defaultReceiverFundBasisPoints;

        TransferConfig memory config = transferConfigs[msg.sender];
        if (config.active) {
            senderBurn = config.senderBurnBasisPoints;
            senderFund = config.senderFundBasisPoints;
            receiverBurn = config.receiverBurnBasisPoints;
            receiverFund = config.receiverFundBasisPoints;
        }

        return (senderBurn, senderFund, receiverBurn, receiverFund);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "XVIX: approve from the zero address");
        require(_spender != address(0), "XVIX: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "XVIX: mint to the zero address");
        if (_amount == 0) { return; }

        _increaseBalance(_account, _amount);

        emit Transfer(address(0), _account, _amount);
        _emitFloorPrice();
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "XVIX: burn from the zero address");
        if (_amount == 0) { return; }

        _decreaseBalance(_account, _amount);

        emit Transfer(_account, address(0), _amount);
        _emitFloorPrice();
    }

    function _increaseBalance(address _account, uint256 _amount) private enforceMaxSupply {
        if (_amount == 0) { return; }

        if (safes[_account]) {
            uint256 safeAmount = _amount.mul(SAFE_DIVISOR);
            balances[_account] = balances[_account].add(safeAmount);
            _safeSupply = _safeSupply.add(safeAmount);
            return;
        }

        uint256 normalAmount = _amount.mul(normalDivisor);
        balances[_account] = balances[_account].add(normalAmount);
        _normalSupply = _normalSupply.add(normalAmount);
    }

    function _decreaseBalance(address _account, uint256 _amount) private {
        if (_amount == 0) { return; }

        if (safes[_account]) {
            uint256 safeAmount = _amount.mul(SAFE_DIVISOR);
            balances[_account] = balances[_account].sub(safeAmount, "XVIX: subtraction amount exceeds balance");
            _safeSupply = _safeSupply.sub(safeAmount);
            return;
        }

        uint256 normalAmount = _amount.mul(normalDivisor);
        balances[_account] = balances[_account].sub(normalAmount, "XVIX: subtraction amount exceeds balance");
        _normalSupply = _normalSupply.sub(normalAmount);
    }

    function _emitFloorPrice() private {
        if (_isContract(floor)) {
            emit FloorPrice(IFloor(floor).capital(), totalSupply());
        }
    }

    function _isContract(address account) private view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}