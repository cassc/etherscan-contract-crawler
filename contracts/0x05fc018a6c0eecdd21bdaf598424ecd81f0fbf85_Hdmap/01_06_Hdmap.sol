/// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import { Dmap } from './dmap.sol';
import {
  SimpleNameZone,
  SimpleNameZoneFactory
} from "zonefab/SimpleNameZone.sol";
import { Harberger, Perwei } from "./Harberger.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

struct Deed {
  address controller;
  uint256 collateral;
  uint256 timestamp;
}

// Hdmap as in Harberger dmap
contract Hdmap is ReentrancyGuard {
  Dmap                      public immutable dmap;
  SimpleNameZoneFactory     public immutable zonefab;
  mapping(bytes32=>Deed)    public           deeds;
  uint256                   public immutable numerator    = 1;
  uint256                   public immutable denominator  = 0x1E18558;
  bytes32                          immutable LOCK         = bytes32(uint(0x1));

  error ErrAuthorization();
  error ErrRecipient();
  error ErrValue();

  event Give(
    address indexed giver,
    bytes32 indexed zone,
    address indexed recipient
  );

  constructor() {
    dmap = Dmap(0x90949c9937A11BA943C7A72C3FA073a37E3FdD96);
    zonefab = SimpleNameZoneFactory(0xa964133B1d5b3FF1c4473Ad19bE37b6E2AaDE62b);
  }

  function fiscal(
    bytes32 org
  ) external view returns (uint256 nextPrice, uint256 taxes) {
    Deed memory deed = deeds[org];
    return Harberger.getNextPrice(
      Perwei(numerator, denominator),
      block.timestamp - deed.timestamp,
      deed.collateral
    );
  }

  function assess(bytes32 org) nonReentrant external payable {
    Deed memory deed = deeds[org];
    if (deed.controller == address(0)) {
      deed.collateral = msg.value;
      deed.controller = msg.sender;
      deed.timestamp = block.timestamp;
      deeds[org] = deed;
      dmap.set(org, LOCK, bytes32(bytes20(address(zonefab.make()))));
      emit Give(address(0), org, msg.sender);
    } else {
      (uint256 nextPrice, uint256 taxes) = Harberger.getNextPrice(
        Perwei(numerator, denominator),
        block.timestamp - deed.timestamp,
        deed.collateral
      );

      if (msg.value < nextPrice && deed.controller != msg.sender) {
        revert ErrValue();
      }

      address beneficiary = deed.controller;
      deed.collateral = msg.value;
      deed.controller = msg.sender;
      deed.timestamp= block.timestamp;
      deeds[org] = deed;

      // NOTE: Stakers and beneficiaries must not control the finalization of
      // this function, hence, we're not checking for the calls' success.
      // DONATIONS: Consider donating to dmap://:free.timdaub to help
      // compensate for deployment costs.
      block.coinbase.call{value: taxes}("");
      beneficiary.call{value: nextPrice}("");
      emit Give(beneficiary, org, msg.sender);
    }
  }

  function give(bytes32 org, address recipient) external {
    if (recipient == address(0)) revert ErrRecipient();
    if (deeds[org].controller != msg.sender) revert ErrAuthorization();
    deeds[org].controller = recipient;
    emit Give(msg.sender, org, recipient);
  }

  function lookup(bytes32 org) public view returns (address zone) {
    bytes32 slot = keccak256(abi.encode(address(this), org));
    (, bytes32 data) = dmap.get(slot);
    return address(bytes20(data));
  }

  function read(
    bytes32 org,
    bytes32 key
  ) public view returns (bytes32 meta, bytes32 data) {
    address zone = lookup(org);
    bytes32 slot = keccak256(abi.encode(zone, key));
    return dmap.get(slot);
  }

  function stow(bytes32 org, bytes32 key, bytes32 meta, bytes32 data) external {
    if (deeds[org].controller != msg.sender) revert ErrAuthorization();
    SimpleNameZone z = SimpleNameZone(lookup(org));
    z.stow(key, meta, data);
  }
}