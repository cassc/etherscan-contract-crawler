// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LOTTO is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private constant PERCENTAGE_BASE = 100;
    uint256 private constant ROYALTY_PERCENTAGE = 5;
    address private royaltyReceiver;

    mapping(address => bool) public feeExemptForSender;
    mapping(address => bool) public feeExemptForReceiver;

    event RoyaltyReceiverChanged(address indexed newRoyaltyReceiver);
    event FeeExemptForSenderChanged(address indexed _address, bool _exempt);
    event FeeExemptForReceiverChanged(address indexed _address, bool _exempt);

    constructor() ERC20("LOTTO", "LOTTO") {
        uint256 initialSupply = 4000000000 * 10 ** 18;
        _mint(msg.sender, initialSupply);
    }

    function setFeeExemptForSender(
        address _address,
        bool _exempt
    ) public onlyOwner {
        feeExemptForSender[_address] = _exempt;
        emit FeeExemptForSenderChanged(_address, _exempt);
    }

    function setFeeExemptForReceiver(
        address _address,
        bool _exempt
    ) public onlyOwner {
        feeExemptForReceiver[_address] = _exempt;
        emit FeeExemptForReceiverChanged(_address, _exempt);
    }

    function changeRoyaltyReceiver(
        address newRoyaltyReceiver
    ) public onlyOwner {
        require(
            newRoyaltyReceiver != address(0),
            "RoyaltyToken: royaltyReceiver cannot be the zero address"
        );
        royaltyReceiver = newRoyaltyReceiver;
        emit RoyaltyReceiverChanged(newRoyaltyReceiver);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 royaltyAmount = 0;
        uint256 netAmount = amount;

        if (!feeExemptForSender[sender] && !feeExemptForReceiver[recipient]) {
            royaltyAmount = amount.mul(ROYALTY_PERCENTAGE).div(PERCENTAGE_BASE);
            netAmount = amount.sub(royaltyAmount);
            super._transfer(sender, royaltyReceiver, royaltyAmount);
        }
        super._transfer(sender, recipient, netAmount);
    }
}