// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC677.sol";
import "./ERC777Permit.sol";
import "./utils/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract XRUNE is ERC777, ERC777Permit, ERC677, Ownable {
    uint public constant ERA_SECONDS = 86400;
    uint public constant MAX_SUPPLY = 1000000000 ether;
    uint public nextEra = 1622433600; // 2021-05-31
    uint public curve = 1024;
    bool public emitting = false;
    address public reserve = address(0);

    event NewEra(uint256 time, uint256 emission);

    constructor(address owner) public ERC777("XRUNE Token", "XRUNE", new address[](0)) ERC777Permit("XRUNE") Ownable(owner) {
        _mint(owner, MAX_SUPPLY / 2, "", "");
    }

    function setCurve(uint _curve) public onlyOwner {
        require(_curve > 0 && _curve < 10000, "curve needs to be between 0 and 10000");
        curve = _curve;
    }

    function toggleEmitting() public onlyOwner {
        emitting = !emitting;
    }

    function setReserve(address _reserve) public onlyOwner {
        reserve = _reserve;
    }

    function setNextEra(uint next) public onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(next > nextEra && next > block.timestamp, "next era needs to be in the future");
        nextEra = next;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint amount) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, amount);
        require(to != address(this), "!self");
        dailyEmit();
    }

    function dailyEmit() public {
        // solhint-disable-next-line not-rely-on-time
        if ((block.timestamp >= nextEra) && emitting && reserve != address(0)) {
            uint _emission = dailyEmission();
            emit NewEra(nextEra, _emission);
            nextEra = nextEra + ERA_SECONDS;
            _mint(reserve, _emission, "", "");
        }
    }

    function dailyEmission() public view returns (uint) {
        return (MAX_SUPPLY - totalSupply()) / curve;
    }
}