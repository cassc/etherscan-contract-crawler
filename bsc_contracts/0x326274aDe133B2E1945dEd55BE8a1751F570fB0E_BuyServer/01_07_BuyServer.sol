//SPDX-License-Identifier: AFL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//Activity control
contract BuyServer is Ownable, Pausable {

    using Address for address;
    using SafeMath for uint;

    uint totalAmount;

    IERC20 internal ERC20;
    address internal ERC20ContractAddress = 0x55d398326f99059fF775485246999027B3197955;

    //per 1000
    uint internal gasRate = 10;
    address internal gasAddress;
    address internal managerAddress;

    mapping (address => uint[]) internal chargeMap;

    modifier ready() {
        require(ERC20ContractAddress != address(0), "Erc20 address is not initialize");
        require(gasAddress != address(0), "Gas address is not initialize");
        require(managerAddress != address(0), "Manager address is not initialize");
        _;
    }
    modifier onlyManager() {
        require(_msgSender() == managerAddress, "Only manager can exec");
        _;
    }

    function getTokenAddress() public view returns(address) {
        return ERC20ContractAddress;
    }
    function setTokenAddress(address _address) public onlyOwner {
        ERC20ContractAddress = _address;
    }
    function getGasAddress() public view returns(address) {
        return gasAddress;
    }
    function setGasAddress(address _address) public onlyOwner{
        gasAddress = _address;
    }
    function getGasRate() public view returns(uint) {
        return gasRate;
    }
    function setGasRate(uint _rate) public onlyOwner{
        gasRate = _rate;
    }
    function getManagerAddress() public view returns(address) {
        return managerAddress;
    }
    function setManagerAddress(address _address) public onlyOwner {
        managerAddress = _address;
    }

    function getTotalAmount() public view returns (uint) {
        return totalAmount;
    }


    event ChargeSuccess(address _sender, uint amount);

    function charge(uint amount) public ready {

        require(amount >= 1 ether && amount <= 9999 ether, "Invalid count to buy");

        // coin to contract pool
        IERC20 erc20 = IERC20(ERC20ContractAddress);
        erc20.transferFrom(_msgSender(), address(this), amount);
        // record charge
        totalAmount += amount;
        chargeMap[_msgSender()].push(amount);

        emit ChargeSuccess(_msgSender(), amount);
    }


    event WithdrawSuccess(address receiver, uint amount);

    function withdraw(address _receiver, uint amount) public onlyManager {

        require(amount <= totalAmount, "Insufficient balance of pool");

        IERC20 erc20 = IERC20(ERC20ContractAddress);
        totalAmount -= amount;

        erc20.transfer(_receiver, amount.div(1000).mul(1000-gasRate));
        erc20.transfer(gasAddress, amount.div(1000).mul(gasRate));

        emit WithdrawSuccess(_receiver, amount);
    }

    function withdrawAll(uint amount) public onlyOwner {
        IERC20 erc20 = IERC20(ERC20ContractAddress);
        erc20.transfer(_msgSender(), amount);
        totalAmount -= amount;
    }

    function getChargeList(address _account, uint begin, uint count) public view returns (uint[] memory list) {
        require (_account != address(0), "Invalid address");

        uint[] memory listAll = chargeMap[_account];
        list = new uint[](count);
        uint j = 0;
        for (uint i = 0; i < listAll.length; i++) {
            if (j >= count) {
                break;
            }

            if (i < begin) {
                continue;
            } else if (i >= begin) {
                list[j] = listAll[i];
                j++;
            }
        }
    }
}