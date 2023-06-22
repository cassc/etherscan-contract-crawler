// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";
import { ABDKMath64x64 as Math } from "./ABDKMath64x64.sol";

contract Momentum is ERC20, Ownable {
    int128 shortMomentum;
    int128 longMomentum;
    int128 SMweight;
    int128 LMweightEx;
    int128 LMweightCo;

    mapping (address => mapping (address => uint256)) _allowances;

    bool isBurning = false;

    constructor(
        uint256 initialSupply, 
        uint256 _shortMomentumWeight,
        uint256 _LMweightEx,
        uint256 _LMweightCo,
        uint256 factor,
        uint256 _shortMomentum, 
        uint256 _longMomentum
    ) public ERC20("Momentum", "XMM") {
        _setupDecimals(10);
        _mint(_msgSender(), initialSupply);
        SMweight = Math.divu(_shortMomentumWeight, factor);
        LMweightEx = Math.divu(_LMweightEx, factor);
        LMweightCo = Math.divu(_LMweightCo, factor);
        shortMomentum = Math.fromUInt(_shortMomentum);
        longMomentum = Math.fromUInt(_longMomentum);
    }

    function getShortMomentum() external view returns (uint256) {
        return Math.mulu(shortMomentum, 1);
    }

    function getLongMomentum() external view returns (uint256) {
        return Math.mulu(longMomentum, 1);
    }

    function getMomentumAndSupply() external view returns (uint256, uint256, uint256) {
        uint256 SM = Math.mulu(shortMomentum, 1);
        uint256 LM = Math.mulu(longMomentum, 1);
        return (SM, LM, totalSupply());
    }

    function getNewMomentum(int128 amount, int128 SMcopy, int128 LMcopy) internal view returns (int128, int128) {
        int128 LMweight = (amount < SMcopy) ? LMweightCo : LMweightEx;
        int128 LMnew = Math.add(LMcopy, Math.div(Math.sub(amount, LMcopy), LMweight));
        int128 SMnew = Math.add(SMcopy, Math.div(Math.sub(amount, SMcopy), SMweight));
        return (LMnew, SMnew);
    }

    function getRangeData(int128 LMcopy, int128 SMcopy, int128 LMnew, int128 SMnew) internal pure returns (int128, int128) {
        int128 range = Math.abs(Math.sub(LMcopy, SMcopy));
        int128 newRange = Math.abs(Math.sub(LMnew, SMnew));
        int128 rangeDelta = Math.sub(newRange, range);
        return (rangeDelta, newRange);
    }

    function getDestabilizingTransferFee(int128 amount, int128 newRange, int128 newLongMomentum) internal pure returns (int128) {
        // If newRange is within 2% of newLongMomentum, apply ~0.75% fee 
        // to avoid potential overflow calculations and negative log values
        if (newRange <= Math.div(newLongMomentum, Math.fromUInt(50))) {
            return Math.mul(amount, Math.div(Math.fromUInt(1), Math.fromUInt(133)));
        } else {
            int128 proportion = Math.div(newRange, newLongMomentum);
            int128 rate = Math.add(Math.fromUInt(1), Math.ln(Math.mul(proportion, Math.fromUInt(50))));
            return Math.mul(amount, Math.div(rate, Math.fromUInt(133)));
        }
    }

    function getTransferFee(uint256 amount256, int128 SMcopy, int128 LMcopy) internal returns (uint256) {
        int128 amount = Math.fromUInt(amount256);

        // Guard against flood of small transfers manipulating momentum values
        // If transfer size is less than ~0.3% of lower momentum value, charge 5% fee and skip momentum update
        if (SMcopy <= LMcopy) {
            if (amount < Math.div(SMcopy, Math.fromUInt(333))) {
                return Math.mulu(Math.div(amount, Math.fromUInt(20)), 1);
            }
        } else {
            if (amount < Math.div(LMcopy, Math.fromUInt(333))) {
                return Math.mulu(Math.div(amount, Math.fromUInt(20)), 1);
            }
        }
        
        (int128 newLongMomentum, int128 newShortMomentum) = getNewMomentum(amount, SMcopy, LMcopy);
        (int128 rangeDelta, int128 newRange) = getRangeData(LMcopy, SMcopy, newLongMomentum, newShortMomentum);

        int128 transferFee;

        if (rangeDelta < Math.fromUInt(0)) {
            transferFee = Math.div(amount, Math.fromUInt(133)); // stabilizing transfer ~0.75% fee
        } else {
            transferFee = getDestabilizingTransferFee(amount, newRange, newLongMomentum);
        }

        longMomentum = newLongMomentum;
        shortMomentum = newShortMomentum;

        return Math.mulu(transferFee, 1);
    }

    function startBurning() public onlyOwner {
        isBurning = true;
        renounceOwnership();
    }

    function burnAndTransfer(address sender, address recipient, uint256 amount256) internal {
        if (isBurning) {
            uint256 transferFee = getTransferFee(amount256, shortMomentum, longMomentum);
            uint256 adjustedAmount = amount256.sub(transferFee);
            _burn(sender, transferFee);
            _transfer(sender, recipient, adjustedAmount);
        } else {
            _transfer(sender, recipient, amount256);
        }
    }

    function transfer(address recipient, uint256 amount256) public override returns (bool) {
        burnAndTransfer(_msgSender(), recipient, amount256);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount256) public override returns (bool) {
        burnAndTransfer(sender, recipient, amount256);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount256, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
