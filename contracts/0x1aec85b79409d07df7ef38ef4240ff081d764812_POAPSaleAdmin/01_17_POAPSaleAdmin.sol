// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import { POAPSale } from "./POAPSale.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract POAPSaleAdmin is
  Initializable,
  ContextUpgradeable,
  AccessControlUpgradeable,
  EIP712Upgradeable
{
  event SaleCreated(address indexed saleContract, address indexed deployer, uint256 indexed dropId);
  event SalePaused(address indexed saleContract);
  event SaleUnpaused(address indexed saleContract);
  event SaleFinished(address indexed saleContract, uint256 indexed earned, uint256 indexed refunded);

  bytes32 public constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775; // keccak256("ADMIN_ROLE");

  uint8 private constant ADMIN_ACTION_PAUSE = 1;
  uint8 private constant ADMIN_ACTION_UNPAUSE = 2;
  uint8 private constant ADMIN_ACTION_FINISH = 4;
  uint8 private constant ADMIN_ACTION_CANCEL = 8;

  mapping(bytes => bool) private _saleSignatures;

  function initialize() public initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    __EIP712_init("POAPSaleAdmin", "1");
  }

  function createSaleWithSignature(
    uint256 dropId,
    uint256 price,
    uint256 quantity,
    uint256 startTimestamp,
    uint256 endTimestamp,
    address payable fundsReceiver,
    bytes calldata signature
  ) public returns (address) {
    require(
      hasRole(
        ADMIN_ROLE,
        _signerSale(dropId, price, quantity, startTimestamp, endTimestamp, fundsReceiver, signature)
      ),
      "POAPSaleAdmin: bad signature"
    );
    require(!_saleSignatures[signature], "POAPSaleAdmin: repeated signature");
    require(quantity > 0, "POAPSaleAdmin: empty sale");
    require(block.timestamp < startTimestamp, "POAPSaleAdmin: past sale");
    require(startTimestamp < endTimestamp, "POAPSaleAdmin: negative sale");
    POAPSale saleContract = new POAPSale(
      address(this),
      payable(_msgSender()),
      fundsReceiver,
      dropId,
      price,
      quantity,
      startTimestamp,
      endTimestamp
    );
    _saleSignatures[signature] = true;
    emit SaleCreated(address(saleContract), _msgSender(), dropId);
    return address(saleContract);
  }

  function _signerSale(
    uint256 dropId,
    uint256 price,
    uint256 quantity,
    uint256 startTimestamp,
    uint256 endTimestamp,
    address payable fundsReceiver,
    bytes calldata signature
  ) internal view returns (address) {
    return ECDSAUpgradeable.recover(
      _hashTypedDataV4(keccak256(abi.encode(
        keccak256(bytes("POAPSale(uint256 dropId,uint256 price,uint256 quantity,uint256 startTimestamp,uint256 endTimestamp,address fundsReceiver,address deployer)")),
        dropId,
        price,
        quantity,
        startTimestamp,
        endTimestamp,
        fundsReceiver,
        _msgSender()
      ))),
      signature
    );
  }

  function pauseSale(address payable saleContract) public {
    require(_msgSender() == POAPSale(saleContract).deployer(), "POAPSaleAdmin: not deployer");
    POAPSale(saleContract).pause();
    emit SalePaused(saleContract);
  }

  function pauseSaleWithSignature(
    address payable saleContract,
    bytes calldata signature
  ) public {
    require(
      hasRole(
        ADMIN_ROLE,
        _signerSaleAdmin(saleContract, ADMIN_ACTION_PAUSE, signature)
      ),
      "POAPSaleAdmin: bad signature"
    );
    POAPSale(saleContract).pause();
    emit SalePaused(saleContract);
  }

  function unpauseSale(address payable saleContract) public {
    require(_msgSender() == POAPSale(saleContract).deployer(), "POAPSaleAdmin: not deployer");
    POAPSale(saleContract).unpause();
    emit SaleUnpaused(saleContract);
  }

  function unpauseSaleWithSignature(
    address payable saleContract,
    bytes calldata signature
  ) public {
    require(
      hasRole(
        ADMIN_ROLE,
        _signerSaleAdmin(saleContract, ADMIN_ACTION_UNPAUSE, signature)
      ),
      "POAPSaleAdmin: bad signature"
    );
    POAPSale(saleContract).unpause();
    emit SaleUnpaused(saleContract);
  }

  function finishSale(
    address payable saleContract,
    address[] memory accepted,
    address[] memory rejected
  ) public {
    require(_msgSender() == POAPSale(saleContract).deployer(), "POAPSaleAdmin: not deployer");
    POAPSale(saleContract).finish(accepted, rejected);
    emit SaleFinished(saleContract, accepted.length, rejected.length);
  }

  function finishSaleWithSignature(
    address payable saleContract,
    address[] memory accepted,
    address[] memory rejected,
    bytes calldata signature
  ) public {
    require(
      hasRole(
        ADMIN_ROLE,
        _signerSaleAdmin(saleContract, ADMIN_ACTION_FINISH, signature)
      ),
      "POAPSaleAdmin: bad signature"
    );
    POAPSale(saleContract).finish(accepted, rejected);
    emit SaleFinished(saleContract, accepted.length, rejected.length);
  }

  function cancelSaleWithSignature(
    address payable saleContract,
    bytes calldata signature
  ) public {
    require(
      hasRole(
        ADMIN_ROLE,
        _signerSaleAdmin(saleContract, ADMIN_ACTION_CANCEL, signature)
      ),
      "POAPSaleAdmin: bad signature"
    );
    POAPSale(saleContract).cancel();
    emit SaleFinished(saleContract, 0, POAPSale(saleContract).received());
  }

  function _signerSaleAdmin(
    address saleContract,
    uint8 action,
    bytes calldata signature
  ) internal view returns (address) {
    return ECDSAUpgradeable.recover(
      _hashTypedDataV4(keccak256(abi.encode(
        keccak256(bytes("POAPSaleAdmin(address saleContract,uint8 action,address admin)")),
        saleContract,
        action,
        _msgSender()
      ))),
      signature
    );
  }
}