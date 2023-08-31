// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract BlueprintedNFT is ERC721Enumerable, Ownable {
    string  public              baseURI;
    
    address public              proxyRegistryAddress;
    address public              payee1;
    address public              payee2;

    bool    public              saleStatus;
    uint256 public constant     MAX_SUPPLY          = 7000;
    uint256 public              MAX_GIVEAWAY        = 350;

    uint256 public constant     MAX_PER_TX          = 20;
    uint256 public              priceInWei          = 0.02 ether;

    mapping(address => bool) public projectProxy;

    constructor(
        string memory _baseURI, 
        address _proxyRegistryAddress, 
        address _payee1,
        address _payee2
    )
        ERC721("BlueprintedNFT", "BP")
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        payee1 = _payee1;
        payee2 = _payee2;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setPrice(uint256 _priceInWei) public onlyOwner {
        priceInWei = _priceInWei;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function toggleSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }

    function mint(uint256 count) public payable {
        require(saleStatus, "Sale is not open");
        require(count * priceInWei == msg.value, "Invalid funds provided.");
        require(count < MAX_PER_TX, "Exceeds max per transaction.");
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Excedes max supply.");
         
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function promoMint(uint _qty, address _to) public onlyOwner {
        require(MAX_GIVEAWAY - _qty >= 0, "Exceeds max giveaway.");
        uint256 totalSupply = _owners.length;
        require(totalSupply + _qty < MAX_SUPPLY, "Excedes max supply.");
        for (uint i = 0; i < _qty; i++) {
            _mint(_to, totalSupply + i);
        }
        MAX_GIVEAWAY -= _qty;
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public  {
        (bool success, ) = payee1.call{value: address(this).balance * 10 / 100}("");
        require(success, "Failed to send to payee1.");
        (bool success2, ) = payee2.call{value: address(this).balance}("");
        require(success2, "Failed to send to payee2.");
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}