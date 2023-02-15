// SPDX-License-Identifier: AGPLv3"

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


import './ERC2981Base.sol';

/**
 * ERC1155Lockable extending IERC1155
 *
 * Add interface function approve(address to, uint256 tokenId, bytes32 hash, bytes calldata data)
 *
 * How to Transfer:
 * Seller
 *  a. Call keys(id, pub) => Gets encrypted key by pubKey1
 *  b. Decrypt key with privKey1 
 *  c. Encrypt key with pubKey2
 *  d. Call new method approveFor for buyer with encrypted key
 * Buyer
 *  a. Call keys(id, pub2) => Gets encrypted key by pubKey2
 *  b. Decrypt key with privKey2
 *  c. Decrypt URI by key
 *  d. Call transferFrom to finalaize the transfer
 */
 
contract ERC1155Lockable is
    ERC2981Base,
    ERC1155,
    Ownable {
    address payable private immutable feeAccount;

    bool private isProtected;

    string public name;
    string public symbol;
    uint private id;
    string private metadata_uri;


    

    uint private Minting_Fees = 6300000000;
    struct TokenInfo  {
        bytes uri;
        RoyaltyInfo royalty;
    }

    mapping(uint256 => TokenInfo) private _tokenInfo;
 
    // mapping(address => bool) private blacklist;

    constructor(string memory _name, string memory _symbol, string memory _metadata_uri)
        ERC1155("") {
            name=_name;
            id = 0;
            symbol = _symbol;
            // isProtected = _isProtected;
            feeAccount = payable(msg.sender);
            metadata_uri = _metadata_uri; 
            // _transferOwnership(n_owner);

    }


    function contractURI() public view returns (string memory) {
        return metadata_uri;
    }


    // function blackListAddress(address[] calldata _blacklist) public returns (bool) {
    //     require(_blacklist.length <0, "Array is empty.");
    //     for (uint256 i = 0; i < _blacklist.length;) {
    //             blacklist[_blacklist[i]] = true;
    //             unchecked { i++; }
    //         }
    //     return true;
    // }
    // function clearBlacklist(address _whiteAddress) public returns(bool){
    //     blacklist[_whiteAddress] = false;
    // }


    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     */
    function uri(uint256 id) public view virtual override returns (string memory) {
        return string(_tokenInfo[id].uri);
    }

    function mint(address to, uint256 amount, bytes calldata uri_, address royaltyRecipient, uint256 royaltyValue) external virtual onlyOwner {

        // require(address(msg.sender)!=owner,"Only owner can mint");
        _mint(to, id, amount, "");
        if (uri_.length > 0) {
            _tokenInfo[id].uri = uri_;
        }
        
        if (royaltyValue > 0) {
            _setTokenRoyalty(id, royaltyRecipient, royaltyValue);
        }
        // keys[to] = key;
        id++;
    }

    /*
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _value - the sale price of the NFT asset specified by _tokenId
     * @return _receiver - address of who should be sent the royalty payment
     * @return _royaltyAmount - the royalty payment amount for value sale price
     */
    function royaltyInfo(uint256 _tokenId, uint256 _value) external view override
        returns (address _receiver, uint256 _royaltyAmount) {
        RoyaltyInfo storage royalty = _tokenInfo[_tokenId].royalty;
        _receiver = royalty.recipient;
        _royaltyAmount = (_value * royalty.amount) / 10000;
    }

    /*
     * @inheritdoc	ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Base, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    // function _beforeTokenTransfer(
    //     address /*operator*/,
    //     address from,
    //     address to,
    //     uint256[] memory /*ids*/,
    //     uint256[] memory /*amounts*/,
    //     bytes memory /*data*/
    // ) internal override {
    //     // delete keys[from];
    //     // require(blacklist[to] == true, "invalid address");
    // }

    /*
     * @dev Sets token royalties
     * @param tokenId the token id fir which we register the royalties
     * @param recipient recipient of the royalties
     * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    


    

    function _setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _tokenInfo[tokenId].royalty = RoyaltyInfo(recipient, uint24(value));
    }    


    function Currentid() public view returns(uint){
        return id - 1;
    }
}