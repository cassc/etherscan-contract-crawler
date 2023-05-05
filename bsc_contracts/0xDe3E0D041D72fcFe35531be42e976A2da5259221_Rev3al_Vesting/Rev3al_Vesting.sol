/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Rev3al_Vesting {
    address public owner;
    address public token;

    address public proposedOwner;
    address public hotWallet;

    bool public pause;

    mapping(address => uint256) public userToVestingPeriod;
    mapping(address => uint256) public uniqueUser;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    modifier onlyHotWallet() {
        require(msg.sender == hotWallet, "Not the hot wallet!");
        _;
    }

    struct Investor {
        uint256 startCliffDate;
        uint256 endCliffDate;
        uint256 totalClaims;
        uint256 currentClaims;
        uint256 amountToDistribute;
        uint256 distributedAmount;
        uint256 lastClaimDate;
        address investor;
    }

    Investor[] public investors;

    event NewInvestor(address indexed investor);
    event Withdraw(address indexed investor, uint256 amount);

    constructor(address _token) {
        owner = msg.sender;
        token = _token;

        // Push empty struct
        Investor memory _newInvestor = Investor(0, 0, 0, 0, 0, 0, 0, address(0));
        investors.push(_newInvestor);
    }
    
    receive() external payable {}

    function addInvestor(address _investor, uint256 _cliffPeriodInMonths, uint256 _totalClaims, uint256 _amountToDistribute) external onlyOwner {
        require(uniqueUser[_investor] == 0, "Can't add a user twice!");
        require(_totalClaims > 0, "Invalid parameter!");
        // require(IToken(token).transferFrom(msg.sender, address(this), _amountToDistribute), "Failed ERC20 Transfer!");

        uniqueUser[_investor] = 1;


        uint256 _timeNow = block.timestamp;
        uint256 _endCliff = _timeNow + (_cliffPeriodInMonths * 30 days);

        Investor memory _newInvestor = Investor(_timeNow, _endCliff, _totalClaims, 0, _amountToDistribute, 0, block.timestamp, _investor);

        userToVestingPeriod[_investor] = investors.length;

        investors.push(_newInvestor);

        emit NewInvestor(_investor);
    }

    function manualWithdrawFromVesting() external {
        _withdrawFromVesting(msg.sender);
    }

    function hotWalletWithdrawFromVesting(address _user) external onlyHotWallet {
        _withdrawFromVesting(_user);
    }

    function _withdrawFromVesting(address _user) internal {
        require(pause == false, "The smart contract is paused!");

        uint256 _id = userToVestingPeriod[_user];
        require(_id > 0, "Not in vesting schedule!");

        Investor storage _investor = investors[_id];
        require(block.timestamp > _investor.endCliffDate, "Still in cliff period!");
        require(block.timestamp > _investor.lastClaimDate + 30 days, "You can claim once per month!");
        require(_investor.currentClaims < _investor.totalClaims, "Can't claim anymore!");


        uint256 _amount  = _investor.amountToDistribute / _investor.totalClaims;

        unchecked {
            ++_investor.currentClaims;
            _investor.distributedAmount += _amount;
        }
        _investor.lastClaimDate = block.timestamp;
        require(IToken(token).transfer(_user, _amount), "Failed ERC20 Transfer!");

        if(_investor.currentClaims == _investor.totalClaims - 1) {
            uniqueUser[_user] = 0;
        }

        emit Withdraw(_user, _amount);
    }

    function proposeOwner(address _newOwner) external onlyOwner {
        proposedOwner = _newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == proposedOwner, "Not proposed owner!");
        owner = msg.sender;
        proposedOwner = address(0);
    }

    function withdrawTokens(address _token) external onlyOwner {
        uint256 _balance = IToken(_token).balanceOf(address(this));
        require(IToken(_token).transfer(owner, _balance), "Invalid ERC20 Transfer!");
    }

    function withdrawBnb() external onlyOwner {
        uint256 _amount = address(this).balance;
        (bool _sent, ) = owner.call{value: _amount}("");
        require(_sent, "Failed Transaction!");
    }

    function pauseSc() external onlyOwner {
        if(pause == true) {
            pause = false;
        } else {
            pause == true;
        }
    }

    function changeHotWallet(address _newHotWallet) external onlyOwner {
        hotWallet = _newHotWallet;
    }
}