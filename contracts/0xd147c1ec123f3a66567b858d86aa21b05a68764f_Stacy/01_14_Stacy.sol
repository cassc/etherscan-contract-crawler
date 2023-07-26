// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IChad.sol";
import "./IProxyRegistry.sol";
import "./IStacy.sol";

contract Stacy is Ownable, ERC721, IStacy {
    error AmountExceedsMax(uint256 amount, uint256 maxAmount);
    error AmountExceedsMaxPerMint(uint256 amount, uint256 maxAmountPerMint);
    error NotEnoughEther(uint256 value, uint256 requiredEther);
    error SaleNotStarted(uint256 timestamp, uint256 startTime);
    error SaleEnded(uint256 timestamp, uint256 endTime);
    error NotChadOwner(address msgSender, uint256 chadId);
    error ChadUsed(uint256 chadId);

    /// @inheritdoc IStacy
    uint256 public immutable override saleStartTimestamp = 1633708800;

    ///  @inheritdoc IStacy
    uint256 public immutable override price = 0.05 ether;

    ///  @inheritdoc IStacy
    uint256 public immutable override maxAmountPerMint = 20;

    ///  @inheritdoc IStacy
    uint256 public immutable override maxSupply = 10_000;

    ///  @inheritdoc IStacy
    address public immutable override chad = 0x9CF63EFbe189091b7e3d364c7F6cFbE06997872b;

    /// @inheritdoc IStacy
    mapping(uint256 => bool) public override isChadUsed;

    /// @inheritdoc IStacy
    string public override contractURI;

    /// @inheritdoc IStacy
    uint256 public override totalSupply;

    // Prefix of each tokenURI
    string internal baseURI;

    // Interface id of `contractURI()` function
    bytes4 internal constant INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    // OpenSea Proxy Registry address
    address internal constant OPEN_SEA_PROXY_REGISTRY = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    /// @notice Creates Stacy NFTs, stores all the required parameters.
    /// @param contractURI_ Collection URI with collection metadata.
    /// @param baseURI_ Collection base URI prepended to each tokenURI.
    constructor(string memory contractURI_, string memory baseURI_) ERC721("Stacy", "STACY") {
        contractURI = contractURI_;
        baseURI = baseURI_;
    }

    /// @inheritdoc IStacy
    function setBaseURI(string memory newBaseURI) external override onlyOwner {
        baseURI = newBaseURI;
    }

    /// @inheritdoc IStacy
    function setContractURI(string memory newContractURI) external override onlyOwner {
        contractURI = newContractURI;
    }

    /// @inheritdoc IStacy
    function mint(uint256 amount) external payable override {
        // solhint-disable not-rely-on-time
        if (block.timestamp < saleStartTimestamp)
            revert SaleNotStarted(block.timestamp, saleStartTimestamp);
        // solhint-enable not-rely-on-time

        if (amount > maxAmountPerMint) revert AmountExceedsMaxPerMint(amount, maxAmountPerMint);
        if (msg.value < price * amount) revert NotEnoughEther(msg.value, price * amount);

        uint256 newSupply = totalSupply + amount;
        if (newSupply > maxSupply) revert AmountExceedsMax(newSupply, maxSupply);

        _safeMintMultiple(_msgSender(), amount);
    }

    /// @inheritdoc IStacy
    function mintPreSale(uint256[] calldata chadIds) external payable override {
        // solhint-disable not-rely-on-time
        if (block.timestamp >= saleStartTimestamp)
            revert SaleEnded(block.timestamp, saleStartTimestamp);
        // solhint-enable not-rely-on-time

        address msgSender = _msgSender();
        uint256 length = chadIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 chadId = chadIds[i];
            if (IChad(chad).ownerOf(chadId) != msgSender) revert NotChadOwner(msgSender, chadId);
            if (isChadUsed[chadId]) revert ChadUsed(chadId);
            isChadUsed[chadId] = true;
        }

        _safeMintMultiple(msgSender, length);
    }

    /// @inheritdoc IStacy
    function withdrawEther() external override onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == INTERFACE_ID_CONTRACT_URI || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        IProxyRegistry proxyRegistry = IProxyRegistry(OPEN_SEA_PROXY_REGISTRY);
        if (proxyRegistry.proxies(owner) == operator) return true;

        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Helper function for minting multiple tokens
    function _safeMintMultiple(address recipient, uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, totalSupply);
        }
    }

    /// @inheritdoc ERC721
    function _safeMint(address recipient, uint256 tokenId) internal override {
        totalSupply += 1;

        super._safeMint(recipient, tokenId);
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}