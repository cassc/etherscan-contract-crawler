pragma solidity ^0.8.15;

import "./IERC20.sol";

interface Factory
{
    function createToken(address ownerAddress, string memory name, string memory symbol, uint8 decimals, uint tSupply, uint16 taxYield, uint16 taxMar, uint16 taxLiq, address taxesAddress) external;
    function getTokenAddress() external view returns(address);
}

contract TokenGenerator
{
    Factory creator;
    IERC20 token;
    address public factoryC;
    address public contractAddress;
    address public ownerAddress;
    address payable receiverAddress;
    uint public generateCost;
    uint public bPayGenerateCost;
    uint public bPayDecimals;
    address public bPayContractAddress;
    event TransferOwnership(address previousOwner, address newOwner);
    constructor(address factoryAddress) public
    {
        factoryC=factoryAddress;
        creator=Factory(factoryAddress);
        contractAddress=address(this);
        ownerAddress=msg.sender;
        receiverAddress= payable(0x80be0342c751A36a411Bf68eC9e3F34e3D2979e8);
        generateCost=150;
        bPayGenerateCost=1600000;
        bPayDecimals=18;
        bPayContractAddress=0xB02380DaB8C0FC599c8C2A98715EC0B1aAC43771;
        token=IERC20(bPayContractAddress);
    }

    modifier onlyOwner
    {
        require(msg.sender==ownerAddress,"Caller is not authorized");
        _;
    }

    function generateToken_BNB(string memory name, string memory symbol, uint8 decimals, uint tSupply, uint16 taxYield, uint16 taxMar, uint16 taxLiq, address taxesAddress) external payable
    {
        uint receiveValue=msg.value;
        uint valueToWei=(receiveValue/10**15);
        require(valueToWei==generateCost,"Insufficient or Wrong amount sent in");
        receiverAddress.transfer(msg.value);
        creator.createToken(msg.sender, name, symbol, decimals, tSupply, taxYield, taxMar, taxLiq, taxesAddress);
    }

    function generateToken_BPay(string memory name, string memory symbol, uint8 decimals, uint tSupply, uint16 taxYield, uint16 taxMar, uint16 taxLiq, address taxesAddress) external
    {
        //On Approval
        require(token.balanceOf(msg.sender)>=bPayGenerateCost,"Insufficient BPay balance");
        token.transferFrom(msg.sender, receiverAddress,bPayGenerateCost*10**bPayDecimals);
        creator.createToken(msg.sender, name, symbol, decimals, tSupply, taxYield, taxMar, taxLiq, taxesAddress);
    }

    function setBNBRate(uint generatingCost) public onlyOwner
    {
        generateCost=generatingCost;
    }

    function setBPayCost(uint tokenFee) public onlyOwner
    {
        bPayGenerateCost=tokenFee;
    }

    function getBalance() public view returns(uint)
    {
        return(token.balanceOf(msg.sender));
    }

    function getGeneratedAddress() public view returns(address)
    {
        return creator.getTokenAddress();
    }

    function transferOwnership(address newOwnerAddress) public onlyOwner
    {
        address curOwner=ownerAddress;
        ownerAddress=newOwnerAddress;
        emit TransferOwnership(curOwner,ownerAddress);
    }
}