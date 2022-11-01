// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ITOPIA.sol";

contract Ransom is Ownable, ReentrancyGuard {

    ITopia private TopiaInterface = ITopia(0x41473032b82a4205DDDe155CC7ED210B000b014D);
    address public TOPIA = 0x41473032b82a4205DDDe155CC7ED210B000b014D;

    uint256 public totalRansomPaid;
    mapping(address => uint256) public ransomPaid;
    address[] public Payees;

    event RansomPaid (address indexed payee, uint256 amount);

    function setTopia(address _topia) external onlyOwner {
        TopiaInterface = ITopia(_topia);
        TOPIA = _topia;
    }

    function payRansom(uint256 _amount) external nonReentrant {
        
        if (ransomPaid[msg.sender] == 0) { // if user hasn't burned any topia yet
            Payees.push(msg.sender);
        }

        ransomPaid[msg.sender] += _amount;
        totalRansomPaid += _amount;

        TopiaInterface.burnFrom(msg.sender, _amount);
        emit RansomPaid(msg.sender, _amount);
    }

    function viewRansomLedger() external view returns (address[] memory addresses, uint256[] memory payments) {
        uint256 length = Payees.length;
        addresses = new address[](length);
        payments = new uint256[](length);

        for (uint i = 0; i < length;) {
            addresses[i] = Payees[i];
            payments[i] = ransomPaid[Payees[i]];
            unchecked { i++; }
        }

        return (addresses, payments);
    }

    function burnBalance() external onlyOwner {
        uint256 bal = IERC20(TOPIA).balanceOf(address(this));
        TopiaInterface.burnFrom(address(this), bal);
    }
}