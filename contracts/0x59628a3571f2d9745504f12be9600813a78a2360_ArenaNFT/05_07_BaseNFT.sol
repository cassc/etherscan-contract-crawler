// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BaseNFT is ERC721A, Ownable {
    address public operator;

    // metadata uris
    string private uriPrefix = "ipfs://XXXXXXXXXX/";
    string private uriSuffix = ".json";
    string private contractMetadataUri = "ipfs://XXXXXXXXXX/contract.json";

    // permanant locks
    bool public urisLocked = false;
    bool public ownerMintsLocked = false;
    bool public userMintsLocked = false;

    /**
     * @notice Data structure for sale params used in the #mint function.
     * `price`: cost to mint each token for this sale (18 decimals).
     * `endTime`: maximum timestamp where minting is enabled.
     * `quantityLimit`: maximum quantity of mints during this sale.
     * `_quantityStart`: total minted (not totalSupply) at start of sale.
     */
    struct Sale {
        uint256 price;
        uint256 endTime;
        uint256 quantityLimit;
        uint256 _quantityStart;
    }

    Sale public currentSale = Sale({price: 0, endTime: 0, quantityLimit: 0, _quantityStart: 0});

    constructor(
        string memory _name_,
        string memory _symbol_,
        string memory _tokenMetadataUriPrefix,
        string memory _contractMetadataUri
    ) ERC721A(_name_, _symbol_) {
        operator = msg.sender;
        uriPrefix = _tokenMetadataUriPrefix;
        contractMetadataUri = _contractMetadataUri;
    }

    /**
     * @dev Throws if called by any account other than the owner/operator.
     */
    modifier onlyOwnerOrOperator() {
        require(
            owner() == msg.sender || operator == msg.sender,
            "Caller is not the owner or operator"
        );
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Buy/mint tokens, only if enabled by the owner/operator.
     * @dev Requirements:
     *
     * - `userMintsLocked` is false.
     * - Sufficient ether is sent.
     * - Time limit not exceeded.
     * - Quantity limit not exceeded.
     * @param quantity number of tokens to mint
     */
    function mint(uint256 quantity) external payable {
        require(!userMintsLocked, "Public mints locked");
        require(currentSale.price * quantity <= msg.value, "Insuffcient funds sent");
        require(currentSale.endTime > block.timestamp, "Sale not active");
        require(
            currentSale.quantityLimit >= (_totalMinted() - currentSale._quantityStart + quantity),
            "Sold out"
        );

        _mint(msg.sender, quantity);
    }

    /**
     * @notice mint `quantity` tokens to `to` - owner/operator only
     * @param to recipient of minted tokens
     * @param quantity number of tokens to mint
     */
    function ownerMint(address to, uint256 quantity) external onlyOwnerOrOperator {
        require(!ownerMintsLocked, "Owner mints locked");
        _mint(to, quantity);
    }

    /**
     * @notice Transfer tokens from self to list of recipients
     * @dev If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * It is more gas optimal to transfer bulk minted tokens in ascending token ID order.
     * @param from owner of tokens to transfer.
     * @param recipients list of address to send tokens to
     * @param tokenIds token id to send to address of the same index in the recipients list
     */
    function airdrop(
        address from,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external onlyOwnerOrOperator {
        require(recipients.length == tokenIds.length, "Invalid input");

        for (uint256 i = 0; i < recipients.length; i++) {
            transferFrom(from, recipients[i], tokenIds[i]);
        }
    }

    /**
     * @notice returns the contract metadata URI.
     */
    function contractURI() external view returns (string memory) {
        return contractMetadataUri;
    }

    /// URI format: `<baseURI><token ID><uriSuffix>`
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), uriSuffix))
                : "";
    }

    /**
     * @dev Set contract metadata URI.
     */
    function setContractMetadataUri(string memory _contractMetadataUri)
        external
        onlyOwnerOrOperator
    {
        require(!urisLocked, "URIs locked");
        contractMetadataUri = _contractMetadataUri;
    }

    /**
     * @dev Set token metadata URI prefix.
     */
    function setUriPrefix(string memory _uriPrefix) external onlyOwnerOrOperator {
        require(!urisLocked, "URIs locked");
        uriPrefix = _uriPrefix;
    }

    /**
     * @dev Set token metadata URI suffix.
     */
    function setUriSuffix(string memory _uriSuffix) external onlyOwnerOrOperator {
        require(!urisLocked, "URIs locked");
        uriSuffix = _uriSuffix;
    }

    /**
     * @notice Lock updating metadata URIs. Cannot be unlocked.
     */
    function lockUris() external onlyOwnerOrOperator {
        require(!urisLocked, "URIs locked");
        urisLocked = true;
    }

    /**
     * @notice Lock free mints by the owner or operator. Cannot be unlocked.
     */
    function lockOwnerMints() external onlyOwnerOrOperator {
        require(!ownerMintsLocked, "Owner mints locked");
        ownerMintsLocked = true;
    }

    /**
     * @notice Lock mints by public. Cannot be unlocked.
     */
    function lockUserMints() external onlyOwnerOrOperator {
        require(!userMintsLocked, "Public mints locked");
        userMintsLocked = true;
    }

    /**
     * @notice Set the operator role. To revoke, set to owner address.
     */
    function setOperator(address _newOperator) external onlyOwnerOrOperator {
        operator = _newOperator;
    }

    /**
     * @notice Set the current sale params for the #mint function.
     * @dev To disable a sale, set the `quantityLimit` to zero.
     * @param price cost to mint each token for this sale.
     * @param endTime maximum timestamp where minting is enabled.
     * @param quantityLimit maximum quantity of mints during this sale.
     */
    function setCurrentSale(
        uint256 price,
        uint256 endTime,
        uint256 quantityLimit
    ) external onlyOwnerOrOperator {
        currentSale = Sale({
            price: price,
            endTime: endTime,
            quantityLimit: quantityLimit,
            // use _totalMinted instead of totalSupply, since burning tokens decreases the totalSupply
            _quantityStart: _totalMinted()
        });
    }

    /**
     * @notice Withdraw funds to owner.
     * Callable by owner/operator, but sends only to owner.
     */
    function withdraw() external onlyOwnerOrOperator {
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }
}