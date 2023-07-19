// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../lib/Constants.sol";
import "../lib/CommonErrors.sol";
import "../lib/Roles.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {ETHSplit} from "../split/ETHSplit.sol";
import {AuctionHouse} from "../auctions/AuctionHouse.sol";
import {TokenERC721, CollectionSettings} from "../token/TokenERC721.sol";

struct DeployOptions {
  bool isUpgradeable;
  bool deployAuctionHouse;
}

contract CollectionFactory is Ownable {
    UpgradeableBeacon public tokenBeacon;
    UpgradeableBeacon public auctionBeacon;

    address public tokenAddress;
    address public auctionAddress;
    address public splitAddress;
    
    event Kairos_ContractsDeployed(address indexed _tokenAddress, 
      address indexed _auctionAddress,
      address indexed _splitAddress,
      bool _isUpgradeable);

    constructor(address _tokenContract, 
      address _auctionContract, 
      address _splitContract,
      bool _createBeacon) {

      tokenAddress = _tokenContract;
      auctionAddress = _auctionContract;
      splitAddress = _splitContract;

      if (_createBeacon) {
        tokenBeacon = new UpgradeableBeacon(_tokenContract);
        auctionBeacon = new UpgradeableBeacon(_auctionContract);
      }
    }

    function setBeacon(address _tokenBeacon, address _auctionBeacon) external onlyOwner {
      tokenBeacon = UpgradeableBeacon(_tokenBeacon);
      auctionBeacon = UpgradeableBeacon(_auctionBeacon);
      if (tokenAddress != address(0)) {
        tokenBeacon.upgradeTo(tokenAddress);
      }
      if (auctionAddress != address(0)) {
        auctionBeacon.upgradeTo(auctionAddress);
      }
    }

    function transferBeaconOwnership(address _owner) external onlyOwner {
      tokenBeacon.transferOwnership(_owner);
      auctionBeacon.transferOwnership(_owner);
    }

    function setImplementationAddresses(address _tokenContract, 
      address _auctionContract, 
      address _splitContract,
      bool _upgradeBeacon) external onlyOwner {

        tokenAddress = _tokenContract;
        auctionAddress = _auctionContract;
        splitAddress = _splitContract;
        if (_upgradeBeacon) {
          tokenBeacon.upgradeTo(_tokenContract);
          auctionBeacon.upgradeTo(_auctionContract);
        }
    }

    function deployContracts(CollectionSettings calldata _st, DeployOptions calldata _options) external onlyOwner 
      returns (address _tokenAddress, address _auctionAddress, address _splitAddress) {
        uint128 toatalRoyaltiesBps = _st.platformFeeBps + _st.royaltyBps;
        if (toatalRoyaltiesBps > MAX_BPS) {
          revert MaxBPS(toatalRoyaltiesBps, MAX_BPS);
        }

        address splitClone = _cloneSplit(_st, toatalRoyaltiesBps);
        address tokenClone = _cloneToken(_st, splitClone, toatalRoyaltiesBps, _options.isUpgradeable);
        address auctionClone;
        if (_options.deployAuctionHouse) {
          auctionClone = _cloneAuction(_st, tokenClone, _options.isUpgradeable);
          TokenERC721(tokenClone).grantRole(MINTER_ROLE, auctionClone);
        }
        TokenERC721(tokenClone).grantRole(MINTER_ROLE, _st.defaultAdmin);
        TokenERC721(tokenClone).grantRole(TRANSFER_ROLE,  _st.defaultAdmin);
        TokenERC721(tokenClone).grantRole(0x00, _st.defaultAdmin);
        TokenERC721(tokenClone).setOwner(_st.defaultAdmin);
        TokenERC721(tokenClone).renounceRole(0x00, address(this));
        TokenERC721(tokenClone).renounceRole(MINTER_ROLE, address(this));
        TokenERC721(tokenClone).renounceRole(TRANSFER_ROLE, address(this));

        emit Kairos_ContractsDeployed(tokenClone, auctionClone, splitClone, _options.isUpgradeable);
        return(tokenClone, auctionClone, splitClone);
    }

    /// @dev clone the auction contract
    function _cloneAuction(CollectionSettings calldata _st, 
      address _tokenClone, 
      bool _isUpgradeable) internal returns (address){
      address auctionClone;
      if (_isUpgradeable) {
    
        auctionClone = address(new BeaconProxy(address(auctionBeacon), 
          abi.encodeWithSelector(AuctionHouse(address(0)).initialize.selector, 
          _st.defaultAdmin, 
          _st.saleRecipient, 
          _tokenClone,
          _st.platformFeeBps, 
          _st.platformFeeRecipient)));
      } else {
        auctionClone = Clones.clone(auctionAddress);
        AuctionHouse(auctionClone).initialize(_st.defaultAdmin, 
          _st.saleRecipient, 
          _tokenClone,
          _st.platformFeeBps, 
          _st.platformFeeRecipient);
      }

      return auctionClone;
    }

    /// @dev clone the token contract
    function _cloneToken(CollectionSettings memory _st, 
      address _splitClone,
      uint128 _toatalRoyaltiesBps,
      bool _isUpgradeable) internal returns (address) {
  
      address tokenClone;
      _st.royaltyRecipient = _splitClone;
      _st.royaltyBps = _toatalRoyaltiesBps;
      address defaultAdmin = _st.defaultAdmin;
      // We change the default admin to "this", so this contract can set roles
      // we will revoke the role after setting the minter roles
      _st.defaultAdmin = address(this);
      if (_isUpgradeable) {
        tokenClone = address(new BeaconProxy(address(tokenBeacon), 
          abi.encodeWithSelector(TokenERC721(address(0)).initialize.selector, _st)));
      } else {
        tokenClone = Clones.clone(tokenAddress);
        TokenERC721(tokenClone).initialize(_st);
      }
      // Restores the defaut admin on the struct
      _st.defaultAdmin = defaultAdmin;
      return tokenClone;
    }

    /// @dev clone the split contract
    function _cloneSplit(CollectionSettings calldata _st, 
      uint128 _toatalRoyaltiesBps) internal returns (address) {

      address splitClone = Clones.clone(splitAddress);
      ETHSplit.Member[] memory splitArray = new ETHSplit.Member[](2);
      splitArray[0] = (ETHSplit.Member(_st.royaltyRecipient, 
        uint32(_st.royaltyBps),
        uint32(_toatalRoyaltiesBps)
      ));
      splitArray[1] = (ETHSplit.Member(
        _st.platformFeeRecipient,
        uint32(_st.platformFeeBps),
        uint32(_toatalRoyaltiesBps)
      ));

      ETHSplit(payable(splitClone)).initialize(splitArray);
      return splitClone;
    }
}