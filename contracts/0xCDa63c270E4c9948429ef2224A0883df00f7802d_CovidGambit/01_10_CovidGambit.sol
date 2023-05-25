/**
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⣰⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⡀⠀⢀⠒⠑⣴⣦⣾⣧⣤⢀⡤⠀⠀⠀⡀⠀⠀⠀
 * ⠀⠀⠀⠀⢀⠀⢀⡘⠉⠁⣰⣾⣿⣿⣿⣿⣿⣿⣷⢀⡤⠊⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⢱⠊⡄⠒⠾⣿⣿⣿⣿⣿⣿⠿⠛⢹⣿⣯⣤⠤⠄⠀⠀
 * ⠀⠀⠀⠒⢦⠂⠀⣇⠀⠸⠟⢈⣿⣿⡁⠺⠗⠀⣸⣿⣿⣃⠀⠀⠀⠀
 * ⠀⠀⠀⠀⢘⢀⣼⠻⢷⣶⣶⣿⣿⣿⣿⣶⣶⣾⠟⣻⣿⡯⠁⠀⠀⠀
 * ⠀⠀⠀⠉⠱⢾⣿⡀⠀⠈⠉⠙⠛⠛⠛⠉⠉⠀⢀⣿⣿⠿⠛⠒⠀⠀
 * ⠀⠀⠀⠀⠔⢛⣿⣷⡈⠒⠀⠀⠀⠔⠁⠊⠒⢈⣾⣿⡏⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠜⠛⠿⣿⣶⣤⣀⣀⣀⣀⣤⣶⣿⠿⣿⠉⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⡸⠛⢉⡿⠻⠟⣿⢿⡟⣏⠁⠀⠘⠄⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⠀⠀⠀⠁⠀⠃⠘⡀⠀⠀⠀⠀⠀
 *
 * COVID GAMBIT: A REVOLUTIONARY ERC-20 DIGITAL GAME INSPIRED BY REAL-WORLD PANDEMICS
 *
 * This document provides a comprehensive guide to understanding and navigating Covid Gambit,
 * an innovative ERC-20 digital game that is based on real-world epidemiological events.
 *
 * Gameplay Guidelines:
 *
 * Participants can acquire $COVID tokens via Uniswap. Upon every transaction, there exists a 10% probability
 * that the participant will become an index case, or in gaming terms, "infected".
 *
 * Once a player is designated as infected, they are faced with a decision: to potentially infect others
 * by utilizing the "sneeze" function or to self-isolate in the quarantine module. It is crucial to
 * note that infected players have a time constraint of 48 hours to make this decision, failure to which
 * results in game "death" due to disease progression, thereby disabling the ability to transfer tokens.
 *
 * The "sneeze" function carries a dual probability: a 30% chance of the infected player gaining immunity
 * and a 100% probability of the target player becoming infected. Therefore, on average, an infected player
 * must "sneeze" on three non-infected wallets to gain immunity and continue the spread of infection.
 * Immunity provides a one-week protection from being "sneezed on" by other players. This function is only
 * applicable to non-infected players.
 *
 * Alternatively, an infected player may choose to enter the quarantine module, which requires a one-week
 * commitment during which the player cannot transfer tokens. Upon completion of the quarantine period, the
 * player will be considered "healthy". Access to the quarantine module is restricted to infected players only.
 *
 * Non-infected or "healthy" players can maintain their status by executing the washHands() function, granting
 * them immunity for an 24-hour period, during which they are unaffected by the "sneeze" function of other
 * players. Regular execution of the washHands() function is advised to maintain player health.
 *
 * Game Dynamics:
 *
 * As per the game's mechanics, only 33% of players can achieve long-term immunity. Given the restriction
 * against "sneezing" on other infected players, a player's options are limited to either entering the
 * week-long quarantine module (locking tokens), or exiting the game by selling their tokens.
 *
 * Strategic Considerations:
 *
 * The goal of this game is twofold: to maintain individual health for the longest possible duration and to
 * collectively combat the pandemic. Players are faced with a moral dilemma: do they infect others to gain
 * immunity, or do they choose to quarantine, promoting collective efforts to end the pandemic?
 * The choice is in the hands of each player.
 *
 * Website: covidgambit.com
 * Twitter: twitter.com/CovidGambitGame
 * Telegram: t.me/CovidGambit
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "interfaces/IUniswapV2Router02.sol";
import "interfaces/IUniswapV2Pair.sol";
import "interfaces/IUniswapV2Factory.sol";

contract CovidGambit is ERC20, Ownable {
    mapping(address => bool) public isVaxxed;
    mapping(address => uint256) public firstInfectedTime;
    mapping(address => uint256) public immunityEndTime;
    mapping(address => uint256) public quarantineEndTime;

    bool plandemicStarted;

    event Sneezed(address indexed patient, address indexed target, bool indexed gotImmunity);
    event GotCovid(address indexed patient, address indexed from);
    event WashedHands(address indexed patient, uint256 immunityEndTime);
    event EnteredQuarantine(address indexed patient, uint256 quarantineEndTime);

    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint256 maxWallet;

    constructor() ERC20("Covid Gambit", "COVID") {
        getVaxxed(address(this));
        getVaxxed(address(router));
        getVaxxed(address(pair));
        getVaxxed(msg.sender);
        getVaxxed(0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B); // Universal router

        _mint(msg.sender, 19_000_000e18);
        pair = IUniswapV2Pair(IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH()));
        maxWallet = totalSupply() / 200; // 0.5% max wallet at launch
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // Launch stuff
        if (from == address(pair) && !isVaxxed[to]) {
            require(amount + balanceOf(to) <= maxWallet, "You can't buy that much right now");
        }

        if (plandemicStarted) {
            // Infected dies in 48 hrs
            if (!isHealthy(from)) {
                require(!isDead(from), "You got covid and died");
            }
            // Can only buy and sell
            require(from == address(pair) || to == address(pair) || isVaxxed[from], "You can't escape covid");
            // Can't sell if in quarantine
            require(!isQuarantined(from), "You are in quarantine");
            // If you buy there's a 10% chance of contracting covid (if you dont have immunity)
            if (from == address(pair) && !isImmune(to) && !isVaxxed[to]) {
                if (isPatientZero(10, to) && !isInfected(to)) {
                    firstInfectedTime[to] = block.timestamp;
                    emit GotCovid(to, from);
                }
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function sneeze(address target) public {
        require(isInfected(msg.sender), "Not infected or already dead");
        require(!isImmune(msg.sender), "Already has immunity");
        require(!isQuarantined(msg.sender), "Already in quarantine");
        require(balanceOf(msg.sender) > 0, "Covid denier");
        require(!isImmune(target), "Target has immunity");
        require(!isVaxxed[target], "Target is vaxxed");
        require(!isQuarantined(target), "Target in quarantine");
        require(isHealthy(target), "Target already infected or dead");
        require(balanceOf(target) > 0, "Target is covid denier");
        firstInfectedTime[target] = block.timestamp;
        bool gotImmunity;
        if (isPatientZero(30, target)) {
            firstInfectedTime[msg.sender] = 0;
            immunityEndTime[msg.sender] = block.timestamp + 7 days;
            gotImmunity = true;
        }
        emit Sneezed(msg.sender, target, gotImmunity);
        emit GotCovid(target, msg.sender);
    }

    function washHands() public {
        require(isHealthy(msg.sender), "Already infected");
        require(!isQuarantined(msg.sender), "Already in quarantine");
        require(balanceOf(msg.sender) > 0, "Covid denier");
        immunityEndTime[msg.sender] = block.timestamp + 24 hours;
        emit WashedHands(msg.sender, immunityEndTime[msg.sender]);
    }

    function enterQuarantine() public {
        require(isInfected(msg.sender), "Not infected or already dead");
        require(!isQuarantined(msg.sender), "Already in quarantine");
        require(!isImmune(msg.sender), "Already has immunity");
        require(balanceOf(msg.sender) > 0, "Covid denier");
        firstInfectedTime[msg.sender] = 0;
        quarantineEndTime[msg.sender] = block.timestamp + 7 days;
        emit EnteredQuarantine(msg.sender, quarantineEndTime[msg.sender]);
    }

    function plandemicStats(address[] memory patients)
        public
        view
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        uint256 healthyCount;
        uint256 infectedCount;
        uint256 quarantinedCount;
        uint256 immuneCount;
        uint256 deadCount;

        for (uint256 i = 0; i < patients.length; i++) {
            uint256 status = patientStatus(patients[i]);

            if (status == 0) {
                healthyCount++;
            } else if (status == 1) {
                infectedCount++;
            } else if (status == 2) {
                quarantinedCount++;
            } else if (status == 3) {
                immuneCount++;
            } else if (status == 4) {
                deadCount++;
            }
        }

        return (healthyCount, infectedCount, quarantinedCount, immuneCount, deadCount);
    }

    function patientStatus(address patient) public view returns (uint256 status) {
        if (isHealthy(patient) && !isQuarantined(patient) && !isImmune(patient) || isVaxxed[patient]) {
            return 0;
        } else if (isInfected(patient)) {
            return 1;
        } else if (isQuarantined(patient)) {
            return 2;
        } else if (isImmune(patient)) {
            return 3;
        } else if (isDead(patient)) {
            return 4;
        }
    }

    function startPlandemic(bool isStarted) public onlyOwner {
        plandemicStarted = isStarted;
    }

    function getVaxxed(address patient) public onlyOwner {
        isVaxxed[patient] = true;
    }

    function getUnvaxxed(address patient) public onlyOwner {
        isVaxxed[patient] = false;
    }

    function setMaxWallet(uint256 _maxWallet) public onlyOwner {
        maxWallet = _maxWallet;
    }
    
    function isPatientZero(uint256 chance, address patient) private returns (bool isIndeed) {
        uint256 dna = uint256(keccak256(abi.encodePacked(patient, block.timestamp, balanceOf(patient)))) % 101;
        return dna <= chance;
    }

    function isHealthy(address patient) private view returns (bool isIndeed) {
        return firstInfectedTime[patient] == 0;
    }

    function isInfected(address patient) private view returns (bool isIndeed) {
        return firstInfectedTime[patient] + 48 hours > block.timestamp;
    }

    function isQuarantined(address patient) private view returns (bool isIndeed) {
        return quarantineEndTime[patient] > block.timestamp;
    }

    function isImmune(address patient) private view returns (bool isIndeed) {
        return immunityEndTime[patient] > block.timestamp;
    }

    function isDead(address patient) private view returns (bool isIndeed) {
        return firstInfectedTime[patient] + 48 hours < block.timestamp;
    }
}