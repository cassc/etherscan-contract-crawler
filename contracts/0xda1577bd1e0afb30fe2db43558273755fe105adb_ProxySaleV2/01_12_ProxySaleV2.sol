pragma solidity ^0.8.4;
/***
 *    ███╗   ███╗███████╗████████╗ █████╗ ██████╗ ██╗   ██╗███████╗
 *    ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║   ██║██╔════╝
 *    ██╔████╔██║█████╗     ██║   ███████║██████╔╝██║   ██║███████╗
 *    ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██╔══██╗██║   ██║╚════██║
 *    ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██████╔╝╚██████╔╝███████║
 *    ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝
 *
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interface/IMetaBus.sol";
import "./interface/IProxySale.sol";

contract ProxySaleV2 is Ownable, ReentrancyGuard, IProxySale {
    using ECDSA for bytes32;
    event Stake(address indexed owner, uint256 indexed tokenId, uint256 indexed timestamp);
    event UnStake(address indexed owner, uint256 indexed tokenId, uint256 indexed timestamp);

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    struct StakeInfo {
        uint256 tokenId;
        uint256 stakeType;
        uint stakeTimestamp;
    }

    Status public status;

    address public proxyAddress;
    IMetaBus private metaBus;
    IERC721Enumerable private erc721;

    uint256 public maxPreNumberMinted = 1;

    uint256 public whiteListMintPrice = 1.58 ether;

    uint256 public publicMintPrice = 1.88 ether;

    mapping(uint256 => StakeInfo) public stakeList;

    mapping(string => address) public verifiedList;

    bytes32 public root;
    mapping(string => address) private signerList;
    address private vault;

    mapping(address => uint256) public preNumberMinted;

    mapping(address => uint256) public publicNumberMinted;

    uint256 public MaxSupply;

    modifier eoaOnly() {
        require(tx.origin == msg.sender, "EOA Only");
        _;
    }

    constructor(address _signerMint, address _signerUnStake, address _vault) public {
        signerList["mint"] = _signerMint;
        signerList["unStake"] = _signerUnStake;
        vault = _vault;
        MaxSupply = 577;
    }

    function isStake(uint256 _tokenId) external view override returns (bool){
        return stakeList[_tokenId].stakeTimestamp > 0;
    }

    function _whitelistVerify(bytes32[] memory _proof)
    internal
    view
    returns (bool)
    {
        return
        MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
        );
    }

    function _hash(string calldata _salt, address _address) internal view returns (bytes32)
    {
        return keccak256(abi.encode(_salt, address(this), _address));
    }

    function _verify(address _signer, bytes32 _hash, bytes memory _token) internal view returns (bool)
    {
        return _signer == _recover(_hash, _token);
    }

    function _recover(bytes32 _hash, bytes memory _token) internal pure returns (address)
    {
        return _hash.toEthSignedMessageHash().recover(_token);
    }

    function makeChange(uint256 _price) private {
        require(msg.value >= _price, "Insufficient ether amount");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    function _preMint(bytes32[] memory _proof) internal{
        require(status == Status.PreSale, "WhiteList not avalible for now");

        require(_whitelistVerify(_proof), "Invalid merkle proof");

        require(MaxSupply - erc721.totalSupply() >= 1, "Max supply reached");

        require(preNumberMinted[msg.sender] < maxPreNumberMinted, "Minting more than the max supply for a single address");

        metaBus.mint(msg.sender);

        makeChange(whiteListMintPrice);

        preNumberMinted[msg.sender] = preNumberMinted[msg.sender] + 1;
    }

    function preMintOfStake(bytes32[] memory _proof, uint256 _stakeType)
    external
    payable
    nonReentrant
    eoaOnly
    {
        _preMint(_proof);
        uint256 _tokenId = erc721.totalSupply() - 1;
        _stake(_tokenId, _stakeType);
    }

    function _publicMint(string calldata _salt, bytes calldata _signature) internal
    {
        require(status == Status.PublicSale, "PublicSale not avalible for now");

        require(_verify(signerList["mint"], _hash(_salt, msg.sender), _signature), "Invalid signature");

        require(MaxSupply - erc721.totalSupply() >= 1, "Max supply reached");

        require(publicNumberMinted[msg.sender] == 0, "Minting more than the max supply for a single address");

        metaBus.mint(msg.sender);

        makeChange(publicMintPrice);

        verifiedList[_salt] = msg.sender;

        publicNumberMinted[msg.sender] = publicNumberMinted[msg.sender] + 1;
    }

    function publicMint(string calldata _salt, bytes calldata _signature)
    public
    payable
    nonReentrant
    eoaOnly
    {
        _publicMint(_salt, _signature);
    }

    function publicMintOfStake(string calldata _salt, bytes calldata _signature, uint256 _stakeType)
    external
    payable
    nonReentrant
    eoaOnly
    {
        _publicMint(_salt, _signature);
        uint256 _tokenId = erc721.totalSupply() - 1;
        _stake(_tokenId, _stakeType);
    }

    function _stake(uint256 _tokenId, uint256 _stakeType) internal {
        require(!(stakeList[_tokenId].stakeTimestamp > 0), "Token already staked");

        require(erc721.ownerOf(_tokenId) == msg.sender, "Only owner can stake");

        require(_stakeType >= 0 && _stakeType < 4, "Stake type is error");

        stakeList[_tokenId] = StakeInfo(_tokenId, _stakeType, block.timestamp);

        emit Stake(msg.sender, _tokenId, stakeList[_tokenId].stakeTimestamp);
    }


    function stake(uint256 _tokenId, uint256 _stakeType) public nonReentrant eoaOnly {
        _stake(_tokenId, _stakeType);
    }

    function unStake(string calldata _salt, bytes calldata _signature,  uint256 _tokenId) public nonReentrant eoaOnly{
        require(stakeList[_tokenId].stakeTimestamp > 0, "Token not staked");

        require(erc721.ownerOf(_tokenId) == msg.sender, "Only owner can unstake");

        require(verifiedList[_salt] != msg.sender, "Already verified");

        require(_verify(signerList["unStake"], _hash(_salt, msg.sender), _signature), "Invalid signature");

        delete stakeList[_tokenId];

        verifiedList[_salt] = msg.sender;

        emit UnStake(msg.sender, _tokenId, block.timestamp);
    }

    function setProxyAddress(address _proxyAddress) public onlyOwner{
        proxyAddress = _proxyAddress;
        metaBus = IMetaBus(proxyAddress);
        erc721 = IERC721Enumerable(proxyAddress);
    }

    function setStatus(Status _status) public onlyOwner {
        status = _status;
    }

    function setRoot(bytes32 _root) public onlyOwner{
        root = _root;
    }

    function setSigner(string memory _key, address _signer) public onlyOwner{
        signerList[_key] = _signer;
    }

    function delSigner(string memory _key) public onlyOwner{
        delete signerList[_key];
    }

    function setVault(address _vault) public onlyOwner{
        vault = _vault;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) public onlyOwner{
        publicMintPrice = _publicMintPrice;
    }

    function setWhiteListMintPrice(uint256 _whiteListMintPrice) public onlyOwner{
        whiteListMintPrice = _whiteListMintPrice;
    }

    function setMaxPreNumberMinted(uint256 _maxPreNumberMinted) public onlyOwner{
        maxPreNumberMinted = _maxPreNumberMinted;
    }

    function addStakeRecord(uint256[] memory tokenIds) public onlyOwner{
        for(uint256 i = 0; i < tokenIds.length; i++){
            stakeList[tokenIds[i]] = StakeInfo(tokenIds[i], 0, block.timestamp);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(vault).transfer(balance);
    }
}