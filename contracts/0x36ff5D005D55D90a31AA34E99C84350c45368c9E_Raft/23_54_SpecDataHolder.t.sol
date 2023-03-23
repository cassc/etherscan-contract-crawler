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

contract SpecDataHolderTest is Test {
  Badges badgesImplementationV1;
  SpecDataHolder specDataHolderImplementationV1;
  Raft raftImplementationV1;

  UUPSProxy badgesProxy;
  UUPSProxy raftProxy;
  UUPSProxy specDataHolderProxy;

  Badges badgesWrappedProxyV1;
  Raft raftWrappedProxyV1;
  SpecDataHolder specDataHolderWrappedProxyV1;

  address passiveAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 passivePrivateKey =
    0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;
  uint256 randomPrivateKey =
    0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
  string specUri = "some spec uri";

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  function setUp() public {
    address contractOwner = address(this);

    badgesImplementationV1 = new Badges();
    specDataHolderImplementationV1 = new SpecDataHolder();
    raftImplementationV1 = new Raft();

    badgesProxy = new UUPSProxy(address(badgesImplementationV1), "");
    raftProxy = new UUPSProxy(address(raftImplementationV1), "");
    specDataHolderProxy = new UUPSProxy(
      address(specDataHolderImplementationV1),
      ""
    );
    badgesWrappedProxyV1 = Badges(address(badgesProxy));
    raftWrappedProxyV1 = Raft(address(raftProxy));
    specDataHolderWrappedProxyV1 = SpecDataHolder(address(specDataHolderProxy));

    badgesWrappedProxyV1.initialize(
      "Badges",
      "BADGES",
      "0.1.0",
      contractOwner,
      address(specDataHolderProxy)
    );
    raftWrappedProxyV1.initialize(contractOwner, "Raft", "RAFT");
    specDataHolderWrappedProxyV1.initialize(address(raftProxy), contractOwner);

    specDataHolderWrappedProxyV1.setBadgesAddress(address(badgesProxy));
  }

  function createRaft() public returns (uint256) {
    address to = address(this);
    address from = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, "some uri");
    emit Transfer(from, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);
    return raftTokenId;
  }

  // set Raft
  function testSetRaft() public {
    createRaft();
    address newRaftAddress = vm.addr(randomPrivateKey);
    specDataHolderWrappedProxyV1.setRaftAddress(newRaftAddress);
    assertEq(specDataHolderWrappedProxyV1.getRaftAddress(), newRaftAddress);
  }

  function testSetRaftAsNonOwner() public {
    createRaft();
    address newRaftAddress = vm.addr(randomPrivateKey);
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    specDataHolderWrappedProxyV1.setRaftAddress(newRaftAddress);
  }

  function testGetRaft() public {
    createRaft();
    specDataHolderWrappedProxyV1.getRaftAddress();
    assertEq(specDataHolderWrappedProxyV1.getRaftAddress(), address(raftProxy));
  }

  function testGetRaftTokenId() public {
    uint256 raftTokenId = createRaft();

    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
    assertEq(specDataHolderWrappedProxyV1.isSpecRegistered(specUri), true);
    assertEq(specDataHolderWrappedProxyV1.getRaftTokenId(specUri), 1);
  }

  function testSetBadgesAddress() public {
    assertEq(
      specDataHolderWrappedProxyV1.getBadgesAddress(),
      address(badgesProxy)
    );
    address randomAddress = vm.addr(randomPrivateKey);

    specDataHolderWrappedProxyV1.setBadgesAddress(randomAddress);
    assertEq(specDataHolderWrappedProxyV1.getBadgesAddress(), randomAddress);
  }

  function testSetBadgesAddressAsNonOwner() public {
    assertEq(
      specDataHolderWrappedProxyV1.getBadgesAddress(),
      address(badgesProxy)
    );
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    specDataHolderWrappedProxyV1.setBadgesAddress(randomAddress);
  }

  function testSetBadgesToRaftsShouldFailForUnauthorizedCaller() public {
    uint256[] memory badgeTokenIds = new uint256[](3);
    badgeTokenIds[0] = 1;
    badgeTokenIds[1] = 2;
    badgeTokenIds[2] = 3;

    uint256[] memory raftTokenIds = new uint256[](3);
    raftTokenIds[0] = 10;
    raftTokenIds[1] = 20;
    raftTokenIds[2] = 30;

    // Test that only authorized parties can set the mappings
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("onlyAuthorized: unauthorized"));
    specDataHolderWrappedProxyV1.setBadgesToRafts(badgeTokenIds, raftTokenIds);

    // happy path where the owner sets the mappings
    specDataHolderWrappedProxyV1.setBadgesToRafts(badgeTokenIds, raftTokenIds);
    assertEq(specDataHolderWrappedProxyV1.getRaftByBadgeId(1), 10);
  }

  function testSetBadgesToRaftsShouldFailWhenProvidingDifferentInputLengths()
    public
  {
    uint256[] memory badgeTokenIds = new uint256[](3);
    badgeTokenIds[0] = 1;
    badgeTokenIds[1] = 2;
    badgeTokenIds[2] = 3;

    uint256[] memory raftTokenIds = new uint256[](2);
    raftTokenIds[0] = 10;
    raftTokenIds[1] = 20;

    vm.expectRevert(bytes("setBadgesToRafts: arrays must be the same length"));
    specDataHolderWrappedProxyV1.setBadgesToRafts(badgeTokenIds, raftTokenIds);
  }

  function testSetSpecsToRaftsShouldFailForUnauthorizedCaller() public {
    string[] memory specUris = new string[](3);
    specUris[0] = "spec uri 1";
    specUris[1] = "spec uri 2";
    specUris[2] = "spec uri 3";

    uint256[] memory raftTokenIds = new uint256[](3);
    raftTokenIds[0] = 1;
    raftTokenIds[1] = 2;
    raftTokenIds[2] = 3;

    // Test that only authorized parties can set the mappings
    address attacker = vm.addr(randomPrivateKey);
    vm.prank(attacker);
    vm.expectRevert(bytes("onlyAuthorized: unauthorized"));
    specDataHolderWrappedProxyV1.setSpecsToRafts(specUris, raftTokenIds);

    // happy path
    specDataHolderWrappedProxyV1.setSpecsToRafts(specUris, raftTokenIds);
    assertEq(specDataHolderWrappedProxyV1.isSpecRegistered(specUris[2]), true);

    // test getRaftTokenId
    assertEq(specDataHolderWrappedProxyV1.getRaftTokenId(specUris[2]), 3);
  }
}