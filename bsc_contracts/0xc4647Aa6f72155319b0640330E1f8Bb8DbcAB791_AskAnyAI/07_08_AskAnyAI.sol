// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IFeeHandler.sol";

contract AskAnyAI is Context, Ownable, ERC20 {
    using Address for address;

    address public minter;
    IFeeHandler public feeHandler;
    uint256 public constant MAX_TRANSFER_FEE = 1500; // 15%

    event FeeHandlerUpdated(address indexed oldFeeHandler, address indexed newFeeHandler);

    constructor(address _owner) ERC20("AskAny.AI", "ASK") {
        _mint(_owner, 300_000_000e18);
        minter = _owner;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == minter, "Only minter");
        _mint(account, amount);
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setFeeHandler(IFeeHandler _feeHandler) external onlyOwner {
        emit FeeHandlerUpdated(address(feeHandler), address(_feeHandler));
        feeHandler = _feeHandler;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 amountToTransfer = amount;

        if (address(feeHandler).isContract())
            try feeHandler.getFeeInfo(sender, recipient, amount) returns (uint256 fee) {
                if (fee > 0 && fee <= MAX_TRANSFER_FEE) {
                    fee = (amount * fee) / 10000;
                    amountToTransfer -= fee;
                    super._transfer(sender, address(feeHandler), fee);
                    try feeHandler.onFeeReceived(sender, recipient, amount, fee) {} catch {}
                }
            } catch {}
        super._transfer(sender, recipient, amountToTransfer);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}