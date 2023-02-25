// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUSDT.sol";

contract TokensTransfer {
    mapping(uint256 => bool) private record;
    address payable private beneficiary;

    address private _owner;

    event TransferSuccess(
        address indexed tokenAddr,
        address from,
        address to,
        uint256 OrderId,
        uint256 Amount
    );

    constructor(address payable reciver) {
        _owner = msg.sender;
        beneficiary = reciver;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    function Setnewreciver(address payable newreciver) public onlyOwner {
        beneficiary = newreciver;
    }

    function Tokenstransfer(
        address tokenAddr,
        uint256 orderid,
        uint256 amount
    ) external {
        require(amount > 0, "Token quantity error");
        require(!record[orderid], "OrderId has been used");
        require(tokenAddr != address(0), "Token error");
    if (tokenAddr == address(0xdAC17F958D2ee523a2206206994597C13D831ec7)) {
        IUSDT(tokenAddr).transferFrom(
            msg.sender,
            beneficiary,
            amount
        );
    } else {
        
        bool success = IERC20(tokenAddr).transferFrom(
            msg.sender,
            beneficiary,
            amount
        );
        require(success,"revert");
    }


        record[orderid] = true;
        emit TransferSuccess(
            tokenAddr,
            msg.sender,
            beneficiary,
            orderid,
            amount
        );
    }
}