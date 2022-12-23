// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BHM_Record is
    ERC1155Burnable,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer
{
    mapping(uint256 => string) private _tokenURI;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => bool) public finalize;

    constructor() ERC1155("") {}

    function uri(uint256 _id) public view override returns (string memory) {
        return _tokenURI[_id];
    }

    function mint(uint256 _tokenId, uint256 _amount) public onlyOwner {
        _mint(msg.sender, _tokenId, _amount, "");
        totalSupply[_tokenId] = _amount;
    }

    function batchMint(
        uint256 _tokenId,
        uint256 _amount,
        address[] memory _receivers
    ) public onlyOwner {
        for (uint256 i = 0; i < _receivers.length; i++) {
            address receiver = _receivers[i];
            _mint(receiver, _tokenId, _amount, "");
        }
        totalSupply[_tokenId] += _receivers.length * _amount;
    }

    function setTokenURI(uint256 _tokenId, string memory _uri)
        public
        onlyOwner
    {
        require(
            !finalize[_tokenId],
            "Cannot be changed because it has been Finalized."
        );

        _tokenURI[_tokenId] = _uri;
    }

    function tokenFinalize(uint256 _tokenId) external onlyOwner {
        finalize[_tokenId] = true;
    }

    // Burn
    function burn(
        address,
        uint256 _tokenId,
        uint256 _amount
    ) public override(ERC1155Burnable) onlyOwner {
        require(totalSupply[_tokenId] >= _amount, "amount is incorrect.");

        totalSupply[_tokenId] -= _amount;
        super.burn(msg.sender, _tokenId, _amount);
    }

    function burnBatch(
        address,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) public override(ERC1155Burnable) onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 amount = _amounts[i];
            require(totalSupply[tokenId] >= amount, "amount is incorrect.");

            totalSupply[tokenId] -= amount;
        }

        super.burnBatch(msg.sender, _tokenIds, _amounts);
    }

    // OpenSea OperatorFilterer
    function setOperatorFilteringEnabled(bool _state) external onlyOwner {
        operatorFilteringEnabled = _state;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // Royality
    function setRoyalty(address _royaltyAddress, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}