// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface CarbonCoinToken {
    function updateExchangeRate (uint rate) external;
}

contract RateUpdate is ERC20  {
    address public owner;
    address public admin;
    CarbonCoinToken public gcxToken;
    uint fee;
    
    constructor(address gcxTokenAddress) ERC20("Green Carbon Contract", "GCXCont") {
        gcxToken = CarbonCoinToken(gcxTokenAddress);
        owner = msg.sender;
        admin = 0x3a8929C8b516939Fe3E958bB1E34Cdea391321C8;
        fee = 0.01 ether;
    }

    function updateRate (uint rate) external payable {
        require(rate > 0);
        require(msg.sender == admin);
        require(msg.value == fee, 'Insufficient to cover fees');
        payable(owner).transfer(fee);
        gcxToken.updateExchangeRate(rate);
    }

    function updateOwner (address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function updateContract (address contractAddress) external {
        require(msg.sender == owner);
        gcxToken = CarbonCoinToken(contractAddress);
    }

    function updateFee (uint newFee) external {
        require(msg.sender == owner);
        require(newFee >= 0 );
        fee = newFee;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getContract() public view returns (address) {
        return address(gcxToken);
    }

    function getFee() public view returns (uint) {
        return fee;
    }
    
    function updateAdmin (address newAdmin) external {
        require(msg.sender == owner);
        admin = newAdmin;
    }
    
    function getAdmin() public view returns (address) {
        return admin;
    }
}