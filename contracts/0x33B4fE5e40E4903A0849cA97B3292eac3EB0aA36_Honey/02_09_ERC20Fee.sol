// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { ERC20 } from "./ERC20.sol";
import { Ownable } from "./helpers/Ownable.sol";
import { IFeeManager } from "./interfaces/IFeeManager.sol";

contract ERC20Fee is ERC20, Ownable {
    /*///////////////////////////////////////////////////////////////
                            FEE-ON-TRANSFER STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private constant MAX_FEE = 1000;
    uint256 private constant BPS_MULTIPLIER = 10000;

    mapping(address => bool) public isExcludedFee;
    mapping(address => bool) public isForcedFee;

    uint256 private _feeSell;
    uint256 private _feeBuy;
    uint256 private _feeTransfer;

    address public feeRecipient;
    bool public isFeeManager;

    /*///////////////////////////////////////////////////////////////
                            FEE-ON-TRANSFER EVENTS
    //////////////////////////////////////////////////////////////*/

    event Fees(uint256 feeSell, uint256 feeBuy, uint256 feeTransfer);
    event ExcludeFee(address account, bool excluded);
    event ForcedFee(address account, bool forced);
    event FeeRecipientChanged(address feeRecipient, bool isFeeManager);

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    /*///////////////////////////////////////////////////////////////
                            FEE-ON-TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            balanceOf[sender] = senderBalance - amount;
        }

        uint256 fee = feeRecipient != address(0) ? _calcFee(sender, recipient, amount) : 0;
        if (fee > 0) {
            balanceOf[recipient] += (amount - fee);
            balanceOf[feeRecipient] += fee;
            emit Transfer(sender, recipient, (amount - fee));
            emit Transfer(sender, feeRecipient, fee);

            if (isFeeManager && IFeeManager(feeRecipient).canSyncFee(sender, recipient)) {
                IFeeManager(feeRecipient).syncFee();
            }
        } else {
            balanceOf[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }

    function setExcludedFee(address account, bool excluded) external onlyOwner {
        isExcludedFee[account] = excluded;
        emit ExcludeFee(account, excluded);
    }

    function setForcedFee(address account, bool forced) external onlyOwner {
        isForcedFee[account] = forced;
        emit ForcedFee(account, forced);
    }

    function getFees()
        external
        view
        returns (
            uint256 feeSell,
            uint256 feeBuy,
            uint256 feeTransfer
        )
    {
        return (_feeSell, _feeBuy, _feeTransfer);
    }

    function setFees(
        uint256 feeSell,
        uint256 feeBuy,
        uint256 feeTransfer
    ) public onlyOwner {
        require(feeSell <= MAX_FEE && feeBuy <= MAX_FEE && feeTransfer <= MAX_FEE, "Fee is outside of range 0-1000");
        _feeSell = feeSell;
        _feeBuy = feeBuy;
        _feeTransfer = feeTransfer;
        emit Fees(feeSell, feeBuy, feeTransfer);
    }

    function changeFeeRecipient(address _feeRecipient, bool _isFeeManager) external onlyOwner {
        feeRecipient = _feeRecipient;
        isFeeManager = _isFeeManager;
        emit FeeRecipientChanged(feeRecipient, isFeeManager);
    }

    function _calcFee(
        address from,
        address to,
        uint256 amount
    ) private view returns (uint256 fee) {
        if (from != address(0) && to != address(0) && !isExcludedFee[from] && !isExcludedFee[to]) {
            if (isForcedFee[to]) {
                fee = _calcBPS(amount, _feeSell);
            } else if (isForcedFee[from]) {
                fee = _calcBPS(amount, _feeBuy);
            } else {
                fee = _calcBPS(amount, _feeTransfer);
            }
        }
    }

    function _calcBPS(uint256 amount, uint256 feeBPS) private pure returns (uint256) {
        return (amount * feeBPS) / BPS_MULTIPLIER;
    }
}