// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract LaunchPadCatsAndDogs is Ownable {
    using SafeMath for uint256;

    // 4 rounds : 0 = not open, 1 = guaranty round, 2 = First come first serve, 3 = sale finished

    uint256 public round1BeganAt;

    function roundNumber() external view returns (uint256) {
        return _roundNumber();
    }

    function _roundNumber() internal view returns (uint256) {
        uint256 _round;
        if (block.timestamp < round1BeganAt || round1BeganAt == 0) {
            _round = 0;
        } else if (
            block.timestamp >= round1BeganAt &&
            block.timestamp < round1BeganAt.add(round1Duration)
        ) {
            _round = 1;
        } else if (
            block.timestamp >= round1BeganAt.add(round1Duration) && !endUnlocked
        ) {
            _round = 2;
        } else if (endUnlocked) {
            _round = 3;
        }

        return _round;
    }

    function setRound1Timestamp(uint256 _round1BeginAt) external onlyOwner {
        round1BeganAt = _round1BeginAt;
    }

    uint256 public round1Duration = 3600; // in secondes 3600 = 1h

    IERC20 public stableCoin =
        IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //Busd

    mapping(address => uint256) public round1Allowance;
    mapping(address => uint256) _round2Allowance;
    mapping(address => bool) _hasParticipated;

    function isWhitelisted(address _address) public view returns (bool) {
        bool result;
        if (_hasParticipated[_address]) {
            result = true;
        } else if (
            round1Allowance[_address] > 0 || _round2Allowance[_address] > 0
        ) {
            result = true;
        }
        return result;
    }

    function round2Allowance(address _address) public view returns (uint256) {
        uint256 result;
        if (_hasParticipated[_address]) {
            result = _round2Allowance[msg.sender];
        } else if (round1Allowance[_address] > 0) {
            result = round1Allowance[_address].mul(200);
        }
        return result;
    }

    uint256 public stableTarget = 30000 * 1E18;
    uint256 public tokenTarget = 1999800  * 1E18;
    uint256 public multiplier = 6666 ; // div per 100

    bool public endUnlocked;

    uint256 public totalOwed;
    mapping(address => uint256) public claimable;
    uint256 public stableRaised;

    uint256 public participants;

    event StartSale(uint256 startTimestamp);
    event EndUnlockedEvent(uint256 endTimestamp);
    event ClaimUnlockedEvent(uint256 claimTimestamp);

    event RoundChange(uint256 roundNumber);

    function initSale(uint256 _tokenTarget, uint256 _stableTarget)
        external
        onlyOwner
    {
        require(_stableTarget > 0, "stable target can't be Zero");
        require(_tokenTarget > 0, "token target can't be Zero");
        tokenTarget = _tokenTarget;
        stableTarget = _stableTarget;
        multiplier = tokenTarget.mul(100).div(stableTarget);
    }

    function setTokenTarget(uint256 _tokenTarget) external onlyOwner {
        require(_roundNumber() == 0, "Presale already started!");
        tokenTarget = _tokenTarget;
        multiplier = tokenTarget.mul(100).div(stableTarget);
    }

    function setStableTarget(uint256 _stableTarget) external onlyOwner {
        require(_roundNumber() == 0, "Presale already started!");
        stableTarget = _stableTarget;
        multiplier = tokenTarget.mul(100).div(stableTarget);
    }

    function startSale() external onlyOwner {
        require(_roundNumber() == 0, "Presale round isn't 0");

        round1BeganAt = block.timestamp;
        emit StartSale(block.timestamp);
    }

    function finishSale() external onlyOwner {
        require(!endUnlocked, "Presale already ended!");

        endUnlocked = true;
        emit EndUnlockedEvent(block.timestamp);
    }

    function addWhitelistedAddress(address _address, uint256 _allocation)
        external
        onlyOwner
    {
        round1Allowance[_address] = _allocation;
    }

    function addMultipleWhitelistedAddresses(
        address[] calldata _addresses,
        uint256[] calldata _allocations
    ) external onlyOwner {
        require(
            _addresses.length == _allocations.length,
            "Issue in _addresses and _allocations length"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            round1Allowance[_addresses[i]] = _allocations[i];
        }
    }

    function removeWhitelistedAddress(address _address) external onlyOwner {
        round1Allowance[_address] = 0;
    }

    function withdrawStable() external onlyOwner returns (bool) {
        require(endUnlocked, "presale has not yet ended");

        return
            stableCoin.transfer(
                msg.sender,
                stableCoin.balanceOf(address(this))
            );
    }

    //update from original contract
    function claimableAmount(address user) external view returns (uint256) {
        return claimable[user].mul(multiplier).div(100);
    }

    function emergencyWithdrawToken(address _token)
        external
        onlyOwner
        returns (bool)
    {
        return
            IERC20(_token).transfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
    }

    function buyRound1Stable(uint256 _amount) external {
        require(_roundNumber() == 1, "presale isn't on good round");

        require(
            stableRaised.add(_amount) <= stableTarget,
            "Target already hit"
        );
        require(
            round1Allowance[msg.sender] >= _amount,
            "Amount too high or not white listed"
        );
        if (!_hasParticipated[msg.sender]) {
            _hasParticipated[msg.sender] = true;
            _round2Allowance[msg.sender] = round1Allowance[msg.sender].mul(200);
        }

        require(stableCoin.transferFrom(msg.sender, address(this), _amount));

        uint256 amount = _amount.mul(multiplier).div(100);

        require(totalOwed.add(amount) <= tokenTarget, "sold out");

        round1Allowance[msg.sender] = round1Allowance[msg.sender].sub(
            _amount,
            "Maximum purchase cap hit"
        );

        if (claimable[msg.sender] == 0) participants = participants.add(1);

        claimable[msg.sender] = claimable[msg.sender].add(_amount);
        totalOwed = totalOwed.add(amount);
        stableRaised = stableRaised.add(_amount);

        if (stableRaised == stableTarget) {
            emit RoundChange(3);
            endUnlocked = true;
            emit EndUnlockedEvent(block.timestamp);
        }
    }

    function buyRound2Stable(uint256 _amount) external {
        require(_roundNumber() == 2, "Not the good round");
        require(round2Allowance(msg.sender) > 0, "you are not whitelisted");
        require(_amount > 0, "amount too low");
        require(
            stableRaised.add(_amount) <= stableTarget,
            "target already hit"
        );
        if (!_hasParticipated[msg.sender]) {
            _hasParticipated[msg.sender] = true;
            _round2Allowance[msg.sender] = round1Allowance[msg.sender].mul(200);
        }

        _round2Allowance[msg.sender] = _round2Allowance[msg.sender].sub(
            _amount,
            "Maximum purchase cap hit"
        );

        require(stableCoin.transferFrom(msg.sender, address(this), _amount));

        uint256 amount = _amount.mul(multiplier).div(100);
        require(totalOwed.add(amount) <= tokenTarget, "sold out");

        if (claimable[msg.sender] == 0) participants = participants.add(1);

        claimable[msg.sender] = claimable[msg.sender].add(_amount);
        totalOwed = totalOwed.add(amount);
        stableRaised = stableRaised.add(_amount);

        if (stableRaised == stableTarget) {
            emit RoundChange(3);
            endUnlocked = true;
            emit EndUnlockedEvent(block.timestamp);
        }
    }
}