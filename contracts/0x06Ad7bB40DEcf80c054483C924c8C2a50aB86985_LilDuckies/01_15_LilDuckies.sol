// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error AllowListAdoptionNotEnabled();
error AllowlistRequired();
error CannotRoastUnAdoptedDucky();
error DuckQuacktoryNotOpenYet();
error DuckRoastingIsClosed();
error ExceedsAllowedAdoptionSize();
error ExceedsMaxPerTransaction();
error ExceedsMaxPerWallet();
error IncorrectPaymentAmount();
error InvalidMintSize();
error AdoptionNotEnabled();
error NotAllowlisted();
error NonExistentToken();
error TooLittleEth();
error WithdrawFailed();

abstract contract DuckQuacktory {
    function roastDucky(address to, uint256 boxId) public virtual returns (uint256);
}

contract LilDuckies is ERC721AQueryable, ReentrancyGuard, ERC2981, Ownable {
    using ECDSA for bytes32;

    uint public MAX_SUPPLY          = 3333;
    uint public MAX_PER_TX          = 5;
    uint public MAX_FREE_PER_WALLET = 1;
    uint public MAX_PER_WALLET      = 5;
    uint public COST_AFTER_FREE     = 0.0033 ether;

    bytes32 public allowListRoot;

    bool public adoptionEnabled = false;
    bool public allowListAdoptionEnabled = false;

    address private duckContract;
    bool public canRoastDucky;

    string private _baseTokenURI;

    constructor() ERC721A("Lil Duckies", "LD") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function allowListAdopt(
      bytes32[] calldata proof,
      uint qty)
        external
        payable
        callerIsUser
        nonReentrant
    {
        if (!allowListAdoptionEnabled) revert AllowListAdoptionNotEnabled();
        if (_totalMinted() + qty + 1 > MAX_SUPPLY) revert ExceedsAllowedAdoptionSize();
        if (_numberMinted(msg.sender) + qty + 1 > MAX_PER_WALLET) revert ExceedsMaxPerWallet();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProof.verify(
                proof,
                allowListRoot,
                leaf)
            ) revert NotAllowlisted();

        uint price = getPrice(qty);

        if (msg.value != price * qty) revert IncorrectPaymentAmount();

        _mint(msg.sender, qty);
        _refundOverPayment(price);
    }

    function adopt(uint qty)
      external
      payable
      callerIsUser
      nonReentrant {
        uint price = getPrice(qty);

        if (!adoptionEnabled) revert AdoptionNotEnabled();
        if (qty + 1 > MAX_PER_TX) revert ExceedsMaxPerTransaction();
        if (_numberMinted(msg.sender) + qty + 1 > MAX_PER_WALLET) revert ExceedsMaxPerWallet();
        if (_totalMinted() + qty + 1 > MAX_SUPPLY) revert ExceedsAllowedAdoptionSize();

        _mint(msg.sender, qty);
        _refundOverPayment(price);
    }

    function getPrice(uint qty) public view returns (uint) {
      uint numMinted = _numberMinted(msg.sender);
      uint free = numMinted < MAX_FREE_PER_WALLET ? MAX_FREE_PER_WALLET - numMinted : 0;
      if (qty >= free) {
        return (COST_AFTER_FREE) * (qty - free);
      }
      return 0;
    }

    function _refundOverPayment(uint256 amount) internal {
        if (msg.value < amount) revert TooLittleEth();
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    function teamAdopt(uint256 quantity, address to) external onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "would exceed max supply"
        );
        _mint(to, quantity);
    }

    function roastDucky(uint256 duckyId) public nonReentrant() returns (uint256) {
      if (!canRoastDucky) {
          if (msg.sender != owner()) revert DuckRoastingIsClosed();
      }

      address to = ownerOf(duckyId);

      if (to != msg.sender) {
          if (msg.sender != owner()) revert CannotRoastUnAdoptedDucky();
      }

      DuckQuacktory quacktory = DuckQuacktory(duckContract);

      _burn(duckyId, true);

      uint256 duckTokenId = quacktory.roastDucky(to, duckyId);
      return duckTokenId;
    }

    function duckiesRoasted(address addr) external view returns (uint256) {
        return _numberBurned(addr);
    }

    function totalDuckiesRoasted() external view returns (uint256) {
        return _totalBurned();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function toggleCanRoastDucky() external onlyOwner {
        if (duckContract == address(0)) revert DuckQuacktoryNotOpenYet();
        canRoastDucky = !canRoastDucky;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setDuckContract(address contractAddress_) external onlyOwner {
        duckContract = contractAddress_;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMaxPerTx(uint256 MAX_PER_TX_) external onlyOwner {
        MAX_PER_TX = MAX_PER_TX_;
    }

    function setMaxPerWallet(uint256 MAX_PER_WALLET_) external onlyOwner {
        MAX_PER_WALLET = MAX_PER_WALLET_;
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        MAX_SUPPLY = maxSupply_;
    }

    function setAllowListRoot(bytes32 allowListRoot_) external onlyOwner{
        allowListRoot = allowListRoot_;
    }

    function numberAdopted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function toggleAllowListAdoptionEnabled() external onlyOwner {
        allowListAdoptionEnabled = !allowListAdoptionEnabled;
    }

    function toggleAdoptionEnabled() external onlyOwner {
        adoptionEnabled = !adoptionEnabled;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

}