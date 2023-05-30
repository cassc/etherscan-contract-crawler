// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {IJBToken as IJBTokenV2} from '@jbx-protocol-v2/contracts/interfaces/IJBToken.sol';
import {IJBToken as IJBTokenV3} from '@jbx-protocol-v3/contracts/interfaces/IJBToken.sol';
import {IJBController} from '@jbx-protocol-v2/contracts/interfaces/IJBController.sol';
import {IJBTokenStore} from '@jbx-protocol-v2/contracts/interfaces/IJBTokenStore.sol';
import {ITicketBooth, ITickets} from '@jbx-protocol-v1/contracts/interfaces/ITicketBooth.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

/** 
  @notice
  An ERC-20 token that can be used by a project in the `JBTokenStore` & also this takes care of the migration of the V1 & V2 project tokens for V3.

  @dev
  Adheres to -
  IJBTokenV3: Allows this contract to be used by projects in the JBTokenStore.

  @dev
  Inherits from -
  ERC20Permit: General ERC20 token standard for allowing approvals to be made via signatures,. 
  Ownable: Includes convenience functionality for checking a message sender's permissions before executing certain transactions.
*/
contract JBV3Token is ERC20Permit, Ownable, ReentrancyGuard, IJBTokenV3 {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error BAD_PROJECT();

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice
    The ID of the project that this token should be exclusively used for.  
  */
  uint256 public immutable override projectId;

  /** 
    @notice
    The V1 Token Booth instance. 
  */
  ITicketBooth public immutable v1TicketBooth;

  /** 
    @notice
    The V2 Token Store instance. 
  */
  IJBTokenStore public immutable v2TokenStore;

  /** 
    @notice
    Storing the v1 project ID to migrate to the v3 project ID. 
  */
  uint256 public immutable v1ProjectId;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice
    The total supply of this ERC20.

    @dev
    Includes the V3 token balance as well as unmigrated V1 and V2 balances.

    @param _projectId the ID of the project to which the token belongs. This is ignored.

    @return The total supply of this ERC20, as a fixed point number.
  */
  function totalSupply(uint256 _projectId) external view override returns (uint256) {
    _projectId; // Prevents unused var compiler and natspec complaints.

    return totalSupply();
  }

  /** 
    @notice
    The total supply of this ERC20.

    @dev
    Includes the V3 token balance as well as unmigrated V1 and V2 balances.

    @return The total supply of this ERC20, as a fixed point number.
  */
  function totalSupply() public view override returns (uint256) {
    uint256 _nonMigratedSupply;

    // If a V1 token is set get the remaining non-migrated supply.
    if(v1ProjectId != 0 && address(v1TicketBooth) != address(0)) {
      _nonMigratedSupply = v1TicketBooth.totalSupplyOf(v1ProjectId)
        - v1TicketBooth.balanceOf(address(this), v1ProjectId);
    }

    if (address(v2TokenStore) != address(0)) {
      _nonMigratedSupply += v2TokenStore.totalSupplyOf(projectId) -
        v2TokenStore.balanceOf(address(this), projectId);
    }

    return
      super.totalSupply() +
      _nonMigratedSupply;
  }

  /** 
    @notice
    An account's balance of this ERC20.

    @param _account The account to get a balance of.
    @param _projectId is the ID of the project to which the token belongs. This is ignored.

    @return The balance of the `_account` of this ERC20, as a fixed point number with 18 decimals.
  */
  function balanceOf(address _account, uint256 _projectId)
    external
    view
    override
    returns (uint256)
  {
    _projectId; // Prevents unused var compiler and natspec complaints.

    return super.balanceOf(_account);
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /** 
    @notice
    The number of decimals included in the fixed point accounting of this token.

    @return The number of decimals.
  */
  function decimals() public view override(ERC20, IJBTokenV3) returns (uint8) {
    return super.decimals();
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _name The name of the token.
    @param _symbol The symbol that the token should be represented by.
    @param _projectId The V3 ID of the project that this token should exclusively be used for.
    @param _v1TicketBooth V1 Token Booth instance, if V1 migration is desired.
    @param _v2TokenStore V2 Token Store instance, if V2 migration is desired.
    @param _v1ProjectId V1 project ID that this token should include.
  */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _projectId,
    ITicketBooth _v1TicketBooth,
    IJBTokenStore _v2TokenStore,
    uint256 _v1ProjectId
  ) ERC20(_name, _symbol) ERC20Permit(_name) {
    projectId = _projectId;
    v1TicketBooth = _v1TicketBooth;
    v2TokenStore = _v2TokenStore;
    v1ProjectId = _v1ProjectId;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Mints more of the token.

    @dev
    Only the owner of this contract can mint more of it.

    @param _projectId The ID of the project to which the token belongs.
    @param _account The account to mint the tokens for.
    @param _amount The amount of tokens to mint, as a fixed point number with 18 decimals.
  */
  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external override onlyOwner {
    // Can't mint for a wrong project.
    if (_projectId != projectId) revert BAD_PROJECT();
    return _mint(_account, _amount);
  }

  /** 
    @notice
    Burn some outstanding tokens.

    @dev
    Only the owner of this contract cant burn some of its supply.

    @param _projectId The ID of the project to which the token belongs. This is ignored.
    @param _account The account to burn tokens from.
    @param _amount The amount of tokens to burn, as a fixed point number with 18 decimals.
  */
  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external override onlyOwner {
    // Can't burn for a wrong project.
    if (_projectId != projectId) revert BAD_PROJECT();
    return _burn(_account, _amount);
  }

  /** 
    @notice
    Approves an account to spend tokens on the `msg.sender`s behalf.

    @param _projectId the ID of the project to which the token belongs. This is ignored.
    @param _spender The address that will be spending tokens on the `msg.sender`s behalf.
    @param _amount The amount the `_spender` is allowed to spend.
  */
  function approve(
    uint256 _projectId,
    address _spender,
    uint256 _amount
  ) external override {
    // Can't approve for a wrong project.
    if (_projectId != projectId) revert BAD_PROJECT();
    approve(_spender, _amount);
  }

  /** 
    @notice
    Transfer tokens to an account.
    
    @param _projectId The ID of the project to which the token belongs. This is ignored.
    @param _to The destination address.
    @param _amount The amount of the transfer, as a fixed point number with 18 decimals.
  */
  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external override {
    // Can't transfer for a wrong project.
    if (_projectId != projectId) revert BAD_PROJECT();
    transfer(_to, _amount);
  }

  /** 
    @notice
    Transfer tokens between accounts.

    @param _projectId The ID of the project to which the token belongs. This is ignored.
    @param _from The originating address.
    @param _to The destination address.
    @param _amount The amount of the transfer, as a fixed point number with 18 decimals.
  */
  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external override {
    // Can't transfer for a wrong project.
    if (_projectId != projectId) revert BAD_PROJECT();
    transferFrom(_from, _to, _amount);
  }

  /** 
    @notice
    Migrate v1 & v2 tokens to v3.
  */
  function migrate() external nonReentrant {
    uint256 _tokensToMint;

    unchecked {
      // Add the number of V1 tokens to migrate.
      _tokensToMint += _migrateV1Tokens();

      // Add the number of V2 tokens to migrate.
      _tokensToMint += _migrateV2Tokens();
    }

    // Mint tokens as needed.
    _mint(msg.sender, _tokensToMint);
  }

  /** 
    @notice
    Migrate V1 tokens to V3.

    @return v3TokensToMint The amount of V1 tokens to be migrated.
  */
  function _migrateV1Tokens() internal returns (uint256 v3TokensToMint) {
    // No V1 tokens to migrate if a V1 project ID isn't stored or a Ticket Booth isn't stored.
    if (v1ProjectId == 0 || address(v1TicketBooth) == address(0)) return 0;

    // Keep a local reference to the the project's V1 token instance.
    ITickets _v1Token = v1TicketBooth.ticketsOf(v1ProjectId);

    // Get a reference to the migrating account's unclaimed balance.
    uint256 _tokensToMintFromUnclaimedBalance = v1TicketBooth.stakedBalanceOf(
      msg.sender,
      v1ProjectId
    );
    // don't include the locked tokens
    _tokensToMintFromUnclaimedBalance -= v1TicketBooth.lockedBalanceOf(msg.sender, v1ProjectId);

    // Get a reference to the migrating account's ERC20 balance.
    uint256 _tokensToMintFromERC20s = _v1Token == ITickets(address(0))
      ? 0
      : _v1Token.balanceOf(msg.sender);

    // Calculate the amount of V3 tokens to mint from the total tokens being migrated.
    unchecked {
      v3TokensToMint = _tokensToMintFromERC20s + _tokensToMintFromUnclaimedBalance;
    }

    // Return if there's nothing to mint.
    if (v3TokensToMint == 0) return 0;

    // Transfer V1 ERC20 tokens to this contract from the msg sender if needed.
    if (_tokensToMintFromERC20s != 0)
      IERC20(_v1Token).transferFrom(msg.sender, address(this), _tokensToMintFromERC20s);

    // Transfer V1 unclaimed tokens to this contract from the msg sender if needed.
    if (_tokensToMintFromUnclaimedBalance != 0)
      v1TicketBooth.transfer(
        msg.sender,
        v1ProjectId,
        _tokensToMintFromUnclaimedBalance,
        address(this)
      );
  }

  /** 
    @notice
    Migrate V2 tokens to V3.

    @return v3TokensToMint The amount of V2 tokens to be migrated.
  */
  function _migrateV2Tokens() internal returns (uint256 v3TokensToMint) {
    // No V2 tokens to migrate if a token store does not exist.
    if (address(v2TokenStore) == address(0)) return 0;

    // Keep a reference to the the project's V2 token instance.
    IJBTokenV2 _v2Token = v2TokenStore.tokenOf(projectId);

    // Get a reference to the migrating account's unclaimed balance.
    uint256 _tokensToMintFromUnclaimedBalance = v2TokenStore.unclaimedBalanceOf(
      msg.sender,
      projectId
    );

    // Get a reference to the migrating account's ERC20 balance.
    uint256 _tokensToMintFromERC20s = _v2Token == IJBTokenV2(address(0))
      ? 0
      : _v2Token.balanceOf(msg.sender, projectId);

    // Calculate the amount of V3 tokens to mint from the total tokens being migrated.
    unchecked {
      v3TokensToMint = _tokensToMintFromERC20s + _tokensToMintFromUnclaimedBalance;
    }

    // Return if there's nothing to mint.
    if (v3TokensToMint == 0) return 0;

    // Transfer V2 ERC20 tokens to this contract from the msg sender if needed.
    if (_tokensToMintFromERC20s != 0)
      _v2Token.transferFrom(projectId, msg.sender, address(this), _tokensToMintFromERC20s);

    // Transfer V2 unclaimed tokens to this contract from the msg sender if needed.
    if (_tokensToMintFromUnclaimedBalance != 0)
      v2TokenStore.transferFrom(
        msg.sender,
        projectId,
        address(this),
        _tokensToMintFromUnclaimedBalance
      );
  }
}