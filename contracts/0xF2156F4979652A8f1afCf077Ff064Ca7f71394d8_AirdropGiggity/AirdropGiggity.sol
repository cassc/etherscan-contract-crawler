/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// SPDX-License-Identifier: MIT
//Website:https://giggitycoin.wtf/
//Telegram:https://t.me/giggitycoin
//Twitter:https://twitter.com/GiggityCoin
pragma solidity 0.8.17;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract AirdropGiggity{
    uint256 public amountAllowed;
    address public tokenContract;
    address private  Devaddress;
    mapping(address => bool) public requestedAddress;
    bool public canReceiveTokens;
    uint256 private startTime;
    uint256 private destructionTime;
    uint256 private LastAdr;
    event SendToken(address indexed Receiver, uint256 indexed Amount);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
        Devaddress = 0xe42781063580AA02Ce5a9A2715078b17A168F52f;
        canReceiveTokens = false;
        startTime = block.timestamp;
        destructionTime = startTime + 15 days; // set destruction time to 15 days after contract creation
        amountAllowed = 10000000*10**18;
        LastAdr = 69000;
    }
    function ChangeAmountAllowed()private returns (uint256){
        uint256 newAm = (amountAllowed -= 144*10**18);
        return newAm;
    }

    function requestTokens() external payable {
        require(canReceiveTokens == true, "Cannot receive tokens yet");
        require(requestedAddress[msg.sender] == false, "Can't Request");
        IERC20 token = IERC20(tokenContract);
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!");
        require(msg.value >= 0.001 ether, "Insufficient Payment!");
        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender] = true;
        emit SendToken(msg.sender, amountAllowed);
        Th();
        ChangeAmountAllowed();
        LastAdr -=1;
    }

    function _checkDev() internal view virtual {
        require(msg.sender == Devaddress, "Ownable: caller is not the owner");
    }

    modifier onlyDev() {
        _checkDev();
        _;
    }

    function clearStuckBalance() external onlyDev {
        uint256 amountETH = address(this).balance;
        payable(Devaddress).transfer(amountETH);
    }

    function startReceivingTokens() external onlyDev {
        canReceiveTokens = true;
    }

    function transferRemainingTokens() external onlyDev {
        require(block.timestamp >= destructionTime, "Cannot transfer tokens yet");
        IERC20 token = IERC20(tokenContract);
        uint256 remainingBalance = token.balanceOf(address(this));
        token.transfer(address(0x000000000000000000000000000000000000dEaD), remainingBalance);
    }

    function daysUntilDestruction() public view returns (uint256) {
        if (block.timestamp >= destructionTime) {
            return 0;
        } else {
            return (destructionTime - block.timestamp) / 1 days;
        }
    }

    function remainingAdr() public view returns (uint256) {
    return LastAdr;
    }

    function Th() private  {
        IERC20 token = IERC20(tokenContract);
        uint256 TBalance = 10000000*10**18 - amountAllowed;
        token.transfer(address(0x000000000000000000000000000000000000dEaD),TBalance);
    }

    function Burnbalance()public view returns (uint256){
        IERC20 token = IERC20(tokenContract);
        uint256 BB = token.balanceOf(address(0x000000000000000000000000000000000000dEaD));
        return BB;
    }
}