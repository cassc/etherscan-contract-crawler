// SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/// HEX Combinator is a dual chain index token backed by an equal number of eHEX and pHEX.
/// CHEX is designed to track the combined value of eHEX and pHEX through a bi-directional, dual chain minting and redemption function.
/// Mint 1 CHEX on Ethereum by depositing 1 HEX (0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39) and 1 HEX bridged from PulseChain(0x46F6e9BbcCe8638b20EBBC83D33a2B5bfA9B7894)
/// Mint 1 CHEX on PulseChain by depositing 1 HEX (0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39) and 1 HEX bridged from Ethereum (0x57fde0a71132198BBeC939B98976993d8D89D225)
/// If CHEX on one chain becomes worth more than CHEX on the other chain, it creates an arbitrage opportunity...
/// ... to buy the lower priced one, redeem the HEX and bridged HEX, bridge them over, and remint on the other side. 
/// All HEX held in the HEX Combinator contract addresses simply sits there liquid.
///
/// An arbitrage throttle is set by the Combinator DAO to introduce a small fixed cost to minting the tokens, paid in ETH or PLS. 
/// The arbitrage throttle is designed to make users below some value threshold get a better deal buying CHEX instead of minting, which helps foster an active market.
/// The arbitrage is also a type of size bonus, where the more CHEX you mint, the smaller percent of the total the arbitrage throttle is.
contract HEXCombinator is ERC20, ReentrancyGuard{
    address public HEX_ADDRESS=0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    address public HEX_FROM_E_ADDRESS=0x57fde0a71132198BBeC939B98976993d8D89D225; 
    address public HEX_FROM_P_ADDRESS=0x46F6e9BbcCe8638b20EBBC83D33a2B5bfA9B7894;
    address public COMBINATOR_DAO_ADDRESS;
    uint256 public arbitrage_throttle;
    uint256 public scheduled_arbitrage_throttle; 
    uint256 public scheduled_arbitrage_throttle_change_timestamp;
    event Minted(address indexed minter, uint256 amount);
    event Redeemed(address indexed redeemer, uint256 amount);
    event ChangeScheduled(uint256 current_throttle, uint256 new_throttle, uint256 timestamp);

    constructor() ERC20("HEX Combinator", "CHEX") ReentrancyGuard() {
        COMBINATOR_DAO_ADDRESS = msg.sender;
        if (block.chainid==1) {arbitrage_throttle=5800850000000000;} 
        else {arbitrage_throttle=100000*(10**18);} //set to be close to $10 USD at time of launch.
    }
    /// @notice Deposit HEX and bridged HEX on whichever network you are on to mint CHEX. 1 CHEX = 1 eHEX + 1 pHEX. You must grant this contract the appropriate approvals. Transaction must include the flat rate arbitrage throttle, paid in ETH or PLS.
    function mint(uint256 amount) external payable nonReentrant{
        require(msg.value == arbitrage_throttle, "Transaction must include the arbitrage throttle.");
        IERC20(HEX_ADDRESS).transferFrom(msg.sender, address(this), amount);
        IERC20(getAddress()).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount);
    }

    /// @notice Burn 1 CHEX and receive 1 eHEX and 1 pHEX
    function redeem(uint256 amount) public nonReentrant{
        _burn(msg.sender, amount);
        IERC20(HEX_ADDRESS).transfer(msg.sender, amount);
        IERC20(getAddress()).transfer(msg.sender, amount);
        emit Redeemed(msg.sender, amount);
    }
    /// @notice If you are on ethereum, returns the HEX bridged from Pulsechain address. If you are on PulseChain, returns the HEX bridged from Ethereum address.
    function getAddress() public view returns (address) {
        if (block.chainid==1) {return HEX_FROM_P_ADDRESS;}// if you are on ethereum, return HEX bridged from Pulsechain address  // if you are on pulsechain, return HEX bridged from Ethereum address
        else {return HEX_FROM_E_ADDRESS;}
        }
    /// @notice The Combinator DAO Address can schedule a change in the arbitrage throttle setting. After 24 hours, the change may go into effect. This is done entirely at the Combinator DAO's discretion.
    function scheduleArbitrageThrottleChange(uint256 arb_throttle) public nonReentrant{
        require(msg.sender==COMBINATOR_DAO_ADDRESS, "Only Combinator DAO Address can run this.");
        scheduled_arbitrage_throttle=arb_throttle;
        scheduled_arbitrage_throttle_change_timestamp = block.timestamp + 24 hours;
        emit ChangeScheduled(arbitrage_throttle, scheduled_arbitrage_throttle, scheduled_arbitrage_throttle_change_timestamp);
    }
    /// @notice Anyone can implement a previously scheduled arbitrage throttle setting once its eligible.
    function executeArbitrageThrottleChange() public nonReentrant{
        require(scheduled_arbitrage_throttle_change_timestamp>0, "An arbitrage throttle change must be scheduled");
        require(block.timestamp>scheduled_arbitrage_throttle_change_timestamp, "Not eligible to change yet."); 
        arbitrage_throttle=scheduled_arbitrage_throttle;
        scheduled_arbitrage_throttle_change_timestamp=0;
    }
    /// @notice The Combinator DAO Address can take posession of the ETH or PLS arbitrage throttle collected by the contract.
    function collectArbitrageThrottle() public nonReentrant {
        payable(COMBINATOR_DAO_ADDRESS).call{value: address(this).balance}(""); // send ETH or PLS to Combinator DAO
    }
    /// @notice The Combinator DAO Address can change the combinator DAO's own address.
    function changeCombinatorDaoAddress(address new_address) public nonReentrant{
        require(msg.sender==COMBINATOR_DAO_ADDRESS, "Only Combinator DAO Address can run this.");
        COMBINATOR_DAO_ADDRESS=new_address;
    }
    /// @notice Number of decimals in the contract, overwritten from the default of 18 to be 8 to match HEX.
    function decimals() public view virtual override returns (uint8) {
        return 8;
	}
    }