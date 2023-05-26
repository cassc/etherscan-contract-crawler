// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

contract EthlizardsGenesisV2 is DefaultOperatorFilterer, Ownable, ERC2981, ERC721 {
    using Strings for uint256;

    // EthlizardsDAO address, for receiving royalties
    address public EthlizardsDAO = 0xa5D55281917936818665c6cB87959b6a147D9306;
    // Address allowed to use adminTransfer
    address public adminTransferer;
    uint256 private constant maxLizardSupply = 100;
    // Metadata for Ethlizards
    string public baseURI = "https://ipfs.io/ipfs/QmUfYUxDCiXHmMvJrjighbQFk6wwGoos8yzTaXE5GNbdNX/";
    // Counter for amount airdropped
    uint256 public supplyAirdropped;
    // Current Royalties
    uint96 public currentRoyaltyPercentage;
    // The status of transfers
    bool public transfersAllowed = false;

    event BaseUriUpdated(string baseURI);
    event AdminTransfererUpdated(address adminTransferer);
    event EthlizardsDAOUpdated(address EthlizardsDAO);
    event TransfersEnabled();

    constructor() ERC721("Ethlizards Genesis", "LIZARD") {
        _setDefaultRoyalty(EthlizardsDAO, 750);
        currentRoyaltyPercentage = 750;
        adminTransferer = msg.sender;
    }

    /**
     * @notice Function to airdrop holders their new NFTs
     * @param owners Array of the address of the owners
     */
    function airdrop(address[] calldata owners, uint256[] calldata tokenIds) external onlyOwner {
        uint256 airdropSize = owners.length;

        if (owners.length != tokenIds.length) {
            revert InputsDoNotMatch({ownersLength: owners.length, tokensLength: tokenIds.length});
        }

        if (supplyAirdropped + airdropSize > maxLizardSupply) {
            revert MaxSupplyAirdropped();
        }

        for (uint256 i; i < airdropSize;) {
            _mint(owners[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        unchecked {
            supplyAirdropped = supplyAirdropped + airdropSize;
        }
    }

    /**
     * @notice Function to transfer an array of tokenIds
     * @param _from Address transferring from
     * @param _tokenIds TokenIds of the owners
     */
    function batchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    /**
     * @notice Sets baseUri for metadata
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseUriUpdated(_baseURI);
    }

    /**
     * @notice Sets the adminTransferer address
     */
    function setAdminTransferer(address _adminTransferer) external onlyOwner {
        adminTransferer = _adminTransferer;
        emit AdminTransfererUpdated(_adminTransferer);
    }

    /**
     * @notice Sets the EthlizardsDAO address
     */
    function setEthlizardsDAOAddress(address _newEthlizardsDAO) external onlyOwner {
        EthlizardsDAO = _newEthlizardsDAO;
        _setDefaultRoyalty(EthlizardsDAO, currentRoyaltyPercentage);
        emit EthlizardsDAOUpdated(EthlizardsDAO);
    }

    /**
     * @notice Sets status of transfers
     */
    function setTransfersActive() external onlyOwner {
        transfersAllowed = true;
        emit TransfersEnabled();
    }

    /**
     * @notice Admin transfer function
     */
    function adminTransferFrom(address _from, address _to, uint256 _tokenId) external {
        if (msg.sender != adminTransferer) {
            revert NotAdminTransferer();
        }
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @notice Overriden tokenURI to accept ipfs links
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")) : "";
    }

    /**
     * @notice Inherited from Opensea's Operator Filter
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Inherited from Opensea's Operator Filter
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @notice Inherited from Opensea's Operator Filter
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Inherited from Opensea's Operator Filter
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Inherited from Opensea's Operator Filter
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Sets the royalties of the collection. Is in 2 dp. EG, 100 = 1%
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        currentRoyaltyPercentage = feeNumerator;
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Deletes royalties
     */
    function deleteDefaultRoyalty() public onlyOwner {
        currentRoyaltyPercentage = 0;
        _deleteDefaultRoyalty();
    }

    /**
     * @notice Interface for marketplaces
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Overriden from default ERC721 contract to prohibit token transfers unless enabled by the owner
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override
    {
        /// @dev, _mint will also call this _beforeTokenTransfer, so we let it do so without any restrictions
        /// if the from address is address(0).
        if (from != address(0) && !transfersAllowed) {
            revert TransfersNotAllowed();
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    ////////////
    // Errors //
    ////////////

    // User is trying to transfer a token when transfers aren't enabled
    error TransfersNotAllowed();
    // The size of the 2 arrays inputted do not match
    error InputsDoNotMatch(uint256 ownersLength, uint256 tokensLength);
    // Max supply has been reached
    error MaxSupplyAirdropped();
    // Person calling the admin transfer function isn't an admin
    error NotAdminTransferer();
}