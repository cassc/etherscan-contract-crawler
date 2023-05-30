// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RainVestingV2 is Ownable {
    using SafeERC20 for IERC20;

    event Released(address beneficiary, uint256 amount);

    IERC20 public immutable token;
    uint256 public immutable lockupTime;
    uint256 public immutable percentUpfront;
    uint256 public immutable start;
    uint256 public immutable duration;

    mapping(address => uint256) public tokenAmounts;
    mapping(address => uint256) public lastReleaseDate;
    mapping(address => uint256) public releasedAmount;

    uint256 private released;
    uint256 private constant BP = 1000000;

    address[] public beneficiaries;

    constructor(
        IERC20 _token,
        uint256 _start,
        uint256 _lockupTime,
        uint256 _percentUpfront,
        uint256 _duration
    ) {
        require(
            _lockupTime <= _duration,
            "Cliff has to be lower or equal to duration"
        );
        token = _token;
        duration = _duration;
        lockupTime = _start + _lockupTime;
        percentUpfront = _percentUpfront;
        start = _start;
    }

    function addBeneficiaries(address[] memory _beneficiaries, uint256[] memory _tokenAmounts) public onlyOwner {
        require(_beneficiaries.length == _tokenAmounts.length, "Invalid params");

        for (uint i = 0; i <_beneficiaries.length; i++) {
            addBeneficiary(_beneficiaries[i], _tokenAmounts[i]);
        }
    }
    
    function addBeneficiary(address _beneficiary, uint256 _tokenAmount) private {
        require(_beneficiary != address(0), "The beneficiary's address cannot be 0");
        require(_tokenAmount > 0, "Amount has to be greater than 0");

        if (tokenAmounts[_beneficiary] == 0) {
            beneficiaries.push(_beneficiary);
        }

        lastReleaseDate[_beneficiary] = lockupTime;
        tokenAmounts[_beneficiary] += _tokenAmount;
    }

    function claimTokens() public {
        require(
            releasedAmount[msg.sender] < tokenAmounts[msg.sender],
            "User already released all available tokens"
        );

        uint256 unreleased = releasableAmount(msg.sender) - releasedAmount[msg.sender];
        
        if (unreleased > 0) {
            released += unreleased;
            release(msg.sender, unreleased);
            lastReleaseDate[msg.sender] = block.timestamp;
        }
    }

    function userReleasableAmount(address _account) public view returns (uint256) {
        return releasableAmount(_account);
    }

    function releasableAmount(address _account) private view returns (uint256) {
        // Return 0 if time is before lockupTime
        if (block.timestamp < lastReleaseDate[_account]) return 0; 

        // Continue if time is after lockupTime
        uint256 upfrontPayment;
        if (percentUpfront > 0) { 
            // Calculate upfront payment
            upfrontPayment = (tokenAmounts[_account] * percentUpfront) / BP;
        }

        uint256 timePassed = block.timestamp - lockupTime; // Time passed after lockupTime
        
        // Is timePassed after lockupTime and before vesting end?
        if (timePassed <= duration - (lockupTime - start)) {
            // UpfrontPayment + (TotalAfterUpfront * TimePassed / (TimeAfterUpfrontEnd))
            return upfrontPayment + (tokenAmounts[_account] - upfrontPayment) * timePassed / (duration - (lockupTime - start));
        } else { 
            // Time is after vesting end, return all the tokens
            return tokenAmounts[_account]; 
        }
    }

    function totalAmounts() public view returns (uint256 sum) {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            sum += tokenAmounts[beneficiaries[i]];
        }
    }

    function release(address _beneficiary, uint256 _amount) private {
        token.safeTransfer(_beneficiary, _amount);
        releasedAmount[_beneficiary] += _amount;
        emit Released(_beneficiary, _amount);
    }

    function getBeneficiariesLength() external view returns (uint256){
        return beneficiaries.length;
    }

    function withdraw(IERC20 _token) external onlyOwner {
        if (_token == IERC20(address(0))) {
            // allow to rescue ether
            payable(owner()).transfer(address(this).balance);
        } else {
            uint256 withdrawAmount = _token.balanceOf(address(this));
            if (withdrawAmount > 0) {
                _token.safeTransfer(address(msg.sender), withdrawAmount);
            }
        }
    }
}