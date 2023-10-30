// SPDX-License-Identifier: MIT

/*
 _____ _ _       _     _     _____     _
|  ___| (_) __ _| |__ | |_  |_   _|__ | | _____ _ __
| |_  | | |/ _` | '_ \| __|   | |/ _ \| |/ / _ \ '_ \
|  _| | | | (_| | | | | |_    | | (_) |   <  __/ | | |
|_|   |_|_|\__, |_| |_|\__|   |_|\___/|_|\_\___|_| |_|
           |___/

*/

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract FlightToken is ERC20, Ownable {
    struct TicketData {
        bytes32 ticketHash;
        uint256 amount;
    }

    struct UserData {
        TicketData[] ticketsData;
        uint256 miles;
    }

    mapping(bytes32 => address) public tickets;
    mapping(address => UserData) public users;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _amount
    ) ERC20(_name, _symbol) {
        _mint(_msgSender(), _amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        _burn(_msgSender(), _amount);
    }

    function mintFromTicket(
        address _address,
        uint256 _amount,
        string memory _ticketHash
    ) external onlyOwner {
        bytes32 encryptedBytes = keccak256(abi.encodePacked(_ticketHash));

        require(
            tickets[encryptedBytes] == address(0),
            "this ticket is already used"
        );

        tickets[encryptedBytes] = _address;

        users[_address].miles += _amount;
        users[_address].ticketsData.push(TicketData(encryptedBytes, _amount));

        _mint(_address, _amount);
    }

    function getTicketsData(address _address)
    public
    view
    returns (TicketData[] memory)
    {
        return users[_address].ticketsData;
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}