//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {DefaultOperatorFiltererUpgradeable} from "../../shared/opensea/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract WagdieBeasts is ERC721AUpgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable, ERC2981 {

    uint256 public toll;
    uint256 public beastPrice;
    bool public isMintingEnabled;
    string private baseURI;

    uint16 public constant maxBeasts = 2222;

    error MintingNotStarted();
    error ExceedsMaxMintQuantity();
    error ExceedsMaxSupply();
    error EthValueTooLow();
    error TollToHigh();

    event MintingEnabledChanged(bool isMintingEnabled);

    function initialize() initializerERC721A initializer public {
        __ERC721A_init('WAGDIE: Beasts', 'BEAST');
        __Ownable_init();
        __DefaultOperatorFilterer_init();

        toll = 570;
        beastPrice = 666 ether;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721AUpgradeable, ERC2981) returns (bool) {
        return 
            ERC721AUpgradeable.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
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
     *  @dev 𝔅𝔢𝔰𝔱𝔬𝔴 𝔱𝔬𝔨𝔢𝔫𝔰 𝔲𝔭𝔬𝔫 𝔱𝔥𝔬𝔰𝔢 𝔡𝔢𝔢𝔪𝔢𝔡 𝔴𝔬𝔯𝔱𝔥𝔶.
     */
    function bestowBeasts(address recipient, uint256 quantity) external onlyOwner {
        if (quantity + totalSupply() > maxBeasts) revert ExceedsMaxSupply();
        _mint(recipient, quantity);
    }

    /**
     *  @dev 𝔖𝔞𝔠𝔯𝔦𝔣𝔦𝔠𝔢 𝔞 𝔟𝔢𝔞𝔰𝔱 𝔶𝔬𝔲 𝔬𝔴𝔫.
     */
    function burnBeast(uint256 tokenId) public virtual {
        _burn(tokenId, true);
    }

    /**
     *  @dev 𝔖𝔢𝔱 𝔱𝔥𝔢 𝔭𝔯𝔦𝔠𝔢 𝔬𝔣 𝔢𝔞𝔠𝔥 𝔟𝔢𝔞𝔰𝔱.
     */
    function setPrice(uint256 price) external onlyOwner {
        beastPrice = price;
    }

    /**
     *  @dev 𝔈𝔫𝔞𝔟𝔩𝔢 𝔱𝔥𝔢 𝔱𝔞𝔪𝔦𝔫𝔤 𝔬𝔣 𝔟𝔢𝔞𝔰𝔱𝔰.
     */
    function updateIsMintingEnabled(bool _isMintingEnabled) external onlyOwner {
        isMintingEnabled = _isMintingEnabled;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     *  @dev 𝔖𝔢𝔱𝔰 𝔱𝔬𝔩𝔩 𝔣𝔬𝔯 𝔟𝔞𝔯𝔱𝔢𝔯𝔦𝔫𝔤 𝔬𝔣 𝔱𝔬𝔨𝔢𝔫𝔰.
     */
    function setToll(
        uint256 _toll
    ) external onlyOwner {
        if (_toll > 2500) revert TollToHigh();
        toll = _toll;
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * toll) / 10000;
        return (owner(), royaltyAmount);
    }

    // OpenSea Operator Filter Overrides
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}