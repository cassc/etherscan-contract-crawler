// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/security/Pausable.sol";
import "./@openzeppelin/contracts/utils/Strings.sol";
import "./@openzeppelin/contracts/utils/ContextMixin.sol";

contract KAD_NFT is ERC1155, IERC2981, Ownable, Pausable, ContextMixin {

    using Strings for uint256;
    string public name;
    string public symbol;
    string public contractUri;
    uint16 public total_supply;
    address private _recipient;

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _contractUri,
        string memory _uriBase,
        uint16 _editionLimit,
        uint16 _total_supply
        ) 
        
        ERC1155(_uriBase, _editionLimit) {
        name = _name;
        symbol = _symbol;
        total_supply = _total_supply;
        contractUri = _contractUri;
        _recipient = owner();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    function uri(uint256 tokenId) override public view returns (string memory) {
        require(tokenId >= 1 && tokenId <= total_supply, "ERC1155Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_uriBase, Strings.toString(tokenId), ".json"));
    }

    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * 1000) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    function _msgSender() internal override view returns (address) {
        return ContextMixin.msgSender();
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }
}