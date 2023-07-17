pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract EthlizardsCouncil is ERC721, Ownable {
    uint256 private constant maxLizardSupply = 5;

    string public baseURI = "https://ipfs.io/ipfs/QmRxSng5Pp8pbQZHmYgcYMVkmNk43TiQLq3GUhZGvSB1nx/";
    // Counter for amount airdropped
    uint256 public supplyAirdropped;
    // Current Royalties
    uint96 public currentRoyaltyPercentage;

    event BaseUriUpdated(string baseURI);
    event AdminTransfererUpdated(address adminTransferer);
    event EthlizardsDAOUpdated(address EthlizardsDAO);
    event TransfersEnabled();

    constructor() ERC721("Ethlizards Council NFTs", "LIZARD") {}

    /**
     * @notice Mints inputted addresses their council NFTs
     * @dev Only called once
     */
    function mintLizards(address[] calldata owners, uint256[] calldata tokenIds) external onlyOwner {
        if (owners.length != tokenIds.length) {
            revert InputsDoNotMatch({ownersLength: owners.length, tokensLength: tokenIds.length});
        }

        if (owners.length != maxLizardSupply) {
            revert IncorrectAmountMinted({ownersLength: owners.length});
        }

        for (uint256 i; i < owners.length;) {
            _mint(owners[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Recalls the token to the owner's wallet
     */
    function ownerRecall(address _from, uint256 _tokenId) external onlyOwner {
        _transfer(_from, owner(), _tokenId);
    }

    /**
     * @notice Overriden from default ERC721 contract to prohibit token transfers
     * unless owner of the contract is transferring it
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override
    {
        /// @dev, _mint will also call this _beforeTokenTransfer, so we let it do so without any restrictions
        /// if the from address is address(0).

        if (from != address(0) && to != owner()) {
            revert TransfersNotAllowed();
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @notice Sets baseUri for metadata
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseUriUpdated(_baseURI);
    }

    /**
     * @notice Overriden tokenURI to accept ipfs links
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")) : "";
    }

    // The size of the 2 arrays inputted do not match
    error InputsDoNotMatch(uint256 ownersLength, uint256 tokensLength);
    // An incorrect number of NFTs where attempted to be minted
    error IncorrectAmountMinted(uint256 ownersLength);
    // User cannot transfe tokens
    error TransfersNotAllowed();
}