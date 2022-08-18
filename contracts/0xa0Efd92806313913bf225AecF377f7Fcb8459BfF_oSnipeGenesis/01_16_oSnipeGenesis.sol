// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1155Guardable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// 157 123 156 151 160 145 //

/// @author Quit (twitter: @0xQuit)
/// @title oSnipe Genesis Pass (twitter: @oSnipeNFT)
contract oSnipeGenesis is ERC1155Guardable, Ownable {
  using Math for uint;
  using Strings for uint256;

  string public constant name = "oSnipe Genesis Pass";
  string public constant symbol = "SNIPE";

  uint256 private constant SNIPER_PRICE = 0.5 ether;
  uint256 private constant OBSERVER_PRICE = 0.03 ether;
  uint256 private constant PURVEYOR_PRICE = 3 ether;
  uint256 private constant SNIPER_ID = 0;
  uint256 private constant PURVEYOR_ID = 1;
  uint256 private constant OBSERVER_ID = 2;
  uint256 private constant COMMITTED_SNIPER_ID = 10;
  uint256 private constant COMMITTED_PURVEYOR_ID = 11;

  uint256 public constant MAX_SNIPERS_SUPPLY = 488;
  uint256 public constant MAX_OBSERVERS_PER_COMMITTED = 10;
  bytes32 public merkleRoot;
  uint256 public numSnipersMinted;

  mapping(address => uint256) observersMinted;

  constructor(string memory _uri, bytes32 _root) ERC1155(_uri) { 
    _mintSnipers(owner(), 13);
    _mint(owner(), PURVEYOR_ID, 1, "");
    _mint(owner(), OBSERVER_ID, 100, "");
    merkleRoot = _root;
  }

  error CannotTransferCommittedToken();
  error NotEnoughTokens();
  error AlreadyClaimed();
  error InvalidProof(bytes32[] proof);
  error WrongValueSent();
  error SaleIsPaused();
  error BurnExceedsMinted();
  error TooManyOutstandingObservers(uint256 numberOfObservers, uint256 numberAllowed);

  mapping(address => bool) public alreadyClaimed;
  mapping(address => bool) public alreadyMinted;

  bool public saleIsActive = false;

  /// @notice Sets a new root for free claim verification
  /// @param _root The root to set
  function setMerkleRoot(bytes32 _root) public onlyOwner {
    merkleRoot = _root;
  }

  /// @notice Sets the base metadata URI
  /// @param newuri The new URI
  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  /// @notice Returns the URI for a given token ID
  /// @param tokenId The ID to return URI for
  /// @return TokenURI
  function uri(uint256 tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
  }

  /// @notice Flips public sale state
  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  /// @notice Allows one free claim for each addresses included in the merkle tree
  /// @param _proof The merkle proof to claim with
  function claimSniper(bytes32[] calldata _proof) public {
    if (alreadyClaimed[msg.sender]) revert AlreadyClaimed();

    bytes32 leaf = keccak256((abi.encodePacked(msg.sender)));

    if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
      revert InvalidProof(_proof);
    }

    alreadyClaimed[msg.sender] = true;
    _mintSnipers(msg.sender, 1);
  }

  /// @notice Public function for purchasing Sniper's. Max one per address. Sale must be active.
  /// @dev must send SNIPER_PRICE
  function mintSnipers() public payable {
    if (!saleIsActive) revert SaleIsPaused();
    if (msg.value != SNIPER_PRICE) revert WrongValueSent();
    if (alreadyMinted[msg.sender]) revert AlreadyClaimed();

    alreadyMinted[msg.sender] = true;
    _mintSnipers(msg.sender, 1);
  }

  /**
  * @notice Mints Observer Passes. A sniper can pay to mint up to `MAX_OBSERVERS_PER_COMMITTED` Observers for each Sniper or Purveyor
  * they own. By minting Observers, a Sniper or Purveyor becomes committed. Committed Sniper/Purveyor tokens are untransferrable.
  * In order to uncommit a token, the Observers must be retrieved and redeemed (burned). They do not have to be the same Observers
  * as initially minted, just the same amount.
  * Note that if you have multiple Sniper/Purveyor Passes, you may transfer them as long as you don't fall below a 1:10 ratio of Sniper/Purveyors to Observers.
  * Note that Snipers are committed first, followed by Purveyors if necessary.
  */
  /// @param amount The number of observers to mint.
  /// @dev Must send `OBSERVER_PRICE` * `amount`.
  function mintObservers(uint256 amount) public payable {
    if (msg.value != amount * OBSERVER_PRICE) revert WrongValueSent();

    uint256 newBalance = observersMinted[msg.sender] + amount;

    if (newBalance > maxObserversPermitted(_committedTokenBalance(msg.sender))) {
      uint256 maxObserversPossible = maxObserversPermitted(_uncommittedTokenBalance(msg.sender))
                                    + maxObserversPermitted(_committedTokenBalance(msg.sender))
                                    - observersMinted[msg.sender];

      if (newBalance > maxObserversPossible) {
        revert TooManyOutstandingObservers(newBalance, maxObserversPermitted(_committedTokenBalance(msg.sender)));
      }

      uint256 observerDelta = amount - (maxObserversPermitted(_committedTokenBalance(msg.sender)) - observersMinted[msg.sender]);
      uint256 toBeCommitted = observerDelta.ceilDiv(10);

      if (balanceOf(msg.sender, SNIPER_ID) >= toBeCommitted) {
        _burn(msg.sender, SNIPER_ID, toBeCommitted);
        _mint(msg.sender, COMMITTED_SNIPER_ID, toBeCommitted, "");
      } else {
        uint256[] memory ids = new uint256[](2);
        ids[0] = SNIPER_ID;
        ids[1] = PURVEYOR_ID;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = balanceOf(msg.sender, SNIPER_ID);
        amounts[1] = toBeCommitted - amounts[0];

        _burnBatch(msg.sender, ids, amounts);

        unchecked { ids[0] += 10; }
        unchecked { ids[1] += 10; }

        _mintBatch(msg.sender, ids, amounts, "");
      }
    }

    observersMinted[msg.sender] = newBalance;

    _mint(msg.sender, OBSERVER_ID, amount, "");
  }

  /**
  * @notice Redeems Observer Passes and uncommits as many committed NFTs as possible without
  * falling below the maximum allowed ratio of `MAX_OBSERVERS_PER_COMMITTED` per Sniper/Purveyor.
  * Note Purveyors are uncommitted first, followed by Snipers.
  */
  /// @param amount The number of Observers to redeem (burn).
  function redeemObservers(uint256 amount) external {
    if (observersMinted[msg.sender] < amount) revert BurnExceedsMinted();
    
    unchecked { observersMinted[msg.sender] -= amount; }

    _burn(msg.sender, OBSERVER_ID, amount);
    uint256 observerDelta = maxObserversPermitted(_committedTokenBalance(msg.sender)) - balanceOf(msg.sender, OBSERVER_ID);
    uint256 toBeUncommitted = observerDelta / 10;
    
    if (balanceOf(msg.sender, COMMITTED_PURVEYOR_ID) >= toBeUncommitted) {
      _burn(msg.sender, COMMITTED_PURVEYOR_ID, toBeUncommitted);
      _mint(msg.sender, PURVEYOR_ID, toBeUncommitted, "");
    } else {
      uint256[] memory ids = new uint256[](2);
      ids[0] = COMMITTED_PURVEYOR_ID;
      ids[1] = COMMITTED_SNIPER_ID;

      uint256[] memory amounts = new uint256[](2);
      amounts[0] = balanceOf(msg.sender, COMMITTED_PURVEYOR_ID);
      amounts[1] = toBeUncommitted - amounts[0];

      _burnBatch(msg.sender, ids, amounts);

      unchecked { ids[0] -= 10; }
      unchecked { ids[1] -= 10; }

      _mintBatch(msg.sender, ids, amounts, "");
    }
  }

  /// @notice Burns a Sniper's Pass to upgrade to a Purveyor
  /// @dev Must send `PURVEYOR_PRICE`.
  function burnForPurveyor(uint256 amount) external payable {
    if (msg.value != PURVEYOR_PRICE * amount) revert WrongValueSent();

    _burn(msg.sender, SNIPER_ID, amount);
    _mint(msg.sender, PURVEYOR_ID, amount, "");
  }

  /// @notice Overrides ERC1155 safeTransferFrom. Prevents transfers of committed tokens.
  /// @dev See {IERC1155-safeTransferFrom}.
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public override {
    if (id == COMMITTED_SNIPER_ID || id == COMMITTED_PURVEYOR_ID) {
      revert CannotTransferCommittedToken();
    }
    super.safeTransferFrom(from, to, id, amount, data);
  }

  /// @notice Overrides ERC1155 safeBatchTransferFrom. Prevents transfers that include committed tokens.
  /// @dev See {IERC1155-safeBatchTransferFrom}.
  function safeBatchTransferFrom(
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  ) public override {
      for (uint256 i = 0; i < ids.length; i++ ) {
        if (ids[i] == COMMITTED_PURVEYOR_ID || ids[i] == COMMITTED_SNIPER_ID) {
          revert CannotTransferCommittedToken();
        }
      }

      super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /// @notice Withdraws full contract balance to owner
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    if (!success) revert WrongValueSent();
  }

  /// @param committedTokenBalance The balance of committed tokens used to calculate max Observers
  /// @notice Used to determine hypothetical maximums
  /// @return maximum The maximum Observers for a given balance
  function maxObserversPermitted(uint256 committedTokenBalance) internal pure returns (uint) {
    return committedTokenBalance * MAX_OBSERVERS_PER_COMMITTED;
  }

  /// @notice Returns the balance of committed Snipers and Purveyors for a given user
  /// @param user Address of the user to query for
  /// @return balances The number of committed tokens held by a user
  function _committedTokenBalance(address user) internal view returns (uint256) {
    return balanceOf(user, COMMITTED_SNIPER_ID) + balanceOf(user, COMMITTED_PURVEYOR_ID);
  }

  /// @notice Returns the balance of uncommitted Snipers and Purveyors for a given user
  /// @param user Address of the user to query for
  /// @return balances The number of uncommitted tokens held by a user
  function _uncommittedTokenBalance(address user) internal view returns (uint256) {
    return balanceOf(user, SNIPER_ID) + balanceOf(user, PURVEYOR_ID);
  }

  /// @notice Mints a new Sniper's Pass
  /// @param to The address to mint to
  /// @param amount The number of Sniper's Passes to mint
  /// @dev Must not surpass max Sniper's Pass supply of 488
  function _mintSnipers(address to, uint256 amount) internal {
    if (numSnipersMinted + amount > MAX_SNIPERS_SUPPLY) revert NotEnoughTokens();

    unchecked { numSnipersMinted += amount; }
    _mint(to, SNIPER_ID, amount, "");
  }
}