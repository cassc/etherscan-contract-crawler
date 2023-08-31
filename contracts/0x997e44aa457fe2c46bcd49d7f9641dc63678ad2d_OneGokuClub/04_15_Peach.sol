// contracts/Cheeth.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Peach is ERC20, Ownable {

    uint256 public constant TREASURY_SUPPLY = 10000000 * 1e18;

    address public clubAddress;

    //Mapping of draco to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    //Mapping of draco to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    modifier onlyClubAddress() {
        require(msg.sender == clubAddress, "Not club address");
        _;
    }
    
    constructor() ERC20("Peach", "PEACH") {
        _mint(msg.sender, TREASURY_SUPPLY);
    }

    function setClubAddress(address _clubAddress) public onlyOwner {
        clubAddress = _clubAddress;
    }

    function mintToken(address _claimer, uint256 _amount) public onlyClubAddress {
        _mint(_claimer, _amount);
    }
}