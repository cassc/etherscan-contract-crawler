// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20_USDT {
    function transferFrom(address from, address to, uint value) external;
    function transfer(address to, uint value) external;
}

contract FlowrrSeed is Ownable{

    uint256 private constant baseDivider = 10000;
    uint32 private feePercents = 100;
    address public feeAddr;
    bool public avail_wd = true;
    address public devAddress;

    //Modifier
    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "onlyGovernance:: Not gov"
        );
        _;
    }

    //Events
    event DepositToken(uint256 uid, address account, uint256 amount, address token, uint256 fees);
    event WithdrawToken(address account, uint256 amount, address token);

    constructor(
        address _feeAddr,
        address _devAddress
    ) {
        feeAddr = _feeAddr;
        devAddress = _devAddress;
    }

    //BNB----------------------------
    receive() external payable{
        revert();
    }
    //Token--------------------------
    function depositToken(uint256 uid, uint256 amount, address _tokenAddress) external {
        IERC20_USDT(_tokenAddress).transferFrom(msg.sender, address(this), amount);
        uint256 fees = amount * uint256(feePercents) / baseDivider;
        IERC20_USDT(_tokenAddress).transfer(feeAddr, fees);
        emit DepositToken(uid, msg.sender, amount, _tokenAddress, fees);
    }

    function withdrawToken(address account, uint256 amount, address _tokenAddress) external onlyGovernance {
        require(avail_wd, "Withdraw Currently Unavailable");
        IERC20_USDT(_tokenAddress).transfer(account, amount);
        emit WithdrawToken(account, amount, _tokenAddress);
    }

    //Dev
    function getFeePercent() external onlyGovernance view returns(uint32) {
        return feePercents;
    }

    function switch_wd() external onlyGovernance {
        avail_wd = !avail_wd;
    }

    function update_fees(uint32 _percent) external onlyGovernance{
        feePercents = _percent;
    }

    function update_feeAddr(address _addr) external onlyGovernance{
        require(_addr != address(0), "_Zero Address");
        feeAddr = _addr;
    }

    function changeDev(address account) external onlyOwner {
        require(account != address(0), "Address 0");
        devAddress = account;
    }

}