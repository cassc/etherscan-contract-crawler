// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./StaticNFT.sol";

/* ------------
    Interfaces
   ------------ */

interface IRewarder {
    function reward(
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external;
}

/* ---------
    Structs
   --------- */

struct Stake {
    uint32 ts;
    address owner;
    uint16 bit;
}

/* ------
    Main
   ------ */

contract KiltonHotel is Ownable, IERC721Receiver, StaticNFT {
    using Strings for uint16;
    using Strings for uint256;

    /* --------
        Errors
       -------- */
    error NotYourToken();
    error NotCompleted();
    error ArrayLengthMismatch();
    error StakingNotEnabled();
    error BearAlreadyClaimedReward();
    error BitAlreadyClaimedReward();

    /* --------
        Events
       -------- */
    event Entered(uint256[] bears, uint256[] bits);
    event Exited(uint256[] bears);
    event Escaped(uint256[] bears);

    /* --------
        Config
       -------- */
    uint256 public immutable stakeTime;
    IERC721 public immutable killaBearsContract;
    IERC721 public immutable killaBitsContract;
    IRewarder public rewardsContract;
    bool public stakingEnabled;
    mapping(address => bool) public stakingEnabledFor;

    /* --------
        Stakes
       -------- */
    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256) public balances;
    mapping(uint256 => bool) public bearsClaimed;
    mapping(uint256 => bool) public bitsClaimed;

    constructor(
        address killaBearsAddress,
        address killaBitsAddress,
        uint256 _stakeTime
    ) StaticNFT("KiltonHotel", "Kilton") {
        stakeTime = _stakeTime;
        killaBearsContract = IERC721(killaBearsAddress);
        killaBitsContract = IERC721(killaBitsAddress);
    }

    /* ---------
        Staking
       --------- */

    /// @notice Stake pairs of KILLABEARS and KILLABITS
    function enter(uint256[] calldata bears, uint256[] calldata bits) external {
        if (!stakingEnabled && !stakingEnabledFor[msg.sender])
            revert StakingNotEnabled();

        uint256 index = bears.length;
        if (index != bits.length) revert ArrayLengthMismatch();

        uint256 ts = block.timestamp;

        balances[msg.sender] += index;

        while (index > 0) {
            index--;

            uint256 bear = bears[index];
            uint256 bit = bits[index];
            
            if (bearsClaimed[bear]) revert BearAlreadyClaimedReward();
            if (bitsClaimed[bit]) revert BitAlreadyClaimedReward();

            killaBearsContract.transferFrom(msg.sender, address(this), bear);
            killaBitsContract.transferFrom(msg.sender, address(this), bit);

            stakes[bear] = Stake(uint32(ts), msg.sender, uint16(bit));

            emit Transfer(address(0), msg.sender, bear);
        }

        emit Entered(bears, bits);
    }

    /// @notice Unstake and claim rewards
    function exit(
        uint256[] calldata bears,
        uint256[] calldata rewards,
        bytes calldata signature
    ) external {
        uint256 index = bears.length;
        while (index > 0) {
            index--;

            uint256 bear = bears[index];
            Stake storage stake = stakes[bear];
            address owner = stake.owner;
            uint256 bit = stake.bit;

            if (owner != msg.sender) revert NotYourToken();
            if (block.timestamp - stake.ts < stakeTime) revert NotCompleted();

            bearsClaimed[bear] = true;
            bitsClaimed[bit] = true;
            killaBearsContract.transferFrom(address(this), owner, bear);
            killaBitsContract.transferFrom(address(this), owner, bit);

            delete stakes[bear];
            emit Transfer(msg.sender, address(0), bear);
        }

        rewardsContract.reward(msg.sender, bears, rewards, signature);

        balances[msg.sender]--;

        emit Exited(bears);
    }

    /// @notice Unstake prematurely
    function escape(uint256[] calldata bears) external {
        uint256 index = bears.length;
        while (index > 0) {
            index--;

            uint256 bear = bears[index];
            Stake storage stake = stakes[bear];
            address owner = stake.owner;
            uint256 bit = stake.bit;

            if (owner != msg.sender) revert NotYourToken();

            killaBearsContract.transferFrom(address(this), owner, bear);
            killaBitsContract.transferFrom(address(this), owner, bit);

            delete stakes[bear];

            balances[msg.sender]--;

            emit Transfer(msg.sender, address(0), bear);
            emit Escaped(bears);
        }
    }

    /* -------
        Token
       ------- */

    /// @dev used by StaticNFT base contract
    function getBalance(address _addr)
        internal
        view
        override
        returns (uint256)
    {
        return balances[_addr];
    }

    /// @dev used by StaticNFT base contract
    function getOwner(uint256 tokenId)
        internal
        view
        override
        returns (address)
    {
        return stakes[tokenId].owner;
    }

    /* -------
        Admin
       ------- */

    /// @notice Set the rewarder contract
    function setRewarder(address addr) external onlyOwner {
        rewardsContract = IRewarder(addr);
    }

    /// @notice Enable/disable staking
    function toggleStaking(bool enabled) external onlyOwner {
        stakingEnabled = enabled;
    }

    /// @notice Enable/disable staking for a given wallet
    function toggleStakingFor(address who, bool enabled) external onlyOwner {
        stakingEnabledFor[who] = enabled;
    }

    /// @notice Set the base URI
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    /* -------
        Other
       ------- */

    /// @dev See {IERC721Receiver-onERC721Received}
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @dev URI is different based on which bear and bit are staked, and how long they've been staked
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        if (getOwner(tokenId) == address(0)) revert NonExistentToken();

        Stake storage stake = stakes[tokenId];

        uint256 day = (block.timestamp - stake.ts) / 86400 + 1;

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        "/",
                        stake.bit.toString(),
                        "/",
                        day.toString()
                    )
                )
                : "";
    }
}