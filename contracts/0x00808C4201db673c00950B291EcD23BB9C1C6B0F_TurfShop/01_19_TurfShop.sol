// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./TurfShopEligibilityChecker.sol";

/*********************************
    
       ▄▄▄▄▀ ▄   █▄▄▄▄ ▄████  
    ▀▀▀ █     █  █  ▄▀ █▀   ▀ 
        █  █   █ █▀▀▌  █▀▀    
       █   █   █ █  █  █      
      ▀    █▄ ▄█   █    █     
            ▀▀▀   ▀      ▀    
    
            Turf Shop
              2022

*********************************/

/*
TurfShop: It's an ERC1155 vending machine. It allows for multiple sales and give-aways.

Each specific mint is configured according to the options in its TurfObject struct.

Additional logic around how much a user can mint, and if they're eligible to mint at all,
can be deployed in a secondary contract defined by the `eligibilityCheckerAddress` address on a TurfObject.

See the simple TurfShopEligibilityChecker interface for how that works, or the set of examples living alongside this contract.
*/

contract TurfShop is ERC1155, ERC1155Supply, Ownable, AccessControl, ReentrancyGuard {
  // Yes using Ownable and AccessControl is weird. We don't use Ownable in the code, but OpenSea was a little
  // picky about who "owned" a contract, and we need to transferOwnership, which Ownable supports and OpenSea likes.

  using Counters for Counters.Counter;

  // Users with this role can manage sale data.
  bytes32 public constant MERCH_ROLE = keccak256("MERCH_ROLE");

  // An object can be set or scheduled for minting a few ways:
  // ON_OFF: We just have a bool that determines if it's mintable.
  // TIMESTAMP: Set a `startingReference` and a `endReference`, and the object is mintable between those times.
  // BLOCK_NUMBER: Set a `startingReference` and a `endReference`, and the object is mintable between those block numbers.
  enum TurfObjectReleaseType{ ON_OFF, TIMESTAMP, BLOCK_NUMBER }

  string public name = "Turf Objects";
  string public symbol = "TURF_OBJ";

  struct TurfObject {
    string name; // An internal/descriptive name, the actual name displayed to folks will be in the metadata.
    uint initialSupply; // How many items are available?
    uint startingReference; // Depending on releaseType, this can either be a block number or a timestmap.
    uint endReference; // Depending on releaseType, this can either be a block number or a timestmap.
    bool isOpen; // If releaseType is ON_OFF, this will determine if the sale is active or not.
    address eligibilityCheckerAddress; // The address we'll proxy elgibility checks to.
    address fundsRecipientAddress; // If an object accepts Eth, this is the address we'll transfer the funds to for that sale.
    bool emergencyStopper; // Shut down a sale by setting this to true.
    uint maxAmountPerWallet;
    bool allowAdjustableQty; // If this is true then the minter can specify how many items they want, otherwise we'll mint as much as possible for them.
    uint price; // The price of this item, if it's a sale.
    TurfObjectReleaseType releaseType;
  }

  Counters.Counter private turfObjectCounter;
  
  mapping (uint => TurfObject) public turfObjects;

  // Used to track how much of an item was minted per person, especially useful in the case
  // when we want to limit the amount of items minted per wallet.
  // objectIds -> (address -> mintedCount)  
  mapping(uint => mapping(address => uint)) public mintsPerWalletPerObjectId;

  // Track how much any given object's mint earned here.
  // We can't actually slice up the eth directly, but we'll do our best to do the book keeping
  // so we're able to track the numbers correcfly.
  mapping(uint => uint) public ethPerTurfObject;

  event NewTurfObjectSetup(uint);

  modifier onlyAdmin {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin role required for this action");
    _;
  }

  modifier onlyStaff {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(MERCH_ROLE, msg.sender), "Staff role required for this action");
    _;
  }  

  // Use before minting to confirm that the object being minted is OK to mint now.
  // We support a few options:
  // - ON_OFF: just a simple bool.
  // - TIMESTAMP: allows mint between two block.timestamps.
  // - BLOCK_NUMBER: allows mint between two block.numbers.
  //
  modifier checkReleaseStatus(uint objectId){
    // We can just shut something down if we want to, by updating the turfObject's emergencyStopper value.
    require(!turfObjects[objectId].emergencyStopper, "stopped!");
    if(turfObjects[objectId].releaseType == TurfObjectReleaseType.ON_OFF){
      require(turfObjects[objectId].isOpen, 'mint not active (type 1)');
    } else if(turfObjects[objectId].releaseType == TurfObjectReleaseType.TIMESTAMP){
      require(block.timestamp >= turfObjects[objectId].startingReference && block.timestamp <= turfObjects[objectId].endReference, 'mint not active (type 2)');
    } else if(turfObjects[objectId].releaseType == TurfObjectReleaseType.BLOCK_NUMBER){
      require(block.number >= turfObjects[objectId].startingReference && block.number <= turfObjects[objectId].endReference, 'mint not active (type 3)');
    } else {
      revert('invalid release type');
    }
    _;
  }

  constructor(string memory uri_) ERC1155(uri_) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // Make sure the deployer is an admin.
  }

  // @notice Returns the metadata URI for the given token ID.
  // @param tokenId The token ID.
  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(ERC1155.uri(tokenId), Strings.toString(tokenId), '.json'));
  }

  // @notice Sets up a new Turf Object. Emits an event with the new object's ID.
  // @param turfObject The new object's struct.
  function setupNewObject(TurfObject calldata turfObject) public onlyStaff {
    require(turfObject.initialSupply > 0, "can't setup a 0 supply object");
    require(turfObject.maxAmountPerWallet > 0, "maxAmountPerWallet should be greater than 0");
  
    turfObjects[turfObjectCounter.current()] = turfObject;
    
    // Tell the world:
    emit NewTurfObjectSetup(turfObjectCounter.current());
    
    // Bump us up so we're ready for the next one.
    turfObjectCounter.increment();
  }

  /** @notice Replaces the object at the given `objectId` with a new TurfObject consisting of the given struct.
  Admin only, not staff, to prevent needless meddling.
  This won't adjust balances.
  Probably do not want to do this once a sale is live.
  */
  // @param objectId The ID of the object being updated.
  // @param turfObject The replacement struct.
  function updateObject(uint objectId, TurfObject calldata turfObject) public onlyAdmin {
    turfObjects[objectId] = turfObject;
  }

  /** @notice The mint function.
  Note that the given desired `amount` might be ignored depending on the logic of the TurfObject itself.
  For example, in the case of give-aways, the mintee will be transferred a quantity of objects
  according to that mint's logic regardless of what's specified in `amount`.
  */
  // @param objectId The Turf Object ID to mint
  // @param amount The desired count of items to mint. Might be ignored.
  // @param merkleProof If a Merkle Tree is being used for verification, pass the proof in here.
  // @param data Extra data needed on a case-by-case basis.
  function mint(uint objectId, uint amount, bytes32[] memory merkleProof, bytes memory data) public payable nonReentrant checkReleaseStatus(objectId) {
    // Assuming the sale is even on, according to `checkReleaseStatus`, we need to see that the sender themselves
    // are legit to mint. And we do that by referencing an external contract, where the logic this check lives.

    uint _amount = amount;

    TurfObject memory obj = turfObjects[objectId];

    TurfShopEligibilityChecker checker = TurfShopEligibilityChecker(obj.eligibilityCheckerAddress);
    
    // Some sales can allow the user to pick the quantity.
    // The presence of this changes the logic of the mint in a few ways.
    if(obj.allowAdjustableQty){

      // TurfShopEligibilityChecker returns 2 values, a max allowed for that person and just a bool, if they're eligible or not.
      // If we're using the checker in this context (of an adjustable quantity) we're not going to care about the maxAllowed it returns,
      // only the eligiblity. The use case for this is really just allow lists. maxAllowed is ignored because we set the maxAmountPerWallet on the turfObject itself.

      if(obj.eligibilityCheckerAddress != address(0)){
        (bool isEligible, uint maxAllowed) = checker.check(msg.sender, merkleProof, data);
        require(isEligible, "not eligible");
      }
    } else {
      // Generally we'll just force the minting to the full amount allowed, as returned by the eligibity contract.
      // If that's the case the cost will most likely be 0.
      
      // This also means that the starting amount should be properly set so everyone gets what they're supposed to, this onus is on the TurfObject configuring individual.

      // If `allowAdjustableQty` is false we're going to rely entirely on the returned `maxAllowed` from the checker contract.
      (bool isEligible, uint maxAllowed) = checker.check(msg.sender, merkleProof, data);
      require(isEligible, "not eligible");
      _amount = maxAllowed;
    }

    // If this was an adjustable qty mint then we store the minted objects per address on each mint, to prevent re-minting by that same address.
    // If it's not adjustable we'll assume the Checker contract is tracking this on its own.
    uint mintedPerWallet = (obj.allowAdjustableQty ? mintsPerWalletPerObjectId[objectId][msg.sender] : 0);

    require(
        mintedPerWallet + _amount <= obj.maxAmountPerWallet,
        "exceeded limit per wallet"
    );

    // Check the amount sent is correct, even if it's free.
    require(msg.value == obj.price * _amount, "Sent incorrect Eth");

    require(totalSupply(objectId) + _amount <= obj.initialSupply, "Would exceed max supply");

    // Tell the checker we did our business.
    checker.confirmMint(msg.sender, _amount);

    // Make sure there's still enough to go around.
    // OK if we got here, we're good!
    _mint(msg.sender, objectId, _amount, "");

    // Track how much was paid into this object specifically, for appropriate transfer later on.
    ethPerTurfObject[objectId] = ethPerTurfObject[objectId] + (obj.price * _amount);

     // We'll record how many items a wallet minted only in the case that the quantity is adjustable.
     // We don't care about this if it's a free give away with the quantity set by our Checker contract's logic.
    if(obj.allowAdjustableQty){
      mintsPerWalletPerObjectId[objectId][msg.sender] = mintedPerWallet + _amount;
    }
  }

  // @notice Airdropper
  // @param objectId The Turf Object ID to airdrop
  // @param count How many of that item to send
  // @param addr The recipient's address
  // @dev This won't do any checks of any kind. Danger zone!
  function airdrop(uint objectId, uint count, address addr) public onlyAdmin nonReentrant {
    _mint(addr, objectId, count, "");
  }

  // @notice Fires off the funds for the given Turf Object, off to wherever they go.
  // @params objectId The Turf Object ID associated with the eth we're sending to the proxy.
  function transferFunds(uint objectId) public nonReentrant onlyStaff {
    // I know 'pull' is preferred over 'push', but we're only going to ever be sending to split contracts that we setup,
    // and partners will pull their funds from there.
    uint amountToTransfer = ethPerTurfObject[objectId];
    require(amountToTransfer > 0, "can't transfer 0 eth out");
    address destination = turfObjects[objectId].fundsRecipientAddress;
    payable(destination).transfer(amountToTransfer);
  }

  // @dev Kind of an emegency option, if funds are stuck or something weird is happening with tracking individual tokens' funds.
  // @params address The reipient address of the eth.
  function withdrawAll(address addr) public nonReentrant onlyAdmin {
    payable(addr).transfer(address(this).balance);
  }

  // @notice grant the MERCH_ROLE to an address.
  // @params addr The address to grant the role to.
  function grantMerchRole(address addr) public onlyAdmin {
    grantRole(MERCH_ROLE, addr);
  }

  // @notice Remove the MERCH_ROLE from the given address.
  // @params addr The address to remove the role from.
  function removeMerchRole(address addr) public onlyAdmin {
    revokeRole(MERCH_ROLE, addr);
  }

  function setURI(string memory newURI) external onlyAdmin {
    _setURI(newURI);
  }

  // @notice Returns the newest Turf Object's ID.
  function currentObjectId() external view returns (uint){
    // The counter gets incremented after a new object is setup,
    // so we subract one to get the actual current ID of the most recently created object.
    return turfObjectCounter.current() - 1;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // @dev Needed by Solidity.
  function _beforeTokenTransfer(
      address operator,
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // @notice In case any wayward tokens make their way over.
  function withdrawTokens(IERC20 token) external nonReentrant onlyAdmin {
      uint256 balance = token.balanceOf(address(this));
      token.transfer(msg.sender, balance);
  }

  // @notice Allow us to receive arbitrary ETH if sent directly.
  receive() external payable {}  

  // @dev Useful to check the logic of an object's TurfObjectReleaseType.BLOCK_NUMBER-style mintability logic.
  function checkReleaseStatusByBlock(uint objectId) external view returns (bool, uint256, uint256, uint256) {
    bool r = block.number >= turfObjects[objectId].startingReference && block.number <= turfObjects[objectId].endReference;
    return (r, block.number, turfObjects[objectId].startingReference, turfObjects[objectId].endReference);
  }

  // @dev Useful to check the logic of an object's TurfObjectReleaseType.TIMESTAMP-style mintability logic.
  function checkReleaseStatusByTime(uint objectId) external view returns (bool, uint256, uint256, uint256) {
    bool r = block.timestamp >= turfObjects[objectId].startingReference && block.timestamp <= turfObjects[objectId].endReference;
    return (r, block.timestamp, turfObjects[objectId].startingReference, turfObjects[objectId].endReference);
  }

}