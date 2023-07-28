// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import '@openzeppelin/contracts/interfaces/IERC20Metadata.sol';
import './IVesting.sol';
import './IDexRouter.sol';
import './../IQZoneNFT.sol';

// is called IQZoneIDO in the mindmap

/// @dev The ILaunchpad interface has to be separated in
///   this way because of a bug in solc that prevents us
///   from inhereting from ILaunchpad.
///   https://github.com/ethereum/solidity/issues/11826
/// @title ILaunchpad2
/// @author gotbit
interface ILaunchpad2 {
    event Invested(address indexed from, uint256 stableAmount);
    event PayBackInvestor(address indexed from, uint256 amount);
    event PayBackProject(uint256 amount);

    // this is what the project will be able to change
    struct Launch {
        uint256 hardCap;
        uint256 softCap;
        uint256 maxVentureAllocation;
        uint256 startTime;
        uint64 duration;
        uint256 price;
    }

    /// @dev Initializes the contract.
    /// @param projectId_ Project ID the round is associated with.
    /// @param roundType Round type. 0 for seed, 1 for private, 2 for public.
    /// @param launchData_ Launch data.
    /// @param launchpadKickback_ IQ Zone's comission as an 18 digit number.
    /// @param dexRouter_ DEX used for price discovery for payBackOnPrice
    /// @param nft_ IQ Zone NFT contract
    function initialize(
        uint256 projectId_,
        uint256 roundType,
        Launch calldata launchData_,
        uint256 launchpadKickback_,
        address stableToken_,
        address nativeToken_,
        address kickbackWallet_,
        address dexRouter_,
        address nft_
    ) external;

    /// @dev price of 1 project token in usd
    function price() external view returns (uint256);

    /// @dev Returns the project ID the round is associated with.
    function projectId() external view returns (uint256);

    /// @dev Returns the round type.
    function roundType() external view returns (uint256);

    /// @dev Returns the address of the manager contract.
    function manager() external view returns (address);

    /// @dev Returns max amount of investments the project can raise in this round.
    ///   Investments over that amount are allowed but excess funds are
    ///   distributed to the investors according to their share.
    function hardCap() external view returns (uint256);

    /// @dev Returns min amount of investments the project has to raise in this round
    ///   If the project raises less, funds invested are airdropped back to investors.
    function softCap() external view returns (uint256);

    /// @dev Returns max amount of project tokens that will be distributed to investors.
    function projectTokensAmount() external view returns (uint256);

    /// @dev Returns the amount of project tokens that will be distributed to investors
    ///   given current conditions.
    function projectTokensToDistribute() external view returns (uint256);

    /// @dev Returns max amount that can be invested in this round by holders of venture nft.
    function maxVentureAllocation() external view returns (uint256);

    /// @dev Returns when investment in the round started.
    function startTime() external view returns (uint256);

    /// @dev Returns how long the investments were accepted for.
    function duration() external view returns (uint64);

    /// @dev Helper function for precision.
    function oneProjectToken() external view returns (uint256);

    /// @dev Allows to get the comission IQ Zone takes
    /// @return _launchpadKickback the comission as an 18 digit number
    function launchpadKickback() external view returns (uint256);

    /// @dev Allows to get the stablecoin's contract
    /// @return token the stablecoin's contract
    function stableToken() external view returns (IERC20Metadata token);

    /// @dev Allows to get the project token's contract
    /// @return token the project token's contract
    function projectToken() external view returns (IERC20Metadata token);

    /// @dev Returns the native token's contract (WETH)
    function nativeToken() external view returns (IERC20Metadata token);

    /// @dev Allows to get the project's wallet
    /// @return projectWallet_ the project's wallet
    function projectWallet() external view returns (address);

    /// @dev Returns the IQ Zone wallet that receives the kickback
    function kickbackWallet() external view returns (address);

    /// @dev Returns address of the DEX used for price discovery for payBackOnPrice
    function dexRouter() external view returns (IDexRouter);

    /// @dev Returns address of the IQ Zone NFT contract
    function nft() external view returns (IQZoneNFT);

    /// @dev Allows to get the amount of stablecoins raised by the project in this round
    /// @return stables the amount of stables invested
    function raised() external view returns (uint256 stables);

    /// @dev Allows to get the amount of stablecoins invested by a particular user in the project
    /// @param user the investor
    /// @return stables the amount of stablecoins invested
    function invested(address user) external view returns (uint256 stables);

    /// @dev Returns the amount of project tokens a user will receive for their investment
    function userTotal(address user) external view returns (uint256);

    /// @dev Allows to get vesting contract
    /// @return vestingContract the vesting contract
    function vestingContract() external view returns (address vestingContract);

    /// @dev Allows the user to invest stablecoins into the project
    /// @param stableAmount the amount of stablecoins to invest
    function invest(
        address investor,
        uint256 stableAmount,
        bytes memory data,
        bytes memory signature
    ) external;

    /// @dev Allows the investor to get their money back in case allocations didn't meet soft cap / token price went below the IDO price
    function payBack(address investor) external;

    /// @dev Allows the investor to get their money back in case token price went below the IDO price
    function payBackOnPrice(address investor) external;

    /// @dev Allows the vesting contract to transfer project's tokens
    /// @param amount the amount of tokens to transfer
    /// @param to token receiver
    function transferProjectToken(uint256 amount, address to) external;

    /// @dev Allows the vesting contract to transfer stable tokens
    /// @param amount the amount of tokens to transfer
    /// @param to token receiver
    function transferStableToken(uint256 amount, address to) external;

    /// @dev Allows the manager contract to change the vesting contract
    function setVestingContract(address) external;

    /// @dev Returns whether the launch has failed, that is, whether any of the rounds have failed to reach the softcap
    /// @return _launchFailed whether the launch has failed
    function launchFailed() external view returns (bool);

    /// @dev Allows the launchpad admin to airdrop overcapped tokens
    function airdropOvercap(uint256 size) external;

    /// @dev Returns the amount of investments raised so far capped by hardCap
    function raisedCapped() external view returns (uint256);

    /// @dev Returns the amount of investors
    function investorsLength() external view returns (uint256);

    /// @dev Returns whether the investor was paid back
    function paidBack(address investor) external view returns (bool);

    /// @dev Returns whether the required amount of project tokens was transferred
    function tokensTransferred() external view returns (bool);

    /// @dev Checks and updates tokensTransferred()
    function setTokensTransferred() external;

    /// @dev Changes the round type
    function setRoundType(uint256) external;

    /// @dev Changes round data
    function setRoundData(Launch memory, address) external;

    /// @dev Changes the DEX address
    function setDexRouter(address) external;

    /// @dev Updates project token with info from Manager
    function setProjectToken() external;
}

/// @title ILaunchpad
/// @author gotbit
interface ILaunchpad is ILaunchpad2 {

}