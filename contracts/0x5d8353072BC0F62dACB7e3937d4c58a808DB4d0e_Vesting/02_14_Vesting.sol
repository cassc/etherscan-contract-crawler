pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TriallToken.sol";

contract Vesting is EIP712, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for TriallToken;
    using Math for uint256;

    event Harvest(address indexed sender, uint256 amount);
    event Deposite(address indexed sender, uint256 amount, bool isFiat);
    event Deposites(address[] indexed senders, uint256[] amounts);

    event SetWhitelist(address[] users, uint256[] allocation);
    event SetTGE(uint256 time);
    event Message(uint256, uint256, uint256, uint256);

    bytes32 private immutable _CONTAINER_TYPEHASE =
        keccak256(
            "Container(address sender,uint256 amount,bool isFiat,uint256 nonce)"
        );

    uint256 public constant MAX_INITIAL_PERCENTAGE = 1e20;
    address public immutable signer;
    uint8 public immutable rewardTokenDecimals;
    uint8 public immutable stakedTokenDecimals;

    uint256 public startDate;
    bool public isWithdrawFunds;

    mapping(address => uint256) public rewardsPaid;
    mapping(address => uint256) public deposited;

    TriallToken private immutable _rewardToken;
    IERC20 private immutable _depositToken;
    uint256 private immutable _initialPercentage;
    uint256 private immutable _minAllocation;
    uint256 private immutable _maxAllocation;
    uint256 private immutable _countPeriodOfVesting;

    string private _name;
    uint256 private _totalSupply;
    uint256 private _tokenPrice;
    uint256 private _totalDeposited;

    mapping(address => mapping(uint256 => bool)) private nonces;

    constructor(
        string memory name_,
        address rewardToken_,
        address depositToken_,
        address signer_,
        uint256 initialUnlockPercentage_,
        uint256 vestingNumberMonth_,
        uint256 minAllocation_,
        uint256 maxAllocation_
    ) EIP712("Vesting", "v1") {
        require(
            rewardToken_ != address(0) && depositToken_ != address(0),
            "Incorrect token address"
        );
        require(vestingNumberMonth_ > 0, "Incorrect amount");
        require(
            minAllocation_ <= maxAllocation_ && maxAllocation_ != 0,
            "Incorrect allocation size"
        );
        require(
            initialUnlockPercentage_ <= MAX_INITIAL_PERCENTAGE,
            "Incorrect initial percentage"
        );
        require(signer_ != address(0), "Incorrect signer address");

        _initialPercentage = initialUnlockPercentage_;
        _countPeriodOfVesting = vestingNumberMonth_;
        _minAllocation = minAllocation_;
        _maxAllocation = maxAllocation_;
        signer = signer_;
        _name = name_;

        _rewardToken = TriallToken(rewardToken_);
        _depositToken = IERC20(depositToken_);

        rewardTokenDecimals = IERC20Metadata(rewardToken_).decimals();
        stakedTokenDecimals = IERC20Metadata(depositToken_).decimals();
    }

    function getAvailAmountToDeposit(address _addr)
        external
        view
        returns (uint256 minAvailAllocation, uint256 maxAvailAllocation)
    {
        uint256 remaining = convertToCurrency(_totalSupply) - _totalDeposited;

        maxAvailAllocation = Math.min(
            _maxAllocation - deposited[_addr],
            remaining
        );
        if (deposited[_addr] == 0) {
            minAvailAllocation = _minAllocation;
        } else {
            minAvailAllocation = 0;
        }
    }

    function getInfo()
        external
        view
        returns (
            string memory name,
            address stakedToken,
            address rewardTokem,
            uint256 minAllocation,
            uint256 maxAllocation,
            uint256 totalSupply,
            uint256 totalDeposited,
            uint256 tokenPrice,
            uint256 initialUnlockPercentage,
            uint256 countPeriodOfVesting
        )
    {
        return (
            _name,
            address(_depositToken),
            address(_rewardToken),
            _minAllocation,
            _maxAllocation,
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
        uint256 tokenBalance = convertToToken(deposited[_addr]);

        if (!_isVestingStarted()) {
            return (tokenBalance, 0);
        }

        uint256 unlock = _calculateUnlock(_addr);

        return (tokenBalance - unlock - rewardsPaid[_addr], unlock);
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

    function addDepositeAmount(
        address[] calldata _addrArr,
        uint256[] calldata _amountArr
    ) external onlyOwner {
        require(_addrArr.length == _amountArr.length, "Incorrect array length");
        require(!_isVestingStarted(), "Sale is closed");

        uint256 remainingAllocation = _totalSupply -
            convertToToken(_totalDeposited);

        for (uint256 index = 0; index < _addrArr.length; index++) {
            uint256 convertAmount = convertToToken(_amountArr[index]);
            require(
                convertAmount <= remainingAllocation,
                "Not enough allocation"
            );

            remainingAllocation -= convertAmount;

            deposited[_addrArr[index]] += _amountArr[index];

            _totalDeposited += _amountArr[index];
        }
        emit Deposites(_addrArr, _amountArr);
    }

    function withdrawFunds() external nonReentrant onlyOwner {
        require(!isWithdrawFunds, "Withdraw funds was called before");
        require(_isVestingStarted(), "Vesting can't be started");
        isWithdrawFunds = true;

        uint256 unSoldToken = _totalSupply - convertToToken(_totalDeposited);
        _rewardToken.burn(unSoldToken);

        uint256 balance = _depositToken.balanceOf(address(this));
        _depositToken.safeTransfer(msg.sender, balance);
    }

    function deposite(
        uint256 _amount,
        bool _fiat,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {
        require(!nonces[msg.sender][_nonce], "Nonce used before");
        require(
            _isValidSigner(msg.sender, _amount, _fiat, _nonce, _v, _r, _s),
            "Invalid signer"
        );
        require(!_isVestingStarted(), "Sale is closed");
        require(_isValidAmount(_amount), "Invalid amount");

        nonces[msg.sender][_nonce] = true;
        deposited[msg.sender] += _amount;
        _totalDeposited += _amount;

        uint256 transferAmount = _convertToCorrectDecimals(
            _amount,
            rewardTokenDecimals,
            stakedTokenDecimals
        );
        if (!_fiat) {
            _depositToken.safeTransferFrom(
                msg.sender,
                address(this),
                transferAmount
            );
        }

        emit Deposite(msg.sender, _amount, _fiat);
    }

    function harvest() external {
        require(_isVestingStarted(), "Vesting can't be started");

        uint256 amountToTransfer = _calculateUnlock(msg.sender);

        rewardsPaid[msg.sender] += amountToTransfer;

        _rewardToken.safeTransfer(msg.sender, amountToTransfer);

        emit Harvest(msg.sender, amountToTransfer);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function convertToToken(uint256 _amount) public view returns (uint256) {
        return (_amount * 10**rewardTokenDecimals) / _tokenPrice;
    }

    function convertToCurrency(uint256 _amount) public view returns (uint256) {
        return (_amount * _tokenPrice) / 10**rewardTokenDecimals;
    }

    function _calculateUnlock(address _addr) internal view returns (uint256) {
        uint256 tokenAmount = convertToToken(deposited[_addr]);
        uint256 initialUnlockAmount = (tokenAmount * _initialPercentage) /
            MAX_INITIAL_PERCENTAGE;

        uint256 passeMonth = Math.min(
            (block.timestamp - startDate) / (30 days),
            _countPeriodOfVesting
        );

        return
            (((tokenAmount - initialUnlockAmount) * passeMonth) /
                _countPeriodOfVesting) +
            initialUnlockAmount -
            rewardsPaid[_addr];
    }

    function _convertToCorrectDecimals(
        uint256 _amount,
        uint256 _fromDecimals,
        uint256 _toDecimals
    ) internal pure returns (uint256) {
        if (_fromDecimals < _toDecimals) {
            _amount = _amount * (10**(_toDecimals - _fromDecimals));
        } else if (_fromDecimals > _toDecimals) {
            _amount = _amount / (10**(_fromDecimals - _toDecimals));
        }
        return _amount;
    }

    function _isVestingStarted() internal view returns (bool) {
        return block.timestamp > startDate && startDate != 0;
    }

    function _isValidAmount(uint256 _amount) internal view returns (bool) {
        uint256 depositAmount = deposited[msg.sender];
        uint256 remainingAmount = Math.min(
            _maxAllocation - depositAmount,
            convertToToken(_totalSupply) - _totalDeposited
        );
        return
            (_amount < _minAllocation && depositAmount == 0) ||
                (_amount > _maxAllocation || _amount > remainingAmount)
                ? false
                : true;
    }

    function _isValidSigner(
        address _sender,
        uint256 _amount,
        bool _fiat,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(_CONTAINER_TYPEHASE, _sender, _amount, _fiat, _nonce)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address messageSigner = ECDSA.recover(hash, _v, _r, _s);

        return messageSigner == signer;
    }
}