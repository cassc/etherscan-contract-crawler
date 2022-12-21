// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title PokumiWar
 * @author Sebastien Gazeau
 * @dev Manage Pokmi's Pokumi War game
 */
contract PokumiWar is ERC1155, AccessControl, ERC1155Receiver, ERC1155Burnable, ERC1155Pausable {
    using Counters for Counters.Counter;
    struct InitialDataGame {
        string idPokumi;
        uint warrior;
    }
    struct InitialSeason {
        address player;
        string idPokumi;
    }
    struct Season {
        address winner;
        uint8 nbrOfDay;
        uint nbrOfWarrior;
    }

	Counters.Counter private seasonIds;
    uint private randNonce;
    bool public warIsStarted;
    address[] public players;
    mapping(string => uint) private pokumiArmy;
    mapping(uint => Season) public seasons;

    constructor() ERC1155("PokumiWarrrior"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        
    }

    event ReceivedERC1155(address operator, address from, uint256 id, uint256 values, bytes data);
    event ReceivedBatchERC1155(address operator, address from, uint256[] ids, uint256[] values, bytes data);
    event WinnerSeason(uint _seasonId,address _winner);
    event WarStarting(Season _season, uint _startDayWar);
    event DayConflit(uint _seasonId, uint _nbrOfDefeatedWarrior, uint _warDay);
    event WarriorEngaged(address _player, uint _season, uint _nbrOfWarriorEngader, uint _engagementDate);
    event SeasonStarted(uint _seasonStartDate);
    event PlayersClean(uint _playersCleanDate);

    function initializeData(InitialDataGame[] memory pokumi) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(pokumi.length > 0, "intialize data empty");
        for(uint i = 0; i <= pokumi.length -1; i++){
            pokumiArmy[pokumi[i].idPokumi] = pokumi[i].warrior;
        }
    }
    /**
     * @dev start a new war season
     * @param season a table of players eligible for this season with the number of warriors assigned to them
     */
    function startingSeason(InitialSeason[] memory season) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(season.length > 0, "intialize data empty");
        warIsStarted = false;
        seasonIds.increment();
        for(uint i = 0; i <= season.length -1; i++){
            _mint(season[i].player, 1, pokumiArmy[season[i].idPokumi], "");
        }

        emit SeasonStarted(block.timestamp);
    }
    /**
     * @dev allows a player to hire a certain number of warriors for the current season
     */
    function engageInSeason(uint warrior) external {
        require(!warIsStarted, "the fights have already started");
        require(warrior > 0, "send more warrior");
        require(balanceOf(msg.sender, 1) >= warrior, "not enough warrior");

        safeTransferFrom(msg.sender, address(this), 1, warrior, "");

        for(uint i = 0; i < warrior; i++){
            players.push(msg.sender);
        }

        emit WarriorEngaged(msg.sender, seasonIds.current(), warrior,  block.timestamp);
    }

    /**
     * @dev starts the combat phase of the war
     * @return season_ current season information
     */
    function startingWar() external onlyRole(DEFAULT_ADMIN_ROLE) returns(Season memory season_) {
        warIsStarted = true;
        seasons[seasonIds.current()].nbrOfDay = durationWar(players.length);
        seasons[seasonIds.current()].nbrOfWarrior = players.length;
        season_ = seasons[seasonIds.current()];

        emit WarStarting(seasons[seasonIds.current()], block.timestamp);
    }

    /**
     * @dev manages every day of the war
     * @return players_ the warriors still present in the war
     */
    function newDayConflict() external onlyRole(DEFAULT_ADMIN_ROLE) returns (address[] memory players_) {
        require(players.length > 3, "not enough warrior");
        uint futurLength = (players.length / 2) + ((players.length % 2 == 0) ? 0 : 1);
        while(players.length > futurLength){
            players[randMod(players.length-1)] = players[players.length - 1];
            players.pop();
        }
        emit DayConflit(seasonIds.current(), futurLength,  block.timestamp);
        players_ = players;
    }
    /**
     * @dev Selecting the winner of the war
     */
    function lastDayFight() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(players.length == 3 || players.length == 2, "there are too many warriors left");
        seasons[seasonIds.current()].winner = players[randMod(players.length-1)];
        delete players;

        emit WinnerSeason(seasonIds.current(),seasons[seasonIds.current()].winner);
    }
    /**
     * @dev Selecting the winner of the war
     */
    function cleanPlayers() external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete players;

        emit PlayersClean(block.timestamp);
    }
    /**
     * @dev Get the number of warrior for a Pokumi
     * @return players_ list of all participants
     */
    function getAllParticipants() view external returns (address[] memory players_){
        return players;
    }

    /**
     * @dev Get the number of warrior for a Pokumi
     * @param _id The id of the Pokumi
     * @return oneArmy_ number of warrior the requested Pokumi
     */
    function getArmy(string memory _id) view external returns (uint oneArmy_){
        oneArmy_ = pokumiArmy[_id];
    }
    /**
     * @dev Getter for the number of warriors in the current season
     * @return nbrWarrior_ the number of warrior
     */
    function getNbrWarrior() external view returns(uint nbrWarrior_){
        nbrWarrior_ = players.length;
    }
    /**
     * @dev Getter for the current season
     * @return currentSeason_ the number of the season
     */
    function getCurrentSeason() external view returns (uint currentSeason_) {
        return seasonIds.current();
    }
    /**
     * @dev calculate the number of days that a war will last
     * @param x the number of warriors participating in the war
     * @return r the number of days of the war
     */
    function durationWar(uint x) internal pure returns (uint8 r) {
        require (x > 0);
        if (x >= 2**128) { x >>= 128; r += 128; }
        if (x >= 2**64) { x >>= 64; r += 64; }
        if (x >= 2**32) { x >>= 32; r += 32; }
        if (x >= 2**16) { x >>= 16; r += 16; }
        if (x >= 2**8) { x >>= 8; r += 8; }
        if (x >= 2**4) { x >>= 4; r += 4; }
        if (x >= 2**2) { x >>= 2; r += 2; }
        if (x >= 2**1) { x >>= 1; r += 1; }
    }    

    /**
     * @dev Generates a random number
     * @param _modulus number to get max range
     * @return random_ a random number
     * 
     */
    function randMod(uint _modulus) internal returns(uint random_) {
        randNonce++; 
        random_ = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override returns (bytes4){
        emit ReceivedERC1155(operator, from, id, value, data);
        return IERC1155Receiver.onERC1155Received.selector;
    } 

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override returns (bytes4){
        emit ReceivedBatchERC1155(operator, from, ids, values, data);
        return IERC1155Receiver.onERC1155Received.selector;
    }  
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155,ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}