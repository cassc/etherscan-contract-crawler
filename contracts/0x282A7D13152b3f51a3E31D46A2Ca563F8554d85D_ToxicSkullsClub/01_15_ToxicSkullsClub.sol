// SPDX-License-Identifier: MIT
// Author: Pagzi Tech Inc. | 2022
// Toxic Skulls Club - TSC | 2022
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract ToxicSkullsClub is ERC721Enumerable, Ownable, ReentrancyGuard {
    //allowlist settings    
    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;

    //sale settings
    uint256 public cost = 0.08 ether;
    uint256 public costPre = 0.07 ether;
    uint256 public maxSupply = 9999;
    uint256 public maxMint = 10;
    uint256 public maxMintPre = 2;
    bool public paused = false;

    //backend settings
    string public baseURI;
    address internal immutable founders = 0x1ff63DF1077a40ec7A4f5a85a07eA7aC773EF368;
    address internal immutable pagzidev = 0xeBaBB8C951F5c3b17b416A3D840C52CcaB728c19;
    address internal immutable partner = 0x9C3EDD974552898350bbD3425608CE03cDE2426a;
    mapping(address => bool) public projectProxy;

    //date variables
    uint256 public publicDate = 1649966400;
    uint256 public preDate = 1649955600;

    //mint passes/claims
    mapping(address => uint256) public mintPasses;
    address public proxyAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    modifier checkLimit(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMint, "Invalid mint amount!");
        require(_owners.length + _mintAmount < maxSupply + 1, "Max supply exceeded!");
        _;
    }
    
    modifier checkDate() {
        require(!paused, "Public sale is paused!");
        require((publicDate <= block.timestamp),"Public sale is not yet!");
        _;
    }
    modifier checkPreDate() {
        require(!paused, "Pre sale is paused!");
        require((preDate <= block.timestamp),"Presale is not yet!");
        _;
    }

    modifier checkPrice(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }
    modifier checPrePrice(uint256 _mintAmount) {
        require(msg.value >= costPre * _mintAmount, "Insufficient funds!");
        _;
    }

    constructor() ERC721("Toxic Skulls Club", "TSC") {
        baseURI = "https://tsc.nftapi.art/meta/";
    }

    // external
    function mint(uint256 count) external payable checkLimit(count) checkPrice(count) checkDate {
        uint256 totalSupply = _owners.length;
        for(uint i; i < count; i++) { 
            _mint(msg.sender, totalSupply + i + 1);
        }
    }
    
    function mintPass(uint256 count) external payable checkLimit(count) checPrePrice(count) checkPreDate {
        uint256 totalSupply = _owners.length;
        uint256 reserve = mintPasses[msg.sender];
        require(reserve > 0, "Low reserve!");
        for (uint256 i = 0; i < count; ++i) {
            _mint(msg.sender, totalSupply + i + 1);
        }
        mintPasses[msg.sender] = reserve - count;
        delete totalSupply;
        delete reserve;
    }

    function mintPre(uint256 count, bytes32[] calldata _merkleProof) external payable checkLimit(count) checPrePrice(count) checkPreDate {
        // Verify allowlist requirements
        require((claimed[msg.sender] + count) < (maxMintPre + 1), "Address has no allowance!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid merkle proof!");
        uint256 totalSupply = _owners.length;
        for(uint i; i < count; i++) { 
            _mint(msg.sender, totalSupply + i + 1);
        }
        claimed[msg.sender] = claimed[msg.sender] + count;
        delete totalSupply;
        delete leaf;
    }
    //only owner
    function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
    require(quantity.length == recipient.length, "Provide quantities and recipients" );
    uint totalQuantity;
    uint256 totalSupply = _owners.length;
    for(uint i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
    }
    require(totalSupply + totalQuantity + 1 <= maxSupply, "Not enough supply!" );
        for(uint i = 0; i < recipient.length; ++i){
        for(uint j = 0; j < quantity[i]; ++j){
            _mint(recipient[i], totalSupply + 1);
            totalSupply++;
        }
        }
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }
    function setCostPre(uint256 _costPre) external onlyOwner {
        costPre = _costPre;
    }
    function setPublicDate(uint256 _publicDate) external onlyOwner {
        publicDate = _publicDate;
    }
    function setPreDate(uint256 _preDate) external onlyOwner {
        preDate = _preDate;
    }
    function setDates(uint256 _publicDate, uint256 _preDate) external onlyOwner {
        publicDate = _publicDate;
        preDate = _preDate;
    }
    function setMintPass(address _address,uint256 _quantity) external onlyOwner {
        mintPasses[_address] = _quantity;
    }
    function setMintPasses(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        for(uint256 i; i < _addresses.length; i++){
        mintPasses[_addresses[i]] = _amounts[i];
        }
    }
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
    function switchProxy(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }
    function setProxy(address _proxyAddress) external onlyOwner {
        proxyAddress = _proxyAddress;
    }
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
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
    function isApprovedForAll(address _owner, address operator) public view override(IERC721,ERC721) returns (bool) {
        //Free listing on OpenSea by granting access to their proxy wallet. This can be removed in case of a breach on OS.
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(pagzidev).transfer((balance * 200) / 1000);
        payable(founders).transfer((balance * 720) / 1000);
        payable(partner).transfer((balance * 80) / 1000);
    }
}
contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}