// SPDX-License-Identifier: MIT
/*

  _____   _____ _____ ___   _   ___ ___ ____
 |   \ \ / / __|_   _/ _ \ /_\ | _ \ __|_  /
 | |) \ V /\__ \ | || (_) / _ \|  _/ _| / /
 |___/ |_| |___/ |_| \___/_/ \_\_| |___/___|

*/

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IScrapToken.sol";

contract ScrapToken is ERC20("Scrap", "SCRAP"), Ownable, IScrapToken, Pausable {
	event ClaimedScrap(address indexed _account, uint256 _reward);

    uint256 constant public DAILY_RATE = 100 ether;
    uint256 constant public DAILY_LEGENDARY_BONUS = 300 ether;
    // December 31, 2030 3:59:59 PM GMT-08:00
    uint256 constant public LAST_EPOCH = 1924991999;
    uint256 constant public LEGENDARY_SUPPLY = 10;

    IERC721 public dystoApez;

	mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;
    mapping(address => uint256) public legendaryOwned;

    constructor(address _dystoApez) {
        require(_dystoApez != address(0), "ADDRESS_ZERO");
        dystoApez = IERC721(_dystoApez);
    }

    function updateReward(address _from, address _to, uint256 _tokenId) external override {
        require(_from == address(0) || dystoApez.ownerOf(_tokenId) == _from, "NOT_OWNER_OF_APE");
        require(msg.sender == address(dystoApez), "ONLY_DYSTOAPEZ");

        if (_from != address(0)) {
            if (lastUpdate[_from] > 0 && lastUpdate[_from] < LAST_EPOCH)
                rewards[_from] += _calculateRewards(_from);

            lastUpdate[_from] = block.timestamp;
        }

        if (_to != address(0)) {
            if (lastUpdate[_to] > 0 && lastUpdate[_to] < LAST_EPOCH)
                rewards[_to] += _calculateRewards(_to);

            lastUpdate[_to] = block.timestamp;
        }

        if (_tokenId <= LEGENDARY_SUPPLY && block.timestamp < LAST_EPOCH) {
            if (_from != address(0))
                legendaryOwned[_from] -= 1;
            legendaryOwned[_to] += 1;
        }
    }

    function getClaimableReward(address _account) external view override returns(uint256) {
        return rewards[_account] + _calculateRewards(_account);
    }

    function claimReward() external override {
        require(lastUpdate[msg.sender] < LAST_EPOCH, "PAST_LAST_EPOCH");
        uint256 claimableReward = rewards[msg.sender] + _calculateRewards(msg.sender);
        require(claimableReward > 0, "NOTHING_TO_CLAIM");
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
        _mint(msg.sender, claimableReward);
        emit ClaimedScrap(msg.sender, claimableReward);
    }

    function _calculateRewards(address _account) internal view returns(uint256) {
        uint256 claimableEpoch = Math.min(block.timestamp, LAST_EPOCH);
        uint256 delta = claimableEpoch - lastUpdate[_account];
        if (delta > 0) {
            uint256 pendingBasic = dystoApez.balanceOf(_account) * (DAILY_RATE * delta / 86400);
            uint256 pendingLegendary = legendaryOwned[_account] * (DAILY_LEGENDARY_BONUS * delta / 86400);
            uint256 bonus = _calculateBonus(_account) * delta / 86400;

            return pendingBasic + pendingLegendary + bonus;
        }
        return 0;
    }

    function _calculateBonus(address _account) internal view returns(uint256) {
        uint256 curBalance = dystoApez.balanceOf(_account);
        if (curBalance >= 20)
            return 400 ether;
        if (curBalance >= 10)
            return 150 ether;
        if (curBalance >= 5)
            return 50 ether;
        if (curBalance >= 2)
            return 10 ether;
        return 0;
    }

    function setDystoApez(address _dystoApez) external onlyOwner {
        require(_dystoApez != address(0), "ADDRESS_ZERO");
        dystoApez = IERC721(_dystoApez);
    }

    function pause() external onlyOwner {
        require(!paused(), "ALREADY_PAUSED");
        _pause();
    }

    function unpause() external onlyOwner {
        require(paused(), "ALREADY_UNPAUSED");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!paused(), "TRANSFER_PAUSED");
        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public pure override returns(uint8) {
        return 18;
    }
}