pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./TriallToken.sol";

contract PrivateVesting is Ownable {
    using Math for uint256;
    using SafeERC20 for TriallToken;

    event Harvest(address indexed sender, uint256 amount);
    event SetWhitelist(address[] users, uint256[] allocation);
    event SetTGE(uint256 time);

    uint256 public constant MAX_INITIAL_PERCENTAGE = 1e20;
    bool public isBurned;
    uint256 public startDate;
    mapping(address => uint256) public rewardsPaid;
    mapping(address => uint256) public deposited;

    TriallToken private immutable _rewardToken;
    uint256 private immutable _initialPercentage;
    uint256 private immutable _countPeriodOfVesting;

    string private _name;
    uint256 private _tokenPrice;
    uint256 private _totalSupply;
    uint256 private _totalDeposited;

    constructor(
        string memory name_,
        address rewardToken_,
        uint256 initialUnlockPercentage_,
        uint256 vestingNumberMonth_
    ) {
        require(rewardToken_ != address(0), "Incorrect token address");
        require(vestingNumberMonth_ > 0, "Incorrect amount");
        require(
            initialUnlockPercentage_ <= MAX_INITIAL_PERCENTAGE,
            "Incorrect initial percentage"
        );

        _name = name_;
        _initialPercentage = initialUnlockPercentage_;
        _countPeriodOfVesting = vestingNumberMonth_;

        _rewardToken = TriallToken(rewardToken_);
    }

    function getInfo()
        external
        view
        returns (
            string memory name,
            address rewardTokem,
            uint256 totalSupply,
            uint256 totalDeposited,
            uint256 tokenPrice,
            uint256 initialUnlockPercentage,
            uint256 countPeriodOfVesting
        )
    {
        return (
            _name,
            address(_rewardToken),
            _totalSupply,
            _totalDeposited,
            _tokenPrice,
            _initialPercentage,
            _countPeriodOfVesting
        );
    }

    function getBalanceInfo(address _addr)
        external
        view
        returns (uint256 lockedBalance, uint256 unlockedBalance)
    {
        if (!_isVestingStarted()) {
            return (deposited[_addr], 0);
        }

        uint256 unlock = _calculateUnlock(_addr);
        return (deposited[_addr] - unlock - rewardsPaid[_addr], unlock);
    }

    function setWhitelist(
        address[] calldata _addr,
        uint256[] calldata _tokenAmount
    ) external onlyOwner {
        require(!_isVestingStarted(), "Vesting can be started");
        require(_addr.length == _tokenAmount.length, "Incorrect array length");

        for (uint256 index = 0; index < _addr.length; index++) {
            if (deposited[_addr[index]] > 0) {
                _totalDeposited -= deposited[_addr[index]];
            }

            _totalDeposited += _tokenAmount[index];

            require(
                _totalDeposited <= _totalSupply,
                "Can't be more then totalSupply"
            );

            deposited[_addr[index]] = _tokenAmount[index];
        }
        emit SetWhitelist(_addr, _tokenAmount);
    }

    function initializeToken(uint256 tokenPrice_, uint256 totalSypply_)
        external
        onlyOwner
    {
        require(_tokenPrice == 0, "Is was initialized before");
        require(totalSypply_ > 0 && tokenPrice_ > 0, "Incorrect amount");

        _tokenPrice = tokenPrice_;
        _totalSupply = totalSypply_;

        _rewardToken.safeTransferFrom(msg.sender, address(this), totalSypply_);
    }

    function setTGE(uint256 _tge) external onlyOwner {
        require(startDate == 0 && _tge != 0, "TGE is set or zero");
        startDate = _tge;
        emit SetTGE(_tge);
    }

    function burnUnsoldToken() external onlyOwner {
        require(startDate != 0, "Vesting can't be started");
        require(!isBurned, "Burned was called before");
        isBurned = true;
        _rewardToken.burn(_totalSupply - _totalDeposited);
    }

    function harvest() external {
        require(_isVestingStarted(), "Vesting can't be started");

        uint256 amountToTransfer = _calculateUnlock(msg.sender);

        rewardsPaid[msg.sender] += amountToTransfer;

        _rewardToken.safeTransfer(msg.sender, amountToTransfer);

        emit Harvest(msg.sender, amountToTransfer);
    }

    function _calculateUnlock(address _addr) internal view returns (uint256) {
        uint256 tokenAmount = deposited[_addr];

        uint256 initialUnlockAmount = (tokenAmount * _initialPercentage) /
            MAX_INITIAL_PERCENTAGE;

        uint256 passeMonth = Math.min(
            (block.timestamp - startDate) / 30 days,
            _countPeriodOfVesting
        );
        return
            (((tokenAmount - initialUnlockAmount) * passeMonth) /
                _countPeriodOfVesting) +
            initialUnlockAmount -
            rewardsPaid[_addr];
    }

    function _isVestingStarted() internal view returns (bool) {
        return block.timestamp > startDate && startDate != 0;
    }
}