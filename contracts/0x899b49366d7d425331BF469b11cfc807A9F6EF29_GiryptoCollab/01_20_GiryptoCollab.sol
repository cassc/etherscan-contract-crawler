// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract GiryptoCollab is ERC1155, ERC1155Supply, ERC1155Burnable, IERC2981, ReentrancyGuard, DefaultOperatorFilterer, Ownable {

    using Strings for uint256;

    string public name;
    string public symbol;
    uint256 public currentTokenID = 1;
    uint256 public royaltiesPercentage = 530;
    address public communityWallet = 0xbFdbd0392f843C4a6309b47b88e01eCB10088b02;
    mapping(uint256 => mapping(address => bool)) public whitelist;

    struct TokenData {
        string uri;
        uint256 maxmint;
        uint256 supply;
        uint256 price;
        bool soulbound;
        bool whitelist;
    }
    mapping(uint256 => TokenData) public token;

    event MintEvent(
        uint256 indexed date,
        address indexed to,
        uint256 indexed tokenID,
        uint256 amount
    );

    event RoyaltyPercentageEvent(uint256 _newPercentage);

    modifier mintCompliance(address _receiver, uint256 _tokenId, uint256 _mintAmount) {
        require(exists(_tokenId), "Token does not exist");
        require(totalSupply(_tokenId) + _mintAmount <= token[_tokenId].supply, "Max supply exceeded");
        require(msg.value >=  token[_tokenId].price * _mintAmount, "Insufficient funds");
        if(_receiver != owner()){
            require(balanceOf(_receiver, _tokenId) + _mintAmount <= token[_tokenId].maxmint, "Max NFT per address exceeded");
        }
		_;
	}

    modifier onlyExternal() {
		require(msg.sender == tx.origin, "Contracts not allowed to mint");
		_;
	}

    constructor() ERC1155("") {
        name = "Artist Collab";
        symbol = "GAC";
    }

    function mintCall(
        address _receiver, 
        uint256 _tokenId, 
        uint256 _mintAmount
    ) internal {

        _mint(_receiver, _tokenId, _mintAmount, "");
        emit MintEvent(block.timestamp, _receiver, _tokenId, _mintAmount);

    }

    // for owner to mint
    function ownerMint(
            address _receiver, 
            uint256 _tokenId, 
            uint256 _mintAmount
        ) public payable mintCompliance(_receiver, _tokenId, _mintAmount) onlyOwner
    {
        mintCall(_receiver, _tokenId, _mintAmount);
    }

    // for public to mint, could have whitelist enable and payment
    function publicMint(
        uint256 _tokenId, 
        uint256 _mintAmount
    ) public payable mintCompliance(msg.sender, _tokenId, _mintAmount) onlyExternal nonReentrant
    {
        if (token[_tokenId].whitelist) {
            require(whitelist[_tokenId][msg.sender], "Not Whitelisted");
        }

        mintCall(msg.sender, _tokenId, _mintAmount);
    }

    // for airdrop by owner
    function airDrop(
            address[] memory _addresses, 
            uint256 _tokenId, 
            uint256[] memory _mintAmount
        ) public onlyOwner 
    {   
        require(exists(_tokenId), "Token does not exist");
        require(totalSupply(_tokenId) + _addresses.length <= token[_tokenId].supply, "Max supply exceeded");

        for (uint256 i = 0; i < _addresses.length; i++) {
            mintCall(_addresses[i], _tokenId, _mintAmount[i]);
        }
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return(token[_tokenId].uri);
    }

    // this is required for soul bound and NFT per user checking
    function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual override(ERC1155, ERC1155Supply) {  
        //from address(0) is during mint
        //to address(0) is during burn
        if(from != address(0) && to != address(0) && from != owner()){

            for (uint256 i = 0; i < ids.length ; i++) { 
                require(token[ids[i]].soulbound != true, "The tokens cannot be transferred");
                require(balanceOf(to, ids[i]) + amounts[i] <= token[ids[i]].maxmint, "Max NFT per address exceeded");
            }

        }

        if(data.length == 0) {
            data = new bytes(0);
        }
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
	}


    /*
    ONLY OWNER
    */
    //create new token, _price use wei
    // 1 eth = 1000000000000000000 wei
    function createNewToken(
            string memory _uri, 
            uint256 _mintAmount,  
            uint256 _maxmint, 
            uint256 _supply,
            uint256 _price,
            bool _soulbound,
            bool _whitelist
        ) public onlyOwner
    {
        mintCall(msg.sender, currentTokenID, _mintAmount);
        TokenData memory data = TokenData(_uri, _maxmint, _supply, _price, _soulbound, _whitelist);
        token[currentTokenID] = data;
        currentTokenID++;
    }

    //set token uri
    function setUri(uint256 _tokenId, string memory _uri) public onlyOwner {
        token[_tokenId].uri = _uri;
    }

    //set token max mint per user
    function setMaxMint(uint256 _tokenId, uint256 _maxmint) public onlyOwner {
        token[_tokenId].maxmint = _maxmint; 
    }

    //set token supply
    function setSupply(uint256 _tokenId, uint256 _supply) public onlyOwner {
        token[_tokenId].supply = _supply;
    }

    //set token price
    function setPrice(uint256 _tokenId, uint256 _price) public onlyOwner {
        token[_tokenId].price = _price;
    }

    //set token soul bound
    function setSoulBound(uint256 _tokenId, bool _soulBound) public onlyOwner {
        token[_tokenId].soulbound = _soulBound;
    }

    //set token soul bound
    function setWhiteListBool(uint256 _tokenId, bool _whitelist) public onlyOwner {
        token[_tokenId].whitelist = _whitelist;
    }

    //set whitelist for token
    function setWhiteList(uint256 _tokenId, address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_tokenId][_addresses[i]] = true;
        }
    }

    //change the current running id
    function setTokenID(uint256 _currentTokenID) public onlyOwner {
		currentTokenID = _currentTokenID;
	}

    // set royalty percentage 530 = 5.3%
    function setRoyaltyPercentage(uint256 _newPercentage) public onlyOwner {
		royaltiesPercentage = _newPercentage;
        emit RoyaltyPercentageEvent(royaltiesPercentage);
	}

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function setCommunityWallet(address _wallet) external onlyOwner{
        communityWallet = _wallet;
    }

    /*
    OPENSEA
    */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
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

    /*
    EIP-2981
    */

    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC1155) returns (bool) {
		return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
	}

    function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
		uint256 royalties = (_salePrice * royaltiesPercentage) / 10000;
		return (communityWallet, royalties);
	}
}