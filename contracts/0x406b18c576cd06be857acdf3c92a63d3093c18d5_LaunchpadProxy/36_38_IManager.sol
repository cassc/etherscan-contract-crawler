// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import './ILaunchpad.sol';
import './IVesting.sol';
import './IIqStaking.sol';
import '@openzeppelin/contracts/interfaces/IERC20Metadata.sol';
import '../CredentialVerifier.sol';

uint256 constant ROUNDS_ = 3;

/// @dev The IManager interface has to be separated in
///   this way because of a bug in solc that prevents us
///   from inhereting from IManager.
///   https://github.com/ethereum/solidity/issues/11826
/// @title IManager2
/// @author gotbit
interface IManager2 {
    event CreateRound(
        uint256 indexed projectId,
        uint256 indexed roundId,
        address indexed lpad
    );

    struct Logic {
        address launchpad;
        address vesting;
    }

    struct NftOracleData {
        address signer;
        address nftContract;
        uint256 chainid;
    }

    struct Claim {
        uint256 round;
        address investor;
    }

    struct Project {
        address token;
        address wallet;
    }

    // read

    /// @dev Returns the address of the IQZoneStaking contract of the system
    function iqStaking() external view returns (address);

    /// @dev Returns the address of the IQZoneNFT contract of the system
    function nft() external view returns (address);

    /// @dev Returns the amount of fee for newly created rounds as numerator of 10**-18
    function kickback() external view returns (uint256);

    /// @dev Returns the wallet address where the kickback fee is sent
    function kickbackWallet() external view returns (address);

    /// @dev Returns the WETH address
    function native() external view returns (address);

    /// @dev Returns whether the token is whitelisted
    function stables(address stable) external view returns (bool allowed);

    /// @dev Returns whether the DEX is whitelisted
    function dexes(address router) external view returns (bool allowed);

    /// @dev Returns the implementation address of the launchpad contract
    function launchpadLogic() external view returns (address);

    /// @dev Returns the implementation address of the vesting contract
    function vestingLogic() external view returns (address);

    /// @dev Returns the max round type enum
    function ROUND_TYPES() external view returns (uint8);

    /// @dev Returns whether the current chain has the NFT contract deployed on it
    function shouldUseOracle() external view returns (bool);

    /// @dev Decodes and checks the signature of the nft balances data
    function nftBalancesOracle(
        address user,
        bytes calldata data,
        bytes calldata signature
    ) external view returns (uint256[] memory balance);

    /// @dev Returns the address of the Launchpad contract of the round
    function rounds(uint256 id) external view returns (address);

    /// @dev Returns the amount of rounds created
    function roundsLength() external view returns (uint256);

    /// @dev Returns `size` Launchpad addresses starting from `offset`
    function roundsRead(uint256 offset, uint256 size)
        external
        view
        returns (address[] memory);

    /// @dev Returns the amount of projects created
    function project2Length() external view returns (uint256);

    /// @dev Returns the address of the project's token the investors will get
    function projectToken(uint256 id) external view returns (address);

    /// @dev Returns the project wallet that will get funds invested
    function projectWallet(uint256 id) external view returns (address);

    /// @dev Returns the address of the airdrop contract
    function airdropContract() external view returns (address);

    // write

    /// @dev Allows users with appropriate NFTs to invest in a round
    /// @param round ID of the round to invest in
    /// @param usd Amount of `stable` token to invest
    /// @param data Data to be signed by the NFT oracle
    /// @param signature Signature of `data`
    /// @param proof KYC proof of the investor
    function invest(
        uint256 round,
        uint256 usd,
        bytes memory data,
        bytes memory signature,
        FractalProof memory proof
    ) external;

    /// @dev Claims vested project tokens of round `round` on behalf of `investor`
    /// @param round ID of the round to claim project tokens of
    /// @param investor Address of the investor
    function claim(uint256 round, address investor) external;

    /// @dev Allows investors to recoup losses in case project token price is low
    /// @param round ID of the round to pay back
    function payBackOnPrice(uint256 round) external;

