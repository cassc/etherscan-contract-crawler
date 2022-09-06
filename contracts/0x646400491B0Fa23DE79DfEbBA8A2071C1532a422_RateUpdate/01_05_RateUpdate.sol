// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface CarbonCoin {
    function updateExchangeRate (uint rate) external;
}

contract RateUpdate is ERC20 {
    address owner;
    CarbonCoin public gcxToken;
    uint fee;
    
    constructor() ERC20("Green Carbon Coin", "GCX") {
        gcxToken = CarbonCoin(0x986A87E8ff8434EC111777A4D00FCae001c54f0D);
        owner = msg.sender;
        fee = 0.01 ether;
    }

    function updateRate (uint rate) external payable {
        require(rate > 0);
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
        gcxToken = CarbonCoin(contractAddress);
    }

    function updateFee (uint newFee) external {
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
}