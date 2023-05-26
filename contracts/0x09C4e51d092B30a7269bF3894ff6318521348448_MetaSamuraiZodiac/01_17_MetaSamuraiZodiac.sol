// SPDX-License-Identifier: MIT

// ███╗   ███╗███████╗████████╗ █████╗ ███████╗ █████╗ ███╗   ███╗██╗   ██╗██████╗  █████╗ ██╗
// ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔══██╗████╗ ████║██║   ██║██╔══██╗██╔══██╗██║
// ██╔████╔██║█████╗     ██║   ███████║███████╗███████║██╔████╔██║██║   ██║██████╔╝███████║██║
// ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║╚════██║██╔══██║██║╚██╔╝██║██║   ██║██╔══██╗██╔══██║██║
// ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║  ██║██║  ██║██║
// ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝
//
//                     ███████╗ ██████╗ ██████╗ ██╗ █████╗  ██████╗
//                     ╚══███╔╝██╔═══██╗██╔══██╗██║██╔══██╗██╔════╝
//                       ███╔╝ ██║   ██║██║  ██║██║███████║██║
//                      ███╔╝  ██║   ██║██║  ██║██║██╔══██║██║
//                     ███████╗╚██████╔╝██████╔╝██║██║  ██║╚██████╗
//                     ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {UpdatableOperatorFilterer} from "./operatorFilterer/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./operatorFilterer/RevokableDefaultOperatorFilterer.sol";

/**
 * @dev Implementation of the MS tokens which are ERC721 tokens.
 */
contract MetaSamuraiZodiac is
    ERC721,
    RevokableDefaultOperatorFilterer,
    Ownable,
    ERC2981
{
    /**
     * @dev The base URI of metadata
     */
    string private _baseTokenURI;

    /**
     * @dev The max number of tokens can be minted.
     */
    uint256 public maxSupply;

    /**
     * @dev The total number of the MS tokens minted so far.
     */
    uint256 public totalSupply;

    /**
     * @dev The contract id that can call mintAfterBurning.
     */
    address public contractIdFormintAfterBurning;

    /**
     * @dev Constractor of LupinMetaSamurai contract. Setting the base token URI,
     * max supply, royalty info and merkle proof.
     * @param _maxSupply The amount of max supply
     */
    constructor(uint256 _maxSupply) ERC721("MetaSamurai", "MS") {
        setMaxSupply(_maxSupply);
        setRoyaltyInfo(_msgSender(), 750); // 750 == 7.5%
    }

    /**
     * @dev Throws if minting more than 'maxSupply' or
     * when '_mintAmount' is 0.
     * @param _mintAmount The amount of minting
     */
    modifier mintCompliance(uint256 _mintAmount) {
        require(
            totalSupply + _mintAmount <= maxSupply,
            "Must mint within max supply"
        );
        require(_mintAmount > 0, "Must mint at least 1");
        _;
    }

    /**
     * external
     * -----------------------------------------------------------------------------------
     */

    /**
     * @dev For receiving ETH just in case someone tries to send it.
     */
    receive() external payable {}

    /**
     * @notice Only the owner can mint the number of '_mintAmount'.
     * @dev Mint the specified MS tokens and transfer them to the owner address.
     * @param _mintAmount The amount of minting
     */
    function ownerMint(uint256 _mintAmount)
        external
        onlyOwner
        mintCompliance(_mintAmount)
    {
        mint_(_mintAmount, owner());
    }

    function mintAfterBurning(address _caller, uint256 _amount)
        external
        mintCompliance(_amount)
    {
        require(
            _msgSender() == contractIdFormintAfterBurning,
            "Wrong contract ID"
        );
        mint_(_amount, _caller);
    }

    function setContractID(address _newContractID) external onlyOwner {
        contractIdFormintAfterBurning = _newContractID;
    }

    /**
     * @notice Only the owner can withdraw all of the contract balance.
     * @dev All the balance transfers to the owner's address.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw is failed!!");
    }

    /**
     * public
     * -----------------------------------------------------------------------------------
     */

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @dev Set the new token URI to '_baseTokenURI'.
     */
    function setBaseTokenURI(string memory _newTokenURI) public onlyOwner {
        _baseTokenURI = _newTokenURI;
    }

    /**
     * @dev Set the new max supply to 'maxSupply'.
     */
    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    /**
     * @dev Set the new royalty fee and the new receiver.
     */
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFee)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * internal
     * -----------------------------------------------------------------------------------
     */

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * private
     * -----------------------------------------------------------------------------------
     */

    /**
     * @dev This is the common minting function of ownerMint and preMint.
     * Mint the specified MS tokens and transfer them to '_to'.
     * @param _mintAmount The amount of minting
     * @param _to The address where MS tokens are transferred.
     */
    function mint_(uint256 _mintAmount, address _to) private {
        uint256 currentTokenId = totalSupply;
        uint256 maxTokenId = currentTokenId + _mintAmount;

        totalSupply = maxTokenId;
        for (; currentTokenId < maxTokenId; ) {
            unchecked {
                ++currentTokenId;
            }
            _safeMint(_to, currentTokenId);
        }
    }
}