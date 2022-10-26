//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";

interface IStakingContract {
    function depositRewards(uint256 amount) external;
}

interface IToken {
    function getOwner() external view returns (address);

    function burn(uint256 amount) external returns (bool);
}

contract SKMTTaxReceiverV3 {
    // Token
    address public immutable token;

    // Receiver Adresses
    address public charityAddress;
    address public defiAddress;
    address public devAddress;

    // Allocation Percentage
    uint256 public charityPercentage;
    uint256 public defiPercentage;
    uint256 public devPercentage;

    /**
        Minimum Amount Of Tokens In Contract To Trigger `trigger` Unless `approved`
        If Set To A Very High Number, Only Approved May Call Trigger Function
        If Set To A Very Low Number, Anybody May Call At Their Leasure
     */
    uint256 public minimumTokensRequiredToTrigger;

    // Address => Can Call Trigger
    mapping(address => bool) public approved;

    // Events
    event Approved(address caller, bool isApproved);
    event DepositRewards(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == IToken(token).getOwner(), "Only Token Owner");
        _;
    }

    constructor(
        address token_,
        address charityAddress_,
        address defiAddress_,
        address devAddress_
    ) {
        require(
            token_ != address(0) &&
                charityAddress_ != address(0) &&
                defiAddress_ != address(0) &&
                devAddress_ != address(0),
            "Zero Address"
        );

        token = token_;
        charityAddress = charityAddress_;
        defiAddress = defiAddress_;
        devAddress = devAddress_;

        approved[msg.sender] = true;

        charityPercentage = 10;
        defiPercentage = 30;
        devPercentage = 50;
    }

    function trigger() external {
        // Token Balance In Contract
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance < minimumTokensRequiredToTrigger && !approved[msg.sender]) {
            return;
        }

        if (balance > 0) {
            uint256 charityBalance = (balance * charityPercentage) / 100;
            uint256 defiBalance = (balance * defiPercentage) / 100;
            uint256 devBalance = (balance * devPercentage) / 100;
            uint256 burn = balance - charityBalance - defiBalance - devBalance;

            // send to destinations
            if (charityBalance > 0) {
                IERC20(token).transfer(charityAddress, charityBalance);
            }
            if (devBalance > 0) {
                IERC20(token).transfer(devAddress, devBalance);
            }
            if (burn > 0) {
                IToken(token).burn(burn);
            }
            if (defiBalance > 0) {
                IStakingContract(defiAddress).depositRewards(defiBalance);
                emit DepositRewards(defiBalance);
            }
        }
    }

    function setCharityAddress(address charityAddress_) external onlyOwner {
        require(charityAddress_ != address(0));
        charityAddress = charityAddress_;
    }

    function setCharityPercentage(uint256 newCharityPercentage_)
        external
        onlyOwner
    {
        require(
            (defiPercentage + devPercentage + newCharityPercentage_) <= 100
        );
        charityPercentage = newCharityPercentage_;
    }

    function setDefiAddress(address defiAddress_) external onlyOwner {
        require(defiAddress_ != address(0));
        defiAddress = defiAddress_;
    }

    function setDefiPercentage(uint256 newDefiPercentage_) external onlyOwner {
        require(
            (charityPercentage + devPercentage + newDefiPercentage_) <= 100
        );
        defiPercentage = newDefiPercentage_;
    }

    function setDevAddress(address devAddress_) external onlyOwner {
        require(devAddress_ != address(0));
        devAddress = devAddress_;
    }

    function setDevPercentage(uint256 newDevPercentage_) external onlyOwner {
        require(
            (charityPercentage + defiPercentage + newDevPercentage_) <= 100
        );
        devPercentage = newDevPercentage_;
    }

    function setApproved(address caller, bool isApproved) external onlyOwner {
        approved[caller] = isApproved;
        emit Approved(caller, isApproved);
    }

    function setMinTriggerAmount(uint256 minTriggerAmount) external onlyOwner {
        minimumTokensRequiredToTrigger = minTriggerAmount;
    }

    function withdraw() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}