    /// @dev Allows investors to get their money back if the IDO failed
    /// @param round ID of the round that failed
    function payBack(uint256 round) external;

    /// @dev Tells the round that the project token has been transferred
    ///   and moves it to the next stage. Callable by the admin.
    /// @param round ID of the round to move to the next stage
    function setTokensTransferred(uint256 round) external;

    /// @dev Airdrops investments in a round that exceed the soft cap.
    ///   Callable by the admin.
    /// @param round ID of the round to airdrop
    /// @param size Amount of investors to airdrop to
    function airdropOvercap(uint256 round, uint256 size) external;

    /// @dev Returns the amount of investors participating in a round.
    /// @param round ID of the round
    function investorsLength(uint256 round) external view returns (uint256);

    /// @dev Changes the vesting contract for the round
    ///   Callable by the admin.
    /// @param round ID of the round to change
    function setVestingContract(uint256 round, address) external;

    /// @dev Changes the vesting schedule for the round.
    ///   Callable by the admin.
    /// @param round ID of the round to change
    function changeVestingSchedule(uint256 round, IVesting.Unlock[] calldata) external;

    /// @dev Changes settings of the NFT oracle. Callable by the admin.
    function changeNftOracleSettings(NftOracleData calldata) external;

    /// @dev Creates a round and deploys contracts for it.
    /// @param projectId ID of the project to associate the round with
    /// @param roundType Type of the round, 0 - seed, 1 - private, 2 - public
    /// @param sched Vesting schedule for the round
    /// @param stable Token to accept as investment in the round
    /// @param dexRouter DEX used for price discovery for payBackOnPrice
    function createRound(
        uint256 projectId,
        uint8 roundType,
        ILaunchpad.Launch calldata launchData,
        IVesting.Unlock[] calldata sched,
        address stable,
        address dexRouter
    ) external;

    /// @dev Changes the round type
    /// @param roundId ID of the round to change
    /// @param roundType New round type (0 - seed, 1 - private, 2 - public)
    function setRoundType(uint256 roundId, uint256 roundType) external;

    /// @dev Changes the round data
    /// @param roundId ID of the round to change
    /// @param data The data to set
    /// @param stableToken The new stable token
    function setRoundData(
        uint256 roundId,
        ILaunchpad.Launch memory data,
        address stableToken
    ) external;

    /// @dev Changes the DEX router used for price discovery for payBackOnPrice
    /// @param roundId ID of the round to change
    function setDexRouter(uint256 roundId, address) external;

    /// @dev Airdrops any token. The token should be
    ///   transferred to the Airdrop contract beforehand.
    /// @param token Address of the token to airdrop
    /// @param amount Total amount of token to airdrop
    /// @param receivers Array of receivers and their shares of `amount`
    function airdrop(
        address token,
        uint256 amount,
        IIqStaking.UserSharesOutput[] memory receivers
    ) external;

    /// @dev Changes the airdrop contract used in airdrop()
    /// @param airdropContract_ The new airdrop contract
    function setAirdropContract(address airdropContract_) external;

    /// @dev Allows the manager contract to airdrop
    /// @param manager_ The manager contract
    function setAirdropManager(address manager_) external;

    /// @dev Creates a project
    /// @param token Token of the project. Can be 0. This token will be given to investors
    /// @param wallet Wallet of the project. This wallet will receive investments.
    function createProject(address token, address wallet) external;

    /// @dev Changes the token and wallet of a project
    /// @param token New token of the project
    /// @param wallet New wallet of the project
    function setProjectParams(
        uint256 id,
        address token,
        address wallet
    ) external;
}

/// @dev The manager contract is the central contract of the
///   system, keeping track of roles, rounds and projects.
/// @title IManager
/// @author gotbit
interface IManager is IManager2 {
    /// @dev Returns the address trusted with relaying NFT ownership
    ///   information between chains and information needed to check
    ///   the signature from that address.
    function nftOracle() external view returns (NftOracleData calldata);

    /// @dev Returns project data.
    /// @param id ID of the project
    function project2(uint256 id) external view returns (Project memory);
}