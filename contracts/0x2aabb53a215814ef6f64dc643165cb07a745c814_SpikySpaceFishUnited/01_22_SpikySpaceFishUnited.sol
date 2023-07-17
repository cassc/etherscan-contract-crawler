// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "closedsea/src/OperatorFilterer.sol";

contract SpikySpaceFishUnited is
Initializable,
UUPSUpgradeable,
OwnableUpgradeable,
ERC2981Upgradeable,
OperatorFilterer,
ERC721Upgradeable
{
    /// @notice Maximum supply for the collection
    uint256 public constant MAX_TOKEN = 10000;

    /// @notice Base URI for the token
    string private baseURI;

    uint public totalSupply;

    function initialize(string memory baseURI_) public initializer {
        __ERC721_init("SpikySpaceFish United", "SSFU");
        __Ownable_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();
        _registerForOperatorFiltering();
        baseURI = baseURI_;
    }

    /**
     * @notice Airdrop NFTs to
     * @param _wallets Owners to airdrop to
     * @param _tokenIds token id to issue
     */
    function airdrop(
        address[] calldata _wallets,
        uint256[] calldata _tokenIds
    ) external onlyOwner {
        require(_wallets.length == _tokenIds.length, "Invalid Input");
        require(
            totalSupply + _wallets.length <= MAX_TOKEN,
            "Max supply exceeded"
        );
        totalSupply += _wallets.length;
        for (uint256 i = 0; i < _wallets.length; i++) {
            _mint(_wallets[i], _tokenIds[i]);
        }
    }



    /**
     * @inheritdoc ERC721Upgradeable
     */
    function isApprovedForAll(
        address owner,
        address operator
    )
    public
    view
    virtual
    override(ERC721Upgradeable)
    returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function setApprovalForAll(
        address operator,
        bool approved
    )
    public
    override(ERC721Upgradeable)
    onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function approve(
        address operator,
        uint256 tokenId
    )
    public
    override(ERC721Upgradeable)
    onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
    public
    override(ERC721Upgradeable)
    onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
    public
    override(ERC721Upgradeable)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
    public
    override(ERC721Upgradeable)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Set the Base URI
     * @param baseURI_ Base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */

    function supportsInterface(
        bytes4 interfaceId
    )
    public
    view
    virtual
    override(ERC721Upgradeable, ERC2981Upgradeable)
    returns (bool)
    {
        return
        ERC721Upgradeable.supportsInterface(interfaceId) ||
        ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @inheritdoc UUPSUpgradeable
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @notice Return the implementation contract
     * @return address The implementation contract address
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /*
     * @notice withdraw ether from contract
     */

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
                value: address(this).balance
            }("");
        require(success, "transfer failed!");
    }

    receive() external payable {}
}