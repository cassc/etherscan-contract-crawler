//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract LynchsLocksSuperContest is ERC721Enumerable, Ownable, RoyaltiesV2Impl, Pausable {
    /******************************/
    /**    State Variables       **/
    /******************************/

    // Max Supply
    uint256 public constant MAX_SUPPLY = 10;
    // URI for metadata
    string public baseURI;
    // Royalties interface
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // To claim ethers
    address payable public escrow;
    // To get royalties
    address payable public secondary;
    // NFT Price
    uint256 public nftPrice;
    // NFT Price
    uint256 public discountPrice;
    // Merkle Root for Discounts
    bytes32 public merkleRoot;
    // Mapping of discounts = used
    mapping(address => bool) public discountClaimed;

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
    modifier onlyWhenNotMaxSupplyReached() {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Lynchs Locks: Max Supply reached!");
        _;
    }

    /******************************/
    /**    Constructor           **/
    /******************************/

    constructor(
        address _escrow,
        address _secondary,
        bytes32 _merkleRoot,
        uint256 _nftPrice,
        uint256 _discountPrice,
        string memory _uri
    ) ERC721("Lynchs Locks Football Super Contest", "LLFSC") {
        require(_escrow != address(0), "Lynchs Locks: escrow is the zero address");
        require(_secondary != address(0), "Lynchs Locks: secondary is the zero address");
        escrow = payable(_escrow);
        secondary = payable(_secondary);
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
    function mintByOwner(address _to) external onlyOwner onlyWhenNotMaxSupplyReached {
        _mintNFT(_to, totalSupply());
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
        require(_newEscrow != address(0), "Lynchs Locks: new escrow is the zero address");
        escrow = payable(_newEscrow);
        emit EscrowUpdated(msg.sender, _newEscrow);
    }

    /// @notice updateSecondary, called only by owner
    /// @dev update secondary address
    /// @param _newSecondary, new address to receive royalty payments
    function updateSecondary(address _newSecondary) external onlyOwner {
        require(_newSecondary != address(0), "Lynchs Locks: new secondary is the zero address");
        secondary = payable(_newSecondary);
        emit SecondaryUpdated(msg.sender, _newSecondary);
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
        require(_newPrice > 0, "Lynchs Locks: new price zero");
        nftPrice = _newPrice;
        emit PriceUpdated(msg.sender, _newPrice);
    }

    /// @notice updatediscountPrice, called only by owner
    /// @dev updates the discount sale price
    /// @param _newPrice, new price for discounted NFT sales
    function updateDiscountPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Lynchs Locks: new price zero");
        discountPrice = _newPrice;
        emit DiscountUpdated(msg.sender, _newPrice);
    }

    /// @notice claim, called only by owner
    /// @dev claim the raised funds and send it to the escrow wallet
    // https://solidity-by-example.org/sending-ether
    function claim() external onlyOwner {
        // Send returns a boolean value indicating success or failure.
        (bool sent, ) = escrow.call{value: address(this).balance}("");
        require(sent, "Lynchs Locks: Failed to send Ether");
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

    /// @notice royaltyInfo
    /// @dev get royalties for Mintable using the ERC2981 standard
    /// @param _tokenId, token ID NFT
    /// returns receiver address, address (secondary wallet)
    /// returns royaltyAmount, royality amount to send to the owner
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
        }
        return (address(0), 0);
    }

    /// @notice mintNFT, external function
    /// @dev mint new NFTs
    function mintNFT() external payable whenNotPaused onlyWhenNotMaxSupplyReached {
        require(msg.value >= nftPrice, "Lynchs Locks: Ether value sent is not correct");

        _mintNFT(msg.sender, totalSupply());
    }

    /// @notice discount, external function
    /// @dev mint NFTs at a discounted price
    /// @param _merkleProof, a merkle proof for the discounted buyer
    // TY to this author: https://medium.com/@ItsCuzzo/using-merkle-trees-for-nft-whitelists-523b58ada3f9
    function discount(bytes32[] calldata _merkleProof)
        external
        payable
        whenNotPaused
        onlyWhenNotMaxSupplyReached
    {
        require(!discountClaimed[msg.sender], "Lynchs Locks: Discount already claimed.");

        // Verify the _merkleProof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Lynchs Locks: Address is not allowlisted"
        );

        require(msg.value >= discountPrice, "Lynchs Locks: Ether value sent is not correct");

        // Mark the address as having claimed their discount
        discountClaimed[msg.sender] = true;

        _mintNFT(msg.sender, totalSupply());
    }

    /******************************/
    /**    PUBLIC Functions      **/
    /******************************/

    /// @notice tokenURI
    /// @dev get token URI of given token ID.
    /// @param _tokenId, token ID NFT
    /// @return URI
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Lynchs Locks: URI query for nonexistent token");

        return baseURI;
    }

    /// @notice supportsInterface
    /// @dev used to use the ERC2981 standard
    /// @param interfaceId, ERC2981 interface
    /// @return bool, true or false
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /******************************/
    /**    INTERNAL Functions    **/
    /******************************/

    /// @notice _mintNFT, internal function for minting
    /// @dev shared logic for minting a NFT
    /// @param _to, address to mint NFT
    /// @param _tokenId, token ID to mint.
    function _mintNFT(address _to, uint256 _tokenId) internal {
        _setRoyalties(_tokenId, secondary, 400);
        _safeMint(_to, _tokenId);
    }

    /// @notice _setRoyalties, internal function
    /// @dev configure royalties details for each NFT minted (secondary market)
    /// @param _tokenId,  token ID
    /// @param _royaltiesRecipientAddress, the secondary wallet to collect royalities (secondary wallet)
    /// @param _percentageBasisPoints, percentage for the secondary wallet
    function _setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesRecipientAddress,
        uint96 _percentageBasisPoints
    ) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }
}