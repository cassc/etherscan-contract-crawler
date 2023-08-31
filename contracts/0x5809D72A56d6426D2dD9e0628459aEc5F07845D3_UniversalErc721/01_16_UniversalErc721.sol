// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/DefaultOperatorFiltererUpgradeable.sol";
pragma solidity ^0.8.17;

contract UniversalErc721 is ERC721Upgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    bool public isPaused;

    address public royaltyRecipient;
    uint256 public ROYALTY_PERCENTAGE;
    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;

    string private _baseURIString;

    error TransfersArePaused();
    error ExceedingMaxSupply();
    error TokenAlreadyConfigured();

    uint256 public MAX_SUPPLY;
    uint256 public totalTokensMinted;
    address public minter;

    string private _tokenName;
    string private _tokenSymbol;

    modifier onlyMinter() {
      require(_msgSender() == minter, "Only minter can call this function");
      _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    // Initialiser function to init the contract
    function initialize() external initializer {
      royaltyRecipient = _msgSender();
      ROYALTY_PERCENTAGE = 500;
      _tokenName = "Whitelable";
      _tokenSymbol = "WL";

      __ERC721_init("", "");
      __Ownable_init();
      DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
      
      _mint(_msgSender(), totalTokensMinted++);
    }

    // Get the name of the token
    function name() public view override returns (string memory) {
      return _tokenName;
    }

    // Get the symbol of the token
    function symbol() public view override returns (string memory) {
      return _tokenSymbol;
    }

    // Calculate and return the royalty information
    function calculateRoyaltyInfo(uint256, uint256 salePriceInWei) external view returns (address receiver, uint256 royaltyAmountInWei) {
      uint256 amount = salePriceInWei * ROYALTY_PERCENTAGE / PERCENTAGE_DENOMINATOR;
      return (royaltyRecipient, amount);
    }
    
    // Get the base URI of the token
    function _baseURI() internal view override returns (string memory) {
        return _baseURIString;
    }

    // Set the base URI of the token
    function setBaseURI(string memory uri) public onlyOwner {
      _baseURIString = uri;
    }

    // Pause transfers
    function pauseTransfers(bool pause) external onlyOwner {
      isPaused = pause;
    }

    // Set minter address
    function setMinter(address _minter) external onlyOwner {
      minter = _minter;
    }

    // Set royalty recepient 
    function setRoyaltyRecepient(address _royaltyRecepient) external onlyOwner {
      royaltyRecipient = _royaltyRecepient;
    }

    // Function to configure mint
    function configureToken(
      uint256 maxSupply,
      uint256 royalty,
      string memory _name,
      string memory  _symbol,
      string memory  uri,
      address _minter
    ) external onlyOwner {
      if (MAX_SUPPLY != 0) {
        revert TokenAlreadyConfigured();
      }

      MAX_SUPPLY = maxSupply;
      ROYALTY_PERCENTAGE = royalty;
      _tokenName = _name;
      _tokenSymbol = _symbol;
      setBaseURI(uri);
      minter = _minter;
    }
    // Mint token with next ID
    function mintToken(address to) external onlyMinter {
      if (
        totalTokensMinted >= MAX_SUPPLY
      ) {
        revert ExceedingMaxSupply();
      }
      _mint(to, totalTokensMinted++);
    }

    /**
     * @dev Overwrites basic ERC721 functions to activate DefaultOperatorFilterer.
     */
    function transferFrom(
      address from,
      address to,
      uint256 tokenId
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Overwrites basic ERC721 functions to activate DefaultOperatorFilterer.
     */
    function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Overwrites basic ERC721 functions to activate DefaultOperatorFilterer.
     */
    function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory data
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, data);
    }

    // Override the _beforeTokenTransfer function to add a check for paused sale
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (isPaused) {
          revert TransfersArePaused();
        }
    }
}