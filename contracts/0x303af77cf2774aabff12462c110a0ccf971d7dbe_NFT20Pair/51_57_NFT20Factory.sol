pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./NFT20Pair.sol";
import "../interfaces/INFT20Pair.sol";

contract NFT20Factory is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // keep track of nft address to pair address
    mapping(address => address) public nftToToken;
    mapping(uint256 => address) public indexToNft;

    uint256 public counter;
    uint256 public fee;

    event pairCreated(
        address indexed originalNFT,
        address newPair,
        uint256 _type
    );

    constructor() public {}

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
        fee = 5;
    }

    function nft20Pair(
        string calldata name,
        address _nftOrigin,
        uint256 _nftType
    ) external {
        // if pair exists then throw.
        require(
            nftToToken[_nftOrigin] == address(0),
            "A token for this NFT already exists"
        );

        NFT20Pair _nft20pair = new NFT20Pair();

        _nft20pair.init(
            string(abi.encodePacked("NFT20 ", name)),
            string(abi.encodePacked(name, "20")),
            _nftOrigin,
            _nftType
        );
        nftToToken[_nftOrigin] = address(_nft20pair);
        indexToNft[counter] = _nftOrigin;
        counter = counter + 1;
        emit pairCreated(_nftOrigin, address(_nft20pair), _nftType);
    }

    function getPairByNftAddress(uint256 index)
        public
        view
        returns (
            address _nft20pair,
            address _originalNft,
            uint256 _type,
            string memory _name,
            string memory _symbol,
            uint256 _supply
        )
    {
        _originalNft = indexToNft[index];
        _nft20pair = nftToToken[_originalNft];
        (_type, _name, _symbol, _supply) = INFT20Pair(_nft20pair).getInfos();
    }

    // this is to sset value in case we decided to change tokens given to a tokenizing project.
    function setValue(
        address _pair,
        uint256 _nftType,
        string calldata _name,
        string calldata _symbol
    ) external onlyOwner {
        INFT20Pair(_pair).setParams(_nftType, _name, _symbol);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}