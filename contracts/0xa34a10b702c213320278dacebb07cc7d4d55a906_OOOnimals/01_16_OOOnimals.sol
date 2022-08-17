// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Developed By: @WurdigMich
 */
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721Enumerable.sol";


contract OOOnimals is ERC721Enumerable, ERC2981, Ownable {
    string public baseURI;
    address public simonoFromAccounting;
    uint256 public MAX_SUPPLY;
    bytes32 public whitelistMerkleRoot;
    uint256 public constant RESERVES = 2444;
    uint256 public publicMintPrice = 0.3 ether;
    uint256 public preMintPrice = 0.3 ether;
    address public proxyRegistryAddress;
    mapping(address => bool) public projectProxy;
    mapping(address => uint) public addressToMinted;


    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress,
        address _simonoFromAccounting

    ) ERC721("OOOnimals", "OOOnimals") {
        baseURI = _baseURI;
        simonoFromAccounting = _simonoFromAccounting;
        proxyRegistryAddress = _proxyRegistryAddress;
        _setDefaultRoyalty(_simonoFromAccounting, 1000);
    }

    // update/set royalty info for the collection
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    // update set base URI for the collection
    function setBaseURI(string memory _baseURI) public onlyOwner {
        
        baseURI = _baseURI;
    }

    // get the token URI for a specific tokenId of collection
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        
        require(_exists(_tokenId), "Token does not exist.");
       
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    // flip proxy address preApproval
    function flipProxyState(address proxyAddress) public onlyOwner {
        
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    // set whitelistMerkleRoot
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    // collect reserves
    function collectReserves(uint256 _amount) external onlyOwner {
        
        for (uint256 i; i < _amount; i++) _safeMint(simonoFromAccounting, i);
    }

    // collect unSold
    function collectUnsold() external onlyOwner {
        
        require(_owners.length != 0 && MAX_SUPPLY!=0, "Mint hasnt even started yet");
        
        uint256 _totalSupply = _owners.length;
        
        for (uint256 i; i < MAX_SUPPLY; i++) _safeMint(_msgSender(), _totalSupply + i);
    }
    // set mint price
    function setMintPrice(uint256 _publicMintPrice) external onlyOwner {
        
        publicMintPrice = _publicMintPrice;
    }

    // toggle public sale by modifying MAX_SUPPY
    function setMaxSupply(uint256 _MAX_SUPPLY) external onlyOwner {
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
        require(count * preMintPrice <= msg.value, "Invalid funds provided.");
        require(addressToMinted[_msgSender()]<6, "Excedes limit per wallet");
        addressToMinted[_msgSender()] += count;
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Excedes max supply.");
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    //publicMint with the _amount parameter to support nftpay
    function publicMint(uint256 _amount) public payable {
        
        require(publicMintPrice * _amount <= msg.value, "Invalid funds provided.");

        uint256 _totalSupply = _owners.length;

        require(_totalSupply + _amount < MAX_SUPPLY, "Excedes max supply.");
        require(addressToMinted[_msgSender()] < 6, "Excedes limit per wallet");

        for(uint i; i < _amount; i++) { 
            _mint(_msgSender(), _totalSupply + i);
        }
    }
    
    //mint function to support crossmint
    function crossMint(address _to, uint256 _amount) public payable {
        
        require(
            _msgSender() == 0xdAb1a1854214684acE522439684a145E62505233,
            "This function is for Crossmint only."
        );
        require(publicMintPrice * _amount == msg.value, "Invalid funds provided.");

        uint256 _totalSupply = _owners.length;

        require(_totalSupply + _amount < MAX_SUPPLY, "Excedes max supply.");
        require(addressToMinted[_msgSender()] < 6, "Excedes limit per wallet");
        for(uint i; i < _amount; i++) { 
            _mint(_to, _totalSupply + i);
        }
    }

    //burn...
    function burn(uint256 tokenId) public {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        
        _burn(tokenId);
    }

    //callable by anyone as the address is hardcoded
    function withdraw() public {
        
        (bool success, ) = simonoFromAccounting.call{value: address(this).balance}("");
        require(success, "Failed to send to Simono.");
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

    //supporting preapproval for opensea proxies and other proxies that we might add
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    //modified mint functionality to maintain an array rather than mapping
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}