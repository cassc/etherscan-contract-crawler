// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./FreeFromNFT.sol";
import "./Signature.sol";

contract FreeFromFactory is OwnableUpgradeable, Signature{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Donate(address from, address to, uint256 toTokenId, address token, uint256 amount);
    event DonateNFT(address from, address to, uint256 toTokenId, address token, uint256 tokenId);
    event Create(address user, address nftAddress);
    event MintMessage(address nft, uint256 tokenId);
    event BurnMessage(address nft, uint256 tokenId);

    //        NFT   =>   user
    mapping(address => address) public ownerOf;
    //        user  =>   nft
    mapping(address => address) public nfts;
    address public vault;
    uint256 public taxRate;
    //        nft
    mapping(address => bool) public mintByFactory;

    function initialize(address _vault) public initializer {
        OwnableUpgradeable.__Ownable_init();
        vault = _vault;
        taxRate = 100;  //100/10000 = 1%
    }

    function changeTaxRate(uint256 _newRate) public onlyOwner {
      taxRate = _newRate;
    }

    function changeVault(address _newVault) public onlyOwner {
      vault = _newVault;
    }

    function _create(
        address _user,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) internal {
      bytes32 salt = keccak256(abi.encodePacked(_symbol, _user, address(this)));
      FreeFromNFT ffn = new FreeFromNFT{salt: salt}(address(this), _name, _symbol, _baseURI);
      address ffnAddr = address(ffn);
      require(ownerOf[ffnAddr] == address(0), "already created");
      ownerOf[ffnAddr] = _user;
      nfts[_user] = ffnAddr;
      mintByFactory[ffnAddr] = true;
      emit Create(_user, ffnAddr);
    }

    function factoryCreate(address _user, 
                          string memory _name, 
                          string memory _symbol, 
                          string memory _baseURI
                          ) public onlyOwner {
      _create(_user, _name, _symbol, _baseURI);
    }

    function userCreate(string memory _name, string memory _symbol, string memory _baseURI) public {
      _create(msg.sender, _name, _symbol, _baseURI);
    }

    function nftOwnerOf(address _nft, uint256 _tokenId) public view returns (address) {
      require(ownerOf[_nft] != address(0), "nft not exist");
      return IERC721Upgradeable(_nft).ownerOf(_tokenId);
    }

    function setFactoryMint(bool _flag) public {
      mintByFactory[nfts[msg.sender]] = _flag;
    }

    function mintMessageByFactory(address _nft, string memory _cid, bytes memory _signature) public onlyOwner {
      address user = ownerOf[_nft];
      require(user != address(0), "nft not exist");
      require(mintByFactory[_nft], "can't mint by factory");
      uint256 tokenId = FreeFromNFT(_nft).mint(user, _cid);
      //verify signature
      bytes32 message = prefixed(keccak256(abi.encodePacked(
            address(this),
            user, 
            _nft,
            tokenId,
            _cid
        )));
      require(verifySignature(message, _signature, user), "verification failed");
      emit MintMessage(_nft, tokenId);
    }

    function mintMessageByUser(string memory _cid) public {
      address nft = nfts[msg.sender];
      require(nft != address(0), "no nft");
      uint256 tokenId = FreeFromNFT(nft).mint(msg.sender, _cid);
      emit MintMessage(nft, tokenId);
    }

    function burnMessage(address _nft, uint256 _tokenId) public {
      FreeFromNFT ffn = FreeFromNFT(_nft);
      require(ffn.ownerOf(_tokenId) == msg.sender, "not owner");
      ffn.burn(_tokenId);
      emit BurnMessage(_nft, _tokenId);
    } 

    //collect tax when donate
    function donate(address _to, uint256 _toTokenId, address _token, uint256 _amount)payable public {
      require(_amount > 0 , "donate 0");
      address owner = nftOwnerOf(_to, _toTokenId);
      uint256 tax = _amount * taxRate / 10000;
      uint256 remain = _amount - tax;
      if(_token == address(0)){
        require(msg.value == _amount, "value error");
        payable(vault).transfer(tax);
        payable(owner).transfer(remain);
      }else{
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, vault, tax);
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, owner, remain);
      }
      emit Donate(msg.sender, _to, _toTokenId, _token, _amount);
    }

    function donateNFT(address _to, uint256 _toTokenId, address _token, uint256[] memory _tokenIds) public {
      address owner = nftOwnerOf(_to, _toTokenId);
      for(uint256 i=0; i<_tokenIds.length; i++){
        IERC721Upgradeable(_token).safeTransferFrom(msg.sender, owner, _tokenIds[i]);
        emit DonateNFT(msg.sender, _to, _toTokenId, _token, _tokenIds[i]);
      }
      
    }
}