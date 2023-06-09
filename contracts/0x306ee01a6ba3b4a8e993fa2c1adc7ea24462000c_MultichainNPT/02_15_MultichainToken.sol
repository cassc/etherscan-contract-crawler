// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

import './ERC20Capped.sol';

/**
 * @title MultichainToken
 * @dev This contract is template for Multichain token
 */
contract MultichainToken is AccessControl, Ownable, Pausable, ERC20Capped {
  // Create a new role identifier for the minter role
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
  bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint256) public nonces;

  /**
   * @dev Creates an instance of `MeterToken` where `name` and `symbol` is initialized.
   * Names and symbols can vary from the pegging currency
   */
  constructor(string memory _name, string memory _symbol, uint256 maxCap_) ERC20(_name, _symbol) ERC20Capped(maxCap_) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(OPERATOR_ROLE, _msgSender());
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(_name)),
        keccak256(bytes('1')),
        chainId,
        address(this)
      )
    );
  }

  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, 'MultichainToken: EXPIRED');
    bytes32 digest = keccak256(
      abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)))
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, 'MultichainToken: INVALID_SIGNATURE');
    _approve(owner, spender, value);
  }

  function mint(address to, uint256 amount) external returns (bool) {
    // Check that the calling account has the minter role
    require(hasRole(MINTER_ROLE, msg.sender), 'MultichainToken: Caller is not a minter');
    _mint(to, amount);
    return true;
  }

  function burn(uint256 amount) external returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  // Caller bridge
  function burn(address _from, uint256 _amount) external returns (bool) {
    require(hasRole(BURNER_ROLE, msg.sender), 'MultichainToken: Caller is not a burner');
    _burn(_from, _amount);
    return true;
  }

  // polygon pos bridge
  function deposit(address user, bytes calldata depositData) external {
    require(hasRole(MINTER_ROLE, msg.sender), 'MultichainToken: Caller is not a minter');
      uint256 amount = abi.decode(depositData, (uint256));
      _mint(user, amount);
  }

  function withdraw(uint256 amount) external {
      _burn(_msgSender(), amount);
  }
  //

  // pauseable
  function pause() public {
    require(hasRole(OPERATOR_ROLE, msg.sender), 'MultichainToken: Caller is not a pauser');
    _pause();
  }

  function unpause() public {
    require(hasRole(OPERATOR_ROLE, msg.sender), 'MultichainToken: Caller is not a pauser');
    _unpause();
  }

  function setCap(uint256 cap_) public {
    require(hasRole(OPERATOR_ROLE, msg.sender), 'MultichainToken: Caller is not a pauser');
    _setCap(cap_);
  }

  function _beforeTokenTransfer( address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(!paused(), 'MultichainToken: token transfer while paused');
  }
  //
}