//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract ToneByFaust is 
    Initializable, 
    ERC721Upgradeable, 
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable, 
    PausableUpgradeable,
    ERC721RoyaltyUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    string public uriPrefix;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Tone by Faust", "TONE");
        __ERC721Enumerable_init();
        __Ownable_init();
        __Pausable_init();
        __ERC721Royalty_init();
	    __DefaultOperatorFilterer_init();

        uriPrefix = "https://meta.tonic.xyz/tone/";
    }

    function adminMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function adminMintBulk(address[] calldata addresses, uint256[] calldata tokenIds)
        external
        onlyOwner
    {
        require(
            addresses.length == tokenIds.length,
            "mismatch in array lengths"
        );
        for (uint8 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i],tokenIds[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function contractURI() public pure returns (string memory) {
        return "https://meta.tonic.xyz/tone/collection";
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override (ERC721Upgradeable)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        StringsUpgradeable.toString(_tokenId)
                    )
                )
                : "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(address payable _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }
    
    /*
     * Set secondary market royalties using the EIP2981 standard
     * Royalties will be sent to the supplied `reciever` address
     * The royalty is calcuated feeNumerator / 10000
     * A 5% royalty, would use a feeNumerator of 500 (500/10000=.05)
     */
    function setRoyalties(address reciever, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(reciever, feeNumerator);
    }

    function setUriPrefix(string memory _prefix) public onlyOwner {		
         uriPrefix = _prefix;		
     }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable,ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable,ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are required by OpenSea Operator Filter (https://github.com/ProjectOpenSea/operator-filter-registry)
    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable,IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable,IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable,IERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable,IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable,IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}