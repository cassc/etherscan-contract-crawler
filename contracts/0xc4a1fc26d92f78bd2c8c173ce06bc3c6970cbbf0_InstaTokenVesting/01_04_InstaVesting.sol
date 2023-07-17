//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

interface TokenInterface {
    function balanceOf(address account) external view returns (uint);
    function delegate(address delegatee) external;
    function transfer(address dst, uint rawAmount) external returns (bool);
}

interface VestingFactoryInterface {
    function updateRecipient(address _oldRecipient, address _newRecipient) external;
}

contract InstaTokenVesting is Initializable {
    using SafeMath for uint;

    event LogClaim(uint _claimAmount);
    event LogRecipient(address indexed _delegate);
    event LogDelegate(address indexed _delegate);
    event LogOwner(address indexed _newOwner);
    event LogTerminate(address owner, uint tokenAmount, uint32 _terminateTime);

    TokenInterface public constant token = TokenInterface(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb);
    address public immutable factory;
    address public owner;
    address public recipient;

    uint256 public vestingAmount;
    uint32 public vestingBegin;
    uint32 public vestingCliff;
    uint32 public vestingEnd;

    uint32 public lastUpdate;

    uint32 public terminateTime;

    constructor(address factory_) {
        factory = factory_;
    }

    function initialize(
        address recipient_,
        address owner_,
        uint256 vestingAmount_,
        uint32 vestingBegin_,
        uint32 vestingCliff_,
        uint32 vestingEnd_
    ) public initializer {
        require(vestingBegin_ >= block.timestamp, 'TokenVesting::initialize: vesting begin too early');
        require(vestingCliff_ >= vestingBegin_, 'TokenVesting::initialize: cliff is too early');
        require(vestingEnd_ > vestingCliff_, 'TokenVesting::initialize: end is too early');

        if (owner_ != address(0)) owner = owner_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function updateRecipient(address recipient_) public {
        require(msg.sender == recipient || msg.sender == owner, 'TokenVesting::updateRecipient: unauthorized');
        recipient = recipient_;
        VestingFactoryInterface(factory).updateRecipient(msg.sender, recipient);
        emit LogRecipient(recipient);
    }

    function updateOwner(address owner_) public {
        require(msg.sender == owner, 'TokenVesting::updateOwner: unauthorized');
        owner = owner_;
        emit LogOwner(owner);
    }

    function delegate(address delegatee_) public {
        require(msg.sender == recipient, 'TokenVesting::delegate: unauthorized');
        token.delegate(delegatee_);
        emit LogDelegate(delegatee_);
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, 'TokenVesting::claim: not time yet');
        require(terminateTime == 0, 'TokenVesting::claim: already terminated');
        uint amount;
        if (block.timestamp >= vestingEnd) {
            amount = token.balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = uint32(block.timestamp);
        }
        require(token.transfer(recipient, amount), "TokenVesting::claim: not-enough-token");
        emit LogClaim(amount);
    }

    function terminate() public {
        require(terminateTime == 0, 'TokenVesting::terminate: already terminated');
        require(msg.sender == owner, 'TokenVesting::terminate: unauthorized');

        claim();

        uint amount = token.balanceOf(address(this));
        require(token.transfer(owner, amount), "TokenVesting::terminate: transfer failed");

        terminateTime = uint32(block.timestamp);

        emit LogTerminate(owner, amount, terminateTime);
    }

}