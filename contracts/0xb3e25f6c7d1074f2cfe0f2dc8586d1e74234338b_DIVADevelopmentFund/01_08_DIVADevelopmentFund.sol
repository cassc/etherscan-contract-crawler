// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IDIVADevelopmentFund} from "./interfaces/IDIVADevelopmentFund.sol";
import {IDIVAOwnershipShared} from "./interfaces/IDIVAOwnershipShared.sol";

contract DIVADevelopmentFund is IDIVADevelopmentFund, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // DIVA ownership contract
    IDIVAOwnershipShared private immutable _DIVA_OWNERSHIP;

    // Deposit related storage variables
    Deposit[] private _deposits;
    mapping(address => uint256[]) private _tokenToDepositIndices;

    // Mapping introduced to allow differentiating between deposits that came in via
    // the implemented `deposit` functions and direct deposits, made by sending native
    // assets or ERC20 tokens directly to the contract address. The difference between
    // the contract balance and `_tokenToUnclaimedDepositAmount` represents the amount
    // of direct deposits that can be withdrawn via `withdrawDirectDeposit` without
    // vesting.
    mapping(address => uint256) private _tokenToUnclaimedDepositAmount;

    modifier onlyDIVAOwner() {
        address _currentOwner = _DIVA_OWNERSHIP.getCurrentOwner();
        if (_currentOwner != msg.sender) {
            revert NotDIVAOwner(msg.sender, _currentOwner);
        }
        _;
    }

    constructor(IDIVAOwnershipShared _divaOwnership) payable {
        if (address(_divaOwnership) == address(0)) {
            revert ZeroDIVAOwnershipAddress();
        }
        _DIVA_OWNERSHIP = _divaOwnership;
    }

    // Function to receive native asset. msg.data must be empty, otherwise it will fail.
    receive() external payable {}

    function deposit(uint256 _releasePeriodInSeconds)
        external
        payable
        override
        nonReentrant
    {
        if (!_isValidReleasePeriod(_releasePeriodInSeconds)) {
            revert InvalidReleasePeriod();
        }
        uint256 _depositIndex = _addNewDeposit(
            address(0),
            msg.value,
            _releasePeriodInSeconds
        );

        emit Deposited(msg.sender, _depositIndex);
    }

    function deposit(
        address _token,
        uint256 _amount,
        uint256 _releasePeriodInSeconds
    ) external override nonReentrant {
        if (!_isValidReleasePeriod(_releasePeriodInSeconds)) {
            revert InvalidReleasePeriod();
        }
        uint256 _depositIndex = _addNewDeposit(
            _token,
            _amount,
            _releasePeriodInSeconds
        );

        IERC20 _tokenInstance = IERC20(_token);

        // Transfer token from user to `this`. Revert if a fee is applied
        // during transfer.
        uint256 _before = _tokenInstance.balanceOf(address(this));
        _tokenInstance.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = _tokenInstance.balanceOf(address(this));

        if (_after - _before != _amount) {
            revert FeeTokensNotSupported();
        }

        emit Deposited(msg.sender, _depositIndex);
    }

    function withdraw(address _token, uint256[] calldata _indices)
        external
        payable
        override
        nonReentrant
        onlyDIVAOwner
    {
        uint256 _claimableAmount;
        uint256 _len = _indices.length;
        for (uint256 _i = 0; _i < _len; ) {
            Deposit storage _deposit = _deposits[_indices[_i]];
            if (_deposit.token != _token) {
                revert DifferentTokens();
            }
            if (_deposit.lastClaimedAt < _deposit.endTime) {
                _claimableAmount += _claimableAmountForDeposit(_deposit);
                _deposit.lastClaimedAt = block.timestamp;
            }            
            unchecked {
                ++_i;
            }
        }

        _tokenToUnclaimedDepositAmount[_token] -= _claimableAmount;

        if (_token == address(0)) {
            (bool success, ) = msg.sender.call{value: _claimableAmount}("");
            if (!success) revert FailedToSendNativeAsset();
        } else {
            IERC20(_token).safeTransfer(msg.sender, _claimableAmount);
        }

        emit Withdrawn(msg.sender, _token, _claimableAmount);
    }

    function withdrawDirectDeposit(address _token)
        external
        payable
        override
        nonReentrant
        onlyDIVAOwner
    {
        uint256 _claimableAmount;
        if (_token == address(0)) {
            _claimableAmount =
                address(this).balance -
                _tokenToUnclaimedDepositAmount[_token];
            (bool success, ) = msg.sender.call{value: _claimableAmount}("");
            if (!success) revert FailedToSendNativeAsset();
        } else {
            IERC20 _depositTokenInstance = IERC20(_token);
            _claimableAmount =
                _depositTokenInstance.balanceOf(address(this)) -
                _tokenToUnclaimedDepositAmount[_token];
            IERC20(_token).safeTransfer(msg.sender, _claimableAmount);
        }

        emit Withdrawn(msg.sender, _token, _claimableAmount);
    }

    function getDepositsLength()
        external
        view
        override
        returns (uint256 length)
    {
        length = _deposits.length;
    }

    function getDivaOwnership()
        external
        view
        override
        returns (IDIVAOwnershipShared divaOwnership)
    {
        divaOwnership = _DIVA_OWNERSHIP;
    }

    function getDepositInfo(uint256 _index)
        external
        view
        override
        returns (Deposit memory depositInfo)
    {
        depositInfo = _deposits[_index];
    }

    function getDepositIndices(
        address _token,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view override returns (uint256[] memory indices) {
        if (_endIndex > _startIndex) {
            uint256 _len = _tokenToDepositIndices[_token].length;
            indices = new uint256[](_endIndex - _startIndex);
            for (uint256 i = _startIndex; i < _endIndex; ) {
                if (i >= _len) {
                    indices[i - _startIndex] = 0;
                } else {
                    indices[i - _startIndex] = _tokenToDepositIndices[_token][
                        i
                    ];
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            indices = new uint256[](0);
        }
    }

    function getDepositIndicesLengthForToken(address _token)
        external
        view
        override
        returns (uint256 depositIndicesLength)
    {
        depositIndicesLength = _tokenToDepositIndices[_token].length;
    }

    function getUnclaimedDepositAmount(address _token)
        external
        view
        override
        returns (uint256 amount)
    {
        amount = _tokenToUnclaimedDepositAmount[_token];
    }

    function _addNewDeposit(
        address _token,
        uint256 _amount,
        uint256 _releasePeriodInSeconds
    ) internal returns (uint256 depositIndex) {
        _deposits.push(
            Deposit(
                _token,
                _amount,
                block.timestamp,
                block.timestamp + _releasePeriodInSeconds,
                block.timestamp
            )
        );
        depositIndex = _deposits.length - 1;
        _tokenToDepositIndices[_token].push(depositIndex);

        _tokenToUnclaimedDepositAmount[_token] += _amount;
    }

    function _claimableAmountForDeposit(Deposit memory _deposit)
        internal
        view
        returns (uint256 amount)
    {
        if (block.timestamp >= _deposit.endTime) {
            amount =
                _deposit.amount -
                (_deposit.amount *
                    (_deposit.lastClaimedAt - _deposit.startTime)) /
                (_deposit.endTime - _deposit.startTime);
        } else {
            amount =
                (_deposit.amount * (block.timestamp - _deposit.lastClaimedAt)) /
                (_deposit.endTime - _deposit.startTime);
        }
    }

    function _isValidReleasePeriod(uint256 _releasePeriodInSeconds) private pure returns (bool) {
        return (_releasePeriodInSeconds != 0 && _releasePeriodInSeconds <= 30*365 days);
    }
}