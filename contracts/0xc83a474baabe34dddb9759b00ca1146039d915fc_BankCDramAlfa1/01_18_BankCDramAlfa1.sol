pragma solidity >=0.7.0 < 0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BankCDramAlfa1 is ERC20, Ownable, PullPayment{
    AggregatorV3Interface internal priceFeed;
    using Address for address;
    //using SafeERC20 for serc;
    using Counters for Counters.Counter;
    Counters.Counter private currentId;
    uint256 convBig = 10000000000000000;
    CDramStruct _criptoDram;
    ERC20 public token = ERC20(address(this));
    address _usdtAddress = 0x509Ee0d083DdF8AC028f2a56731412edD63223B9;
    address _admin;

    uint256 public _cryptoDramBalance;
    uint256 public _currentUserBalance;
    uint256 public _amount;
    uint256 public _allowanse;
    bool public _approval = false;

    int public etherPrice;

    uint public transferAmount;

    address public parseSigne;

    struct CDramStruct{
        string Name;
        uint256 BankBalance;
        uint256 AvaibleBlance;
        uint256 TotalDeposit;
        uint256 TotalCredit;
    }

    mapping (uint256 => uint256) CusomerToDeposit;
    mapping (uint256 => uint256) CustomerToCredit;

    constructor() ERC20('Crypto dram - Cdram', 'CDramERC20') { 
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        currentId.increment();
        console.log(currentId.current());
        _criptoDram = CDramStruct('CriptoDram', 0, 0, 0, 0);
        etherPrice = getLatestPrice();
    }

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price * 1000000000;
    }

    function mintCDram(uint256 amount) public onlyOwner{
       // uint256 _amountToBig = moneyToBig(amount);
        _criptoDram.BankBalance = _criptoDram.BankBalance + amount;
        _mint(msg.sender, amount);
        _amount = amount;
    }

    function fireCDram(uint256 amount) public{
        address nullAddress = address(0xdead);
        _transfer(owner(), nullAddress, amount);
        //token.transfer(nullAddress, amount);
    }

    function sale() public payable {
        _cryptoDramBalance = token.balanceOf(owner());
        require (msg.value <= _cryptoDramBalance, "Not enough crypto drams!");
        //require (msg.exchange > 0, "Exchange is require!");
        transferAmount = msg.value;
        uint256 totalUSD = EthToUsd(msg.value); 
        //uint256 totalCDram = totalUSD;// - totalUSD*10/100;
        _transfer(owner(), msg.sender, totalUSD);
    }

    function buy(uint256 amount) public {
        _currentUserBalance = token.balanceOf(msg.sender);
        
        //uint256 totalUSDToTransfer = amountCDram;// - amountCDram*10/100;
        //uint256 totalEth = UsdToEth(amountCDram);
        uint256 totalUSD = EthToUsd(amount); 
        require (totalUSD <= _cryptoDramBalance, "Not enough crypto drams!");
        _transfer(msg.sender, owner(), totalUSD);
        address payable client = payable(msg.sender);
        //client.transfer(totalEth);
        (bool send, bytes memory data) = client.call{value: amount}("");
        require(send,"File to send!");
    }


    function moneyToBig(uint256 arg) internal returns(uint256){
        uint256 result  = arg*convBig;

        return result;
    }

    //TODO
    function GetCDramBalance() public view returns(uint256){
        //_cryptoDramBalance = token.balanceOf(owner());
        return token.balanceOf(owner());
    }

    function getCurrentUserBalance() public  view returns(uint256){
        //_currentUserBalance = token.balanceOf(msg.sender);
        return token.balanceOf(msg.sender);
    }

    //tmp functions

    function ChangeOwner(address newOwner) public onlyOwner{
        _admin = newOwner;
        _transferOwnership(newOwner);
    }

    function EthToUsd(uint256 arg) private returns (uint256){
        uint256 etherRate = uint(getLatestPrice());
        return arg*etherRate/100000000000000000;
    }
    function UsdToEth(uint256 arg) private returns (uint256){
        uint256 etherRate = uint(getLatestPrice());
        return (arg/etherRate)*1000000000000000000;
    }


    /** ---------------------------------- singnature ---------------------------------------------------*/
