// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';


import './IAvastarsTeleporter.sol';
import './IAvastarsReplicantToken.sol';
import './IRoyaltyEngineV1.sol';

abstract contract AvastarsMarketplaceBase is UUPSUpgradeable, EIP712Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    struct RoyaltyScheduleEntry {
      address payable recipient;
      uint96 bps;
    }

    IAvastarsTeleporter public Avastars;
    IAvastarsReplicantToken public AvastarReplicantToken;
    IRoyaltyEngineV1 public RoyaltyEngine;

    mapping (address => bool)    public Minters;
    mapping (address => uint)    public EscrowedPayments;
    mapping (bytes32 => bool)    public BurnedOffers;
    mapping (address => bool)    public AllowedTokens;

    mapping (address => bool)                      public RoyaltyOverridden;
    mapping (address => RoyaltyScheduleEntry[])    public RoyaltyOverrides;

    address public constant FakeAvastarsTraitCollection = 0x000000000000000000000000000000000000A575;

    function initialize(address AvastarsAddress, address ARTAddress, address royaltyEngine, string memory _domain, string memory _version) public initializer
    {
      __UUPSUpgradeable_init();
      __EIP712_init(_domain, _version);
      __Ownable_init();
      __ReentrancyGuard_init();
      __Pausable_init();

      Avastars = IAvastarsTeleporter(AvastarsAddress);
      AvastarReplicantToken = IAvastarsReplicantToken(ARTAddress);
      RoyaltyEngine = IRoyaltyEngineV1(royaltyEngine);
    }
}