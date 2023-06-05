// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IERC721Token.sol";

/// @title ERC721TokenFactory
/// @notice Factory contract that can deploy ERC721, ERC721 Soulbound tokens for use on Coinvise Campaigns
/// @author Coinvise
contract ERC721TokenFactory is Ownable {
  /// @notice Emitted when trying to set `erc721TokenImpl`, `erc721SoulboundTokenImpl` to zero address
  error InvalidAddress();

  /// @notice Emitted when `fee * _maxSupply` is not passed in as msg.value during `deployERC721Token()`
  error InvalidFee();

  /// @notice Emitted when ether transfer reverted
  error TransferFailed();

  /// @notice Emitted when an ERC721Token clone is deployed
  /// @param _tokenType type of token deployed
  /// @param _erc721TokenClone address of the deployed clone
  /// @param _creator address of the creator of the deployed clone
  /// @param _erc721TokenImpl address of the implementation used for the deployed clone
  event ERC721TokenDeployed(
    TokenType indexed _tokenType,
    address _erc721TokenClone,
    address indexed _creator,
    address indexed _erc721TokenImpl
  );

  /// @notice Emitted when funds are withdrawn
  /// @param _feeTreasury treasury address to which fees are withdrawn
  /// @param _amount amount of funds withdrawn to `_feeTreasury`
  event Withdrawal(address _feeTreasury, uint256 _amount);

  /// @notice Emitted when erc721TokenImpl is changed
  /// @param _oldERC721TokenImpl old erc721TokenImpl
  /// @param _newERC721TokenImpl new erc721TokenImpl
  event ERC721TokenImplSet(
    address _oldERC721TokenImpl,
    address _newERC721TokenImpl
  );

  /// @notice Emitted when erc721SoulboundTokenImpl is changed
  /// @param _oldERC721SoulboundTokenImpl old erc721SoulboundTokenImpl
  /// @param _newERC721SoulboundTokenImpl new erc721SoulboundTokenImpl
  event ERC721SoulboundTokenImplSet(
    address _oldERC721SoulboundTokenImpl,
    address _newERC721SoulboundTokenImpl
  );

  /// @notice Emitted when fee is changed
  /// @param _oldFee old fee
  /// @param _newFee new fee
  event FeeSet(uint256 _oldFee, uint256 _newFee);

  /// @notice Enum to differentiate type of token to deploy
  enum TokenType {
    ERC721Token,
    ERC721SoulboundToken
  }

  /// @notice Implementation contract address used to deploy ERC721Token clones
  address public erc721TokenImpl;

  /// @notice Implementation contract address used to deploy ERC721SoulboundToken clones
  address public erc721SoulboundTokenImpl;

  /// @notice Fee per _maxSupply to be paid
  /// @dev `fee * _maxSupply` should be passed in as msg.value during `deployERC721Token()`
  uint256 public fee;

  /// @notice Sets `_erc721TokenImpl`, `_erc721SoulboundTokenImpl`, `_fee`
  /// @dev Reverts if `_erc721TokenImpl` or `_erc721SoulboundTokenImpl` param is address(0)
  /// @param _erc721TokenImpl ERC721Token implementation contract address
  /// @param _erc721SoulboundTokenImpl ERC721SoulboundToken implementation contract address
  /// @param _fee fee per _maxSupply to be paid
  constructor(
    address _erc721TokenImpl,
    address _erc721SoulboundTokenImpl,
    uint256 _fee
  ) {
    /* if (
      _erc721TokenImpl == address(0) || _erc721SoulboundTokenImpl == address(0)
    ) revert InvalidAddress(); */

    assembly {
      if or(iszero(_erc721TokenImpl), iszero(_erc721SoulboundTokenImpl)) {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    erc721TokenImpl = _erc721TokenImpl;
    erc721SoulboundTokenImpl = _erc721SoulboundTokenImpl;
    fee = _fee;
  }

  /// @notice Deploys and initializes a new ERC721Token | ERC721SoulboundToken clone with the params
  /// @dev Uses all token params + `_saltNonce` to calculate salt for clone.
  ///      Reverts if `fee * _maxSupply` is not passed in as msg.value.
  ///      Emits `ERC721TokenDeployed` or `ERC721SoulboundTokenDeployed`
  /// @param _tokenType Enum to differentiate type of token to deploy: ERC721Token | ERC721SoulboundToken
  /// @param _name Token name
  /// @param _symbol Token symbol
  /// @param contractURI_ Token contract metadata URI
  /// @param tokenURI_ Token metadata URI
  /// @param _trustedAddress Address used for signatures
  /// @param _maxSupply Max allowed token amount
  /// @param _saltNonce Salt nonce to be used for the clone
  /// @return Address of the newly deployed clone
  function deployERC721Token(
    TokenType _tokenType,
    string memory _name,
    string memory _symbol,
    string memory contractURI_,
    string memory tokenURI_,
    address _trustedAddress,
    uint256 _maxSupply,
    uint256 _saltNonce
  ) external payable returns (address) {
    if (msg.value != fee * _maxSupply) revert InvalidFee();

    address impl = _tokenType == TokenType.ERC721Token
      ? erc721TokenImpl
      : erc721SoulboundTokenImpl;
    address erc721TokenClone = Clones.cloneDeterministic(
      impl,
      keccak256(
        abi.encodePacked(
          _name,
          _symbol,
          contractURI_,
          tokenURI_,
          msg.sender,
          _trustedAddress,
          _maxSupply,
          _saltNonce
        )
      )
    );
    IERC721Token(erc721TokenClone).initialize(
      _name,
      _symbol,
      contractURI_,
      tokenURI_,
      msg.sender,
      _trustedAddress,
      _maxSupply
    );

    /* emit ERC721TokenDeployed(_tokenType, erc721TokenClone, msg.sender, impl); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, erc721TokenClone)
      log4(
        memPtr,
        32, // _erc721TokenClone
        0x23899f3b1fe55da77188b135df7513bf63e425a3958ee2866b3a19547c56effe, // ERC721TokenDeployed(uint8,address,address,address)
        _tokenType, // _tokenType
        caller(), // _creator
        impl // _erc721TokenImpl
      )
    }

    return erc721TokenClone;
  }

  /// @notice Set ERC721Token implementation contract address
  /// @dev Callable only by `owner`.
  ///      Reverts if `_erc721TokenImpl` is address(0).
  ///      Emits `ERC721TokenImplSet`
  /// @param _erc721TokenImpl ERC721Token implementation contract address
  function setERC721TokenImplAddress(
    address _erc721TokenImpl
  ) external onlyOwner {
    /* if (_erc721TokenImpl == address(0)) revert InvalidAddress(); */

    assembly {
      if iszero(_erc721TokenImpl) {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    address _oldERC721TokenImpl = erc721TokenImpl;

    erc721TokenImpl = _erc721TokenImpl;

    /* emit ERC721TokenImplSet(_oldERC721TokenImpl, _erc721TokenImpl); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, _oldERC721TokenImpl) // _oldERC721TokenImpl
      mstore(add(memPtr, 32), _erc721TokenImpl) // _newERC721TokenImpl
      log1(
        memPtr,
        64,
        0xcbc745d8ffafdbb1db5af2ff6acd261357d2d6fa74ac0ea4389b92c8891a6bd8 // ERC721TokenImplSet(address,address)
      )
    }
  }

  /// @notice Set ERC721SoulboundToken implementation contract address
  /// @dev Callable only by `owner`.
  ///      Reverts if `_erc721SoulboundTokenImpl` is address(0).
  ///      Emits `ERC721SoulboundTokenImplSet`
  /// @param _erc721SoulboundTokenImpl ERC721SoulboundToken implementation contract address
  function setERC721SoulboundTokenImplAddress(
    address _erc721SoulboundTokenImpl
  ) external onlyOwner {
    /* if (_erc721SoulboundTokenImpl == address(0)) revert InvalidAddress(); */

    assembly {
      if iszero(_erc721SoulboundTokenImpl) {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    address _oldERC721SoulboundTokenImpl = erc721SoulboundTokenImpl;

    erc721SoulboundTokenImpl = _erc721SoulboundTokenImpl;

    /* emit ERC721SoulboundTokenImplSet(
      _oldERC721SoulboundTokenImpl,
      _erc721SoulboundTokenImpl
    ); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, _oldERC721SoulboundTokenImpl) // _oldERC721SoulboundTokenImpl
      mstore(add(memPtr, 32), _erc721SoulboundTokenImpl) // _newERC721SoulboundTokenImpl
      log1(
        memPtr,
        64,
        0x9367781c37dc381ab012632d88359dc932afe7feabe3bc1a25a1f244c7324d03 // ERC721SoulboundTokenImplSet(address,address)
      )
    }
  }

  /// @notice Set fee
  /// @dev Callable only by `owner`.
  ///      Emits `FeeSet`
  /// @param _fee fee per _maxSupply
  function setFee(uint256 _fee) external onlyOwner {
    uint256 _oldFee = fee;
    fee = _fee;

    /* emit FeeSet(_oldFee, _fee); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, _oldFee) // _oldFee
      mstore(add(memPtr, 32), _fee) // _newFee
      log1(
        memPtr,
        64,
        0x74dbbbe280ef27b79a8a0c449d5ae2ba7a31849103241d0f98df70bbc9d03e37 // FeeSet(uint256,uint256)
      )
    }
  }

  /// @notice Withdraw funds to `_feeTreasury`
  /// @dev Transfers contract balance only to `_feeTreasury`, iff balance > 0.
  ///      Emits `Withdrawal`
  function withdraw(address _feeTreasury) external onlyOwner {
    uint256 _balance = address(this).balance;

    if (_balance > 0) {
      (bool success, ) = _feeTreasury.call{value: _balance}("");
      /* if (!success) revert TransferFailed(); */
      assembly {
        if iszero(success) {
          mstore(0x00, 0x90b8ec18) // TransferFailed()
          revert(0x1c, 0x04)
        }
      }

      /* emit Withdrawal(_feeTreasury, _balance); */
      assembly {
        let memPtr := mload(64)
        mstore(memPtr, _feeTreasury) // _feeTreasury
        mstore(add(memPtr, 32), _balance) // _amount
        log1(
          memPtr,
          64,
          0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65 // Withdrawal(address,uint256)
        )
      }
    }
  }
}