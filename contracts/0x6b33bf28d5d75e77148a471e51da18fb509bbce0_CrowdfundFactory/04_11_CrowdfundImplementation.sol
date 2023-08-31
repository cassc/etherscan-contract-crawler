//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error dateError();
error invalidGoal();
error crowdfundIsActive();
error inactiveCrowdfund();
error withdrawalIsNotActive();
error NotEnoughETHDonation();
error notEnoughTokenDonation();
error NotEnoughBalance();
error FailedToSendNativeToken();

contract CrowdfundImplementation is Ownable, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public startsAt;
    uint256 public endsAt;
    uint256 public goal;
    bytes public metaPtr;

    bool public canRefund;

    mapping(address => uint256) public userFunds;

    event Donated(address sender, uint256 amount);
    event Funded(address to, uint256 amount);
    event RefundActive(bool refunding);
    event UserBalanceWithdrawn(address user, uint256 balance);

    modifier crowfundingEnded() {
        if (block.timestamp < endsAt) {
            revert crowdfundIsActive();
        }
        _;
    }

    modifier crowdfundingIsActive() {
        if (block.timestamp < startsAt || block.timestamp > endsAt) {
            revert inactiveCrowdfund();
        }
        _;
    }

    constructor () {
        _disableInitializers();
    }

    function initialize(bytes memory meta) initializer public {
        (
            address safe,
            address _token,
            uint256 _startsAt,
            uint256 _endsAt,
            uint256 _goal,
            bytes memory _metaPtr
        ) = abi.decode(
                meta,
                (address, address, uint256, uint256, uint256, bytes)
            );

        if (_endsAt <= _startsAt) {
            revert dateError();
        }

        if (_goal < 1) {
            revert invalidGoal();
        }

        _transferOwnership(safe);
        if (_token != address(0)) {
            token = IERC20(_token);
        }
        startsAt = _startsAt;
        endsAt = _endsAt;
        goal = _goal;
        metaPtr = _metaPtr;
    }

    function donate(uint256 amount) public payable crowdfundingIsActive {
        uint256 _donatedAmount = msg.value;
        if (tokenIsNative()) {
            if (_donatedAmount == 0) {
                revert NotEnoughETHDonation();
            }
        } else {
            if (amount == 0) {
                revert notEnoughTokenDonation();
            }
            token.safeTransferFrom(msg.sender, address(this), amount);
            _donatedAmount = amount;
        }

        userFunds[msg.sender] += _donatedAmount;

        emit Donated(msg.sender, _donatedAmount);
    }

    function enableRefund() public onlyOwner crowfundingEnded {
        canRefund = true;

        emit RefundActive(true);
    }

    function fund() public onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        address to = owner();
        if (tokenIsNative()) {
            (bool sent, ) = to.call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            amount = token.balanceOf(address(this));
            token.safeTransfer(to, amount);
        }

        emit Funded(to, amount);
    }

    function withdraw() public nonReentrant {
        if (!canRefund) {
            revert withdrawalIsNotActive();
        }

        uint256 amount = userFunds[msg.sender];

        userFunds[msg.sender] = 0;

        if (amount == 0) {
            revert NotEnoughBalance();
        }

        if (tokenIsNative()) {
            (bool sent, ) = msg.sender.call{value: amount}("");
            if (!sent) {
                revert FailedToSendNativeToken();
            }
        } else {
            token.safeTransferFrom(address(this), msg.sender, amount);
        }

        emit UserBalanceWithdrawn(msg.sender, amount);
    }

    function tokenIsNative() public view returns (bool) {
        return address(token) == address(0);
    }

    function hasCrowdfundingEnded() public view returns (bool) {
        return block.timestamp > endsAt;
    }
}