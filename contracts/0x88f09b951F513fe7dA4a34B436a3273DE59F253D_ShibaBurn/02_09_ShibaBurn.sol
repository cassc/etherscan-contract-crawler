pragma solidity >=0.8.9 <0.9.0;
//SPDX-License-Identifier: MIT

import "../node_modules/@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

import "./ISwapper.sol";
import "./XToken.sol";



/*
  Hello and welcome to the ShibaBurn burning portal.
    This is a contract that empowers developers to
    create incentive based deflation for all ERC20 tokens!

  ShibaBurn allows for an infinite number of burn pools
  to be created for any given token. By default, burn pools track the following data:
    - total tokens burnt by each user
    - total tokens burnt by all users

  ShibaBurn also allows for ETH to be "zapped" into burn pool ownershib by means of
  buying the specified token on ShibaSwap, and burning it in one transaction. This
  is only possible if eth-token liquidity is present on ShibaSwap.com


  If configured by the ShibaBurn owner wallet, burn pools can optionally:
    - Mint xTokens for users (e.g. burntSHIB in the case of burning SHIB to the default pool)
    - Keep track of the index at which any given address exceeds a burnt amount beyond an admin specified threshold

          _____                    _____                    _____                    _____                    _____          
         /\    \                  /\    \                  /\    \                  /\    \                  /\    \         
        /::\    \                /::\____\                /::\    \                /::\    \                /::\    \        
       /::::\    \              /:::/    /                \:::\    \              /::::\    \              /::::\    \       
      /::::::\    \            /:::/    /                  \:::\    \            /::::::\    \            /::::::\    \      
     /:::/\:::\    \          /:::/    /                    \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
    /:::/__\:::\    \        /:::/____/                      \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
    \:::\   \:::\    \      /::::\    \                      /::::\    \      /::::\   \:::\    \      /::::\   \:::\    \   
  ___\:::\   \:::\    \    /::::::\    \   _____    ____    /::::::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \  
 /\   \:::\   \:::\    \  /:::/\:::\    \ /\    \  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\ ___\  /:::/\:::\   \:::\    \ 
/::\   \:::\   \:::\____\/:::/  \:::\    /::\____\/::\   \/:::/  \:::\____\/:::/__\:::\   \:::|    |/:::/  \:::\   \:::\____\
\:::\   \:::\   \::/    /\::/    \:::\  /:::/    /\:::\  /:::/    \::/    /\:::\   \:::\  /:::|____|\::/    \:::\  /:::/    /
 \:::\   \:::\   \/____/  \/____/ \:::\/:::/    /  \:::\/:::/    / \/____/  \:::\   \:::\/:::/    /  \/____/ \:::\/:::/    / 
  \:::\   \:::\    \               \::::::/    /    \::::::/    /            \:::\   \::::::/    /            \::::::/    /  
   \:::\   \:::\____\               \::::/    /      \::::/____/              \:::\   \::::/    /              \::::/    /   
    \:::\  /:::/    /               /:::/    /        \:::\    \               \:::\  /:::/    /               /:::/    /    
     \:::\/:::/    /               /:::/    /          \:::\    \               \:::\/:::/    /               /:::/    /     
      \::::::/    /               /:::/    /            \:::\    \               \::::::/    /               /:::/    /      
       \::::/    /               /:::/    /              \:::\____\               \::::/    /               /:::/    /       
        \::/    /                \::/    /                \::/    /                \::/____/                \::/    /        
         \/____/                  \/____/                  \/____/                  ~~                       \/____/         
                                                                                                                             
                          _____                    _____                    _____                    _____                   
                         /\    \                  /\    \                  /\    \                  /\    \                  
                        /::\    \                /::\____\                /::\    \                /::\____\                 
                       /::::\    \              /:::/    /               /::::\    \              /::::|   |                 
                      /::::::\    \            /:::/    /               /::::::\    \            /:::::|   |                 
                     /:::/\:::\    \          /:::/    /               /:::/\:::\    \          /::::::|   |                 
                    /:::/__\:::\    \        /:::/    /               /:::/__\:::\    \        /:::/|::|   |                 
                   /::::\   \:::\    \      /:::/    /               /::::\   \:::\    \      /:::/ |::|   |                 
                  /::::::\   \:::\    \    /:::/    /      _____    /::::::\   \:::\    \    /:::/  |::|   | _____           
                 /:::/\:::\   \:::\ ___\  /:::/____/      /\    \  /:::/\:::\   \:::\____\  /:::/   |::|   |/\    \          
                /:::/__\:::\   \:::|    ||:::|    /      /::\____\/:::/  \:::\   \:::|    |/:: /    |::|   /::\____\         
                \:::\   \:::\  /:::|____||:::|____\     /:::/    /\::/   |::::\  /:::|____|\::/    /|::|  /:::/    /         
                 \:::\   \:::\/:::/    /  \:::\    \   /:::/    /  \/____|:::::\/:::/    /  \/____/ |::| /:::/    /          
                  \:::\   \::::::/    /    \:::\    \ /:::/    /         |:::::::::/    /           |::|/:::/    /           
                   \:::\   \::::/    /      \:::\    /:::/    /          |::|\::::/    /            |::::::/    /            
                    \:::\  /:::/    /        \:::\__/:::/    /           |::| \::/____/             |:::::/    /             
                     \:::\/:::/    /          \::::::::/    /            |::|  ~|                   |::::/    /              
                      \::::::/    /            \::::::/    /             |::|   |                   /:::/    /               
                       \::::/    /              \::::/    /              \::|   |                  /:::/    /                
                        \::/____/                \::/____/                \:|   |                  \::/    /                 
                         ~~                       ~~                       \|___|                   \/____/                  
                                                                                                                             




*/



