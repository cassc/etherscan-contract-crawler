// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Gold is ERC20Burnable, Ownable {
    /*
  _______________________________________
 /                                       \
/   _   _   _                 _   _   _   \
|  | |_| |_| |   _   _   _   | |_| |_| |  |
|   \   _   /   | |_| |_| |   \   _   /   |
|    | | | |     \       /     | | | |    |
|    | |_| |______|     |______| |_| |    |
|    |              ___              |    |
|    |  _    _    (     )    _    _  |    |
|    | | |  |_|  (       )  |_|  | | |    |
|    | |_|       |       |       |_| |    |
|   /            |_______|            \   |
|  |___________________________________|  |
\         GOLD for Realms of Ether        /
 \_______________________________________/
*/

    using SafeMath for uint256;

    event FortressStaked(uint256);

    // translates to 5 gold / day
    uint256 public INITIAL_EMISSION_RATE = 57870370370370;

    // translates to 2 gold / day
    uint256 public FINAL_EMISSION_RATE = 23148148148148;

    uint256 public PERIOD_ONE = 1633039200;

    address NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    // OpenSea Creatures rinkeby
    address public constant fortressAddress =
        0x8479277AaCFF4663Aa4241085a7E27934A0b0840;

    // Mapping of fortress to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    // Mapping of fortress to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    constructor() ERC20("Gold", "GOLD") {}

    function stakeByIds(uint256[] memory tokenIds) public {
        require(tokenIds.length > 0, "Must provide at least 1 tokenId");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(fortressAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == NULL_ADDRESS,
                "Token must be stakable by you!"
            );

            IERC721(fortressAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
            emit FortressStaked(tokenIds[i]); // use this on ui to show staked tokens
        }
    }

    /**
     *  This function is reserved for emergency exiting the contract
     */
    function emergencyExit(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );
            IERC721(fortressAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            tokenIdToStaker[tokenIds[i]] = NULL_ADDRESS;
        }
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );
            uint256 tokenStakedTimestamp = tokenIdToTimeStamp[tokenIds[i]];
            IERC721(fortressAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                calcRewards(tokenStakedTimestamp, block.timestamp);

            tokenIdToStaker[tokenIds[i]] = NULL_ADDRESS;
        }

        _mint(msg.sender, totalRewards);
    }

    function calcRewards(uint256 tokenStakedTimestamp, uint256 blockTimestamp)
        public
        view
        returns (uint256)
    {
        uint256 rewards = 0;

        if (blockTimestamp < PERIOD_ONE) {
            // we are in initial period, full time rewarded with initial emissions rate
            rewards =
                (blockTimestamp - tokenStakedTimestamp) *
                INITIAL_EMISSION_RATE;
        } else {
            // we are in final period, differentiate if staking started before that
            // uint underflows so using 0 when isAfter
            bool isBefore = PERIOD_ONE > tokenStakedTimestamp;

            if (isBefore) {
                uint256 timeBetweenStakeAndPeriodOne = PERIOD_ONE -
                    tokenStakedTimestamp;
                // started before
                // reward for initial period
                rewards = timeBetweenStakeAndPeriodOne * INITIAL_EMISSION_RATE;
                // reward for final period
                rewards =
                    rewards +
                    (blockTimestamp -
                        (tokenStakedTimestamp + timeBetweenStakeAndPeriodOne)) *
                    FINAL_EMISSION_RATE;
            } else {
                // started after
                // reward for final period
                rewards =
                    (blockTimestamp - tokenStakedTimestamp) *
                    FINAL_EMISSION_RATE;
            }
        }
        return rewards;
    }

    function claimInternal(uint256 tokenId, address staker) internal {
        require(
            tokenIdToStaker[tokenId] == staker,
            "Token is not claimable by you!"
        );

        _mint(
            staker,
            calcRewards(tokenIdToTimeStamp[tokenId], block.timestamp)
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function claimByTokenId(uint256 tokenId) public {
        claimInternal(tokenId, msg.sender);
    }

    function claimByTokenIds(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claimInternal(tokenIds[i], msg.sender);
        }
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenId] != NULL_ADDRESS,
            "Token is not staked!"
        );

        return calcRewards(tokenIdToTimeStamp[tokenId], block.timestamp);
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }
}