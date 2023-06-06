// SPDX-License-Identifier: MPL

pragma solidity ~0.8.4;

import "./IERC20.sol";

interface IZGTERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ZGTVesting {
    IZGTERC20Metadata private _zgtContract;
    address private _owner;
    uint256 private _vestedBalance;
    uint64 public _startTimestamp;
    uint64 public _vestingDuration;

    mapping(address => VestingParams) private _vesting;

    struct VestingParams {
        //96bit are enough: max value is 1000000000000000000000000000
        //96bit are:                    79228162514264337593543950336
        uint96 vestingAmount;
        //64bit for timestamp in seconds lasts 584 billion years
        uint64 vestingDuration;
        //how much vested funds were already claimed
        uint96 vestingClaimed;
    }

    event Vested(address indexed account, uint96 amount, uint64 vestingDuration);
    event TransferOwner(address indexed owner);
    event SetStartTimestamp(uint64 startTimestamp);
    event Claim(address indexed account, uint96 amount);

    modifier onlyOwner(){
        require(msg.sender == _owner, "Vesting: not the owner");
        _;
    }

    constructor(address zgtContract, uint64 startTimestamp, uint64 vestingDuration) {
        _owner = msg.sender;
        _zgtContract = IZGTERC20Metadata(zgtContract);
        _startTimestamp = startTimestamp;
        _vestingDuration = vestingDuration;
    }

    function transferOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Vesting: transfer owner the zero address");
        require(newOwner != address(this), "Vesting: transfer owner to this contract");

        _owner = newOwner;
        emit TransferOwner(newOwner);
    }

    function setStartTimestamp(uint64 startTimestamp) public virtual onlyOwner {
        require(block.timestamp < _startTimestamp, "Vesting: existing start timestamp has already been reached");
        require(block.timestamp < startTimestamp, "Vesting: can only set a start timestamp in the future");

        _startTimestamp = startTimestamp;
        emit SetStartTimestamp(startTimestamp);
    }

    function vest(address[] calldata accounts, uint96[] calldata amounts) public virtual onlyOwner {
        require(accounts.length == amounts.length, "Vesting: accounts and amounts length must match");

        for(uint256 i=0;i<accounts.length;i++) {
            //only vest those accounts that are not yet vested. We dont want to merge vestings
            if(_vesting[accounts[i]].vestingAmount == 0) {
                _vestedBalance += amounts[i];
                _vesting[accounts[i]] = VestingParams(amounts[i], _vestingDuration, 0);
                emit Vested(accounts[i], amounts[i], _vestingDuration);
            }
        }
        require(_vestedBalance <= _zgtContract.balanceOf(address(this)), "Vesting: not enough tokens in this contract for vesting");
    }

    function canClaim(address vested) public view virtual returns (uint256) {
        if(block.timestamp <= _startTimestamp || _startTimestamp == 0) {
            return 0;
        }
        VestingParams memory v = _vesting[vested];
        return claimableAmount(v);
    }

    function claimableAmount(VestingParams memory v) internal view virtual returns (uint256) {
        uint256 currentDuration = block.timestamp - _startTimestamp;

        uint256 unlockedFunds = 0;
        if(v.vestingDuration < currentDuration) {
            //we can give all of it, vesting time passed, otherwise we see a div by zero
            unlockedFunds = v.vestingAmount;
        } else {
            unlockedFunds = v.vestingAmount * currentDuration / v.vestingDuration;
        }
        return unlockedFunds - v.vestingClaimed;
    }

    function vestedBalance() public view virtual returns (uint256) {
        return _vestedBalance;
    }

    function vestedBalanceOf(address vested) public view virtual returns (uint256) {
        VestingParams memory v = _vesting[vested];
        return v.vestingAmount - v.vestingClaimed;
    }

    function claim(address to, uint96 amount) public virtual {
        require(block.timestamp > _startTimestamp, 'Vesting: timestamp now or in the past?');
        require(_startTimestamp != 0, "Vesting: contract not live yet");
        require(to != address(0), "Vesting: transfer from the zero address");
        require(to != address(this), "Vesting: sender is this contract");
        require(to != address(_zgtContract), "Vesting: sender is _zgtContract contract");

        VestingParams storage v = _vesting[msg.sender];

        require(amount <= claimableAmount(v), "ZGT: cannot transfer vested funds");

        v.vestingClaimed += amount;
        _vestedBalance -= amount;
        _zgtContract.transfer(to, amount);
        emit Claim(to, amount);
    }
}
