// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "openzeppelin-solidity/contracts/token/common/ERC2981.sol";

contract NewmismaMelody is ERC1155, AccessControl, Pausable, ERC1155Burnable, ERC1155Supply, ERC2981 {
    // Admin setup
    address internal withdrawAddress;

    // Royalties
    address internal royaltyAddress;
    uint96 private royaltyValue;

    // Collection specifics
    uint96 private maxQuantityPerArtwork;
    uint96 private maxQuantityPerCollector;
    uint256 private pricePerToken;
    string private contractUri;

    // Permissions management
    constructor() ERC1155("Newmisma - Melody girls") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Admin setup
        withdrawAddress = msg.sender;

        // Royalties
        royaltyAddress = msg.sender;
        royaltyValue = 1000;

        // Collection specifics
        maxQuantityPerArtwork = 1;
        maxQuantityPerCollector = 1;
        pricePerToken = 0.25 ether;
    }

    // Metadata for contract and token
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        require(tokenId >= 0, "Newmisma: Nonexistent token");
        string memory tokenUri = super.uri(tokenId);
        return string(abi.encodePacked(tokenUri, Strings.toString(tokenId)));
    }

    function mint(uint256 id, uint256 amount, bytes memory data) public payable whenNotPaused {
        require(amount > 0, "Newmisma: not enough token to mint");
        require((balanceOf(msg.sender, id) + amount) <= maxQuantityPerCollector, "Newmisma: you cannot mint more than allowed");
        require(msg.value >= pricePerToken * amount, "Newmisma: not enough eth provided");
        require((amount + totalSupply(id)) <= maxQuantityPerArtwork, "Newmisma: not enough supply remaining");
        _mint(msg.sender, id, amount, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    // EIP-2981: Royalties
    function updateRoyalties(address _royaltyAddress, uint96 _royaltyValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_royaltyAddress != address(0), "Newmisma: new recipient is the zero address");
        royaltyAddress = _royaltyAddress;
        royaltyValue = _royaltyValue;
    }

    function updateRoyaltiesForToken(uint256 tokenId, address _royaltyAddress, uint96 _royaltyValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, _royaltyAddress, _royaltyValue);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltyAddress, (_salePrice * royaltyValue) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl, ERC2981) returns (bool){
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    function getMetadata() external view returns (uint256, uint256, uint256, address, uint96) {
        return (pricePerToken, maxQuantityPerCollector, maxQuantityPerArtwork, royaltyAddress, royaltyValue);
    }

    function setContractUri(string memory _contractUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractUri = _contractUri;
    }

    function setURI(string memory newuri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success) {
        (success,) = payable(withdrawAddress).call{value: address(this).balance}("");
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}