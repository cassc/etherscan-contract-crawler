// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SageNFT1155Royalties is  IERC2981, Ownable,ERC1155URIStorage {

    string public name; 
    string public symbol; 
    uint256 public tokenCount;
    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => RoyaltyInfo) internal _royalties;

    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    constructor(
        string memory _name, 
        string memory _symbol    
    )
    
    ERC1155(_name){
        name = _name;
        symbol = _symbol ;
    }

    function createToken(
        uint256 amount, 
        string memory URI, 
        address royaltyRecipient,
        uint256 royaltyValue) public  {  

        _mint(msg.sender, tokenCount, amount, ""); 
        _setURI(tokenCount, URI);
        require(royaltyValue <5001, "Royalties must be < 50%");
        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenCount, royaltyValue, royaltyRecipient);
        }
        tokenCount +=1;

    }

    
    
    function uri(uint256 _tokenId) override public view returns(string memory){
        return super.uri(_tokenId);
    }

    /** @dev EIP2981 royalties implementation. */

    /// @dev Sets token royalties
    /// @param tokenId the token id fir which we register the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(uint256 tokenId, uint256 value , address recipient ) internal {
        require(value <= 5001, "ERC2981Royalties: Must be <=50%");
        _royalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }

    
    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
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

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}