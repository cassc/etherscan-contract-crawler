//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract LLCollection is
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    RoyaltiesV2Impl,
    Pausable
{
    /******************************/
    /**    State Variables       **/
    /******************************/

    // Token URI Array
    string[] internal tokenUris;
    // Max NFTs to mint
    uint256 public constant MAX_NFT = 100;
    // NFT price
    uint256 public nftPrice;
    // Royalties interface
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // To claim ethers
    address payable public escrow;
    // To get royalties
    address payable public secondary;

    /******************************/
    /**    Events                **/
    /******************************/
    event EscrowUpdated(address caller, address indexed newEscrow);
    event SecondaryUpdated(address caller, address indexed newSecondary);

    /******************************/
    /**    Constructor           **/
    /******************************/

    constructor(
        uint256 _nftPrice,
        address _escrow,
        address _secondary,
        string[3] memory _tokenUris
    ) ERC721("Legendary Lions", "LELI") {
        require(
            _escrow != address(0),
            "Legendary Lions: escrow is the zero address"
        );
        require(
            _secondary != address(0),
            "Legendary Lions: secondary is the zero address"
        );
        escrow = payable(_escrow);
        secondary = payable(_secondary);
        tokenUris = _tokenUris;
        nftPrice = _nftPrice;
        _pause();
    }

    /******************************/
    /**    ONLYOWNER Functions   **/
    /******************************/

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

    /// @notice mintByOwner, called only by owner
    /// @dev mint one NFT for a given address (for giveaway and partnerships)
    /// @param _to, address to mint NFT
    /// @param _tokenType, token type to mint.
    function mintByOwner(address _to, uint256 _tokenType) external onlyOwner {
        _mintNFT(_to, _tokenType, totalSupply());
    }

    /// @notice updatePrice, called only by owner
    /// @dev update price
    /// @param _newPrice, new address to receive escrow payments
    function updatePrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Legendary Lions: new price is zero");
        nftPrice = _newPrice;
    }

    /// @notice updateEscrow, called only by owner
    /// @dev update escrow address
    /// @param _newEscrow, new address to receive escrow payments
    function updateEscrow(address _newEscrow) external onlyOwner {
        require(
            _newEscrow != address(0),
            "Legendary Lions: new escrow is the zero address"
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
            "Legendary Lions: new secondary is the zero address"
        );
        secondary = payable(_newSecondary);
        emit SecondaryUpdated(msg.sender, _newSecondary);
    }

    /// @notice claim, called only by owner
    /// @dev claim the raised funds and send it to the escrow wallet
    // https://solidity-by-example.org/sending-ether
    function claim() external onlyOwner {
        // Send returns a boolean value indicating success or failure.
        (bool sent, ) = escrow.call{value: address(this).balance}("");
        require(sent, "Legendary Lions: Failed to send Ether");
    }

    /******************************/
    /**    EXTERNAL Functions   **/
    /******************************/

    /// @notice _mintNFT, internal function
    /// @dev mint new NFTs and verify all epochs and conditions
    /// @param _tokenType, token type to mint.
    function mintNFT(uint256 _tokenType) external payable whenNotPaused {
        require(
            msg.value >= nftPrice,
            "Legendary Lions: Ether value sent is not correct"
        );

        _mintNFT(msg.sender, _tokenType, totalSupply());
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
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }
        return (address(0), 0);
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
        virtual
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
    /// @param _tokenType, token type to mint.
    /// @param _tokenId, token ID to mint.
    function _mintNFT(
        address _to,
        uint256 _tokenType,
        uint256 _tokenId
    ) internal {
        require(
            totalSupply() + 1 <= MAX_NFT,
            "Legendary Lions: Tokens number to mint cannot exceed number of MAX tokens"
        );
        _setRoyalties(_tokenId, secondary, 400);
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, tokenUris[_tokenType]);
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

    /// @notice _burn, internal function
    /// @dev override needed for contract
    /// @param tokenId,  token ID
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
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
}