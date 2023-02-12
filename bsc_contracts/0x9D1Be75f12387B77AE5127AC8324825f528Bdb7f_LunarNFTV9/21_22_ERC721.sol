// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/** 
* @title An NFT Smart Contract
* @author Lunar Defi, Inc. Copyright © 2022. All rights reserved. 
* @notice This contract allows users to mint Lunar NFTs.
* @dev This contract is also upgradeable and contains private functions for depositing and validating Lunar NFT tokens can be minted.
*/
contract LunarNFT is Initializable, ERC721Upgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
  /*
  Includes
  */
  using CountersUpgradeable for CountersUpgradeable.Counter;

  /*
  Private Members
  */

  //Tracks the total number of tokens minted so far.
  CountersUpgradeable.Counter private tokenSupply;

  /*
  Public Members
  */

  /// Contract balances used by deposits functions
  mapping(address => uint256) public userBalances;

  /// Tracks the number of tokens minted per account
  mapping(address => uint256) public userAlreadyMinted;

  /// Max number of NFTs that can be minted
  uint256 public maxTokenMintable;  

  /// Individual price of each NFT
  uint256 public mintPrice;

  /// NFT URI pointing to metadata storage
  string public baseURI;

  //Tracks the current Mint State
  MintState public mintState;

  ///Custom Contract Roles
  /*
  Transaction Role 
  */
  bytes32 public constant TRANSACTION_ROLE = keccak256("TRANSACTION_ROLE");
  /*
  Liquidity Role 
  */
  bytes32 public constant LIQUIDITY_ROLE = keccak256("LIQUIDITY_ROLE");
 
  /*
  Contract Events
  */

  /**
  * @notice Triggered when a deposit has been completed for a given wallet address.
  * @dev Custom Event | DepositCompleted
  * @param fromAddress  - The wallet address from which the event comes from.
  * @param amount       - Amount being deposited to the contract.
  */
  event DepositCompleted(address indexed fromAddress, uint256 amount);

  /**
  * @notice Triggered when minting process is finished.
  * @dev Custom Event | MintCompleted
  * @param toAddress          - The wallet address from which the event comes from.
  * @param issuedTokenCount   - A integer representing the number of tokens that were airdropped.
  */
  event MintCompleted(address indexed toAddress, uint256 issuedTokenCount);

  /**
  * @notice Triggered when a refund is issued to a given wallet address.
  * @dev Custom Event | RefundCompleted
  * @param toAddress        - The wallet address from which the refund is being issued to.
  * @param updatedTimestamp - Timestamp to track when a refund is issued.
  */
  event RefundCompleted(address indexed toAddress, uint256 updatedTimestamp);

  /**
  * @notice Triggered when a token has been airdropped to the wallet address.
  * @dev Custom Event | TokenIssued
  * @param toAddress  - The wallet address from which the event comes from.
  * @param tokenId    - An integer representing the token that was airdropped.
  * @param success    - An boolean determining whether or not the token was airdropped.
  * @param message    - A string containing any potential error messages for this token.
  */
  event TokenIssued(address indexed toAddress, uint256 tokenId, bool success, string message);

  /**
  * @notice Triggered when the mint state has been modified.
  * @dev Custom Event | MintStateUpdated
  * @param mintState          - The State the MintState public member was updated to.
  * @param updatedTimestamp   - Timestamp to track when mint state changes.
  */
  event MintStateUpdated(MintState indexed mintState, uint256 updatedTimestamp);

    /**
  * @notice Triggered when an attempt to burn a token has been made.
  * @dev Custom Event | TokenBurned
  * @param tokenId      - An integer representing the token that was burned / recovered.
  * @param success      - An boolean determining whether or not the token was actually burned / recovered.
  * @param message      - A string containing any potential error messages for an attempted token burn.
  */
  event TokenBurned(uint256 indexed tokenId, bool success, string message);
  
  /**
  * @notice Triggered when burn process is finished.
  * @dev Custom Event | BurnCompleted
  * @param burnTokenCount - A integer representing the number of tokens that were burned.
  */
  event BurnCompleted(uint256 burnTokenCount);

  /*
  Enumerations 
  */

  /// DISABLED =  0,    Minting disabled
  /// PRIVATE =   1,    Only internal addresses can mint
  /// WHITELIST = 2,    Only whitelisted addresses can mint
  /// PUBLIC =    3,    Any wallet address can mint
  /// INTERNAL =  4,    Only restricted addresses can mint
  /// EXPANDED =  5,    Any wallet address can mint even more
  enum MintState 
  {
    DISABLED,
    PRIVATE,
    WHITELIST,
    PUBLIC,
    INTERNAL,
    EXPANDED
  }

  /*
  Deployer Role 
  */
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  
  /*
  Indicators
  */

  /// Checks if deposits are allowed or disallowed.
  bool public allowDeposits; 

  /*
  Contract Constructor
  */ 

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /** @notice replaces constructor for an upgradeable contract
    * @dev oz-contracts-upgrades are initialized here along with some private members.
    * @param _name                - Name of NFT
    * @param _symbol              - Symbol identifier for NFT contract
    * @param _maxTokenMintable    - Total amount of regular tokens this contract should mint
    * @param _mintPrice           - Individual price of each NFT.
    * @param _nonRevealURI        - URI Base for the NFTs image location
    * @param _adminAddress        - Default Admin Address
    * @param _transactionAddress  - Transferring liquidity out of the wallet
    * @param _liquidityAddress    - Executes backend functions
  */
  function initialize(
    string memory _name,
    string memory _symbol,
    uint256 _maxTokenMintable,
    uint256 _mintPrice,
    string memory _nonRevealURI,
    address _adminAddress,
    address _transactionAddress,
    address _liquidityAddress) public initializer
  {
    __ERC721_init(_name, _symbol);
    __Pausable_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();
    
    _grantRole(DEPLOYER_ROLE, msg.sender);
    _grantRole(DEFAULT_ADMIN_ROLE, _adminAddress);
    _grantRole(TRANSACTION_ROLE, _transactionAddress);
    _grantRole(LIQUIDITY_ROLE, _liquidityAddress);

    maxTokenMintable = _maxTokenMintable;
    mintPrice = _mintPrice;
    baseURI = _nonRevealURI;

    pause();
  }
  
  /*
  Public Functions
  */

  /*
  * Contract Standard Functions | The following code is required by the contract specification.
  */

  /**
  * @notice Upgrades the contract with a new implementation
  * @dev This function is called during upgrade by using OpenZepplin upgrade resources during deployment of new implementation 
  * @param newImplementation - The address of the new contract
  */
  function _authorizeUpgrade(address newImplementation)
    internal
    onlyAdminRoles
    override
  {
  }

  /**
  * @notice Shows the version of the contract being used
  * @dev The value represents the current version of the contract should be updated and overridden with new implementations
  * @return version - The current version of the contract
  */
  function version() external virtual pure returns(string memory)
  {
    return "1.0.0";
  }

  /**
  * @notice Displays to other contracts standards in which our contracts implements 
  * @dev ERC165 Implementation
  * @param interfaceId- interface to query for supported classes
  */
  function supportsInterface(bytes4 interfaceId)
       public
       view
       override(ERC721Upgradeable, AccessControlUpgradeable)
       returns (bool)
   {
       return super.supportsInterface(interfaceId);
   }

  /** @notice Generic Deposit function
    * @dev Deposits against the current contract and displayed publicly
  */
  function deposit() external payable whenNotPaused
  {
    require(allowDeposits, "Deposits are currently disabled.");
    require(msg.value > 0, "You must deposit an amount greater than 0.");
    userBalances[msg.sender] += msg.value;
    emit DepositCompleted(msg.sender, msg.value);
  }

  /**
  * @notice Withdraws all the BNB in contract
  * @dev Withdraws the user deposited funds in the contract
  * @param account - Account to withdraw the funds to
  */
  function withdrawFunds(address payable account) external whenNotPaused onlyRole(LIQUIDITY_ROLE)
  {
    (bool sent,) = account.call{ value: address(this).balance }("");
    require(sent, "We were unable to complete a withdrawl at this time.");
  }

  /**
  * @notice Updates the NFT Base URI
  * @dev Changes the metadata path URI
  */
  function setBaseURI(string memory _uri) external whenNotPaused onlyPlexusRoles
  {
    baseURI = _uri;
  }

  /** 
  * @notice Mints the provided number of Tokens (parameter) to a beneficiary account. 
  * @dev Mints one token at a time.
  * @param to       - The receiver of the token(s) to be minted
  * @param tokenIds - Array of tokens to be minted when this function is invoked.
  */
  function plexusMint(address to, uint256[] memory tokenIds) external whenNotPaused onlyPlexusRoles
  {
    //Check if minting is possible
    _canMint();

    //Private Members
    uint256 tokensMinted = 0; 
    string memory mintingErrorMessage;
    bool mintResult = false;
  
    for (uint256 i = 0; i < tokenIds.length; i++)
    {
      //Setup can user mint members
      bool canUserResult = false;
      string memory canUserMessage;

      //Setup mint result members
      string memory mintResultMessage;

      //SHEPARD: Skips validation when the Admin wallet is minting. 
      if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
      {
        //Check if user can conduct minting
        (canUserResult, canUserMessage) = _canUserMintToken(to);

        if (!canUserResult)
        {
          emit TokenIssued(to, tokenIds[i], canUserResult, canUserMessage);
          mintingErrorMessage = canUserMessage;
          mintResult = false;
          //exit loop if canUserMint result has failed
          break;
        }
                
        //Subtract cost of a single token. 
        userBalances[to] = userBalances[to] - mintPrice;
      }
      
      // Mint the token
      (mintResult, mintResultMessage) = _mintInternal(to, tokenIds[i]);

      if (!mintResult) 
      {
        emit TokenIssued(to, tokenIds[i], mintResult, mintResultMessage);
        mintingErrorMessage = mintResultMessage;
        continue;
      }
 
      tokensMinted++;
      emit TokenIssued(to, tokenIds[i], mintResult, mintResultMessage);
    }

    //SHEPARD: Check if tokens were minted, if tokens minted is less than what was passed, supply has been reached. Only then should we refund the deposited amount.
    if (tokensMinted > 0 && tokensMinted < tokenIds.length && tokenSupply.current() >= maxTokenMintable)
    {
      refundTokens(tokenIds.length, tokensMinted, to); 
    }

    //SHEPARD: If we couldn’t mint any NFTs, tell them why.
    require(tokensMinted > 0, mintingErrorMessage);

    emit MintCompleted(to, tokensMinted);
  }

  /**
  * @notice Returns the total number of NFTs that have been minted.
  * @return totalSupply - Total number of NFTs minted
  */
  function totalSupply() external view returns(uint256)
  {
    return tokenSupply.current();
  }

  /**
  * @notice Updates the mint state based on the passed MintState Enum value.
  * @param newMintState - MintState enumeration values (0-5).
  * @dev only DEFAULT_ADMIN_ROLE and TRANSACTION_ROLE can call method
  */
  function updateMintState(MintState newMintState) external whenNotPaused onlyPlexusRoles
  {
    mintState = newMintState;
    emit MintStateUpdated(mintState, block.timestamp);
  }

  /*
  Private Functions
  */

  /** 
  * @notice System wide check to see if minting can occur against the contract. 
  * @dev Private check
  */
  function _canMint() internal view
  {
    //Check if system-wide minting is enabled.
    require(mintState > MintState.DISABLED, "Minting is currently disabled.");
    //Check if the current tokenSupply is less than the max number of tokens that can be mined.
    require(tokenSupply.current() < maxTokenMintable, "We're sorry, but there are no more NFTs available to be minted.");
  }

  /**
  * @notice Checks if a given address can mint against the contract.
  * @dev Uses several different conditions to determine if minting is possible based on user Balance and already minted NFT limits.
  * @param to       - The wallet address attempting to mint. 
  * @return success - Boolean flag to check if a mint can occur.
  * @return message - Empty if successful, otherwise contains a detailed response describing the failure.
  */
  function _canUserMintToken(address to) internal view returns(bool success, string memory message)
  {
    //SHEPARD: Check if the user has a balance to mint one (1) token.
    uint256 _mintingCost = mintPrice * 1;
    if (userBalances[to] < _mintingCost)
    {
      return (false, "Wallet deposit balance is insufficient to complete the requested transaction.");
    }
    
    //SHEPARD: Check if user has not exceeded the allowed amount based on the mint state for all limited minting MintStates.
    // DISABLED = 0, PRIVATE =   1, WHITELIST = 2, PUBLIC = 3, INTERNAL =  4, EXPANDED = 5
    if (mintState == MintState.WHITELIST)
    {
      if (userAlreadyMinted[to] >= 3)
      {
        return (false, "The specified wallet has already minted the maximum number of NFTs allowed for the pre-sale.");
      }
    }
    else if (mintState == MintState.PUBLIC || mintState == MintState.PRIVATE)
    {
      if (userAlreadyMinted[to] >= 5)
      {
        //SHEPARD: Both Public and Private MintStates have the same mint limit threshold but must produce different info messages.
        if(mintState == MintState.PUBLIC)
          return (false, "The specified wallet has already minted the maximum number of NFTs allowed for the public sale.");
        else
          return (false, "The specified wallet has already minted the maximum number of NFTs allowed for the private sale.");
      }
    }
    else if (mintState == MintState.EXPANDED)
    {
      if (userAlreadyMinted[to] >= 10)
      {
          return (false, "The specified wallet has already minted the maximum number of NFTs allowed for the expanded sale.");
      }
    }

    //SHEPARD: Check if the token supply still exists
    if (tokenSupply.current() >= maxTokenMintable)
    {
      return (false, "Congratulations, you lucky bastard! You got the last one.");
    }
    
    //User can mint the token.
    return (true, "");
  }

  /**
   * @notice Conducts a mint for a given token (tokenId) for a given account.
   * @dev Our admin role will skip the array update for the userAlreadyMinted tracker.
   * @param to      - Account where the NFT will be minted to.
   * @param tokenId - Token Id to Mint.
   */
  function _mintInternal(address to, uint256 tokenId) private returns (bool success, string memory message) 
  {
    try this.mintHelper(to, tokenId) {
      tokenSupply.increment();
      if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
      {
        userAlreadyMinted[to] += 1;
      }
      return (true, "Success!");
    } catch Error(string memory reason) {
      return (false, reason);
    }
  }

  /**
  * @notice Calls the internal function {_safeMint} that cannot be called within this contract with a low-level call.
  * @param to       - Account where the NFT will be minted to.
  * @param tokenId  - Token Id to Mint.
  */
  function mintHelper(address to, uint256 tokenId) external
  {
    //validating only contract can make this interaction
    require(msg.sender == address(this), "The specified wallet is not allowed to execute this function.");
    _safeMint(to, tokenId);
  }

  /**
  * @notice Calculates the total to be refunded and emits the RefundCompleted event.
  * @param tokensRequested  - Total tokens originally requested.
  * @param tokensMinted     - Total tokens Minted.
  * @param toAddress        - Account where the refund will be issued to.
  */
  function refundTokens(uint256 tokensRequested, uint256 tokensMinted, address toAddress) private
  {
    //SHEPARD: Calculate the difference to refund.
    uint256 tokensToRefund = tokensRequested - tokensMinted;

    if(tokensToRefund > 0)
    {
      //SHEPARD: Calculate the refund total value
      uint256 refundValue = tokensToRefund * mintPrice;
      
      //CYPHER: deduct the amount to refund user
      userBalances[toAddress] = userBalances[toAddress] - refundValue;

      //SHEPARD: Issue the refund and emit the Refund event.
      payable(toAddress).transfer(refundValue);
      emit RefundCompleted(toAddress, block.timestamp);
    }
  }

  /**
  * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
  *      token will be the concatenation of the `baseURI` and the `tokenId`
  *      (but without '.json' in it).
  */
  function _baseURI() internal view override returns (string memory)
  {
    return baseURI;
  }

  /** 
   * @notice Disables execution of public contract functions.
   * @dev Pausing the contract also disables deposits so that when you unpause the contract
   *      you must explicitly choose to re-enable deposits to allow Plexus to clear its backlog.
   */
  function pause() public onlySystemRoles
  {
    allowDeposits = false;
    _pause();
  }

  /**
   *@notice Enables execution of public contract functions.
  */
  function unpause() public onlySystemRoles
  {
    _unpause();
  }
  
  /**
  *@notice This intercepts calls to the OpenZeppelin transferFrom call to ensure transfers aren't executed when the contract is paused.
  */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
  
  /*
  Lunar Standard Roles
  */

  /**
  * @dev Modifier to ensure that only Plexus(TM) roles can make function calls.
  */
  modifier onlyPlexusRoles() 
  {
    //SHEPARD: Check if sender has the correct role.
    require(hasRole(TRANSACTION_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "The specified wallet is not allowed to execute this function.");
    //SHEPARD: This line matters for modifiers, don't take it out!
    _;
  }

  /**
  * @dev Modifier to ensure that only System roles can make function calls.
  */
  modifier onlySystemRoles() 
  {
    //SHEPARD: Check if sender has the correct role.
    require(hasRole(DEPLOYER_ROLE, msg.sender) || hasRole(TRANSACTION_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "The specified wallet is not allowed to execute this function.");
    //SHEPARD: This line matters for modifiers, don't take it out!
    _;
  }

  /**
  * @dev Modifier to ensure that only administrative roles can make function calls.
  */
  modifier onlyAdminRoles() 
  {
    //SHEPARD: Check if sender has the correct role.
    require(hasRole(DEPLOYER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "The specified wallet is not allowed to execute this function.");
    //SHEPARD: This line matters for modifiers, don't take it out!
    _;
  }

  /*
  Expanded Functionality
  */

  /**
  * @notice Updates the maxTokenMintable value based on the passed parameter.
  * @dev We have validation to prevent the maxSupply value from being too low or from exceeding Lunar per-chain limit.
  * @param maxSupply - A uint256 that is greater than the current supply and less than the Lunar per-chain limit.
   */
  function setMaxSupply(uint256 maxSupply) external whenNotPaused onlyPlexusRoles
  {
    require(maxSupply > tokenSupply.current() && maxSupply < 8889, "The specified maxSupply must be greater than zero (0) and also greater than the number of tokens already issued.");
    maxTokenMintable = maxSupply;
  }

  /** 
  * @notice Burns the provided number of Tokens (parameter), sending tokens to an empty (0) account. 
  * @dev Burns one token at a time, iterating through the array of tokenIds.
  * @param tokenIds - Array of tokens to be burned when this function is invoked.
  */
  function plexusBurn(uint256[] memory tokenIds) external whenNotPaused onlyPlexusRoles
  {
    //Private Members
    uint256 tokensBurned = 0; 
    bool burnResult = false;
    string memory burnErrorMessage;
  
    for (uint256 i = 0; i < tokenIds.length; i++)
    {
      //Setup canBurn variables
      bool canBurnResult = false;
      string memory canBurnResultMsg;
      address burnTokenOwner;

      //Setup burnResult message
      string memory burnResultMessage;
      
      //Check if the token exists and return results
      (canBurnResult, canBurnResultMsg, burnTokenOwner) = _canBurnToken(tokenIds[i]);

      if(!canBurnResult)
      {
        emit TokenBurned(tokenIds[i], canBurnResult, canBurnResultMsg);
        burnErrorMessage = canBurnResultMsg;
        burnResult = false;
        continue;
      }

      //Burn token using internal method with try/catch enabled.
      (burnResult, burnResultMessage) = _burnInternal(burnTokenOwner, tokenIds[i]);

      if (!burnResult) 
      {
        emit TokenBurned(tokenIds[i], burnResult, burnResultMessage);
        burnErrorMessage = burnResultMessage;
        continue;
      }

      tokensBurned++;
      emit TokenBurned(tokenIds[i], burnResult, burnResultMessage);
    }

    //SHEPARD: If we couldn’t mint any NFTs, tell them why.
    require(tokensBurned > 0, burnErrorMessage);

    emit BurnCompleted(tokensBurned);
  }

  /**
  * @notice Conducts a burn for a given token (tokenId) from the total supply of tokens.
  * @dev This function includes a try/catch pattern to prevent reverts when {_burn} fails.
  * @param tokenId - Token Id to Burn.
  */
  function _burnInternal(address from, uint256 tokenId) private returns (bool success, string memory message) 
  {
    try this.burnHelper(tokenId) {
      // SHEPARD: Decrease tokenSupply and check if the current token's owner has entry under the 
      //          userAlreadyMinted array. If so, then reduce the userAlreadyMinted by one token.
      tokenSupply.decrement();
      if (userAlreadyMinted[from] > 0)
      {
        userAlreadyMinted[from] -= 1;
      }
      return (true, "Success!");
    } catch Error(string memory reason) {
      return (false, reason);
    }
  }

  /**
  * @notice Calls the internal function {_burn} that cannot be called within this contract with a low level call.
  * @param tokenId  - Token Id to Burn.
  */
  function burnHelper(uint256 tokenId) external
  {
    //validating only contract can make this interaction
    require(msg.sender == address(this), "The specified wallet is not allowed to execute this function.");
    _burn(tokenId);
  }

  /**
  * @notice Checks if a given token exsits and returns a boolean and an address if the burn can occur against the contract.
  * @dev Uses _exists and ownerOf from the base classes to determine if burning is possible.
  * @param tokenId        - Token Id for the token being checked. 
  * @return tokenExists   - Boolean flag to check if a burn can occur.
  * @return message       - Empty if successful, otherwise contains a detailed response describing the failure.
  * @return ownerAddress  - Address of the token owner or a zero account if no token exists.
  */
  function _canBurnToken(uint256 tokenId) internal view returns(bool tokenExists, string memory message, address ownerAddress)
  {
    //Check if the token exists prior to attempting to get the owner
    if(!ERC721Upgradeable._exists(tokenId))
    {
      return (false, "The specified tokenId is invalid and can not be burned.", address(0));
    }

    //If the token exists, return the token owner and the results.
    address tokenOwner = ERC721Upgradeable.ownerOf(tokenId);
    return (true, "", tokenOwner);
  }

  /**
  * @notice Updates the deposit flag based on the boolean value being passed.
  * @param newDepositFlag  - boolean value determining if deposits are allowed or disallowed.
  * @dev only DEFAULT_ADMIN_ROLE and TRANSACTION_ROLE can call method
  */
  function updateAllowDeposits(bool newDepositFlag) external whenNotPaused onlyPlexusRoles
  {
    allowDeposits = newDepositFlag;
  }
  
  /**
  * @notice Temporary Functionality | Decrements the available tokenSuply by a specified amount.
  * @dev Utilizes a for loop to achieve desired outcome.
  * @param amountToDecrement - A uint256 that represents the value the totalSupply should be decremented by.
  */
  function decrementTotalSupply(uint256 amountToDecrement) external whenNotPaused onlyPlexusRoles
  {
    // SHEPARD: Fall early and don't decrement when too low or too high of a decrement would occurr.
    require(amountToDecrement > 0 && amountToDecrement <= maxTokenMintable, "Decrement value must be greater than zero and less than mintable tokens.");
    
    // SHEPARD: Loop through the number of requested decrement calls.
    for (uint256 i = 0; i < amountToDecrement; i++)
    {
      tokenSupply.decrement();
    }
  }
}