// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./SafeERC20.sol";

contract TwelveZodiacNFT is ERC721Enumerable  {
    using SafeERC20 for IERC20;

    IERC20 private Wallet;
    address owner;
    bool public transferAllowance;
    uint8 constant CodeLength = 10;
    string BASE_URI;
    uint256 cost;

    struct NFTProducts {
        string name;
        uint256 busdprice;
        uint256 fuel;
        string tokenuri;
        bool available;
    }

    struct NFTData {
        string name;
        uint256 busdprice;
        uint256 fuel;
        string tokenuri;
        string code;
    }

    struct CodeNFT {
        uint256 tokenid;
        bool registered;
    }

    uint256[] _productids;
    mapping(uint256 => NFTProducts) _products;
    mapping(uint256 => NFTData) _nfts;
    mapping(string => CodeNFT) _codes;

    using Counters for Counters.Counter;
    Counters.Counter private counterIDs;

    constructor(IERC20 payment_token) ERC721("Twelve Zodiac NFT", "TZNFT") {
        Wallet = IERC20(payment_token);
        owner = msg.sender;
        transferAllowance = false;
        counterIDs.increment();
        BASE_URI = "";
    }

    modifier onlyOwner() {
       CheckOwner();
        _;
    }

    function CheckOwner() internal view virtual {
        require((owner == msg.sender), "ACCESS_DENIED");
    }

    event AdminTokenRecovery(address _tokenRecovered, uint256 _amount);
    event BuyNFT(address _buyer, uint256 _tokenid);

    function random(uint256 _number, uint256 _counter) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _counter))) % _number;
    }

    function CodeGenerator() internal view returns (string memory) {
        bytes memory word = new bytes(CodeLength);
        bytes memory chars = new bytes(36);
        chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
        for (uint256 i = 0; i < CodeLength; i++) {
            uint256 randomNumber = random(36, i);
            word[i] = chars[randomNumber];
        }
        return string(word);
    }

    function BuyItem(uint32 _productid) external payable returns (uint256 tokenID, string memory codenft) {
        require(msg.value >= cost);
        require(_products[_productid].available, "Product not found");
        require(Wallet.transferFrom(msg.sender, address(this), _products[_productid].busdprice), "Payment BUSD Fail");

        bool codevalid = false;
        while(!codevalid) {
            codenft = CodeGenerator();
            if(!_codes[codenft].registered) codevalid = true;
        }

        tokenID = counterIDs.current();
        counterIDs.increment();
        _mint(msg.sender, tokenID);
        _codes[codenft] = CodeNFT(tokenID, true);
        _nfts[tokenID] = NFTData({
                name: _products[_productid].name,
                busdprice: _products[_productid].busdprice,
                fuel: _products[_productid].fuel,
                tokenuri: _products[_productid].tokenuri,
                code: codenft
            });
        
        emit BuyNFT(msg.sender, tokenID);
        return (tokenID, codenft);
    }

    function getTokenIDByCode(string memory _code) external view returns (uint256) {
        require(_codes[_code].registered, "Code is not found");
        return _codes[_code].tokenid;
    }

    function tokenURI(uint256 _tokenID) public view virtual override returns (string memory) {
        require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");
        return string(bytes.concat(bytes(BASE_URI), bytes(_nfts[_tokenID].tokenuri)));
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(transferAllowance, "Token unable to transfer");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(transferAllowance, "Token unable to transfer");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(transferAllowance, "Token unable to transfer");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function OwnerTokenIds(address addr) public view returns (uint256[] memory) {
        uint256 nftCount = balanceOf(addr);
        uint256[] memory tokenIds = new uint256[](nftCount);
        for (uint256 i; i < nftCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokenIds;
    }

    function ownerOf(uint256 _tokenid) public view virtual override returns (address) {
        address addr = _ownerOf(_tokenid);
        require(addr != address(0), "ERC721: invalid token ID");
        return addr;
    }

    function getTokenData(uint256 _tokenid) public view returns (NFTData memory) {
        require(_exists(_tokenid), "ERC721Metadata: URI query for nonexistent token");
        NFTData memory result = _nfts[_tokenid];
        if(ownerOf(_tokenid) != msg.sender) {
            result.code = "forbidden";
        }
        result.tokenuri = string(bytes.concat(bytes(BASE_URI), bytes(result.tokenuri)));
        return result;
    }

    function getProductDetails(uint256 _id) public view returns (NFTProducts memory) {
        NFTProducts memory result = _products[_id];
        result.tokenuri = string(bytes.concat(bytes(BASE_URI), bytes(result.tokenuri)));
        return result;
    }

    function getProductIds() public view returns (uint256[] memory) {
        return _productids;
    }

    function getAllProducts() public view returns (NFTProducts[] memory) {
        NFTProducts[] memory id = new NFTProducts[](_productids.length);
        for (uint i = 0; i < _productids.length; i++) {
            NFTProducts memory product_data = _products[_productids[i]];
            product_data.tokenuri = string(bytes.concat(bytes(BASE_URI), bytes(product_data.tokenuri)));
            id[i] = product_data;
        }
        return id;
    }

    /**
     * Owner function
     */
    function setProducts(
        uint256 _id, string memory _name, uint256 _price, uint256 _fuel, string memory _ipfs
    ) public onlyOwner {
        if(!_products[_id].available) _productids.push(_id);
        _products[_id] = NFTProducts({
                            name : _name,
                            busdprice : _price,
                            fuel : _fuel,
                            tokenuri : _ipfs,
                            available: true
                        });
    }

    function removeProducts(uint256 _id) external onlyOwner {
        require(_products[_id].available, "Products does not exist.");
        for(uint i = 0; i < _productids.length; i++) {
            if(_productids[i] == _id) {
                _productids[i] = _productids[_productids.length - 1];
            }
        }
        _productids.pop();
        delete _products[_id];
    }

    function setAllowTransfer(bool _value) external onlyOwner {
        transferAllowance = _value;
    }

    function setCost(uint256 _newCost) public onlyOwner() {
        cost = _newCost;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner() {
        BASE_URI = _baseUri;
    }

    /**
    * Rescue Token
    */
    function recoveryToken(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function withdrawPayable() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
 }