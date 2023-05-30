// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Enumerable.sol";

contract EtherealApes is ERC721Enumerable, Ownable {
    string  public              baseURI;
    
    address public              proxyRegistryAddress;
    address public              withdrawalAddress;

    bytes32 public              whitelistMerkleRoot;
    uint256 public              MAX_SUPPLY;

    uint256 public constant     MAX_PER_TX          = 6;
    uint256 public constant     RESERVES            = 440;
    uint256 public constant     priceInWei          = 0.08 ether;

    mapping(address => bool) public projectProxy;
    mapping(address => uint) public addressToMinted;

    constructor(
        string memory _baseURI, 
        address _proxyRegistryAddress, 
        address _withdrawalAddress
    )
        ERC721("Ethereal Apes", "Ethereal Apes")
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        withdrawalAddress = _withdrawalAddress;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function collectReserves() external onlyOwner {
        require(_owners.length == 0, 'Reserves already taken.');
        for(uint256 i; i < RESERVES; i++)
            _mint(_msgSender(), i);
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function togglePublicSale(uint256 _MAX_SUPPLY) external onlyOwner {
        delete whitelistMerkleRoot;
        MAX_SUPPLY = _MAX_SUPPLY;
    }


    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function getAllowance(string memory allowance, bytes32[] calldata proof) public view returns (string memory) {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(allowance, payload), proof), "Invalid Merkle Tree proof supplied.");
        return allowance;
    }

    function whitelistMint(uint256 count, uint256 allowance, bytes32[] calldata proof) public payable {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(Strings.toString(allowance), payload), proof), "Invalid Merkle Tree proof supplied.");
        require(addressToMinted[_msgSender()] + count <= allowance, "Exceeds whitelist supply"); 
        require(count * priceInWei == msg.value, "Invalid funds provided.");

        addressToMinted[_msgSender()] += count;
        uint256 totalSupply = _owners.length;
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Exceeds max supply.");
        require(count < MAX_PER_TX, "Exceeds max per transaction.");
        require(count * priceInWei == msg.value, "Invalid funds provided.");
    
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public  {
        (bool successOne, ) = payable(0x6BaCdF4e911a8dacd6450415C06bb84F2b767951).call{value: address(this).balance * 50 / 100}("");
        require(successOne, "Failed to send to first withdrawal address");

        (bool successTwo, ) = withdrawalAddress.call{value: address(this).balance}("");
        require(successTwo, "Failed to send to second withdrawal address.");
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