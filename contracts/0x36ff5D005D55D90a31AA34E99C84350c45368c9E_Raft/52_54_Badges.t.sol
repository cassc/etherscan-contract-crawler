// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.16;

import "lib/forge-std/src/Test.sol";
import { IERC721Metadata } from "./interfaces/IERC721Metadata.sol";
import { IERC4973 } from "lib/ERC4973/src/interfaces/IERC4973.sol";
import { Badges } from "./Badges.sol";
import { SpecDataHolder } from "./SpecDataHolder.sol";
import { Raft } from "./Raft.sol";
import "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Merkle } from "lib/murky/src/Merkle.sol";
import { MerkleProof } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract UUPSProxy is ERC1967Proxy {
  constructor(address _implementation, bytes memory _data)
    ERC1967Proxy(_implementation, _data)
  {}
}

contract BadgesTest is Test {
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

  uint256 raftHolderPrivateKey =
    0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
  address raftHolderAddress =
    vm.addr(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);

  uint256 claimantPrivateKey =
    0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
  address claimantAddress =
    vm.addr(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a);

  string[] specUris = ["spec1", "spec2"];
  string badTokenUri = "bad token uri";

  string errAirdropUnauthorized = "airdrop: unauthorized";
  string err721InvalidTokenId = "ERC721: invalid token ID";
  string errBadgeAlreadyRevoked = "revokeBadge: badge already revoked";
  string errBalanceOfNotValidOwner =
    "balanceOf: address(0) is not a valid owner";
  string errGiveToManyArrayMismatch =
    "giveToMany: recipients and signatures length mismatch";
  string errGiveRequestedBadgeToManyArrayMismatch =
    "giveRequestedBadgeToMany: recipients and signatures length mismatch";
  string errInvalidSig = "safeCheckAgreement: invalid signature";
  string errGiveRequestedBadgeInvalidSig =
    "giveRequestedBadge: invalid signature";
  string errOnlyBadgesContract = "onlyBadgesContract: unauthorized";
  string errNoSpecUris = "refreshMetadata: no spec uris provided";
  string errNotOwner = "Ownable: caller is not the owner";
  string errNotRaftOwner = "onlyRaftOwner: unauthorized";
  string errCreateSpecUnauthorized = "createSpec: unauthorized";
  string errNotRevoked = "reinstateBadge: badge not revoked";
  string errSafeCheckUsed = "safeCheckAgreement: already used";
  string errSpecAlreadyRegistered = "createSpec: spec already registered";
  string errSpecNotRegistered = "mint: spec is not registered";
  string errGiveUnauthorized = "give: unauthorized";
  string errUnequipSenderNotOwner = "unequip: sender must be owner";
  string errTakeUnauthorized = "take: unauthorized";
  string errMerkleInvalidLeaf = "safeCheckMerkleAgreement: invalid leaf";
  string errMerkleInvalidSignature =
    "safeCheckMerkleAgreement: invalid signature";
  string errTokenDoesntExist = "tokenExists: token doesn't exist";
  string errTokenExists = "mint: tokenID exists";
  string errRevokeUnauthorized = "revokeBadge: unauthorized";
  string errReinstateUnauthorized = "reinstateBadge: unauthorized";
  string errRequestedBadgeUnauthorized = "giveRequestedBadge: unauthorized";

  string specUri = "some spec uri";

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event RefreshMetadata(string[] specUris, address sender);

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

    vm.label(passiveAddress, "passive");
  }

  // // helper function
  function createRaftAndRegisterSpec() internal returns (uint256) {
    address to = raftHolderAddress;
    address zeroAddress = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, specUri);
    emit Transfer(zeroAddress, to, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);

    vm.prank(to);
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
    assertEq(specDataHolderWrappedProxyV1.isSpecRegistered(specUri), true);

    return raftTokenId;
  }

  // // helper function
  function getSignature(address active, uint256 passive)
    internal
    returns (bytes memory)
  {
    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(
      active,
      vm.addr(passive),
      specUri
    );
    // passive is always the one signing away permission for the active party to do something
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passive, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    return signature;
  }

  function testIERC721Metadata() public {
    assertTrue(
      badgesWrappedProxyV1.supportsInterface(type(IERC721Metadata).interfaceId)
    );
  }

  function testIERC4973() public {
    bytes4 interfaceId = type(IERC4973).interfaceId;
    assertEq(interfaceId, bytes4(0x8d7bac72));
    assertTrue(badgesWrappedProxyV1.supportsInterface(interfaceId));
  }

  function testCheckMetadata() public {
    assertEq(badgesWrappedProxyV1.name(), "Badges");
    assertEq(badgesWrappedProxyV1.symbol(), "BADGES");
  }

  function testIfEmptyAddressReturnsBalanceZero(address fuzzAddress) public {
    vm.assume(fuzzAddress != address(0));
    assertEq(badgesWrappedProxyV1.balanceOf(address(fuzzAddress)), 0);
  }

  function testThrowOnZeroAddress() public {
    vm.expectRevert(bytes(errBalanceOfNotValidOwner));
    badgesWrappedProxyV1.balanceOf(address(0));
  }

  function testFailGetOwnerOfNonExistentTokenId(uint256 tokenId) public view {
    // needs assert
    badgesWrappedProxyV1.ownerOf(tokenId);
  }

  // DATA HOLDER TESTS

  function testSetDataHolder(address fuzzAddress) public {
    address dataHolderAddress = address(specDataHolderProxy);
    assertEq(badgesWrappedProxyV1.getDataHolderAddress(), dataHolderAddress);

    badgesWrappedProxyV1.setDataHolder(fuzzAddress);
    assertEq(badgesWrappedProxyV1.getDataHolderAddress(), fuzzAddress);
  }

  function testSetDataHolderAsNonOwner() public {
    address dataHolderAddress = address(specDataHolderProxy);
    assertEq(badgesWrappedProxyV1.getDataHolderAddress(), dataHolderAddress);
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    vm.expectRevert(bytes(errNotOwner));
    badgesWrappedProxyV1.setDataHolder(randomAddress);
  }

  // OWNERSHIP TESTS

  function testGetOwnerOfContract() public {
    assertEq(badgesWrappedProxyV1.owner(), address(this));
  }

  function testTransferOwnership(address fuzzAddress) public {
    vm.assume(fuzzAddress != address(0));
    address currentOwner = badgesWrappedProxyV1.owner();
    assertEq(currentOwner, address(this));
    badgesWrappedProxyV1.transferOwnership(fuzzAddress);
    assertEq(badgesWrappedProxyV1.owner(), fuzzAddress);
  }

  function testTransferOwnershipFromNonOwner() public {
    address currentOwner = badgesWrappedProxyV1.owner();
    assertEq(currentOwner, address(this));
    address randomAddress = vm.addr(randomPrivateKey);
    vm.prank(randomAddress);
    vm.expectRevert(bytes(errNotOwner));
    badgesWrappedProxyV1.transferOwnership(randomAddress);
  }

  // // CREATE SPEC TESTS

  function testCreateSpecAsRaftOwner() public {
    address raftOwner = address(this);
    uint256 raftTokenId = raftWrappedProxyV1.mint(raftOwner, specUri);

    vm.prank(raftOwner);
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  function testCreateSpecAsAdmin() public {
    address raftOwner = address(this);
    address admin = address(123);
    uint256 raftTokenId = raftWrappedProxyV1.mint(raftOwner, specUri);
    raftWrappedProxyV1.setAdmin(raftTokenId, admin, true);

    vm.prank(admin);
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  function testCreateSpecAsDeactivatedAdmin() public {
    address raftOwner = address(this);
    address admin = address(123);
    uint256 raftTokenId = raftWrappedProxyV1.mint(raftOwner, specUri);
    raftWrappedProxyV1.setAdmin(raftTokenId, admin, false);

    vm.prank(admin);
    vm.expectRevert(bytes(errCreateSpecUnauthorized));
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  function testCreateSpecAsUnauthorizedAccount() public {
    address to = address(this);
    address randomAddress = vm.addr(randomPrivateKey);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, specUri);

    vm.prank(randomAddress);
    vm.expectRevert(bytes(errCreateSpecUnauthorized));
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  // can't test this one with fuzzing because the owner is set in the "setup"
  // function above, so replacing "to" with "fuzzAddress" will always fail
  function testCreatingWithExistingSpecUriShouldRevert() public {
    address to = address(this);
    address zeroAddress = address(0);

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(to, specUri);
    emit Transfer(zeroAddress, to, raftTokenId);
    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(to), 1);

    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);

    vm.expectRevert(bytes(errSpecAlreadyRegistered));
    badgesWrappedProxyV1.createSpec(specUri, raftTokenId);
  }

  // TODO: write test for a non-owner calling transferOwnership
  // tricky because we need to call a proxy to do this

  // TAKE TESTS
  // happy path
  function testTake() public returns (uint256, uint256) {
    address active = claimantAddress;
    address passive = raftHolderAddress;
    uint256 raftTokenId = createRaftAndRegisterSpec();
    bytes memory signature = getSignature(active, raftHolderPrivateKey);

    vm.prank(active);
    uint256 tokenId = badgesWrappedProxyV1.take(passive, specUri, signature);

    assertEq(badgesWrappedProxyV1.balanceOf(active), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), active);

    return (raftTokenId, tokenId);
  }

  function testTakeAfterIssuerTransferredRaftShouldFail()
    public
    returns (uint256, uint256)
  {
    uint256 raftTokenId = createRaftAndRegisterSpec();
    bytes memory signature = getSignature(
      claimantAddress,
      raftHolderPrivateKey
    );
    address newRaftHolder = address(123);

    // transfer raft to new holder
    vm.prank(raftHolderAddress);
    raftWrappedProxyV1.transferFrom(
      raftHolderAddress,
      newRaftHolder,
      raftTokenId
    );

    vm.prank(claimantAddress);
    vm.expectRevert(bytes(errTakeUnauthorized));
    uint256 tokenId = badgesWrappedProxyV1.take(
      raftHolderAddress,
      specUri,
      signature
    );

    assertEq(badgesWrappedProxyV1.balanceOf(claimantAddress), 0);

    return (raftTokenId, tokenId);
  }

  function testTakeAfterIssuerTransferredRaftAndSetPreviousHolderAsAdmin()
    public
    returns (uint256, uint256)
  {
    uint256 raftTokenId = createRaftAndRegisterSpec();
    bytes memory signature = getSignature(
      claimantAddress,
      raftHolderPrivateKey
    );
    address newRaftHolder = address(123);

    // transfer raft to new holder
    vm.prank(raftHolderAddress);
    raftWrappedProxyV1.transferFrom(
      raftHolderAddress,
      newRaftHolder,
      raftTokenId
    );

    // mark the old holder as admin
    vm.prank(newRaftHolder);
    raftWrappedProxyV1.setAdmin(raftTokenId, raftHolderAddress, true);

    vm.prank(claimantAddress);
    uint256 tokenId = badgesWrappedProxyV1.take(
      raftHolderAddress,
      specUri,
      signature
    );

    assertEq(badgesWrappedProxyV1.balanceOf(claimantAddress), 1);
    assertEq(badgesWrappedProxyV1.tokenURI(tokenId), specUri);
    assertEq(badgesWrappedProxyV1.ownerOf(tokenId), claimantAddress);

    return (raftTokenId, tokenId);
  }

  function testTakeWithSigFromUnauthorizedActor() public {
    address active = claimantAddress;
    address passive = raftHolderAddress;
    uint256 badActorPrivateKey = 123;
    createRaftAndRegisterSpec();
    bytes memory signature = getSignature(active, badActorPrivateKey);

    vm.prank(active);
    vm.expectRevert(bytes(errInvalidSig));
    uint256 tokenId = badgesWrappedProxyV1.take(passive, specUri, signature);

    assertEq(tokenId, 0);
    assertEq(badgesWrappedProxyV1.balanceOf(active), 0);
  }

  function testTakeWithUnregisteredSpec() public {
    address passive = raftHolderAddress;
    address zeroAddress = address(0);
    address active = claimantAddress;

    vm.expectEmit(true, true, true, false);
    uint256 raftTokenId = raftWrappedProxyV1.mint(passive, specUri);
    emit Transfer(zeroAddress, passive, raftTokenId);

    assertEq(raftTokenId, 1);
    assertEq(raftWrappedProxyV1.balanceOf(passive), 1);

    // normally we would register the spec here
    bytes memory signature = getSignature(active, raftHolderPrivateKey);
    vm.prank(active);
    // but we didn't, so we'll get this error when we try to "take"
    // because when we look up the spec that's associated with this raft, which doesn't exist
    vm.expectRevert(bytes(err721InvalidTokenId));
    badgesWrappedProxyV1.take(passive, specUri, signature);
  }

  function testTakeWithBadTokenUri() public {
    address active = claimantAddress;

    bytes32 hash = badgesWrappedProxyV1.getAgreementHash(
      active,
      vm.addr(raftHolderPrivateKey),
      badTokenUri
    );
    // passive is always the one signing away permission for the active party to do something
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(raftHolderPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    // errors with this because we check for a valid spec URI before validating the signature
    vm.expectRevert(bytes(errInvalidSig));
    badgesWrappedProxyV1.take(passiveAddress, specUri, signature);
  }
}