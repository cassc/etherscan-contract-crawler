/* SPDX-License-Identifier: MIT
                                       __  .__     
  ________ _______    ______     _____/  |_|  |__  
 / ____/  |  \__  \  / ____/   _/ __ \   __\  |  \ 
< <_|  |  |  // __ \< <_|  |   \  ___/|  | |   Y  \
 \__   |____/(____  /\__   | /\ \___  >__| |___|  /
    |__|          \/    |__| \/     \/          \/ 
*/

pragma solidity 0.8.15;

import {IZooOfNeuralAutomata} from "../interfaces/IZooOfNeuralAutomata.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";

contract Quaqs is Owned {
    uint256 constant maxSupply = 1000;
    uint256 constant price = 0.0314 ether;

    address public zona;
    uint256 public startTime;

    uint256 public sold;
    bool private claimed;

    constructor(
        address _owner,
        address _zona, 
        uint256 _startTime
    ) Owned(_owner) {
        zona = _zona;
        startTime = _startTime;
    }

    function mint(uint256 amount) external payable {
        require(startTime <= block.timestamp);
        require(msg.value >= price * amount);
        require(sold + amount <= maxSupply);

        sold += amount;

        IZooOfNeuralAutomata(zona).mint(msg.sender, 1, amount);
    }

    function reserved() external onlyOwner {
        require(!claimed);
        claimed = true;
        IZooOfNeuralAutomata(zona).mint(owner, 1, 24);
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}