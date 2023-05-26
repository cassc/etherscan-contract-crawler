// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PyeClaim is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    struct Allotment {
        uint256 allotedPYE;
        uint256 claimedPYE;
        uint256 claimedApple;
        uint256 claimedCherry;
    }

    mapping(address => Allotment) public Allotments;

    uint256 private claimDateIndex = 0; // multiplicative factor for each daily slice of Apl/Cher, representing each day since claimStartDate.
    uint256 private constant minIndex = 0;
    uint256 private constant maxIndex = 64; // capped at 64 days of Apl/Cher withdrawls 
    uint256 public constant claimStartDate =  1655924400;  // This is exactly 30 days after startTime, when withdrawals are now possible.
    uint256 private claimDate = 1656010800; // claimStartDate + 1 day, updates regularly and keeps track of first daily withdrawl, requires 24hrs for increment 
    
    address public PYE;
    address public Cherry;
    address public Apple;

    uint256 public immutable startTime; // beginning of 30 day vesting window (unix timestamp)
    uint256 public immutable totalAllotments; // sum of every holder's Allotment.total (PYE tokens)
    uint256 public claimableApple;
    uint256 public claimableCherry;
    uint256 constant accuracyFactor = 1 * 10**18;
    
    event TokensClaimed(address _holder, uint256 _amountPYE, uint256 _amountApple, uint256 _amountCherry);
    event PYEFunded(address _depositor, uint256 _amount, uint256 _timestamp);
    event AppleFunded(address _depositor, uint256 _amount, uint256 _timestamp);
    event CherryFunded(address _depositor, uint256 _amount, uint256 _timestamp);
    event PYERemoved(address _withdrawer, uint256 _amount, uint256 _timestamp);
    event AppleRemoved(address _withdrawer,uint256 _amount, uint256 _timestamp);
    event CherryRemoved(address _withdrawer, uint256 _amount, uint256 _timestamp);

   
    constructor(uint256 _startTime) {
        startTime = _startTime; //1653332400 for 24 May 2022 @ 12:00:00 PM UTC
        PYE = 0x5B232991854c790b29d3F7a145a7EFD660c9896c;
        Apple = 0x6f43a672D8024ba624651a5c2e63D129783dAd1F;
        Cherry = 0xD2858A1f93316242E81CF69B762361F59Fb9b18E;
        totalAllotments = (4 * 10**9) * 10**9; // 4 billion PYE tokens
    }

    // @dev: disallows contracts from entering
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    // ------------------ Getter Fxns ----------------------

    function getPYEAllotment(address _address) public view returns (uint256) {
        return Allotments[_address].allotedPYE;
    }

    function getAPPLEAllotment(address _address) public view returns (uint256) {
        uint256 original = Allotments[_address].allotedPYE; // initial allotment
        uint256 weightedAllotment = (original.mul(accuracyFactor)).div(totalAllotments);
        uint256 allottedApple = ((weightedAllotment.mul(claimableApple)).div(accuracyFactor));

        return allottedApple;
    }

    function getCHERRYAllotment(address _address) public view returns (uint256) {
        uint256 original = Allotments[_address].allotedPYE; // initial allotment
        uint256 weightedAllotment = (original.mul(accuracyFactor)).div(totalAllotments);
        uint256 allottedCherry = ((weightedAllotment.mul(claimableCherry)).div(accuracyFactor));

        return allottedCherry;
    }

    function getClaimed(address _address) public view returns (uint256, uint256, uint256) {
        return 
            (Allotments[_address].claimedPYE,
             Allotments[_address].claimedApple,
             Allotments[_address].claimedCherry);
    }

    function getElapsedTime() public view returns (uint256) {
        return block.timestamp.sub(startTime);
    }

    function getContractApple() public view returns (uint256) {
        return IERC20(Apple).balanceOf(address(this));
    }

    function getContractCherry() public view returns (uint256) {
        return IERC20(Cherry).balanceOf(address(this));
    }

    function getClaimDateIndex() public view returns (uint256) {
        return claimDateIndex;
    }

    // ----------------- Setter Fxns -----------------------

    function setPYE(address _PYE) public onlyOwner {PYE = _PYE;}

    function setApple(address _Apple) public onlyOwner {Apple = _Apple;}

    function setCherry(address _Cherry) public onlyOwner {Cherry = _Cherry;}

    function setAllotment(address _address, uint256 _allotment) public onlyOwner {
        Allotments[_address].allotedPYE = _allotment;
    }

    function setBatchAllotment(address[] calldata _holders, uint256[] calldata _allotments) external onlyOwner {
        for (uint256 i = 0; i < _holders.length; i++) {
            Allotments[_holders[i]].allotedPYE = _allotments[i];
        }
    }

    function updateIndex() external {
        require(block.timestamp > claimDate && claimDateIndex <= maxIndex && claimDateIndex >= minIndex); {
            claimDateIndex = block.timestamp.sub(claimStartDate).div(86400);
            if (claimDateIndex > maxIndex) {claimDateIndex = maxIndex;}
            claimDate += 1 days;
        }
    }

    // ----------------- Contract Funding/Removal Fxns -------------

    function fundPYE(uint256 _amountPYE) external onlyOwner {
        IERC20(PYE).transferFrom(address(msg.sender), address(this), _amountPYE);
        emit PYEFunded(msg.sender, _amountPYE, block.timestamp);
    }

    function fundApple(uint256 _amountApple) external onlyOwner {
        IERC20(Apple).transferFrom(address(msg.sender), address(this), _amountApple);
        claimableApple = claimableApple.add(_amountApple);
        emit AppleFunded(msg.sender, _amountApple, block.timestamp);
    }

    function fundCherry(uint256 _amountCherry) external onlyOwner { 
        IERC20(Cherry).transferFrom(address(msg.sender), address(this), _amountCherry);
        claimableCherry = claimableCherry.add(_amountCherry);
        emit CherryFunded(msg.sender, _amountCherry, block.timestamp);
    }

    function removePYE(uint256 _amountPYE) external onlyOwner {
        require(getElapsedTime() < 30 days || getElapsedTime() > 180 days , "Cannot withdraw PYE during the vesting period!");
        require(_amountPYE <= IERC20(PYE).balanceOf(address(this)), "Amount exceeds contract PYE balance!");
        IERC20(PYE).transfer(address(msg.sender), _amountPYE);
        emit PYERemoved(msg.sender, _amountPYE, block.timestamp);
    }

    function removeApple(uint256 _amountApple) external onlyOwner {
        require(getElapsedTime() > 180 days , "Can only remove apple after vesting period!");
        require(_amountApple <= IERC20(Apple).balanceOf(address(this)), "Amount exceeds contract Apple balance!");
        IERC20(Apple).transfer(address(msg.sender), _amountApple);
        claimableApple = claimableApple.sub(_amountApple);
        emit AppleRemoved(msg.sender, _amountApple, block.timestamp);
    }

    function removeCherry(uint256 _amountCherry) external onlyOwner {
        require(getElapsedTime() > 180 days , "Can only remove cherry after vesting period!");
        require(_amountCherry <= IERC20(Cherry).balanceOf(address(this)), "Amount exceeds contract Cherry balance!");
        IERC20(Cherry).transfer(address(msg.sender), _amountCherry);
        claimableCherry = claimableCherry.sub(_amountCherry);
        emit CherryRemoved(msg.sender, _amountCherry, block.timestamp);
    }

    // ----------------- Withdraw Fxn ----------------------

    function claimTokens() external nonReentrant notContract() {
        require(getElapsedTime() > 30 days , "You have not waited the 30-day cliff period!");
        if(block.timestamp > claimDate && claimDateIndex <= maxIndex && claimDateIndex >= minIndex) {
            claimDateIndex = block.timestamp.sub(claimStartDate).div(86400);
            if (claimDateIndex > maxIndex) {claimDateIndex = maxIndex;}
            claimDate += 1 days;
        }
        uint256 original = Allotments[msg.sender].allotedPYE; // initial allotment
        uint256 withdrawn = Allotments[msg.sender].claimedPYE; // amount user has claimed
        uint256 available = original.sub(withdrawn); // amount left that can be claimed
        uint256 tenPercent = (original.mul((1 * 10**18))).div(10 * 10**18); // 10% of user's original allotment;
        uint256 dailyApple = (claimableApple.mul(15625 * 10**18)).div(1 * 10**6);
        uint256 dailyCherry = (claimableCherry.mul(15625 * 10**18)).div(1 * 10**6);

        uint256 weightedAllotment = (original.mul(accuracyFactor)).div(totalAllotments);
        uint256 withdrawableApple = ((weightedAllotment.mul(dailyApple).div(1 * 10**18)).mul(claimDateIndex).div(accuracyFactor)).sub(Allotments[msg.sender].claimedApple);
        uint256 withdrawableCherry = ((weightedAllotment.mul(dailyCherry).div(1 * 10**18)).mul(claimDateIndex).div(accuracyFactor)).sub(Allotments[msg.sender].claimedCherry);

        uint256 withdrawablePYE;

        if (getElapsedTime() >= 93 days) {
            withdrawablePYE = available;
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 86 days && getElapsedTime() < 93 days) {
            withdrawablePYE = (9 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 79 days && getElapsedTime() < 86 days) {
            withdrawablePYE = (8 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 72 days && getElapsedTime() < 79 days) {
            withdrawablePYE = (7 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 65 days && getElapsedTime() < 72 days) {
            withdrawablePYE = (6 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 58 days && getElapsedTime() < 65 days) {
            withdrawablePYE = (5 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 51 days && getElapsedTime() < 58 days) {
            withdrawablePYE = (4 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 44 days && getElapsedTime() < 51 days) {
            withdrawablePYE = (3 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 37 days && getElapsedTime() < 44 days) {
            withdrawablePYE = (2 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 30 days && getElapsedTime() < 37 days) {
            withdrawablePYE = tenPercent.sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else {
            withdrawablePYE = 0;
        }
    }

    // ------------------------ Internal Helper/Transfer Fxns ------

    function checkThenTransfer(uint256 _withdrawablePYE, uint256 _withdrawableApple, uint256 _withdrawableCherry, uint256 _available) internal {
        require(_withdrawablePYE <= _available && _withdrawablePYE <= IERC20(PYE).balanceOf(address(this)) , 
            "You have already claimed for this period, or you have claimed your total PYE allotment!");
        require(_withdrawableApple <= getContractApple() && _withdrawableCherry <= getContractCherry() ,
            "Cherry or Apple transfer exceeds contract balance!");

        if (_withdrawablePYE > 0) {
            IERC20(PYE).safeTransfer(msg.sender, _withdrawablePYE);
            Allotments[msg.sender].claimedPYE = Allotments[msg.sender].claimedPYE.add(_withdrawablePYE);
        }
        if (_withdrawableApple > 0) {
            IERC20(Apple).safeTransfer(msg.sender, _withdrawableApple);
            Allotments[msg.sender].claimedApple = Allotments[msg.sender].claimedApple.add(_withdrawableApple);
        }
        if (_withdrawableCherry > 0) {
            IERC20(Cherry).safeTransfer(msg.sender, _withdrawableCherry);
            Allotments[msg.sender].claimedCherry = Allotments[msg.sender].claimedCherry.add(_withdrawableCherry);
        }

        emit TokensClaimed(msg.sender, _withdrawablePYE, _withdrawableApple, _withdrawableCherry);
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    // ----------------------- View Function To Calculate Withdraw Amt. -----

    function calculateWithdrawableAmounts(address _address) external view returns (uint256, uint256, uint256) {
        
        uint256 original = Allotments[_address].allotedPYE; // initial allotment
        uint256 withdrawn = Allotments[_address].claimedPYE; // amount user has claimed
        uint256 available = original.sub(withdrawn); // amount left that can be claimed
        uint256 tenPercent = (original.mul((1 * 10**18))).div(10 * 10**18); // 10% of user's original allotment;
        uint256 dailyApple = (claimableApple.mul(15625 * 10**18)).div(1 * 10**6);
        uint256 dailyCherry = (claimableCherry.mul(15625 * 10**18)).div(1 * 10**6);

        uint256 weightedAllotment = (original.mul(accuracyFactor)).div(totalAllotments);
        uint256 withdrawableApple = ((weightedAllotment.mul(dailyApple).div(1 * 10**18)).mul(getClaimDateIndex()).div(accuracyFactor)).sub(Allotments[_address].claimedApple);
        uint256 withdrawableCherry = ((weightedAllotment.mul(dailyCherry).div(1 * 10**18)).mul(getClaimDateIndex()).div(accuracyFactor)).sub(Allotments[_address].claimedCherry);

        uint256 withdrawablePYE;

        if (getElapsedTime() >= 93 days) {withdrawablePYE = available;
        } else if (getElapsedTime() >= 86 days && getElapsedTime() < 93 days) {withdrawablePYE = (9 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 79 days && getElapsedTime() < 86 days) {withdrawablePYE = (8 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 72 days && getElapsedTime() < 79 days) {withdrawablePYE = (7 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 65 days && getElapsedTime() < 72 days) {withdrawablePYE = (6 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 58 days && getElapsedTime() < 65 days) {withdrawablePYE = (5 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 51 days && getElapsedTime() < 58 days) {withdrawablePYE = (4 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 44 days && getElapsedTime() < 51 days) {withdrawablePYE = (3 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 37 days && getElapsedTime() < 44 days) {withdrawablePYE = (2 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 30 days && getElapsedTime() < 37 days) {withdrawablePYE = tenPercent.sub(withdrawn);
        } else {withdrawablePYE = 0;}

        return (withdrawablePYE, withdrawableApple, withdrawableCherry);
    }    
}