address public dumpAddress;

    function parseSignature(uint256 cdValue, uint256 ethValue, bytes memory signature) public returns(address){
        bytes32 hash = keccak256(abi.encodePacked(Strings.toString(ethValue), Strings.toString(cdValue)));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        dumpAddress = ECDSA.recover(message, signature);
        return dumpAddress;
    }

    function parseSignatureLoanPayment(uint256 payingCdramByEther, uint256 cdValue, uint256 ethValue, int isFullPayed, bytes memory signature) public returns(address){
        uint boolVal = 0;
        if(isFullPayed==1){
           boolVal = 1; 
        }
        bytes32 hash = keccak256(abi.encodePacked(Strings.toString(payingCdramByEther), Strings.toString(ethValue), Strings.toString(cdValue), Strings.toString(boolVal)));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        dumpAddress = ECDSA.recover(message, signature);
        return dumpAddress;
    }

    function loan(uint256 cdram, bytes memory signature) public payable returns(bool){
        uint256 pledge = msg.value;
        
        require (_admin == parseSignature(cdram, pledge, signature), "Loan transaction failed!");
        _transfer(owner(), msg.sender, cdram);
        return true;
    }


    function loanPayment(uint256 payingCdramByEther, uint256 cdram, uint256 eth, int isFullPayed, bytes memory signature) public returns(bool){
        _cryptoDramBalance = token.balanceOf(msg.sender);

        require (cdram <= _cryptoDramBalance, "Not enough crypto drams!");
        
        require (_admin == parseSignatureLoanPayment(payingCdramByEther, cdram, eth, isFullPayed, signature), "Loan pay transaction failed, signatura is not compatible!");
        _transfer(msg.sender, owner(), cdram);
        if(isFullPayed == 1)
        {
            address payable client = payable(msg.sender);
            (bool send, bytes memory data) = client.call{value: eth}("");
            require(send,"File to send!");
            return send;
        }
        
        return true;
    }

//usdt functions********************************************************

    // function setUsdtAddress(address usdtAddress) public onlyOwner{
    //     _usdtAddress = usdtAddress;
    // }

    // function dbgGetUsdtBlance(address addr) public returns(uint256){
    //     ERC20 usdt;
    //     usdt = ERC20(_usdtAddress);
    //     return usdt.balanceOf(addr);
    // }

    // function getUsdtBlance() public view returns(uint256){
    //     ERC20 usdt;
    //     usdt = ERC20(_usdtAddress);
    //     return usdt.balanceOf(msg.sender);
    // }

    // function usdtLoanWithEther(uint256 usdtAmount, bytes memory signature) public payable returns(bool){
    //     uint256 pledge = msg.value;
    //     ERC20 usdt;
    //     usdt = ERC20(_usdtAddress);
    //     require (_admin == parseSignature(usdtAmount, pledge, signature), "Loan transaction failed!");
    //     usdt.transfer(msg.sender, usdtAmount);
    //     return true;
    // }

    // function usdtLoanWithEtherPayment(uint256 usdtAmount, uint256 pledge, bytes memory signature) public returns(bool){
    //     ERC20 usdt;
    //     usdt = ERC20(_usdtAddress);
    //     require (_admin == parseSignature(usdtAmount, pledge, signature), "Loan transaction failed!");
    //     usdt.transferFrom(msg.sender, owner(), usdtAmount);
    //    // payable(msg.sender).transfer(usdtAmount);
    //     address payable client = payable(msg.sender);
    //     (bool send, bytes memory data) = client.call{value: pledge}("");
    //     require(send,"File to send!");

    //     return send;
    // }

    // function cDramLoanWithUsdt(uint256 cdram, uint256 pledge, bytes memory signature) public returns(bool){
       
    //     ERC20 usdt;
    //     usdt = ERC20(_usdtAddress);
    //     require (_admin == parseSignature(cdram, pledge, signature), "Loan transaction failed!");
    //     _transfer(owner(), msg.sender, cdram);
    //     //usdt.transferFrom(msg.sender, owner(), pledge);
    //     usdt.safeTransferFrom(msg.sender, owner(), pledge);
    //    // payable(msg.sender).transfer(pledge);
    //     return true;
    // }

    // function cDramLoanWithUsdtPayment(uint256 cdram, uint256 pledge, bytes memory signature) public returns(bool){
    //     ERC20 usdt;
    //     usdt = ERC20(_usdtAddress);
    //     require (_admin == parseSignature(cdram, pledge, signature), "Loan transaction failed!");
    //     usdt.safeTransferFrom(owner(), msg.sender, pledge);
    //    // payable(owner()).transfer(pledge);
    //     _transfer(msg.sender, owner(), cdram);

    //     return true;
    // }

}