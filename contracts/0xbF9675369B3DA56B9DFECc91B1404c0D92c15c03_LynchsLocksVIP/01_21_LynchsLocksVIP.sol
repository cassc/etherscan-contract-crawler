//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract LynchsLocksVIP is
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    RoyaltiesV2Impl,
    Pausable
{
    /******************************/
    /**    State Variables       **/
    /******************************/

    struct PhaseConfig {
        uint256 firstId;
        uint256 maxTokens;
        string tokenUri;
    }

    uint256 public currentPhase;
    mapping(uint256 => PhaseConfig) public vipPhaseConfig;
    mapping(uint256 => uint256) public numMintedByPhase;
    mapping(uint256 => mapping(address => bool)) public buyersPerPhase;

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
    // Mapping of signatures used
    mapping(uint256 => mapping(address => bool)) public discountClaimed;

    /******************************/
    /**    Events                **/
    /******************************/
    event EscrowUpdated(address caller, address indexed newEscrow);
    event SecondaryUpdated(address caller, address indexed newSecondary);
    event MerkleUpdated(address caller, bytes32 indexed newMerkle);
    event PriceUpdated(address caller, uint256 indexed newPrice);
    event DiscountUpdated(address caller, uint256 indexed newPrice);
    event NftMinted(
        address indexed minter,
        uint256 indexed tokenId,
        uint256 indexed phase
    );
    event NewPhaseCreated(uint256 indexed phase, uint256 indexed maxTokens);

    /******************************/
    /**    Modifiers             **/
    /******************************/

    // This means that if the max amount of tokens has been reached for the current phase,
    // you cannot mint anymore
    modifier onlyWhenNotMaxSupplyReached() {
        require(
            numMintedByPhase[currentPhase] + 1 <=
                vipPhaseConfig[currentPhase].maxTokens,
            "Lynchs Locks: Max Supply reached for current phase!"
        );
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
        uint256 _discountPrice
    ) ERC721("Lynchs Locks VIP Pass", "LVIP") {
        require(
            _escrow != address(0),
            "Lynchs Locks: escrow is the zero address"
        );
        require(
            _secondary != address(0),
            "Lynchs Locks: secondary is the zero address"
        );
        escrow = payable(_escrow);
        secondary = payable(_secondary);
        nftPrice = _nftPrice;
        discountPrice = _discountPrice;
        merkleRoot = _merkleRoot;
        _pause();
    }

    /******************************/
    /**    ONLYOWNER Functions   **/
    /******************************/

    /// @notice mintByOwner, called only by owner
    /// @dev mint one NFT for a given address (for giveaway and partnerships)
    /// @param _to, address to mint NFT
    function mintByOwner(address _to)
        external
        onlyOwner
        onlyWhenNotMaxSupplyReached
    {
        _mintNFT(_to, totalSupply());
    }

    /// @notice setPhaseConfig, called only by owner
    /// @dev Creates a new class of NFTs for the monthly membership
    /// @param _phase, the unique ID of the phase. Follows YYYYmm naming convention
    /// @param _maxTokens, the maximum amount of tokens for the phase
    /// @param _tokenUri, the URI for the token metadata
    function setPhaseConfig(
        uint256 _phase,
        uint256 _maxTokens,
        string memory _tokenUri
    ) external onlyOwner {
        require(
            currentPhase != _phase,
            "Lynchs Locks: Current phase still minting"
        );

        vipPhaseConfig[_phase] = PhaseConfig(
            totalSupply(),
            _maxTokens,
            _tokenUri
        );
        numMintedByPhase[_phase] = 0;
        currentPhase = _phase;
        emit NewPhaseCreated(_phase, _maxTokens);
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
        require(
            _newEscrow != address(0),
            "Lynchs Locks: new escrow is the zero address"
        );
        escrow = payable(_newEscrow);
        emit EscrowUpdated(msg.sender, _newEscrow);
    }

    /// @notice updateSecondary, called only by owner
    /// @dev update escrow address
    /// @param _newSecondary, new address to receive royalty payments
    function updateSecondary(address _newSecondary) external onlyOwner {
        require(
            _newSecondary != address(0),
            "Lynchs Locks: new secondary is the zero address"
        );
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
    function tokensOfOwner(address _ownerAddress)
        external
        view
        returns (uint[] memory)
    {
        uint tokenCount = balanceOf(_ownerAddress);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_ownerAddress, i);
        }
        return tokensId;
    }

    /// @notice royaltyInfo
    /// @dev get royalties for Mintable using the ERC2981 standard
    /// @param _tokenId, token ID NFT
    /// @param _salePrice, sale price
    /// returns receiver address, address (secondary wallet)
    /// returns royaltyAmount, royality amount to send to the owner
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }
        return (address(0), 0);
    }

    /// @notice mintNFT, external function
    /// @dev mint new NFTs
    function mintNFT()
        external
        payable
        whenNotPaused
        onlyWhenNotMaxSupplyReached
    {
        require(
            msg.value >= nftPrice,
            "Lynchs Locks: Ether value sent is not correct"
        );

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
        require(
            !discountClaimed[currentPhase][msg.sender],
            "Lynchs Locks: Discount already claimed."
        );

        // Verify the _merkleProof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Lynchs Locks: Address is not allowlisted"
        );

        require(
            msg.value >= discountPrice,
            "Lynchs Locks: Ether value sent is not correct"
        );

        // Mark the address as having claimed their discount
        discountClaimed[currentPhase][msg.sender] = true;

        _mintNFT(msg.sender, totalSupply());
    }

    /******************************/
    /**    PUBLIC Functions      **/
    /******************************/

    /// @notice supportsInterface
    /// @dev used to use the ERC2981 standard
    /// @param interfaceId, ERC2981 interface
    /// @return bool, true or false
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
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

    /// @notice tokenURI
    /// @dev get token URI of given token ID.
    /// @param _tokenId, token ID NFT
    /// @return URI
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    /******************************/
    /**    INTERNAL Functions    **/
    /******************************/

    /// @notice _mintNFT, internal function for minting
    /// @dev shared logic for minting a NFT
    /// @param _to, address to mint NFT
    /// @param _tokenId, token ID to mint.
    function _mintNFT(address _to, uint256 _tokenId) internal {
        require(
            !buyersPerPhase[currentPhase][_to],
            "Lynchs Locks: Max 1 per wallet per phase!"
        );

        numMintedByPhase[currentPhase] += 1;
        buyersPerPhase[currentPhase][_to] = true;
        _setRoyalties(_tokenId, secondary, 400);
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, vipPhaseConfig[currentPhase].tokenUri);
        emit NftMinted(_to, _tokenId, currentPhase);
    }

    /// @notice _setRoyalties, internal function
    /// @dev configure royalties details for each NFT minted (secondary market)
    /// @param _tokenId,  token ID
    /// @param _royaltiesRecipientAddress, the secondary wallet to collect royalities (secondary wallet)
    /// @param _percentageBasisPoints, percentage for the secondary wallet
    function _setRoyalties(
        uint _tokenId,
        address payable _royaltiesRecipientAddress,
        uint96 _percentageBasisPoints
    ) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    /// @notice _beforeTokenTransfer, internal function
    /// @dev override needed for contract
    /// @param from,  from address
    /// @param to,  to address
    /// @param tokenId,  token ID
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice _burn, internal function
    /// @dev override needed for contract
    /// @param tokenId,  token ID
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}