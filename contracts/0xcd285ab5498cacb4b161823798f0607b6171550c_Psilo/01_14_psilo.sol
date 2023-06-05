// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Enumerable.sol";

contract Psilo is ERC721Enumerable, Ownable {
    string  public              baseURI;
    
    address public              proxyRegistryAddress;
    address public              teamAddress;

    bytes32 public              mintlistMerkleRoot; //supplied to start the presale
    uint256 public              MAX_SUPPLY; //set to start the public sale

    uint256 public constant     MAX_PER_TX          = 11; // < used in comparison
    uint256 public constant     MAX_PER_WALLET      = 11; // < used in comparison  
    uint256 public constant     RESERVES            = 588; //Team mint amount
    uint256 public constant     priceInWei          = 0.08 ether;

    address public CrossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;

    mapping(address => bool) public projectProxy; 
    mapping(address => uint) public addressToMinted;

    constructor(
        string memory _baseURI, 
        address _proxyRegistryAddress, 
        address _teamAddress
    )
        ERC721("Psilo", "Psilo")
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        teamAddress = _teamAddress;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        //Rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
        //Mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
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

    function setMintlistMerkleRoot(bytes32 _mintlistMerkleRoot) external onlyOwner {
        mintlistMerkleRoot = _mintlistMerkleRoot;
    }

    function togglePublicSale(uint256 _MAX_SUPPLY) external onlyOwner {
        delete mintlistMerkleRoot;
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof, bytes32 merkleRoot) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function getAllowance(string memory allowance, bytes32[] calldata proof) public view returns (string memory) {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(allowance, payload), proof, mintlistMerkleRoot), "Invalid Merkle Tree proof supplied.");
        return allowance;
    }

    function mintTo(address to, uint _count) external payable {
        require(_count < MAX_PER_TX, "Can't mint more than the max mint.");

        uint256 totalSupply = _owners.length;
        require(totalSupply + _count < MAX_SUPPLY, "Exceeds max supply.");
        require(msg.sender == CrossmintAddress, "This function is for Crossmint only.");
        require(_count * priceInWei == msg.value, "Invalid funds provided.");
        for(uint i; i < _count; i++) {
            _mint(to, totalSupply + i);
        }
    }

    function mintlistMint(uint256 count, uint256 allowance, bytes32[] calldata proof) public payable {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(Strings.toString(allowance), payload), proof, mintlistMerkleRoot), "Invalid Merkle Tree proof supplied.");
        require(addressToMinted[_msgSender()] + count <= allowance, "Exceeds mintlist supply"); 
        require(count * priceInWei == msg.value, "Invalid funds provided.");

        addressToMinted[_msgSender()] += count;
        uint256 totalSupply = _owners.length;
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function publicMint(uint256 count) public payable {
        require(tx.origin == msg.sender);
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Exceeds max supply."); 
        require(addressToMinted[_msgSender()] + count < MAX_PER_WALLET, "Exceeds max wallet.");
        addressToMinted[_msgSender()] += count;
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
        (bool success, ) = teamAddress.call{value: address(this).balance}("");
        require(success, "Failed to send to Team.");
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