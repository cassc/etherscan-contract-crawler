// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract GiraffeMarketPlace{
    address public owner;
    address public marketManager;
    address payable public marketWallet;
    bool public saleOpen;
    mapping(IERC20 => bool) public acceptableCoins ;
    using Counters for Counters.Counter;
    Counters.Counter private _unlistIds;
    mapping(uint256 => unListNFT) unlistedNFTs;
    using SafeERC20 for address;
     using ECDSA for bytes32;
    constructor(){
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct unListNFT{
        IERC721 _collectionId;
        uint256 _tokenId;
        address _seller;
        uint256 _unlistTime;
    }



    function BUY(IERC721[] memory _collectionIds, uint256[] memory _tokenIds, address[] memory _sellerAddresses ,IERC20 _coinId, uint256[] memory _prices ,uint256 _totalPrice, uint256 _tax,string[] memory messages, bytes[] memory signatures) public payable {
        require(saleOpen == true,"Sale Off");
        require(acceptableCoins[_coinId] == true,"Coins are not accepted");
        require(_coinId.balanceOf(msg.sender) >= _totalPrice+_tax,"Coin balance is not enough");
        require(_coinId.allowance(msg.sender,address(this)) >= _totalPrice+_tax,"Coin allowance is not enough" );
        _coinId.transferFrom(msg.sender, marketWallet, _tax);
        for(uint i=0; i < _collectionIds.length; i++){
            address _seller = _sellerAddresses[i];
            string memory _message = messages[i];
            bytes memory _signature = signatures[i];
            address signer = _verifySignature(_message,_signature);
            require(_seller == signer,"You are not signer");
            IERC721 _collectionId = _collectionIds[i];
            uint256 _tokenId = _tokenIds[i];
            uint256 _price = _prices[i];
            _coinId.transferFrom(msg.sender, _seller, _price);
            _collectionId.safeTransferFrom(_seller, msg.sender, _tokenId);
        }
    }

    function changeAcceptableCoin(IERC20 _coin, bool _accept) public onlyOwner{
        acceptableCoins[_coin] = _accept;
    }

    //TRANSFER
    function transferNFT(IERC721 _collectionId, address _to, uint256 _tokenId) public {
        require(_collectionId.ownerOf(_tokenId) == msg.sender,"You are not the owner");
        _collectionId.safeTransferFrom(msg.sender, _to, _tokenId);
    }

    function unlistNFT(IERC721 _collectionId, uint256 _tokenId) public {
        require(_collectionId.ownerOf(_tokenId) == msg.sender,"You are not the owner");
        _unlistIds.increment();
        uint256 unlistId = _unlistIds.current();
        uint256 _time = block.timestamp;
        unlistedNFTs[unlistId] = unListNFT(_collectionId, _tokenId, msg.sender, _time);
    }

    function toggleSale(bool _saleOpen) public onlyOwner{
             saleOpen = _saleOpen;
    }
    function changeOwner(address _newOwner) public onlyOwner{
             owner = payable(_newOwner);
    }
    
    function changeMarketWallet(address _newMarketWallet) public onlyOwner{
             marketWallet = payable(_newMarketWallet);
    }

    function changeMarketManager(address _newMarketManager) public onlyOwner{
             marketManager = payable(_newMarketManager);
    }
   

    function _verifySignature(string memory message, bytes memory signature)  internal pure  returns (address) {
       bytes32 messagehash =  keccak256(bytes(message));
        return address(messagehash.toEthSignedMessageHash().recover(signature));
    }
  
}