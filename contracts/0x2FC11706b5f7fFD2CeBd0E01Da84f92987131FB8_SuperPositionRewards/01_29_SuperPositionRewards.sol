// SPDX-License-Identifier: MIT
//
//
// SuperPosition Reward Claimer created by Ryan Meyers @sreyeMnayR
// Twitter: @sp__to  Web: https://superposition.to
//
//
// Generosity attracts generosity.
//
// The world will be saved by beauty.
//
//

pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// event SaleComplete(address indexed _to, address indexed _from, uint256 _value, uint256 _id);

contract SuperPositionRewards is Initializable, UUPSUpgradeable, OwnableUpgradeable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, EIP712Upgradeable {

  event RewardClaimed(uint256 indexed claimId, address indexed to, address indexed contractAddress, uint256 tokenId, uint256 amount);

  error InvalidClaimKey();
  error WalletNotSender();
  error ClaimKeyAlreadyUsed();
  error TokenBalanceTooLow();
  error UnknownTokenType();

  struct ClaimKey {
      address wallet;
      address tokenContract;
      uint256 tokenId;
      uint256 amount;
      uint256 claimId;
  }

  bytes32 private constant CLAIMKEY_TYPE_HASH = keccak256("ClaimKey(address wallet,address tokenContract,uint256 tokenId,uint256 amount,uint256 claimId)");

  mapping(uint => bool) private _claimed;

  address private _signer;

   function initialize(address signer_, string calldata name_, string calldata version_) public initializer {
    _signer = signer_;

    ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    __Ownable_init();
    __EIP712_init(name_, version_);
    __UUPSUpgradeable_init();

   }

   ///@dev required by the OZ UUPS module
   function _authorizeUpgrade(address) internal override onlyOwner {}


  function claim(
    bytes calldata signature,
    ClaimKey calldata key
  ) public {
    if (msg.sender != key.wallet) revert WalletNotSender();
    if (!checkClaim(signature, key)) revert InvalidClaimKey();
    if (_claimed[key.claimId]) revert ClaimKeyAlreadyUsed();

    _claimed[key.claimId] = true; // no re-entrancy, do this first.

    _sendToken(key.tokenContract, key.tokenId, key.amount, msg.sender);
    emit RewardClaimed(key.claimId, msg.sender, key.tokenContract, key.tokenId, key.amount);

  }


  function checkClaim(bytes calldata signature, ClaimKey calldata key) public view returns (bool) {

    bytes32 digest = _hashTypedDataV4(
        keccak256(
            abi.encode(
                CLAIMKEY_TYPE_HASH,
                msg.sender,
                key.tokenContract,
                key.tokenId,
                key.amount,
                key.claimId
            )
        )
      );

      return ECDSAUpgradeable.recover(digest, signature) == _signer;
    }

  function _sendToken(address contract_, uint tokenId_, uint amount_, address to_) internal virtual {

        uint256 contractStandard = detectContractStandard(contract_);

        if(contractStandard == 1155) {
            if(IERC1155(contract_).balanceOf(address(this), tokenId_) < amount_) revert TokenBalanceTooLow();
            IERC1155(contract_).safeTransferFrom(address(this), to_, tokenId_, amount_, "");
        } else if(contractStandard == 721){
            if(IERC721(contract_).ownerOf(tokenId_) !=  address(this)) revert TokenBalanceTooLow();
            IERC721(contract_).transferFrom(address(this), to_, tokenId_);
        } else if(contractStandard == 20) {
            if(IERC20( contract_).balanceOf(address(this)) <  amount_) revert TokenBalanceTooLow();
            IERC20(contract_).transferFrom(address(this), to_, amount_);
        } else {
            revert UnknownTokenType();
        }

    }

    function setSigner(address signer_) public onlyOwner {
        _signer = signer_;
    }

    function signer() public view returns (address) {
        return _signer;
    }

  function detectContractStandard(address contract_) public virtual view returns (uint256) {
      try IERC165(contract_).supportsInterface(type(IERC1155).interfaceId) {
          if(IERC165(contract_).supportsInterface(type(IERC1155).interfaceId)) {
            return 1155;
          } else if(IERC165(contract_).supportsInterface(type(IERC721).interfaceId)){
            return 721;
          } else {
            if(IERC20(contract_).balanceOf(_msgSender()) >= 0){
              return 20;
            }
          }
        } catch {
            if(IERC20(contract_).balanceOf(_msgSender()) >= 0){
              return 20;
            }
        }
        return 0;
    }

}