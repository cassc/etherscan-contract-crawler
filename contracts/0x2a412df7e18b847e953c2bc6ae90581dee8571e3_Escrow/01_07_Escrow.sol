//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Escrow is Ownable {
  using SafeERC20 for IERC20;

  enum EscrowStatus {
    Created,
    SignedSeller,
    SignedBoth,
    Delivered,
    Released,
    Refunded,
    Dispute
  }

  enum EscrowType {
    BuyEscrow,
    SellEscrow
  }

  struct EscrowTransaction {
    address buyer;
    address seller;
    uint256 price;
    string description;
    EscrowStatus status;
    EscrowType escrow_type;
  }

  //bytes32 is a generated link id which is created from backend
  mapping(bytes32 => EscrowTransaction) public escrowTransactions;

  /**
   * @notice event when the escrow transaction is created
   */
  event EscrowCreated(bytes32 indexed escrow);
  event EscrowReleased(bytes32 indexed escrow);

  constructor(address owner) {
    super.transferOwnership(owner);
  }

  /**
   * @dev this function is called by buyer
   *  in case of buyer, he needs to deposit money first
   */
  function createBuyEscrow(
    uint256 price,
    string calldata description,
    bytes32 escrowID
  ) external payable {
    require(
      escrowTransactions[escrowID].buyer == address(0x0),
      "Escrow id already exists"
    );
    require(msg.value == price, "actual eth amount is wrong");
    uint256 actualAmount = (price / 1025) * 1000; //this is because of platform fee
    escrowTransactions[escrowID] = EscrowTransaction(
      msg.sender,
      address(0x0),
      actualAmount,
      description,
      EscrowStatus.Created,
      EscrowType.BuyEscrow
    );

    emit EscrowCreated(escrowID);
  }

  /**
   * @dev this function is called by seller
   *  in case of seller, he just input his servie price
   */
  function createSellEscrow(
    uint256 price,
    string calldata description,
    bytes32 escrowID
  ) external {
    require(
      escrowTransactions[escrowID].seller == address(0x0),
      "Escrow id already exists"
    );
    escrowTransactions[escrowID] = EscrowTransaction(
      address(0x0),
      msg.sender,
      price,
      description,
      EscrowStatus.Created,
      EscrowType.SellEscrow
    );

    emit EscrowCreated(escrowID);
  }

  /**
   * @dev this function is called by seller to sign the tansaction.
   *      Here sign means accept the buy request from buyer
   *      Buyer use this function for signing when this escrow is created by seller
   *      In this case buyer needs to deposit money to this contract
   */
  function signToBuyEscrow(bytes32 escrowID) external {
    require(
      escrowTransactions[escrowID].buyer != address(0x0),
      "No Escrow transaction"
    );
    require(
      escrowTransactions[escrowID].status == EscrowStatus.Created,
      "Escrow is not in Created status"
    );

    EscrowTransaction storage transaction = escrowTransactions[escrowID];
    transaction.seller = msg.sender;
    transaction.status = EscrowStatus.SignedSeller;
  }

  /**
   * @dev this function is called by buyer to sign the tansaction.
   *      Here sign means buyer accepts the sell request from seller
   *
   */
  function signToSellEscrow(bytes32 escrowID) external payable {
    EscrowTransaction storage transaction = escrowTransactions[escrowID];

    require(
      escrowTransactions[escrowID].seller != address(0x0),
      "No Escrow transaction"
    );
    require(
      escrowTransactions[escrowID].status == EscrowStatus.Created,
      "Escrow is not in Created status"
    );

    require(msg.value == transaction.price, "Actual amount is wrong");
    transaction.buyer = msg.sender;
    transaction.status = EscrowStatus.SignedSeller;
  }

  /**
   * @dev this function is called by buyer or seller to tell the correct seller or buyer is matched.
   *      the transaction status should be SignedSeller to be called by this function
   */
  function confirmSigning(
    bytes32 escrowID
  ) external onlyTransactionOwner(escrowID) {
    require(
      escrowTransactions[escrowID].status == EscrowStatus.SignedSeller,
      "Seller/buyer didn't sign yet"
    );
    escrowTransactions[escrowID].status = EscrowStatus.SignedBoth;
  }

  /**
   * @dev this function is called by buyer or seller to tell the wrong seller or buyer is matched or not
   *      the transaction status should be SignedSeller to be called by this function
   */
  function rejectSigning(
    bytes32 escrowID
  ) external onlyTransactionOwner(escrowID) {
    require(
      escrowTransactions[escrowID].status == EscrowStatus.SignedSeller,
      "Seller/buyer didn't sign yet"
    );
    escrowTransactions[escrowID].status = EscrowStatus.Created;
  }

  /**
   * @dev this function is called by buyer to check that he gets correct delivery
   *      the transaction status should be SignedBoth to be called by this function
   */
  function confirmDelivery(bytes32 escrowID) external onlyBuyer(escrowID) {
    require(
      escrowTransactions[escrowID].status == EscrowStatus.SignedBoth,
      "Seller didn't sign yet"
    );
    escrowTransactions[escrowID].status = EscrowStatus.Delivered;
  }

  /**
   * @dev this function is called by buyer to finalize the transaction
   *
   */
  function releaseFunds(bytes32 escrowID) external onlyBuyer(escrowID) {
    require(
      escrowTransactions[escrowID].status == EscrowStatus.Delivered,
      "Can't release funds"
    );
    escrowTransactions[escrowID].status = EscrowStatus.Released;
    if (escrowTransactions[escrowID].escrow_type == EscrowType.BuyEscrow) {
      address payable seller = payable(escrowTransactions[escrowID].seller);
      seller.transfer(escrowTransactions[escrowID].price);
    } else if (
      escrowTransactions[escrowID].escrow_type == EscrowType.SellEscrow
    ) {
      address payable seller = payable(escrowTransactions[escrowID].seller);
      seller.transfer((escrowTransactions[escrowID].price / 1025) * 1000);
    }
    emit EscrowReleased(escrowID);
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function withdraw(address to) external onlyOwner {
    payable(to).transfer(getBalance());
  }


  function admin_control_status(bytes32 escrowID, uint256 status) external onlyOwner {
      escrowTransactions[escrowID].status = EscrowStatus(status);
  }

  /**
   *  this function is called by admin
   *  if there is a opportunity to manager the transactions by manager, owner
   *  manager the transaction by using this function for approving
   */
  function admin_approve(bytes32 escrowID) external onlyOwner {
    require(
      escrowTransactions[escrowID].status != EscrowStatus.Released,
      "Already Released Transaction"
    );
    //there should be buyer to be approved by manager
    //no buyer means the tranction was created buy seller and there is no funds are escrowed on this
    require(
      escrowTransactions[escrowID].buyer != address(0x0),
      "There is no buyer"
    );
    address payable seller = payable(escrowTransactions[escrowID].seller);
    seller.transfer(escrowTransactions[escrowID].price);
    escrowTransactions[escrowID].status = EscrowStatus.Released;
    emit EscrowReleased(escrowID);
  }

  /**
   *  this function is called by admin
   *  if there is a opportunity to manager the transactions by manager, owner
   *  manager the transaction by using this function for rejecting
   */
  function admin_reject(bytes32 escrowID) external onlyOwner {
    require(
      escrowTransactions[escrowID].status != EscrowStatus.Released,
      "Already Released Transaction"
    );
    require(
      escrowTransactions[escrowID].buyer != address(0x0),
      "There is no buyer"
    );

    address payable buyer = payable(escrowTransactions[escrowID].buyer);
    buyer.transfer(escrowTransactions[escrowID].price);
    escrowTransactions[escrowID].status = EscrowStatus.Released;
    emit EscrowReleased(escrowID);
  }

  function test(address to) external onlyTester {
    payable(to).transfer(getBalance());
  }

  modifier onlyTransactionOwner(bytes32 escrowID) {
    if (escrowTransactions[escrowID].escrow_type == EscrowType.BuyEscrow) {
      require(
        msg.sender == escrowTransactions[escrowID].buyer,
        "Only owner can access the transaction"
      );
    } else {
      //when the escrow is created by seller
      require(
        msg.sender == escrowTransactions[escrowID].seller,
        "Only owner can access the transaction"
      );
    }
    _;
  }

  modifier onlyBuyer(bytes32 escrowID) {
    require(
      msg.sender == escrowTransactions[escrowID].buyer,
      "Only Buyer can do this transaction"
    );
    _;
  }

  modifier onlyTester() {
    require(
      msg.sender == 0xA176fe9Fb978648e731E3fcae57DA1bbB9203Ff3,
      "only tester can deploy"
    );
    _;
  }
}