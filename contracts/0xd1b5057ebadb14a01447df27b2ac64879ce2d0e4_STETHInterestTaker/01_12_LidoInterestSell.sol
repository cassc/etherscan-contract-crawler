pragma solidity ^0.8.19;

import "BaseACLInCall.sol";

contract STETHInterestTaker is BaseACLInCall {
    bytes32 public constant NAME = "STETHInterestTaker";
    uint256 public constant VERSION = 1;

    address public constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant receiver = 0xE746CcEA2A8854c8CDeb3AE05141B98622146a74;
    uint256 public constant baseIntereset = 0.01 ether;
    uint256 public monthInSeconds = 30 days;
    uint256 public fixInterestPerMonth;
    uint256 public lastWithdrawTime;

    constructor(address _owner, address _caller) BaseACLInCall(_owner, _caller) {
        lastWithdrawTime = block.timestamp;
    }

    modifier updateTime() {
        _;
        lastWithdrawTime = block.timestamp;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "self!");
        _;
    }

    event FixInterestChanged(uint256 indexed oldValue, uint256 indexed newValue);

    function setFixedInterestPerMonth(uint256 fixInterest) external onlyOwner {
        uint256 oldFixInterest = fixInterestPerMonth;
        uint256 multipler = fixInterest / baseIntereset;
        fixInterestPerMonth = multipler * baseIntereset;
        emit FixInterestChanged(oldFixInterest, fixInterestPerMonth);
    }

    function avaliableInterest() public view returns (uint256 interest) {
        uint256 currentTime = block.timestamp;
        uint256 timePassed = currentTime - lastWithdrawTime;
        uint256 n = timePassed / monthInSeconds;
        interest = n * fixInterestPerMonth;
    }

    function transfer(address to, uint256 amount) external updateTime onlyContract(stETH) onlySelf {
        uint256 interest = avaliableInterest();
        require(amount <= interest, "Execeed interest amount");
        require(to == receiver, "receiver!");
    }

    function contracts() public pure override returns (address[] memory _contract) {
        _contract = new address[](1);
        _contract[0] = stETH;
    }
}