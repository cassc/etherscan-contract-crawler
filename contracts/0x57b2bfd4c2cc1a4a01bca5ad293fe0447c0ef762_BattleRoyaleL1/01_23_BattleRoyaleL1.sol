// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AxelarExecutable } from "@axelar/contracts/executable/AxelarExecutable.sol";
import { Auth } from "../Auth.sol";
import { Card } from "../Card.sol";
import { Stance } from "../Stance.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { OperationType } from "../OperationType.sol";
import { IAxelarGasService } from "@axelar/contracts/interfaces/IAxelarGasService.sol";

enum TicketPrices {
  LOW,
  MEDIUM,
  HIGH
}

contract BattleRoyaleL1 is Auth, AxelarExecutable, Pausable {
  IAxelarGasService public immutable gasReceiver;
  string public destinationChain;
  bytes32 public destinationChainHash;
  string public destinationAddress;
  bytes32 public destinationAddressHash;

  address payable public protocolFeeBeneficiary;
  uint256 public protocolFee;

  error ExecuteInvalidOrigin();
  error NotEnoughEth();
  error NotSupportedCollection();
  error NFTNotOwned();
  error BadAssetTicketPrice();

  mapping(address => mapping(TicketPrices => uint256)) public ticketPrices;

  mapping(address => bool) public supportedCollections;

  constructor(
    address _gateway,
    address _gasReceiver,
    address payable _protocolFeeBeneficiary,
    uint256 _protocolFee
  ) AxelarExecutable(_gateway) Auth(msg.sender) {
    protocolFeeBeneficiary = _protocolFeeBeneficiary;
    protocolFee = _protocolFee;
    gasReceiver = IAxelarGasService(_gasReceiver);
  }

  /**
   * @notice Adds an owned NFT to a Battle Royale queue
   *
   * @dev This function is called by the owner of the NFT
   * @dev This process will be resolved at the L2 chain
   *
   * @param _betAsset Address of the betting asset for this Battle Royale queue
   * @param _ticketPrice Ticket price for this Battle Royale queue
   * @param _fighter Fighter stats to be queued
   * @param _cardProof Merkle proof of the card stats (it will be checked at L2)
   * @param _stance Stance of the fighter
   * @param _collection Address of the fighter NFT collection
   * @param _nftId ID of the fighter NFT
   */
  function queue(
    address _betAsset,
    TicketPrices _ticketPrice,
    Card memory _fighter,
    bytes32[] memory _cardProof,
    Stance _stance,
    address _collection,
    uint256 _nftId
  ) external payable whenNotPaused {
    uint256 fee = protocolFee;
    if (fee >= msg.value) {
      revert NotEnoughEth();
    }
    if (!supportedCollections[_collection]) {
      revert NotSupportedCollection();
    }

    if (ERC721(_collection).ownerOf(_nftId) != msg.sender) {
      revert NFTNotOwned();
    }
    uint256 ticketPrice = ticketPrices[_betAsset][_ticketPrice];
    if (ticketPrice == 0) {
      revert BadAssetTicketPrice();
    }

    ERC20(_betAsset).transferFrom(msg.sender, address(this), ticketPrice);

    _sendMessage(
      msg.value - fee,
      abi.encode(
        OperationType.ENQUEUE,
        abi.encode(
          _betAsset, _ticketPrice, _fighter, _cardProof, _stance, _collection, _nftId, msg.sender
        )
      )
    );
  }

  /**
   * @notice Executes the next Battle Royale queue
   * @dev It can be called by anyone
   * @dev This process will be resolved at the L2 chain, sending a message back to this contract with the result
   */
  function executeNextBattleRoyale(address _asset, TicketPrices _ticketPrice)
    external
    payable
    whenNotPaused
  {
    _sendMessage(msg.value, abi.encode(OperationType.EXECUTE, abi.encode(_asset, _ticketPrice)));
  }

  /**
   * @notice Sets the protocol fee
   * @dev It can be called by an authorized address
   *
   * @param _protocolFee New protocol fee
   *
   */
  function setProtocolFee(uint256 _protocolFee) external authorized {
    protocolFee = _protocolFee;
  }

  /**
   * @notice Withdraws the protocol fees (in ETH)
   * @dev It can be called by an authorized address
   *
   * @param _fee Amount of fees to withdraw
   */
  function withdrawFees(uint256 _fee) external authorized {
    protocolFeeBeneficiary.transfer(_fee);
  }

  /**
   * @notice Sets the protocol fee beneficiary
   * @dev It can be called by an authorized address
   *
   * @param _beneficiary New protocol fee beneficiary
   */
  function setProtocolFeeBeneficiary(address payable _beneficiary) external authorized {
    protocolFeeBeneficiary = _beneficiary;
  }

  /**
   * @notice Sets the ticket price for a given asset
   * @dev It can be called by an authorized address
   *
   * @param _asset Address of the asset
   * @param _priceType Type of ticket price
   * @param _newPrice New ticket price
   */
  function setTicketPrice(address _asset, TicketPrices _priceType, uint256 _newPrice)
    external
    authorized
  {
    ticketPrices[_asset][_priceType] = _newPrice;
  }

  /**
   * @notice Sets the supported collections
   * @dev It can be called by an authorized address
   *
   * @param collection Address of the collection
   * @param supported Whether the collection is supported or not
   */
  function setSupportedCollection(address collection, bool supported) external authorized {
    supportedCollections[collection] = supported;
  }

  /**
   * @notice Recovers assets from the contract (emergency use)
   * @dev It can be called by an authorized address
   *
   * @param assets Addresses of the assets to recover
   * @param amounts Amounts of the assets to recover
   * @param to Addresses to send the assets to
   */
  function recoverAssets(address[] memory assets, uint256[] memory amounts, address[] memory to)
    external
    authorized
  {
    for (uint256 i = 0; i < assets.length; i++) {
      ERC20(assets[i]).transfer(to[i], amounts[i]);
    }
  }

  /**
   * @notice Sets the destination chain
   * @dev It can be called by an authorized address
   * @dev It will be used to validate the origin chain of the result messages
   *
   * @param _newDest New destination chain
   */
  function setDestinationChain(string memory _newDest) external authorized {
    destinationChain = _newDest;
    destinationChainHash = keccak256(abi.encodePacked(_newDest));
  }

  /**
   * @notice Sets the destination address
   * @dev It can be called by an authorized address
   * @dev It will be used to validate the origin address of the result messages
   *
   * @param _newAddr New destination address
   */
  function setDestinationAddress(string memory _newAddr) external authorized {
    destinationAddress = _newAddr;
    destinationAddressHash = keccak256(abi.encodePacked(_newAddr));
  }

  /**
   * @notice Pauses the contract
   * @dev It can be called by an authorized address
   *
   * @param _paused Whether the contract should be paused or not
   */
  function pause(bool _paused) external authorized {
    if (_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function _execute(
    string calldata _sourceChain,
    string calldata _sourceAddress,
    bytes calldata _payload
  ) internal override {
    if (!_validOrigin(_sourceChain, _sourceAddress)) {
      revert ExecuteInvalidOrigin();
    }
    (address winner, address asset, TicketPrices ticketPrice, uint256 numberOfFighters) =
      abi.decode(_payload, (address, address, TicketPrices, uint256));

    uint256 prize = ticketPrices[asset][ticketPrice] * numberOfFighters;
    ERC20(asset).transfer(winner, prize);
  }

  function _sendMessage(uint256 _gas, bytes memory _payload) private {
    gasReceiver.payNativeGasForContractCall{ value: _gas }(
      address(this), destinationChain, destinationAddress, _payload, msg.sender
    );
    gateway.callContract(destinationChain, destinationAddress, _payload);
  }

  function _validOrigin(string memory _originChain, string memory _originAddress)
    private
    view
    returns (bool)
  {
    return keccak256(abi.encodePacked(_originChain)) == destinationChainHash
      && keccak256(abi.encodePacked(_originAddress)) == destinationAddressHash;
  }
}