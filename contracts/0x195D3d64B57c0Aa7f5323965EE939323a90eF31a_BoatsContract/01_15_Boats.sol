//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BoatsContract is ERC721Enumerable, Ownable, Pausable {
    /******************************/
    /**    State Variables       **/
    /******************************/

    // Max Supply
    uint256 public constant MAX_SUPPLY = 7777;
    // Max Tokens per mint
    uint256 public MAX_TOKENS_PER_MINT = 3;
    // URI for metadata
    string public baseURI;
    // To claim ethers
    address payable public escrow;
    // NFT Price
    uint256 public nftPrice;
    // NFT Price
    uint256 public discountPrice;
    // Merkle Root for Discounts
    bytes32 public merkleRoot;
    // Mapping of discounts = used
    mapping(address => bool) public discountClaimed;
    // Proposed New Owner
    address public proposedOwner;

    /******************************/
    /**    Events                **/
    /******************************/
    event EscrowUpdated(address caller, address indexed newEscrow);
    event SecondaryUpdated(address caller, address indexed newSecondary);
    event MerkleUpdated(address caller, bytes32 indexed newMerkle);
    event PriceUpdated(address caller, uint256 indexed newPrice);
    event DiscountUpdated(address caller, uint256 indexed newPrice);

    /******************************/
    /**    Modifiers             **/
    /******************************/

    // This means that if the max amount of tokens has been reached for the current phase,
    // you cannot mint anymore
    modifier onlyWhenNotMaxSupplyReached(uint256 _nbTokens) {
        require(totalSupply() + _nbTokens <= MAX_SUPPLY, "Boats: Max Supply reached!");
        _;
    }

    /******************************/
    /**    Constructor           **/
    /******************************/

    constructor(
        address _escrow,
        bytes32 _merkleRoot,
        uint256 _nftPrice,
        uint256 _discountPrice,
        string memory _uri
    ) ERC721("Boats", "BOAT") {
        require(_escrow != address(0), "Boats: escrow is the zero address");
        escrow = payable(_escrow);
        nftPrice = _nftPrice;
        discountPrice = _discountPrice;
        merkleRoot = _merkleRoot;
        baseURI = _uri;
    }

    /******************************/
    /**    ONLYOWNER Functions   **/
    /******************************/

    /// @notice mintByOwner, called only by owner
    /// @dev mint one NFT for a given address (for giveaway and partnerships)
    /// @param _to, address to mint NFT
    /// @param _nbTokens, number of tokens to mint
    function mintByOwner(address _to, uint256 _nbTokens)
        external
        onlyOwner
        onlyWhenNotMaxSupplyReached(_nbTokens)
    {
        require(
            _nbTokens <= MAX_TOKENS_PER_MINT,
            "Boats: You cannot mint more than MAX_TOKENS_PER_MINT tokens at once!"
        );
        for (uint256 i; i < _nbTokens; i++) {
            _mintNFT(_to, totalSupply());
        }
    }

    /// @notice pause now, called only by owner
    /// @dev pauses minting
    function pauseNow() external onlyOwner {
        _pause();
    }

    /// @notice unpause now, called only by owner
    /// @dev unpauses minting
    function unpauseNow() external onlyOwner {
        _unpause();
    }

    /// @notice updateEscrow, called only by owner
    /// @dev update escrow address
    /// @param _newEscrow, new address to receive escrow payments
    function updateEscrow(address _newEscrow) external onlyOwner {
        require(_newEscrow != address(0), "Boats: new escrow is the zero address");
        escrow = payable(_newEscrow);
        emit EscrowUpdated(msg.sender, _newEscrow);
    }

    /// @notice updateMerkle, called only by owner
    /// @dev update discount list for discounted buying
    /// @param _newMerkle, new merkle root for discounts
    function updateMerkle(bytes32 _newMerkle) external onlyOwner {
        merkleRoot = _newMerkle;
        emit MerkleUpdated(msg.sender, _newMerkle);
    }

    /// @notice updateNftPrice, called only by owner
    /// @dev updates the sale price
    /// @param _newPrice, new price for NFT sales
    function updateNftPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Boats: new price zero");
        nftPrice = _newPrice;
        emit PriceUpdated(msg.sender, _newPrice);
    }

    /// @notice updatediscountPrice, called only by owner
    /// @dev updates the discount sale price
    /// @param _newPrice, new price for discounted NFT sales
    function updateDiscountPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Boats: new price zero");
        discountPrice = _newPrice;
        emit DiscountUpdated(msg.sender, _newPrice);
    }

    /// @notice proposeNewOwner, called only by owner
    /// @dev updates the proposed owner for contract ownership transfer
    /// @param _proposedOwner, address of the proposed new owner
    function proposeNewOwner(address _proposedOwner) external onlyOwner {
        require(_proposedOwner != address(0), "Boats: proposed owner is the zero address");
        proposedOwner = _proposedOwner;
    }

    /// @notice claim, called only by owner
    /// @dev claim the raised funds and send it to the escrow wallet
    // https://solidity-by-example.org/sending-ether
    function claim() external onlyOwner {
        // Send returns a boolean value indicating success or failure.
        (bool sent, ) = escrow.call{value: address(this).balance}("");
        require(sent, "Boats: Failed to send Ether");
    }

    /******************************/
    /**    EXTERNAL Functions   **/
    /******************************/

    /// @notice tokensOfOwner, external function
    /// @dev returns the token IDs of the owner
    /// @param _ownerAddress, address of the owner
    /// @return tokensId, list of token IDs
    function tokensOfOwner(address _ownerAddress) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_ownerAddress);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_ownerAddress, i);
        }
        return tokensId;
    }

    /// @notice mint, external function
    /// @dev mint new NFTs
    /// @param _nbTokens, number of tokens to mint
    function mint(uint256 _nbTokens)
        external
        payable
        whenNotPaused
        onlyWhenNotMaxSupplyReached(_nbTokens)
    {
        require(msg.value >= nftPrice * _nbTokens, "Boats: Ether value sent is not correct");
        require(
            _nbTokens <= MAX_TOKENS_PER_MINT,
            "Boats: You cannot mint more than MAX_TOKENS_PER_MINT tokens at once!"
        );

        for (uint256 i; i < _nbTokens; i++) {
            _mintNFT(msg.sender, totalSupply());
        }
    }

    /// @notice discount, external function
    /// @dev mint NFTs at a discounted price
    /// @param _merkleProof, a merkle proof for the discounted buyer
    /// @param _nbTokens, number of tokens to mint
    // TY to this author: https://medium.com/@ItsCuzzo/using-merkle-trees-for-nft-whitelists-523b58ada3f9
    function discount(bytes32[] calldata _merkleProof, uint256 _nbTokens)
        external
        payable
        whenNotPaused
        onlyWhenNotMaxSupplyReached(_nbTokens)
    {
        require(!discountClaimed[msg.sender], "Boats: Discount already claimed.");

        // Verify the _merkleProof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Boats: Address is not allowlisted"
        );

        require(msg.value >= discountPrice * _nbTokens, "Boats: Ether value sent is not correct");

        // Mark the address as having claimed their discount
        discountClaimed[msg.sender] = true;

        for (uint256 i; i < _nbTokens; i++) {
            _mintNFT(msg.sender, totalSupply());
        }
    }

    /// @notice safeOwnershipTransfer, accept ownership transfer
    /// @dev new owner calls this function to accept ownership of the contract
    function safeOwnershipTransfer() external {
        require(msg.sender == proposedOwner, "Boats: Caller is not the proposed owner");
        _transferOwnership(msg.sender);
    }

    /******************************/
    /**    PUBLIC Functions      **/
    /******************************/

    /// @notice getPrice
    /// @dev used to return the price for webflow mint functionality
    /// @return nftPrice, price to buy NFT
    function getPrice() public view returns (uint256) {
        return nftPrice;
    }

    /******************************/
    /**    INTERNAL Functions    **/
    /******************************/

    /**
     * @notice _baseURI, returns the base URI variable set in the constructor
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    /// @notice _mintNFT, internal function for minting
    /// @dev shared logic for minting a NFT
    /// @param _to, address to mint NFT
    /// @param _tokenId, token ID to mint.
    function _mintNFT(address _to, uint256 _tokenId) internal {
        _safeMint(_to, _tokenId);
    }
}