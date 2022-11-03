// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";


interface IAlluoToken is IAccessControl{
  function ADMIN_ROLE (  ) external view returns ( bytes32 );
  function BURNER_ROLE (  ) external view returns ( bytes32 );
  function CAP_CHANGER_ROLE (  ) external view returns ( bytes32 );
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function DOMAIN_SEPARATOR (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function PAUSER_ROLE (  ) external view returns ( bytes32 );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function blocklist ( address ) external view returns ( bool );
  function burn ( address account, uint256 amount ) external;
  function changeCap ( uint256 _newCap ) external;
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function delegate ( address delegatee ) external;
  function delegateBySig ( address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s ) external;
  function delegates ( address account ) external view returns ( address );
  function getPastTotalSupply ( uint256 blockNumber ) external view returns ( uint256 );
  function getPastVotes ( address account, uint256 blockNumber ) external view returns ( uint256 );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function maxTotalSupply (  ) external view returns ( uint256 );
  function mint ( address to, uint256 amount ) external;
  function name (  ) external view returns ( string memory);
  function nonces ( address owner ) external view returns ( uint256 );
  function numCheckpoints ( address account ) external view returns ( uint32 );
  function paused (  ) external view returns ( bool );
  function permit ( address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s ) external;
  function setBlockStatus ( address _user, bool _state ) external;
  function setPause ( bool _state ) external;
  function setWhiteStatus ( address _user, bool _state ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory);
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
  function unlockERC20 ( address _token, address _to, uint256 _amount ) external;
  function whitelist ( address ) external view returns ( bool );
}