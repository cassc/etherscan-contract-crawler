// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/***************************
 *      Aura Raffle        *
 *  Community prize vault  *
 *    By: Aura Exchange    *
 **************************/

 import "@thirdweb-dev/contracts/extension/PlatformFee.sol";

contract AuraRaffle {
    address public owner;
    address public deployer;
    address payable[] public players;
    uint public AuraRaffleId;
    mapping (uint => address payable) public AuraRaffleHistory;

    constructor() {
        deployer = msg.sender;
        owner = msg.sender;
        AuraRaffleId = 1;
    }

    function getWinnerByAuraRaffle(uint auraRaffle) public view returns (address payable) {
        return AuraRaffleHistory[auraRaffle];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enter() public payable {
        require(msg.value > 25 ether);

        // address of player entering AuraRaffle
        players.push(payable(msg.sender));
    }

    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

        function _canSetPlatformFeeInfo() internal virtual returns (bool) {
        return msg.sender == deployer;
    }

    function pickWinner() public onlyowner {
        uint index = getRandomNumber() % players.length;
        players[index].transfer(address(this).balance);

        AuraRaffleHistory[AuraRaffleId] = players[index];
        AuraRaffleId++;
        

        // reset the state of the contract
        players = new address payable[](0);
    }

    modifier onlyowner() {
      require(msg.sender == owner);
      _;
    }
}