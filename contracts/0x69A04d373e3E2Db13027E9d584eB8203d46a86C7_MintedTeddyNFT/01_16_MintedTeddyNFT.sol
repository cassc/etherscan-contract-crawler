//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";


contract MintedTeddyNFT is ERC721URIStorage, ERC721Enumerable, EIP712, Ownable {
    string private constant SIGNING_DOMAIN = "MintedTeddy-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    mapping(uint256 => bool) private _locks;
    mapping(uint256 => uint256) private _editions;
    mapping(uint256 => uint256) private _maxSupply;

    /// @notice Sets the supply limits for each Minted Teddy drop.  These are hard limits that cannot be changed.
    constructor() 
        ERC721("MintedTeddy", "MINTEDTEDDY")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
            _maxSupply[1] = 100;
            _maxSupply[2] = 1000;
            _maxSupply[3] = 10000;
            _maxSupply[4] = 10;
            _maxSupply[5] = 1;
    }

    /// @notice The NFTVoucher struct describes a mintable voucher.
    /// @param tokenId This is the Token ID that will be minted.
    /// @param locked If the NFT is unlocked, the metadata can be updated.  This allows a minter to order a custom nft.
    /// @param edition This is the Minted Teddy edition.  It corresponds to the _maxSupply values.
    /// @param initialPrice This is how much it costs to mint the teddy.
    /// @param uri This is a URI that points to the metadata file.
    /// @param signature This is generated when the signer signs the voucher when it's created.
    struct NFTVoucher {
        uint256 tokenId;
        bool locked;
        uint256 edition;
        string initialPrice;
        string uri;
        bytes signature;
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice This gets the balance of the ETH stored in the contract.
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice This returns the number of Teddies that can be minted in an edition.
    function maxSupply(uint256 edition) external view returns (uint256) {
        return _maxSupply[edition];
    }

    /// @notice This mints a teddy.
    /// @param recipient This is the address of the user who is minting the teddy.
    /// @param voucher This is the unique NFTVoucher that is to be minted.
    function mintNFT(address recipient, NFTVoucher calldata voucher) external payable returns (uint256) {
        address signer = _verify(voucher);
        require(voucher.tokenId > 0, "Invalid Token ID.");
        require(voucher.edition >= 1 && voucher.edition <= 5, "Invalid token data. (Edition must be between 1 and 5)");
        require(voucher.locked == true || (voucher.locked == false && voucher.edition == 1), "Only first edition NFT's can be minted unlocked.");
        require(owner() == signer, "This voucher is invalid.");
        require(msg.value == _safeParseInt(voucher.initialPrice), "Incorrect amount of ETH sent.");
        require(_editions[voucher.edition] < _maxSupply[voucher.edition], "No more NFT's available to be minted.");
        
        _setTokenLock(voucher.tokenId, voucher.locked);
        _incrementEditionCount(voucher.edition);
        _safeMint(recipient, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
        
        return voucher.tokenId;
    }

    /// @notice This returns the number of teddies that have been minted in an edition.
    function totalEditionSupply(uint256 edition) external view returns (uint256) {
        return _editions[edition];
    }
    
    /// @notice When a user orders a custom NFT, the user works with our designer to build the perfect NFT.
    /// Once happy with the product, the metadata is updated using this function and locked.
    /// @param tokenId The Token ID to be updated
    /// @param uri The new URI to be set on the token.
    function updateMetadata(uint256 tokenId, string calldata uri) external onlyOwner {
        require(tokenId <= 100, "Customizations are only available for the first 100 tokens.");
        require(_locks[tokenId] != true, "The metadata for this token is locked.");
        _setTokenLock(tokenId, true);
        _setTokenURI(tokenId, uri);
    }
    
    /// @notice This will transfer all ETH from the smart contract to the contract owner.
    function withdraw() external onlyOwner { 
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Gets all the tokens that the address owns.
    /// @param _owner The address of an owner you want to view tokens of.
    function getTokenIds(address _owner) external view returns (uint[] memory) {
        uint[] memory _tokensOfOwner = new uint[](balanceOf(_owner));
        uint i;

        for (i = 0; i < balanceOf(_owner); i++) {
            _tokensOfOwner[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return (_tokensOfOwner);
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher) private view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("NFTVoucher(uint256 tokenId,bool locked,uint256 edition,string initialPrice,string uri)"),
        voucher.tokenId,
        voucher.locked,
        voucher.edition,
        keccak256(bytes(voucher.initialPrice)),
        keccak256(bytes(voucher.uri))
        )));
    }

    /// @notice This safely converts a string into an uint.
    /// @param _a This is the string to be converted into a uint.
    function _safeParseInt(string memory _a) private pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   break;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        return mint;
    }

    /// @notice This will increment the number of tokens that have been minted for an edition
    /// @param edition The edition number for which we are incrementing
    function _incrementEditionCount(uint256 edition) private {
        _editions[edition] = _editions[edition] + 1;
    }

    /// @notice This will set the lock value for a token
    /// @param tokenId The ID of the token you are setting
    /// @param locked The state you wish to put the token into
    function _setTokenLock(uint256 tokenId, bool locked) private {
        _locks[tokenId] = locked;
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher) private view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}