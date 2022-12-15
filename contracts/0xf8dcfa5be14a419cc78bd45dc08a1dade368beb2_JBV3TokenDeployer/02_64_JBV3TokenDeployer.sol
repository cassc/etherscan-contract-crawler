// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ITicketBooth, ITickets} from '@jbx-protocol-v1/contracts/interfaces/ITicketBooth.sol';
import {IProjects} from '@jbx-protocol-v1/contracts/interfaces/IProjects.sol';
import {IJBProjects} from '@jbx-protocol-v2/contracts/interfaces/IJBProjects.sol';
import {IJBTokenStore as IJBV2TokenStore} from '@jbx-protocol-v2/contracts/interfaces/IJBTokenStore.sol';
import {IJBTokenStore as IJBV3TokenStore} from '@jbx-protocol-v3/contracts/interfaces/IJBTokenStore.sol';
import {JBV3Token} from './JBV3Token.sol';

/** 
  @notice
  V3 token deployer which is used by owners of V1 and/or V2 projects to deploy V3 token for their V3 project.
*/
contract JBV3TokenDeployer {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error NOT_OWNER();

  //*********************************************************************//
  // --------------------------- events ------------------------- //
  //*********************************************************************//

  event Deploy(uint256 v3ProjectId, address v3Token, address owner);

  /** 
    @notice
    The V3 & V2 project directory instance (since both use 1 directory instance)
  */
  IJBProjects public immutable projectDirectory;

  /** 
    @notice
    The V3 token store.
  */
  IJBV3TokenStore public immutable tokenStore;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//
  /** 
    @param _projectDirectory The V3 & V2 project directory address.
    @param _tokenStore The token store address.
  */
  constructor(
    IJBProjects _projectDirectory,
    IJBV3TokenStore _tokenStore
  ) {
    projectDirectory = _projectDirectory;
    tokenStore = _tokenStore;
  }

  /**
    @notice
    Deploy the V3 token and attach it to a V3 project.

    @dev
    Only the V3 project owner can deploy the token.

    @param _name The name of the token.
    @param _symbol The symbol that the token should be represented by.
    @param _projectId The V3 ID of the project that this token should exclusively be used for.
    @param _v1TicketBooth V1 Token Booth instance, if V1 migration is desired.
    @param _v2TokenStore V2 Token Store instance, if V2 migration is desired.
    @param _v1ProjectId V1 project ID that this token should include.

    @return v3Token The address of the new token.
  */
  function deploy(
    string memory _name,
    string memory _symbol,
    uint256 _projectId,
    ITicketBooth _v1TicketBooth,
    IJBV2TokenStore _v2TokenStore,
    uint256 _v1ProjectId
  ) external returns (JBV3Token v3Token) {
    // Make sure only the V3 project owner can deploy the token.
    if (_projectId != 0 && projectDirectory.ownerOf(_projectId) != msg.sender) revert NOT_OWNER();

    // Deploy the token.
    v3Token = new JBV3Token(
      _name,
      _symbol,
      _projectId,
      _v1TicketBooth,
      _v2TokenStore,
      _v1ProjectId
    );

    // Attach the token to the token store.
    tokenStore.setFor(_projectId, v3Token);

    // Transfer the ownership to the token store.
    v3Token.transferOwnership(address(tokenStore));

    emit Deploy(_projectId, address(v3Token), msg.sender);
  }
}