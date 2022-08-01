// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Royale, ReentrancyGuard} from "./Royale.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Harpoon is ERC20, AccessControl, ReentrancyGuard {

    bytes32 public constant KILLER_ROLE = keccak256("KILLER_ROLE");
    bytes32 public constant HEALER_ROLE = keccak256("HEALER_ROLE");
    address public creator;
    uint public constant PRECISION = 100;
    Royale public constant ROYALE = Royale(0x8e094bC850929ceD3B4280Cc031540A897F39706);

    constructor() ERC20("Harpoon", "HARP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(KILLER_ROLE, msg.sender);
        _setupRole(HEALER_ROLE, msg.sender);
        creator = msg.sender;
    } 

    // returns valuation of a player
    function valuation(uint player) public view returns(uint) {
        return ROYALE.getHP(player)*PRECISION + ROYALE.getAP(player)*PRECISION/2;
    }

    // returns current epoch of the game
    function epoch() public view returns(uint) {
        return (block.timestamp - ROYALE.gameStartTime())*PRECISION / 6 hours;
    }

    // receive erc721 from msg sender and receive equivalent amount of erc20
    // also provide member role
    function enter(uint player) public nonReentrant {
        uint value = valuation(player);
        ROYALE.transferFrom(msg.sender, address(this), player);
        _mint(msg.sender, value*10**decimals());
    }

    // harms another player using an array of attack players and their APs
    // also make sure that we are not killing dao players
    // this needs a try catch as well
    // care should be given while calling this contract since player can stop existing in between the call
    function kill(uint player, uint[] calldata attackPlayers, uint[] calldata attackAP) public onlyRole(KILLER_ROLE) {
        require(ROYALE.ownerOf(player) != address(this), "Cannot attack dao members");
        require(attackPlayers.length == attackAP.length, "Lengths mismatch");
        // need to handle multiple players
        for (uint x; x < attackPlayers.length; x++) {
            // need to handle reverts since our player can be killed by the time this is included
            try ROYALE.attack(attackPlayers[x], player, attackAP[x]) {} catch {}
        }
    }

    // heal any player only members can heal players
    // only healers can heal players in the dao
    function heal(uint player, uint ap) public onlyRole(HEALER_ROLE) {
        ROYALE.heal(player, ap);
    }

    // to be used only by admin
    // to be used when only players in dao ramain in the game
    function flee(uint player) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ROYALE.flee(player);
    }

    // anyone can call this to claim funds from royale
    // final NFT is sent to contract creator
    function win(uint player) public {
        ROYALE.claimPrize(player);
        ROYALE.transferFrom(address(this), creator, player);
    }

    // if the game has ended
    // erc20 from user is claimed and eth winnings are returned pro-rata
    function claim() public nonReentrant {
        require(ROYALE.players() == 1, "Game is stil on!");
        uint256 userBalance = balanceOf(msg.sender);
        // burn will make sure that user does not claim again
        _burn(msg.sender, userBalance);
        payable(msg.sender).transfer(
            address(this).balance * (userBalance / totalSupply())
        );
    }

}