contract ShibaBurn is Ownable {

  // ShibaSwap router:
  ISwapper public router = ISwapper(0x03f7724180AA6b939894B5Ca4314783B0b36b329);

  // Ledgendary burn address that holds tokens burnt of the SHIB ecosystem:
  address public burnAddress = 0xdEAD000000000000000042069420694206942069;
  address public wethAddress;

  // Addresses of SHIB ecosystem tokens:
  address public shibAddress = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
  address public boneAddress = 0x9813037ee2218799597d83D4a5B6F3b6778218d9;
  address public leashAddress = 0x27C70Cd1946795B66be9d954418546998b546634;
  address public ryoshiAddress = 0x777E2ae845272a2F540ebf6a3D03734A5a8f618e;

  event Burn(address sender, uint256 time, address tokenAddress, uint256 poolIndex, uint256 amount);


  bool locked;
  modifier noReentrancy() {
    require(!locked,"Reentrant call");
    locked = true;
    _;
    locked = false;
  }

  //////////////
  // BURN POOLS:
  //////////////
  //
  // xTokens[tokenAddress][poolIndex]
  //   => address of pool's xToken
  mapping(address => mapping(uint256 => address)) public xTokens;

  // totalBurnt[tokenAddress][poolIndex]
  //   => total amount burnt for specified pool
  mapping(address => mapping(uint256 => uint256)) public totalBurnt;

  // totalTrackedBurners[tokenAddress][poolIndex]
  //    => total number of burners that have exceeded the trackBurnerIndexThreshold
  mapping(address => mapping(uint256 => uint256)) public totalTrackedBurners;

  // trackBurnerIndexThreshold[tokenAddress][poolIndex]
  //    => the burn threshold required to track user burn indexes of a specific pool
  mapping(address => mapping(uint256 => uint256)) public trackBurnerIndexThreshold;

  // burnerIndex[tokenAddress][poolIndex][userAddress]
  //    => the index at which a user exceeded the trackBurnerIndexThreshold for a specific pool
  mapping(address => mapping(uint256 => mapping(address => uint256))) public burnerIndex;


  // burnerIndex[tokenAddress][poolIndex][burnerIndex]
  //    => the address of the a specified tracked burner at a specified index
  mapping(address => mapping(uint256 => mapping(uint256 => address))) public burnersByIndex;

  // amountBurnt[tokenAddress][poolIndex][userAddress]
  //   => amount burnt by a specific user for a specified pool
  mapping(address => mapping(uint256 => mapping(address => uint256))) public amountBurnt;

  constructor(address _wethAddress) Ownable() {
    wethAddress = _wethAddress;
  }

 /** 
   * @notice Intended to be used for web3 interface, such that all data can be pulled at once
   * @param tokenAddress The address of the token for which the query will be made
   * @param currentUser The address used to query user-based pool info and ethereum balance
   * @return burnPool info for the default pool (0) of the specified token
	*/
  function getInfo(address currentUser, address tokenAddress) external view returns (uint256[] memory) {
    return getInfoForPool(0, currentUser, tokenAddress);
  }

  /**
   * @notice Intended to be used for web3 interface, such that all data can be pulled at once
   * @param poolIndex The index of which token-specific burn pool to be used
   * @param tokenAddress The address of the token for which the query will be made
   * @param currentUser The address used to query user-based pool info and ethereum balance
   *
   * @return burnPool info for the specified pool of the specified token as an  array of 11 integers indicating the following:
   *     (0) Number of decimals of the token associated with the tokenAddress
   *     (1) Total amount burnt for the specified burn-pool
   *     (2) Total amount burnt by the specified currentUser for the specified burn-pool
   *     (3) The amount of specified tokens in possession by the specified currentUser
   *     (4) The amount of eth in the wallet of the specified currentUser
   *     (5) The amount of specified tokens allowed to be burnt by this contract
   *     (6) The threshold of tokens needed to be burnt to track the index of a user for the specified pool (if zero, no indexes will be tracked)
   *     (7) Burn index of the current user with regards to a specified pool (only tracked if admin configured, and burn meets threshold requirements)
   *     (8) Total number of burners above the specified threshold for the specific pool
   *     (9) Decimal integer representation of the address of the 'xToken' of the specified pool
   *     (10) Total supply of the xToken associated with the specified pool
   *     (11) Specified pool's xToken balance of currentUser
  */
  function getInfoForPool(uint256 poolIndex, address currentUser, address tokenAddress) public view returns (uint256[] memory) {
    uint256[] memory info = new uint256[](12);
    IERC20Metadata token = IERC20Metadata(tokenAddress);
    info[0] = token.decimals();
    info[1] = totalBurnt[tokenAddress][poolIndex];
    info[2] = amountBurnt[tokenAddress][poolIndex][currentUser];
    info[3] = token.balanceOf(currentUser);
    info[4] = currentUser.balance;
    info[5] = token.allowance(currentUser, address(this));

    if (trackBurnerIndexThreshold[tokenAddress][poolIndex] != 0) {
			info[6] = trackBurnerIndexThreshold[tokenAddress][poolIndex];
			info[7] = burnerIndex[tokenAddress][poolIndex][currentUser];
			info[8] = totalTrackedBurners[tokenAddress][poolIndex];
		}

    if (xTokens[tokenAddress][poolIndex] != address(0)) {
      IERC20Metadata xToken = IERC20Metadata(xTokens[tokenAddress][poolIndex]);
      info[9] = uint256(uint160(address(xToken)));
      info[10] = xToken.totalSupply();
      info[11] = xToken.balanceOf(currentUser);
    }

    return info;
  }

  /**
   * @notice Intended to be used for web3 such that all necessary data can be requested at once
   * @param tokenAddress The address of the token to buy on shibaswap.
   * @return Name and Symbol metadata of specified ERC20 token.
  */
  function getTokenInfo(address tokenAddress) external view returns (string[] memory) {
    string[] memory info = new string[](2);
    IERC20Metadata token = IERC20Metadata(tokenAddress);
    info[0] = token.name();
    info[1] = token.symbol();

    return info;
  }

  /**
   * @param tokenAddress The address of the token to buy on shibaswap.
   * @param minOut specifies the minimum number of tokens to be burnt when buying (to prevent front-runner attacks)
   *
   * @notice Allows users to buy tokens (with ETH on ShibaSwap) and burn them in 1 tx for the
   *     "default" burn pool for the specified token. Based on the admin configuration of each pool,
   *     xTokens may be issued, and/or the burner's index will be tracked.
  */
  function buyAndBurn(address tokenAddress, uint256 minOut) external payable {
    buyAndBurnForPool(tokenAddress, minOut, 0);
  }

  /**
   * @param tokenAddress The address of the token intended to be burnt.
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param threshold the minimum amount of tokens required to be burnt for the burner's index to be tracked
   *
   * @dev This can only be set on pools with no burns
   * @notice Allows the admin address to mark a specific pool as tracking "indexes" of burns above a specific threshold.
   *     This allows for projects to reward users based on how early they burned more than the specified amount.
   *     Setting this threshold will cause each burn to require more gas.
  */
  function trackIndexesForPool(address tokenAddress, uint256 poolIndex, uint256 threshold) public onlyOwner {
    require (totalBurnt[tokenAddress][poolIndex] == 0, "tracking indexes can only be turned on for pools with no burns");
    trackBurnerIndexThreshold[tokenAddress][poolIndex] = threshold;
  }

  /**
   * @param tokenAddress The address of the token intended to be burnt.
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param xTokenAddress the address of the xToken that will be minted in exchange for burning
   *
   * @notice Allows the admin address to set an xToken address for a specific pool.
   * @dev It is required for this contract to have permission to mint the xToken
  */
  function setXTokenForPool(address tokenAddress, uint256 poolIndex, address xTokenAddress) public onlyOwner {
    require (totalBurnt[tokenAddress][poolIndex] == 0, "xToken can only be set on pools with no burns");
    xTokens[tokenAddress][poolIndex] = xTokenAddress;
  }

  /**
   * @notice Allows users to buy tokens (with ETH on ShibaSwap) and burn them in 1 tx.
   *         Based on the admin configuration of each pool, xTokens may be issued,
   *         and the burner's index will be tracked.
   *
   * @dev uses hard coded shibaswap router address
   *
   * @param tokenAddress The address of the token to buy on shibaswap.
   * @param minOut specifies the minimum number of tokens to be burnt when buying (to prevent front-runner attacks)
   * @param poolIndex the index of which token-specific burn pool to be used
   *
  */
  function buyAndBurnForPool(address tokenAddress, uint256 minOut, uint256 poolIndex) public payable noReentrancy {
    address[] memory ethPath = new address[](2);
    ethPath[0] = wethAddress; // WETH
    ethPath[1] = tokenAddress;
    IERC20Metadata token = IERC20Metadata(tokenAddress);

    uint256 balanceWas = token.balanceOf(burnAddress);
    router.swapExactETHForTokens{ value: msg.value }(minOut, ethPath, burnAddress, block.timestamp + 1000);
    uint256 amount = token.balanceOf(burnAddress) - balanceWas;

    _increaseOwnership(tokenAddress, poolIndex, amount);
  }

  /**
   * @dev internal method
   * @param tokenAddress The address of the token intended to be burnt.
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param amount the amount of tokens intended to be burnt
   *
   * @return boolean value which indicates whether or not the burner's burn index should be tracked for the current transaction.
  */
  function shouldTrackIndex(address tokenAddress, uint256 poolIndex, uint256 amount) internal returns (bool) {
    uint256 threshold = trackBurnerIndexThreshold[tokenAddress][poolIndex];
    uint256 alreadyBurnt = amountBurnt[tokenAddress][poolIndex][msg.sender];
    return threshold != 0 &&
      alreadyBurnt < threshold &&
      alreadyBurnt + amount >= threshold;
  }

  /**
   * @notice increases ownership of specified pool.
   * @dev tracks the user's burn Index if configured
   * @dev mints xTokens for the user if configured
   * @dev internal method
   * @param tokenAddress The address of the token intended to be burnt.
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param amount of tokens intended to be burnt
   *
  */
  function _increaseOwnership(address tokenAddress, uint256 poolIndex, uint256 amount) internal {
    if (shouldTrackIndex(tokenAddress, poolIndex, amount)) {
      burnerIndex[tokenAddress][poolIndex][msg.sender] = totalTrackedBurners[tokenAddress][poolIndex];
      burnersByIndex[tokenAddress][poolIndex][totalTrackedBurners[tokenAddress][poolIndex]] = msg.sender;
      totalTrackedBurners[tokenAddress][poolIndex] += 1;
    }

    if (xTokens[tokenAddress][poolIndex] != address(0))
      XToken(xTokens[tokenAddress][poolIndex]).mint(msg.sender, amount);

    amountBurnt[tokenAddress][poolIndex][msg.sender] = amountBurnt[tokenAddress][poolIndex][msg.sender] + amount;
    totalBurnt[tokenAddress][poolIndex] += amount;
    emit Burn(msg.sender, block.timestamp, tokenAddress, poolIndex, amount);
  }

  /**
   * @notice Burns SHIB to the default SHIB pool
   * @param amount the amount of SHIB to be burnt 
  */
  function burnShib(uint256 amount) external {
    burnToken(shibAddress, amount);
  }

  /**
   * @notice Burns RYOSHI to the default RYOSHI pool
   * @param amount the amount of RYOSHI to be burnt 
  */
  function burnRyoshi(uint256 amount) external {
    burnToken(ryoshiAddress, amount);
  }

  /**
   * @notice Burns LEASH to the default LEASH pool
   * @param amount the amount of LEASH to be burnt 
   *
  */
  function burnLeash(uint256 amount) external {
    burnToken(leashAddress, amount);
  }

  /**
   * @notice Burns BONE to the default BONE pool
   * @param amount the amount of BONE to be burnt 
   *
  */
  function burnBone(uint256 amount) external {
    burnToken(boneAddress, amount);
  }

  /**
   * @notice Burns any token to the default (0) pool for that token
   * @param tokenAddress the address of the token intended to be burnt
   * @param amount the amount of tokens to be burnt 
   *
  */
  function burnToken(address tokenAddress, uint256 amount) public {
    burnTokenForPool(tokenAddress, 0, amount);
  }

  /**
   * @notice Burns any token to the specified pool for that token
   * @param tokenAddress the address of the token intended to be burnt
   * @param poolIndex the index of which token-specific burn pool to be used
   * @param amount the amount of tokens to be burnt 
   *
  */
  function burnTokenForPool(address tokenAddress, uint256 poolIndex, uint256 amount) public noReentrancy {
    IERC20Metadata token = IERC20Metadata(tokenAddress);
    require (token.balanceOf(msg.sender) >= amount, "insufficient token balance");

    token.transferFrom(msg.sender, burnAddress, amount);
    _increaseOwnership(tokenAddress, poolIndex, amount);
  }

}