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

    string public name;
    string public symbol;
    uint private id = 0;
    string private metadata_uri;


    

    struct TokenInfo  {
        bytes uri;
        RoyaltyInfo royalty;
        string files;
    }

    mapping(uint256 => TokenInfo) private _tokenInfo;
 

    constructor(string memory _name, string memory _symbol, string memory _metadata_uri)
        ERC1155("") {
            name=_name;
            // id = 0;
            symbol = _symbol;
            metadata_uri = _metadata_uri; 

    }


    function contractURI() public view returns (string memory) {
        return metadata_uri;
    }


  
    function uri(uint256 id) public view virtual override returns (string memory) {
        return string(_tokenInfo[id].uri);
    }

    function mint(address to, uint256 amount, bytes calldata uri_, address royaltyRecipient, uint256 royaltyValue, string memory _pFiles) external virtual onlyOwner {

        // require(address(msg.sender)!=owner,"Only owner can mint");
        _mint(to, id, amount, "");
        if (uri_.length > 0) {
            _tokenInfo[id].uri = uri_;
        }
        
        if (royaltyValue > 0) {
            _setTokenRoyalty(id, royaltyRecipient, royaltyValue);
        }
        _tokenInfo[id].files = _pFiles;
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


    function GetPrivateFiles(uint256 _tokenId) external view returns (string memory) {
        require(balanceOf(address(msg.sender), _tokenId) > 0, "This NFT is not present in ur Account");
        return _tokenInfo[_tokenId].files;
    }


    

    function _setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _tokenInfo[tokenId].royalty = RoyaltyInfo(recipient, uint24(value));
    }    

}