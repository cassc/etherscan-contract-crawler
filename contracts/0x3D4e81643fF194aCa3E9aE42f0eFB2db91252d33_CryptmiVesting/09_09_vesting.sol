// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";
import "@openzeppelin/utils/Address.sol";
import "@openzeppelin/utils/math/SafeMath.sol";

contract CryptmiVesting is Ownable, ReentrancyGuard {
    using Address for address;
    using SafeMath for uint32;
    using SafeMath for uint256;

    IERC20 public rewardTokenAddress;
    uint256 decimals = uint256(1).mul((uint256(10)) ** 18);

    uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60;

    struct AddressInfo {
        uint256 tokenAmount;
        uint32 registrationDay;
        uint32 endDay;
        bool isVestingActive;
    }

    mapping(address => AddressInfo) internal vestings;

    error OnlyOwnerOrBeneficiaryAllowed(address addressAllowed);
    error ZeroAddressProvided();
    error EndDayNotValid();
    error InvalidTokenAmount();
    error AddressAlreadyRegistered(address addressToCheck);
    error AddressNotRegistered(address addressToCheck);
    error EndDayNotReached();
    error NotEnoughTokenAmountInContract();

    event VestingStarted(
        address beneficiary, uint256 tokenAmount, uint32 endDay
    );
    event VestingFinished(address beneficiary, uint256 tokenAmount);

    constructor(address _tokenAddress) {
        if (address(_tokenAddress) == address(0)) {
            revert ZeroAddressProvided();
        }
        rewardTokenAddress = IERC20(_tokenAddress);
    }

    function initVesting(
        address _beneficiary,
        uint256 _rewardTokenAmount,
        uint32 _endDay
    ) external onlyOwner {
        if (_endDay <= 0) {
            revert EndDayNotValid();
        }
        if (_beneficiary == address(0)) {
            revert ZeroAddressProvided();
        }
        if (_rewardTokenAmount <= 0) {
            revert InvalidTokenAmount();
        }
        if (isAddressRegistered(_beneficiary)) {
            revert AddressAlreadyRegistered(_beneficiary);
        }
        _initVesting(_beneficiary, _rewardTokenAmount, _endDay);
        emit VestingStarted(_beneficiary, _rewardTokenAmount, _endDay);
    }

    function _initVesting(
        address _beneficiary,
        uint256 _rewardTokenAmount,
        uint32 _endDay
    ) internal {
        uint256 tokenToTransfer = _rewardTokenAmount.mul(decimals);
        uint32 endDay = uint32(today().add(_endDay));

        vestings[_beneficiary] =
            AddressInfo(tokenToTransfer, today(), endDay, true);
        rewardTokenAddress.approve(_beneficiary, tokenToTransfer);
    }

    function finishVesting() public nonReentrant {
        address caller = address(_msgSender());
        AddressInfo storage vesting = vestings[caller];
        if (!isAddressRegistered(caller)) {
            revert AddressNotRegistered(caller);
        }
        if (
            today() < vesting.registrationDay
                || today().sub(vesting.registrationDay) < vesting.endDay
        ) {
            revert EndDayNotReached();
        }
        uint256 tokenAmount = vesting.tokenAmount;
        if (rewardTokenAddress.balanceOf(address(this)) < tokenAmount) {
            revert NotEnoughTokenAmountInContract();
        }

        _finishVesting(caller, tokenAmount);
        emit VestingFinished(caller, tokenAmount);
    }

    function finishVestingFromOwner(address _beneficiary)
        external
        nonReentrant
        onlyOwner
    {
        AddressInfo storage vesting = vestings[_beneficiary];
        if (!isAddressRegistered(_beneficiary)) {
            revert AddressNotRegistered(_beneficiary);
        }
        if (
            today() < vesting.registrationDay
                || today().sub(vesting.registrationDay) < vesting.endDay
        ) {
            revert EndDayNotReached();
        }
        uint256 tokenAmount = vesting.tokenAmount;
        if (rewardTokenAddress.balanceOf(address(this)) < tokenAmount) {
            revert NotEnoughTokenAmountInContract();
        }

        _finishVesting(_beneficiary, tokenAmount);
    }

    function _finishVesting(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        AddressInfo storage vesting = vestings[_beneficiary];
        vesting.tokenAmount = 0;
        vesting.isVestingActive = false;
        rewardTokenAddress.transfer(_beneficiary, _tokenAmount);
    }

    function withdrawTokens(uint256 _amountToWithdraw) external onlyOwner {
        require(
            _amountToWithdraw > 0
                && _amountToWithdraw <= rewardTokenAddress.balanceOf(address(this)),
            "Wrong amount"
        );

        address caller = address(_msgSender());

        rewardTokenAddress.approve(caller, _amountToWithdraw);
        rewardTokenAddress.transfer(caller, _amountToWithdraw);
    }

    function today() public view returns (uint32 dayNumber) {
        return uint32(block.timestamp.div(SECONDS_PER_DAY));
    }

    function isAddressRegistered(address _beneficiary)
        public
        view
        returns (bool)
    {
        AddressInfo storage vesting = vestings[_beneficiary];
        return vesting.isVestingActive;
    }

    function getRegistrationDay(address _beneficiary)
        public
        view
        returns (uint32)
    {
        return vestings[_beneficiary].registrationDay;
    }

    function getEndDay(address _beneficiary) public view returns (uint32) {
        return vestings[_beneficiary].endDay;
    }

    function getTokenAmount(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return vestings[_beneficiary].tokenAmount;
    }
}