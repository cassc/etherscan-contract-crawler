// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.16;

import "lib/forge-std/src/Test.sol";
import { IERC4973 } from "lib/ERC4973/src/interfaces/IERC4973.sol";
import { Badges } from "./Badges.sol";
import { SpecDataHolder } from "./SpecDataHolder.sol";
import { Raft } from "./Raft.sol";
import "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
  constructor(address _implementation, bytes memory _data)
    ERC1967Proxy(_implementation, _data)
  {}
}

contract RaftTest is Test {
  address passiveAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 passivePrivateKey =
    0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;
  uint256 randomPrivateKey =
    0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
  string specUri;

  string errCantMintToZeroAddress = "cannot mint to zero address";

  Raft implementationV1;
  UUPSProxy proxy;
  Raft wrappedProxyV1;
  // RaftV2 wrappedProxyV2;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event MetadataUpdate(uint256 indexed tokenId);

  event AdminUpdate(
    uint256 indexed tokenId,
    address indexed admin,
    bool isAdded
  );

  function setUp() public {
    address to = address(this);

    specUri = "some spec uri";

    vm.label(passiveAddress, "passive");

    implementationV1 = new Raft();

    // deploy proxy contract and point it to implementation
    proxy = new UUPSProxy(address(implementationV1), "");

    // wrap in ABI to support easier calls
    wrappedProxyV1 = Raft(address(proxy));

    wrappedProxyV1.initialize(to, "Raft", "RAFT");
  }

  function testMintRaft() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = wrappedProxyV1.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(wrappedProxyV1.balanceOf(to), 1);
  }

  function testMintRaftAsNonOwnerWhilePaused() public {
    address to = address(this);
    bool paused = wrappedProxyV1.paused();
    assertEq(paused, true);
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("mint: unauthorized to mint"));
    wrappedProxyV1.mint(to, "some uri");
  }

  function testUnpauseTheContract() public {
    assertEq(wrappedProxyV1.paused(), true);
    wrappedProxyV1.unpause();
    assertEq(wrappedProxyV1.paused(), false);
  }

  function testUnpauseTheContractAsAttacker() public {
    bool paused = wrappedProxyV1.paused();
    assertEq(paused, true);
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    wrappedProxyV1.unpause();
  }

  function testSetTokenURI() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = wrappedProxyV1.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(wrappedProxyV1.balanceOf(to), 1);

    vm.expectEmit(true, true, false, false);
    emit MetadataUpdate(raftTokenId);
    wrappedProxyV1.setTokenURI(raftTokenId, "some new uri");

    assertEq(wrappedProxyV1.tokenURI(raftTokenId), "some new uri");
  }

  function testSetTokenURIOfNonExistentToken() public {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = wrappedProxyV1.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(wrappedProxyV1.balanceOf(to), 1);
    vm.expectRevert(bytes("setTokenURI: URI set of nonexistent token"));
    wrappedProxyV1.setTokenURI(999999999, "some new uri");
  }

  function testSetTokenURIAsNonOwner() public {
    address to = address(this);
    address from = address(0);
    address attacker = vm.addr(randomPrivateKey);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = wrappedProxyV1.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(wrappedProxyV1.balanceOf(to), 1);

    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    wrappedProxyV1.setTokenURI(raftTokenId, "some new uri");
  }

  function testTransferOwnership() public {
    address currentOwner = wrappedProxyV1.owner();
    assertEq(currentOwner, address(this));
    address newOwner = vm.addr(randomPrivateKey);
    wrappedProxyV1.transferOwnership(newOwner);
    assertEq(wrappedProxyV1.owner(), newOwner);
  }

  function testTransferOwnershipFromNonOwner() public {
    address currentOwner = wrappedProxyV1.owner();
    assertEq(currentOwner, address(this));
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    wrappedProxyV1.transferOwnership(attacker);
  }

  function testCantMintToZeroAddress() public {
    address to = address(0);
    vm.expectRevert(bytes(errCantMintToZeroAddress));
    wrappedProxyV1.mint(to, "some uri");
  }

  function testSetAdmin() public {
    address tokenOwner = address(1);
    uint256 tokenId = wrappedProxyV1.mint(tokenOwner, "some uri");

    address admin = address(2);

    // checking for an address in a raft that was never an admin
    bool isActive = false;
    bool actual = wrappedProxyV1.isAdminActive(tokenId, admin);
    assertEq(actual, isActive);

    // checking for a new address being added as an admin
    isActive = true;
    vm.expectEmit(true, true, false, true);
    vm.prank(tokenOwner);
    wrappedProxyV1.setAdmin(tokenId, admin, isActive);
    emit AdminUpdate(tokenId, admin, isActive);

    actual = wrappedProxyV1.isAdminActive(tokenId, admin);
    assertEq(actual, isActive);

    // expect error if a tokenid does not exist
    vm.expectRevert(bytes("addAdmin: tokenId does not exist"));
    vm.prank(tokenOwner);
    wrappedProxyV1.setAdmin(123, admin, isActive);

    // expect error if the called is not the owner of the raftTokenid
    vm.expectRevert(bytes("addAdmin: unauthorized"));
    wrappedProxyV1.setAdmin(tokenId, address(123), isActive);
  }
}