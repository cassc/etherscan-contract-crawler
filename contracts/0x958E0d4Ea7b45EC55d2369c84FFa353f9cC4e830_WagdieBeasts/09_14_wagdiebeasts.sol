//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract WagdieBeasts is ERC721AUpgradeable, AccessControlUpgradeable {

    uint256 public beastPrice;
    bool public isMintingEnabled;
    string private baseURI;

    uint16 public constant maxBeasts = 2222;
    bytes32 public constant ORDAINED_ROLE = keccak256("ORDAINED_ROLE");

    error MintingNotStarted();
    error ExceedsMaxMintQuantity();
    error ExceedsMaxSupply();
    error EthValueTooLow();

    event MintingEnabledChanged(bool isMintingEnabled);

    function initialize() initializerERC721A initializer public {
        __ERC721A_init('WAGDIE: Beasts', 'BEAST');
        __AccessControl_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORDAINED_ROLE, msg.sender);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     *  @dev 𝔗𝔞𝔪𝔢 𝔞 𝔟𝔢𝔞𝔰𝔱 𝔣𝔯𝔬𝔪 𝔱𝔥𝔢 𝔉𝔬𝔯𝔰𝔞𝔨𝔢𝔫 𝔏𝔞𝔫𝔡𝔰.
     */
    function tameBeast(uint256 quantity) external payable {
        if (!isMintingEnabled) revert MintingNotStarted();
        if (quantity > 2) revert ExceedsMaxMintQuantity();
        if (quantity + totalSupply() > maxBeasts) revert ExceedsMaxSupply();
        if (msg.value < beastPrice * quantity) revert EthValueTooLow();
        require(msg.sender == tx.origin);

        _mint(msg.sender, quantity);
    }

    /**
     *  @dev ℭ𝔩𝔞𝔦𝔪 𝔟𝔢𝔞𝔰𝔱𝔰 𝔣𝔬𝔯 𝔗𝔥𝔢 𝔗𝔴𝔬
     */
    function ordainedTame(uint256 quantity) external onlyRole(ORDAINED_ROLE) {
        if (quantity + totalSupply() > maxBeasts) revert ExceedsMaxSupply();
        _mint(msg.sender, quantity);
    }

    /**
     *  @dev 𝔅𝔢𝔰𝔱𝔬𝔴 𝔱𝔬𝔨𝔢𝔫𝔰 𝔲𝔭𝔬𝔫 𝔱𝔥𝔬𝔰𝔢 𝔡𝔢𝔢𝔪𝔢𝔡 𝔴𝔬𝔯𝔱𝔥𝔶.
     */
    function bestowBeasts(address recipient, uint256 quantity) external onlyRole(ORDAINED_ROLE) {
        if (quantity + totalSupply() > maxBeasts) revert ExceedsMaxSupply();
        _mint(recipient, quantity);
    }

    /**
     *  @dev 𝔖𝔢𝔱 𝔱𝔥𝔢 𝔭𝔯𝔦𝔠𝔢 𝔬𝔣 𝔢𝔞𝔠𝔥 𝔟𝔢𝔞𝔰𝔱.
     */
    function setPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        beastPrice = price;
    }

    /**
     *  @dev 𝔈𝔫𝔞𝔟𝔩𝔢 𝔱𝔥𝔢 𝔱𝔞𝔪𝔦𝔫𝔤 𝔬𝔣 𝔟𝔢𝔞𝔰𝔱𝔰.
     */
    function updateIsMintingEnabled(bool _isMintingEnabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isMintingEnabled = _isMintingEnabled;
    }

    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}