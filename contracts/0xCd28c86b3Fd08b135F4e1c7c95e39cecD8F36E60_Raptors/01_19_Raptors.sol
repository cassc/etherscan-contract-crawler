//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// import "erc721a/contracts/ERC721A.sol";
import "./lib/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Raptors is ERC721A, ERC2981, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;
  using SafeMath for uint256;
  /**
   * @dev MINT DETAILS
   */
  uint256 public constant MAX_RAPTORS = 7777;
  uint256 public constant MAX_MINT = 10;
  uint96 public ROYALTY_BASIS_POINTS = 750;

  /**
   * @dev METADATA
   */
  string private baseURIString;

  /**
   * @dev ADDRESSES
   */
  address public OGREX_ADDRESS;
  address public METALABS_RECEIVER;

  /**
   * @dev CONTRACT STATES
   */
  enum State {
    Setup,
    Live,
    Closed
  }
  State private state;

  mapping(uint256 => bool) public rexForRaptor;

  event BalanceWithdrawn(address receiver, uint256 value);

  constructor() ERC721A("Raptors", "RAPTORS", MAX_MINT) {
    OGREX_ADDRESS = address(0x325bAd883B4E9a35277E99902D94DD18186Ae219);
    METALABS_RECEIVER = address(0xb6ff94521C3ed48e7cAfDBa1Acee0238111Dd329);
    baseURIString = "https://api.jurassicpunks.io/raptor/";
    state = State.Setup;
    _setDefaultRoyalty(METALABS_RECEIVER, ROYALTY_BASIS_POINTS);
  }

  /**
   * @notice Check token URI for given tokenId
   * @param tokenId Raptor token ID
   * @return API endpoint for token metadata
   */
  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721A) returns (string memory) {
    return string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
  }

  /**
   * @notice Check the token URI
   * @return Base API endpoint for token metadata URI
   */
  function baseTokenURI() public view virtual returns (string memory) {
    return baseURIString;
  }

  /**
   * @notice Update the token URI for the contract
   * @param tokenUriBase_ New metadata endpoint to set for contract
   */
  function setTokenURI(string memory tokenUriBase_) public onlyOwner {
    baseURIString = tokenUriBase_;
  }

  /**
   * @notice Contract Owner function to set the OG-Rex address
    * @param ogrexAddress_ Address of OG-Rex contract
   */
  function setRexAddress(address ogrexAddress_) public onlyOwner {
    OGREX_ADDRESS = ogrexAddress_;
  }

  /**
   * @notice Check current contract state
   * @return state contract state
   */
  function contractState() public view virtual returns (State) {
    return state;
  }

  /**
   * @notice Set contract state to Setup
   */
  function setStateToSetup() public onlyOwner {
    state = State.Setup;
  }

  /**
   * @notice Set contract state to Live
   */
  function setStateToLive() public onlyOwner {
    require(state == State.Setup, "Contract is not in Setup state");
    state = State.Live;
  }

  /**
   * @notice Set contract state to Closed
   */
  function setStateToClosed() public onlyOwner {
    state = State.Closed;
  }

  /**
   * @notice Function to get minted status of OG-Rex
   * @param tokenIds uint256 array of OG-Rex token IDs
   * @return rexStatus bool array of minted Raptor status for OG-Rex
   */
  function getRexMintedStatus(
    uint256[] calldata tokenIds
  ) public view returns (bool[] memory) {
    bool[] memory rexStatus = new bool[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      rexStatus[i] = rexForRaptor[tokenIds[i]];
    }
    return rexStatus;
  }

  /**
   * @notice Function to check if address is owner of OG-Rex
   * @param tokenId OG-Reg token to check for ownership
   * @param _address Address to check for OG-Rex ownership
   */
  function isRexOwner(
    uint256 tokenId,
    address _address
  ) public view returns (bool) {
    address owner = IERC721A(OGREX_ADDRESS).ownerOf(tokenId);
    if (owner == _address) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @notice Function to check if address is owner of OG-Rex
   * @param tokenId OG-Reg array token to check for ownership
   * @param _address Address to check for OG-Rex ownership
   */
  function isRexBatchOwner(
    uint256[] calldata tokenId,
    address _address
  ) public view returns (bool) {
    for (uint256 i = 0; i < tokenId.length; i++) {
      require(
        isRexOwner(tokenId[i], _address),
        "Address is not owner of OG-REX batch"
      );
    }
    return true;
  }

  /**
   * @notice Function to mint a single Raptor for OG-Rex
   * @param rexId uint256 OG-Rex ID to check for ownership
   */
  function mintRaptor(
    uint256 rexId
  ) public virtual nonReentrant returns (uint256) {
    address recipient = msg.sender;
    require(state == State.Live, "JPunks: Raptors aren't available yet!");
    require(isRexOwner(rexId, recipient), "You are not the owner of OG-Rex");
    require(
      !rexForRaptor[rexId],
      "The Raptor for this OG-Rex has already been minted."
    );
    require(
      totalSupply().add(1) <= MAX_RAPTORS,
      "Sorry, there is not that many Raptors left."
    );

    uint256 raptorRecieved = rexId;

    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(recipient, 1);
    rexForRaptor[rexId] = true;

    return raptorRecieved;
  }

  /**
   * @notice Function to mint a batch of Raptors for OG-Rex
   * @param rexIds uint256 array of OG-Rex array ID to check for ownership
   */
  function mintRaptorBatch(
    uint256[] calldata rexIds
  ) public virtual nonReentrant returns (uint256) {
    address recipient = msg.sender;
    require(state == State.Live, "JPunks: Raptors aren't available yet!");
    require(
      isRexBatchOwner(rexIds, recipient),
      "You are not the owner of OG-Rex"
    );
    require(
      totalSupply().add(rexIds.length) <= MAX_RAPTORS,
      "Sorry, there's not that many Raptors left."
    );
    require(
      rexIds.length <= MAX_MINT,
      "You can only mint 10 Raptors at a time."
    );

    uint256 firstRaptorRecieved = rexIds[0];

    for (uint256 i = 0; i < rexIds.length; i++) {
      require(
        !rexForRaptor[rexIds[i]],
        "The Raptor for this OG-Rex has already been minted."
      );
      if (msg.sender == owner()) {
        _safeMint(recipient, 1);
        rexForRaptor[rexIds[i]] = true;
      } else {
        require(
          isRexOwner(rexIds[i], recipient),
          "You are not the owner of this OG-Rex"
        );
        _safeMint(recipient, 1);
        rexForRaptor[rexIds[i]] = true;
      }
    }

    return firstRaptorRecieved;
  }

    /**
   * @notice Sets the royalty basis points of the collection. 100 = 1%
   */
  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    ROYALTY_BASIS_POINTS = feeNumerator;
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @notice Sets royalty basis points to 0
   */
  function deleteDefaultRoyalty() public onlyOwner {
    ROYALTY_BASIS_POINTS = 0;
    _deleteDefaultRoyalty();
  }

  /**
   * @notice Only Owner Function to withdraw ETH sent to contract
   * @param receiver Address to withdraw ETH to
   */
  function withdrawAllEth(address receiver) public virtual onlyOwner {
    uint256 balance = address(this).balance;
    payable(receiver).transfer(balance);
    emit BalanceWithdrawn(receiver, balance);
  }

  /**
   * @notice Interface for marketplaces
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC2981, ERC721A) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}