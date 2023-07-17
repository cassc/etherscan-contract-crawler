pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "ERC721URIStorage.sol";
import "ERC721Enumerable.sol";
import "IERC2981.sol";
import "Ownable.sol";
import "Address.sol";

/**
 * @title Sample NFT contract
 * @dev Extends ERC-721 NFT contract and implements ERC-2981
 */

contract Token is Ownable, ERC721Enumerable, ERC721URIStorage {
    using Address for address payable;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    string baseUri;
    // Keep a mapping of token ids and corresponding hashes
    mapping(string => uint8) hashes;
    // Maximum amounts of mintable tokens
    uint256 private MAX_SUPPLY = 10000;
    // Address of the royalties recipient
    address private _royaltiesReceiver;
    // Percentage of each sale to pay as royalties
    uint256 private royaltiesPercentage;
    // Mint price wei
    uint256 private mintPrice;
    bool private saleIsActive;

    mapping(address => uint256) private _deposits;

    // Events
    event Mint(uint256 tokenId, address recipient);
    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

constructor(address initialRoyaltiesReceiver) ERC721("BongaNFT", "BCNC") {
        baseUri = "https://bonganft.io/metadata/";
        _royaltiesReceiver = initialRoyaltiesReceiver;
        mintPrice = 150000000000000000;  
        MAX_SUPPLY = 10000;
        royaltiesPercentage = 250;
        saleIsActive = false;
    }
    
    /// @notice Checks if NFT contract implements the ERC-2981 interface
    /// @param _contract - the address of the NFT contract to query
    /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal returns (bool) {
        (bool success) = IERC2981(_contract).
        supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    function startSale() public onlyOwner {
        saleIsActive = true;
    }

    function toggleSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setMintPrice(uint256 newMintPrice)
    external onlyOwner {
        require(mintPrice != newMintPrice, "same price"); // dev: Same price
        mintPrice = newMintPrice;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function setMaxSupply(uint256 newMaxSupply)
    external onlyOwner {
        require(MAX_SUPPLY != newMaxSupply, "same supply"); // dev: Same MAX_SUPPLY
        MAX_SUPPLY = newMaxSupply;
    }

    function setRoyaltiesPercentage(uint256 newRoyaltiesPercentage)
    external onlyOwner {
        require(royaltiesPercentage != newRoyaltiesPercentage, "same percent"); // dev: Same MAX_SUPPLY
        require(newRoyaltiesPercentage < 10000, "Royalty total value should be < 10000");
        royaltiesPercentage = newRoyaltiesPercentage;
    }

    /** Overrides ERC-721's _baseURI function */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory _newUri)
    external onlyOwner {
        baseUri = _newUri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(uint256 tokenId)
    internal override(ERC721, ERC721URIStorage) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        super._burn(tokenId);
    }

    /// @notice Getter function for _royaltiesReceiver
    /// @return the address of the royalties recipient
    function royaltiesReceiver() external view returns(address) {
        return _royaltiesReceiver;
    }

    /// @notice Changes the royalties' recipient address (in case rights are
    ///         transferred for instance)
    /// @param newRoyaltiesReceiver - address of the new royalties recipient
    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
    external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    /// @notice Returns a token's URI
    /// @dev See {IERC721Metadata-tokenURI}.
    /// @param tokenId - the id of the token whose URI to return
    /// @return a string containing an URI pointing to the token's ressource
    function tokenURI(uint256 tokenId)
    public view override(ERC721, ERC721URIStorage)
    returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
    public view virtual override (ERC721, ERC721Enumerable)
    returns (bool) {
        return interfaceId == type(IERC2981).interfaceId ||
        interfaceId == _INTERFACE_ID_ERC2981 ||
        super.supportsInterface(interfaceId);
    }


    /// @notice Returns all the tokens owned by an address
    /// @param _owner - the address to query
    /// @return ownerTokens - an array containing the ids of all tokens
    ///         owned by the address
    function tokensOfOwner(address _owner) external view
    returns(uint256[] memory ownerTokens ) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            for (uint256 i=0; i<tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view
    returns (address receiver, uint256 royaltyAmount) {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 10000;
        return (_royaltiesReceiver, _royalties);
    }

    /// @notice Mints tokens Owner
    /// @param recipient - the address to which the token will be transfered
    /// @return tokenId - the id of the token
    function mintOwner(address recipient) external onlyOwner
    returns (uint256 tokenId)
    {
        require(totalSupply() <= MAX_SUPPLY, "All tokens minted");
        uint256 newItemId = totalSupply() + 1;
        string memory hash = string(abi.encodePacked(uint2uristr(newItemId*15+99), ".json"));
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, hash);
        emit Mint(newItemId, recipient);
        return newItemId;
    }

    /// @notice Mints tokens All
    /// @param recipient - the address to which the token will be transfered
    /// @return tokenId - the id of the token
    function mint(address recipient, uint256 qty) external payable
    returns (uint256 tokenId)
    {
        require(saleIsActive == true, "Minting disabled");
        require(totalSupply() <= MAX_SUPPLY, "All tokens minted");
        require(msg.value >= mintPrice*qty, "Not enough ETH sent; check price!"); 
        uint256 newItemId = totalSupply();
        string memory hash = "";

        for (uint256 i=0; i<qty; i++) {
            newItemId = newItemId + 1;
            hash = string(abi.encodePacked(uint2uristr(newItemId*15+99), ".json"));
            _safeMint(recipient, newItemId);
            _setTokenURI(newItemId, hash);
            emit Mint(newItemId, recipient);
        }
        return newItemId;
    }

    function uint2uristr(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(bstr);
    }

    //deposits
    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee, uint256 payment) public virtual onlyOwner {
        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }

    function withdrawAll(address payable payee) public virtual onlyOwner {
        uint256 balance = address(this).balance;
        payee.sendValue(balance);
        emit Withdrawn(payee, balance);
    }
}