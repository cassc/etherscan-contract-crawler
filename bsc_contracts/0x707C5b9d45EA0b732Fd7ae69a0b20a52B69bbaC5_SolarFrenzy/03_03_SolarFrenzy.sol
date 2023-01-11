pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @author ~ 🅧🅘🅟🅩🅔🅡 ~ (https://twitter.com/Xipzer | https://t.me/Xipzer)
 *
 * ░██████╗░█████╗░██╗░░░░░░█████╗░██████╗░  ███████╗██████╗░███████╗███╗░░██╗███████╗██╗░░░██╗
 * ██╔════╝██╔══██╗██║░░░░░██╔══██╗██╔══██╗  ██╔════╝██╔══██╗██╔════╝████╗░██║╚════██║╚██╗░██╔╝
 * ╚█████╗░██║░░██║██║░░░░░███████║██████╔╝  █████╗░░██████╔╝█████╗░░██╔██╗██║░░███╔═╝░╚████╔╝░
 * ░╚═══██╗██║░░██║██║░░░░░██╔══██║██╔══██╗  ██╔══╝░░██╔══██╗██╔══╝░░██║╚████║██╔══╝░░░░╚██╔╝░░
 * ██████╔╝╚█████╔╝███████╗██║░░██║██║░░██║  ██║░░░░░██║░░██║███████╗██║░╚███║███████╗░░░██║░░░
 * ╚═════╝░░╚════╝░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝╚══════╝░░░╚═╝░░░
 *
 * Solar Frenzy - Jackpot
 *
 * Telegram: https://t.me/SolarFarmMinerOfficial
 * Twitter: https://twitter.com/SolarFarmMiner
 * Landing: https://solarfarm.finance/
 * dApp: https://app.solarfarm.finance/
 */

interface IKingdomHost
{
    function claimFrenzyPrize(address engineer, uint quantity) external;
}

contract SolarFrenzy is Ownable
{
    IKingdomHost public kingdomHost;

    mapping (address => mapping(uint => uint)) public deposits;

    SessionRewards[] public rewards;
    Session[] public sessions;

    struct SessionRewards
    {
        uint sessionNumber;
        bool winnerHasClaimed;
        bool pityHasClaimed;
    }

    struct Session
    {
        uint sessionNumber;
        uint sessionEndTimestamp;
        uint jackpotSize;
        address lastDepositor;
        address topDepositor;
    }

    event FrenzyContribution(uint amount, uint timestamp);
    event FrenzyRewardsClaim(uint amount, uint timestamp);

    modifier onlyKingdom
    {
        require(msg.sender == address(kingdomHost), "SolarGuard: You are not the kingdom host!");
        _;
    }

    function createSession() private
    {
        Session memory session;
        session.sessionNumber = sessions.length + 1;
        session.sessionEndTimestamp = block.timestamp + 86400;

        sessions.push(session);

        SessionRewards memory rewardsClaim;
        rewardsClaim.sessionNumber = sessions.length + 1;

        rewards.push(rewardsClaim);
    }

    function startNewSession() public onlyOwner
    {
        if (sessions.length > 0)
        {
            require(!getSessionStatus(sessions.length), "SolarGuard: The existing session hasn't ended yet!");

            createSession();
        }
        else
            createSession();
    }

    function getCurrentSessionNumber() public view returns (uint)
    {
        return sessions.length;
    }

    function getCurrentSessionStatus() public view returns (bool)
    {
        return getSessionStatus(getCurrentSessionNumber());
    }

    function getCurrentSessionDeposits() public view returns (uint)
    {
        return deposits[msg.sender][getCurrentSessionNumber() - 1];
    }

    function getSessionStatus(uint sessionNumber) public view returns (bool)
    {
        require(sessionNumber <= sessions.length, "SolarGuard: The session number provided is invalid!");

        Session storage session = sessions[sessionNumber - 1];

        return block.timestamp < session.sessionEndTimestamp;
    }

    function getSessionWinner(uint sessionNumber) public view returns (address)
    {
        require(sessionNumber <= sessions.length, "SolarGuard: The session number provided is invalid!");

        Session storage session = sessions[sessionNumber - 1];

        require(block.timestamp >= session.sessionEndTimestamp, "SolarGuard: The session provided has not ended yet!");

        return session.lastDepositor;
    }

    function getSessionPity(uint sessionNumber) public view returns (address)
    {
        require(sessionNumber <= sessions.length, "SolarGuard: The session number provided is invalid!");

        Session storage session = sessions[sessionNumber - 1];

        require(block.timestamp >= session.sessionEndTimestamp, "SolarGuard: The session provided has not ended yet!");

        return session.topDepositor;
    }

    function fundSessionJackpot(uint amount) public onlyOwner
    {
        require(sessions.length > 0, "SolarGuard: There is yet to be a session!");

        Session storage session = sessions[sessions.length - 1];

        require(block.timestamp < session.sessionEndTimestamp, "SolarGuard: The current session has already ended!");

        session.jackpotSize += amount;
    }

    function contribute(address engineer, uint amount, uint time) external onlyKingdom
    {
        require(sessions.length > 0, "SolarGuard: There is yet to be a session!");

        uint sessionNumber = sessions.length;

        Session storage session = sessions[sessionNumber - 1];

        require(block.timestamp < session.sessionEndTimestamp, "SolarGuard: The current session has already ended!");

        deposits[engineer][sessionNumber] += amount;

        session.jackpotSize += amount;
        session.lastDepositor = engineer;
        session.sessionEndTimestamp += time;

        if (deposits[session.topDepositor][sessionNumber] < deposits[engineer][sessionNumber])
            session.topDepositor = engineer;

        emit FrenzyContribution(amount, block.timestamp);
    }

    function claimRewards(uint sessionNumber) external
    {
        require(sessionNumber <= sessions.length, "SolarGuard: The session number provided is invalid!");

        Session storage session = sessions[sessionNumber - 1];

        require(block.timestamp >= session.sessionEndTimestamp, "SolarGuard: The session provided has not ended yet!");
        require(msg.sender == session.lastDepositor || msg.sender == session.topDepositor, "SolarGuard: You are not eligible for a reward!");

        uint claimablePot = (session.jackpotSize * 900) / 1000;

        SessionRewards storage rewardsClaim = rewards[sessionNumber - 1];

        if (session.lastDepositor != session.topDepositor)
        {
            if (msg.sender == session.lastDepositor)
            {
                require(!rewardsClaim.winnerHasClaimed, "SolarGuard: You have already claimed your rewards!");

                claimablePot = (claimablePot * 700) / 1000;
                rewardsClaim.winnerHasClaimed = true;
            }
            else
            {
                require(!rewardsClaim.pityHasClaimed, "SolarGuard: You have already claimed your rewards!");

                claimablePot = (claimablePot * 300) / 1000;
                rewardsClaim.pityHasClaimed = true;
            }
        }
        else
        {
            require(!rewardsClaim.winnerHasClaimed && !rewardsClaim.pityHasClaimed, "SolarGuard: You have already claimed your rewards!");

            rewardsClaim.winnerHasClaimed = true;
            rewardsClaim.pityHasClaimed = true;
        }

        kingdomHost.claimFrenzyPrize(msg.sender, claimablePot);

        emit FrenzyContribution(claimablePot, block.timestamp);
    }

    function setKingdomHost(address kingdomAddress) public onlyOwner
    {
        kingdomHost = IKingdomHost(kingdomAddress);
    }
}