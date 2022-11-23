// SPDX-License-Identifier: MIT

/*

 █████╗ ██████╗    ████████╗██████╗     ██████╗ ██╗   ██╗██╗     ███████╗███████╗██╗
██╔══██╗██╔══██╗   ╚══██╔══╝╚════██╗    ██╔══██╗██║   ██║██║     ██╔════╝██╔════╝██║
███████║██████╔╝█████╗██║    █████╔╝    ██████╔╝██║   ██║██║     █████╗  ███████╗██║
██╔══██║██╔══██╗╚════╝██║    ╚═══██╗    ██╔══██╗██║   ██║██║     ██╔══╝  ╚════██║╚═╝
██║  ██║██║  ██║      ██║   ██████╔╝    ██║  ██║╚██████╔╝███████╗███████╗███████║██╗
╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝   ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝

*/

pragma solidity ^0.8.17;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import './operator-filter-registry/DefaultOperatorFiltererUpgradeable.sol';

contract ART3art is ERC721AUpgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable {
    // metadata
    string public baseURI;
    bool public metadataFrozen;

    // constants and values
    uint256 public MAX_SUPPLY;
    uint256 public perWalletLimit;
    uint256 public mintPrice;

    // sale settings
    bool public mintPaused;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection
     */
    function initialize(uint256 _maxSupply, uint256 _perWalletLimit, uint256 _mintPrice, string memory name, string memory symbol, string memory _uri) initializerERC721A initializer public {
        __ERC721A_init(name, symbol);
        __Ownable_init();
        __DefaultOperatorFilterer_init();

        MAX_SUPPLY = _maxSupply;
        perWalletLimit = _perWalletLimit;
        mintPrice = _mintPrice;
        baseURI = _uri;

        mintPaused = true;
    }

    /**
     * ------------ CONFIG ------------
     */

    /**
     * @dev Gets base metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Sets base metadata URI, callable by owner
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        require(!metadataFrozen);
        baseURI = _uri;
    }

    /**
     * @dev Sets mint price, callable by owner
     */
    function setMintPrice(uint256 newPriceInWei) external onlyOwner {
        mintPrice = newPriceInWei;
    }

    /**
     * @dev Sets per wallet limit, callable by owner
     */
    function setPerWalletLimit(uint256 newLimit) external onlyOwner {
        perWalletLimit = newLimit;
    }

    /**
     * @dev Freezes metadata
     */
    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen);
        metadataFrozen = true;
    }

    /**
     * @dev Pause/unpause sale or presale
     */
    function togglePauseMinting() external onlyOwner {
        mintPaused = !mintPaused;
    }

    /**
     * ------------ MINTING ------------
     */

    /**
     * @dev Owner minting
     */
    function airdropOwner(address[] calldata addrs, uint256[] calldata counts) external onlyOwner {
        for (uint256 i=0; i<addrs.length; i++) {
            _mint(addrs[i], counts[i]);
            _setAux(addrs[i], uint64(_getAux(addrs[i]) + counts[i]));
        }
        require(totalSupply() <= MAX_SUPPLY, "Supply exceeded");
    }

    /**
     * @dev Public minting during public sale
     */
    function mint(uint256 count) public payable {
        require(count > 0, "Count can't be 0");
        require(count + numberMinted(msg.sender) <= perWalletLimit, "Limit exceeded");
        require(!mintPaused, "Minting is currently paused");
        require(msg.value == count * mintPrice, "Wrong ETH value");

        require(totalSupply() + count <= MAX_SUPPLY, "Supply exceeded");

        _mint(msg.sender, count);
    }

    /**
     * @dev Returns number of NFTs minted by addr
     */
    function numberMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr) - _getAux(addr);
    }

    /**
     * @dev Withdraw ether from this contract, callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * ------------ OPENSEA OPERATOR FILTER OVERRIDES ------------
     */

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