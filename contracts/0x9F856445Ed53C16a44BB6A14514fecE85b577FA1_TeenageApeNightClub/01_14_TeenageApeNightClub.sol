// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Enumerable.sol";

contract TeenageApeNightClub is ERC721Enumerable, Ownable {
    string  public  baseURI;
    
    address private  constant  wallet = 0x2914D175A5a3763CC1AaC1a7B8BF67557A42b002;
    address public  proxyRegistryAddress;

    uint256 public  MAX_SUPPLY = 6000;
    uint256 public  MAX_TX = 6;
    uint256 public  reserved = 51;
    uint256 public  free = 600;
    uint256 public  price = 0.042 ether;
    
    bool public saleState = false;
    
    mapping(address => bool) public projectProxy;

    constructor(string memory _baseURI,address _proxyRegistryAddress) ERC721("TeenageApeNightClub", "TANC") {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function toggleProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function flipSaleState() public onlyOwner {
        saleState = !saleState;
    }

    function mint (uint256 count) public payable {
        require(saleState == true, "Sale not stated");
        uint256 totalSupply = _owners.length;
        // max tx check
        require(count < MAX_TX, "Exceeds max transaction.");
        // max supply check
        require(totalSupply + count <= MAX_SUPPLY, "Exceeds max supply.");
        if (totalSupply >= free)
        {
            require(count * price == msg.value, "Invalid funds provided.");            
        }
        else if (totalSupply + count >= free)
        {
            require((count - (free - totalSupply)) * price == msg.value, "Invalid funds provided.");
        }

        for(uint i; i < count; i++)
        {
            _mint(_msgSender(), totalSupply + i);
        }

    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 totalBalance = address(this).balance;

        (bool successA, ) = wallet.call{value: totalBalance}("");
        require(successA, "Failed to send to wallet");
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

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function reserveForTeam(uint256 amount) public onlyOwner {
        uint256 totalSupply = _owners.length;
        require(totalSupply + amount <= MAX_SUPPLY, "Exceeds max supply");
        require(amount < reserved, "You can not get more reserved supply");

        for(uint i; i < amount; i++)
        {
            _mint(wallet, totalSupply + i);
        }
        reserved = reserved - amount;
    }

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}