// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../Errors.sol";

contract TestnetToken is Ownable, ERC20 {
    uint8 private _decimals;
    uint256 public mintCoolDownPeriod;
    uint256 public mintAmountPerCoolDownPeriod;
    mapping(address => uint256) public lastMintTime;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 initialMint,
        uint256 _mintCoolDownPeriod,
        uint256 _mintAmountPerCoolDownPeriod
    ) ERC20(_name, _symbol) Ownable() {
        _decimals = __decimals;
        if (_mintCoolDownPeriod == 0 || _mintAmountPerCoolDownPeriod == 0) {
            revert Errors.InvalidAmount();
        }
        mintCoolDownPeriod = _mintCoolDownPeriod;
        mintAmountPerCoolDownPeriod = _mintAmountPerCoolDownPeriod;
        _mint(msg.sender, initialMint);
    }

    function ownerMint(address recipient, uint256 amount) external onlyOwner {
        if (recipient == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (amount == 0) {
            revert Errors.InvalidMintAmount();
        }
        _mint(recipient, amount);
    }

    function setMintParams(
        uint256 _mintCoolDownPeriod,
        uint256 _mintAmountPerCoolDownPeriod
    ) external onlyOwner {
        if (mintCoolDownPeriod == 0 || mintAmountPerCoolDownPeriod == 0) {
            revert Errors.InvalidAmount();
        }
        mintCoolDownPeriod = _mintCoolDownPeriod;
        mintAmountPerCoolDownPeriod = _mintAmountPerCoolDownPeriod;
    }

    function testnetMint() public virtual {
        uint256 _lastMintTime = lastMintTime[msg.sender];
        if (
            _lastMintTime != 0 &&
            block.timestamp < _lastMintTime + mintCoolDownPeriod
        ) {
            revert Errors.InvalidActionForCurrentStatus();
        }
        lastMintTime[msg.sender] = block.timestamp;
        _mint(msg.sender, mintAmountPerCoolDownPeriod);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}