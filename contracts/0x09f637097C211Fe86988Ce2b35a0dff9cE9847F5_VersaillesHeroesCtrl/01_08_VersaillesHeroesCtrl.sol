// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ECDSA.sol";
import "SafeMath.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";


interface NFT {
    function mint(address to, uint256 boxId, uint256 boxCategory, uint256 quantity, bytes32 randomHash) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
}


interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract VersaillesHeroesCtrl is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeMath for uint256;


    event HeroTrade(bytes32 orderHash, address seller, address buyer, uint256 tokenId, address paymentToken, uint256 price, uint256 fee);
    event CancelHeroOrder(bytes32 orderHash, address seller, uint256 tokenId);

    event WeaponTrade(bytes32 orderHash, address seller, address buyer, uint256 tokenId, address paymentToken, uint256 price, uint256 fee);
    event CancelWeaponOrder(bytes32 orderHash, address seller, uint256 tokenId);

    event HeroUpgrade(uint256 tokenId, uint256 heroRarity, uint256 round);

    event DepositMOH(address sender, uint256 amount);
    event WithdrawMOH(bytes32 withdrawHash, address sender, uint256 amount);

    event DepositVRH(address sender, uint256 amount);
    event WithdrawVRH(bytes32 withdrawHash, address sender, uint256 amount);


    mapping(bytes32 => bool) public hashHistory;

    struct PriceInfo {
        address paymentToken;
        uint256 price;
    }
    mapping(uint256 => PriceInfo) public heroFloorPrice;
    mapping(uint256 => PriceInfo) public weaponFloorPrice;
    mapping(uint256 => PriceInfo) public upgradeFloorPrice;

    address public signer;
    address public fundAddress;

    address public heroAddress;
    address public weaponAddress;
    address public mohAddress;
    address public vrhAddress;

    constructor(address _signer, address _fundAddress, address _heroAddress, address _weaponAddress, address _mohAddress, address _vrhAddress){
        signer = _signer;
        fundAddress = _fundAddress;
        heroAddress = _heroAddress;
        weaponAddress = _weaponAddress;
        mohAddress = _mohAddress;
        vrhAddress = _vrhAddress;
    }



    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }


    function setHeroPrice(uint256 _boxId, address _paymentToken, uint256 _price) external onlyOwner {
        heroFloorPrice[_boxId] = PriceInfo(_paymentToken, _price);
    }
    function setWeaponPrice(uint256 _boxId, address _paymentToken, uint256 _price) external onlyOwner {
        weaponFloorPrice[_boxId] = PriceInfo(_paymentToken, _price);
    }
    function setUpgradePrice(uint256 _heroRarity, address _paymentToken, uint256 _price) external onlyOwner {
        upgradeFloorPrice[_heroRarity] = PriceInfo(_paymentToken, _price);
    }



    function checkSigner(bytes32 _hash, bytes memory _rsv, address _signer) internal {
        require(!hashHistory[_hash], "hash exist");
        hashHistory[_hash] = true;
        address signerTemp = _hash.toEthSignedMessageHash().recover(_rsv);
        require(signerTemp == _signer, "signer not match");
    }


    function claimFreeHero(uint256 _heroBoxId, uint256 _heroBoxCategory, bytes memory _rsv, bytes32 _randomHash)
        external nonReentrant whenNotPaused{

        bytes32 hash = keccak256(abi.encode("claimFreeHero", address(this), msg.sender, _heroBoxId, _heroBoxCategory));
        checkSigner(hash, _rsv, signer);

        NFT(heroAddress).mint(msg.sender, _heroBoxId, _heroBoxCategory, 1, _randomHash);

    }


    function charge(address _paymentToken, uint256 _amount) internal{
        if(_paymentToken == address(0)){
            require(msg.value == _amount, "value error");

            payable(fundAddress).transfer(msg.value);
        }else{
            require(IERC20(_paymentToken).transferFrom(msg.sender, fundAddress, _amount));
        }
    }

    function purchaseHero(uint256 _heroBoxId, uint256 _heroBoxCategory, address _paymentToken, uint256 _price,
        uint256 _quantity, bytes32 _randomHash, bytes memory _rsv) external payable nonReentrant whenNotPaused{

        require(_price > 0, "price invalid");
        require(_quantity > 0, "quantity invalid");

        //check price
        PriceInfo memory priceInfo = heroFloorPrice[_heroBoxId];
        if(priceInfo.price > 0){
            require(_paymentToken == priceInfo.paymentToken &&  _price >= priceInfo.price, "payment invalid");
        }

        bytes32 hash = keccak256(abi.encode("purchaseHero", address(this), msg.sender, _heroBoxId, _heroBoxCategory, _paymentToken, _price, _quantity, _randomHash));
        checkSigner(hash, _rsv, signer);

        uint256 amount = _price.mul(_quantity);
        charge(_paymentToken, amount);

        NFT(heroAddress).mint(msg.sender, _heroBoxId,  _heroBoxCategory, _quantity, _randomHash);

    }

    function purchaseWeapon(uint256 _weaponBoxId, uint256 _weaponBoxCategory, address _paymentToken, uint256 _price,
        uint256 _quantity, bytes32 _randomHash, bytes memory _rsv) external payable nonReentrant whenNotPaused{

        require(_price > 0, "price invalid");
        require(_quantity > 0, "quantity invalid");

        //check price
        PriceInfo memory priceInfo = weaponFloorPrice[_weaponBoxId];
        if(priceInfo.price > 0){
            require(_paymentToken == priceInfo.paymentToken &&  _price >= priceInfo.price, "payment invalid");
        }

        bytes32 hash = keccak256(abi.encode("purchaseWeapon", address(this), msg.sender, _weaponBoxId, _weaponBoxCategory, _paymentToken, _price, _quantity, _randomHash));
        checkSigner(hash, _rsv, signer);

        uint256 amount = _price.mul(_quantity);
        charge(_paymentToken, amount);

        NFT(weaponAddress).mint(msg.sender, _weaponBoxId,  _weaponBoxCategory, _quantity, _randomHash);

    }

    function upgradeHero(uint256 _tokenId, uint256 _heroRarity, address _paymentToken, uint256 _price, uint256 _round, bytes memory _rsv)
        external payable nonReentrant whenNotPaused{

        require(_price > 0, "price invalid");

        //check price
        PriceInfo memory priceInfo = upgradeFloorPrice[_heroRarity];
        if(priceInfo.price > 0){
            require(_paymentToken == priceInfo.paymentToken &&  _price >= priceInfo.price, "payment invalid");
        }

        bytes32 hash = keccak256(abi.encode("upgradeHero", address(this), msg.sender, _tokenId, _heroRarity, _paymentToken, _price, _round));
        checkSigner(hash, _rsv, signer);

        charge(_paymentToken, _price);

        emit HeroUpgrade(_tokenId, _heroRarity, _round);

    }

    function withdrawMOH(uint256 _amount, bytes32 _salt, bytes memory _rsv) external nonReentrant whenNotPaused{

        require(_amount > 0, "amount invalid");

        bytes32 hash = keccak256(abi.encode("withdrawMOH", address(this), msg.sender, _amount, _salt));
        checkSigner(hash, _rsv, signer);

        IERC20(mohAddress).transferFrom(fundAddress, msg.sender, _amount);

        emit WithdrawMOH(hash, msg.sender, _amount);
    }


    function withdrawVRH(uint256 _amount, bytes32 _salt, bytes memory _rsv) external nonReentrant whenNotPaused{

        require(_amount > 0, "amount invalid");

        bytes32 hash = keccak256(abi.encode("withdrawVRH", address(this), msg.sender, _amount, _salt));
        checkSigner(hash, _rsv, signer);

        IERC20(vrhAddress).transferFrom(fundAddress, msg.sender, _amount);

        emit WithdrawVRH(hash, msg.sender, _amount);
    }



    function depositMOH(uint256 _amount) external nonReentrant whenNotPaused{
        require(_amount > 0, "amount invalid");

        require(IERC20(mohAddress).transferFrom(msg.sender, fundAddress, _amount));

        emit DepositMOH(msg.sender, _amount);
    }

    function depositVRH(uint256 _amount) external nonReentrant whenNotPaused{
        require(_amount > 0, "amount invalid");

        require(IERC20(vrhAddress).transferFrom(msg.sender, fundAddress, _amount));

        emit DepositVRH(msg.sender, _amount);
    }





    function hashOrder(address _nftToken, uint256 _tokenId, address _paymentToken,uint256 _price,uint256 _fee,
        address _seller, uint256 _listingTime, uint256 _expirationTime)  public view returns(bytes32){

        return keccak256(abi.encode(address(this), _nftToken, _tokenId, _paymentToken, _price, _fee, _seller, _listingTime, _expirationTime));
    }

    function buy(address _nftToken, uint256 _tokenId, address _paymentToken, uint256 _price,uint256 _fee,
        address _seller, uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) internal returns(bytes32){

        require(_expirationTime >= block.timestamp, "order expired");
        require(_fee > 0 && _fee < _price, "fee invalid");
        require(_seller != msg.sender, "buy self" );

        bytes32 hash = hashOrder(_nftToken, _tokenId, _paymentToken, _price, _fee, _seller, _listingTime, _expirationTime);
        checkSigner(hash, _rsv, _seller);


        //transfer price & fee
        if(_paymentToken == address(0)){
            require(msg.value == _price, "price error");

            payable(fundAddress).transfer(_fee);
            payable(_seller).transfer(_price.sub(_fee));
        }else{
            require(IERC20(_paymentToken).transferFrom(msg.sender, fundAddress, _price));
            require(IERC20(_paymentToken).transferFrom(fundAddress, _seller, _price.sub(_fee)));
        }

        //transfer nft
        NFT(_nftToken).transferFrom(_seller, msg.sender, _tokenId);

        return hash;
    }


    function cancelSellOrder(address _nftToken, uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) internal returns(bytes32) {

        bytes32 hash = hashOrder(_nftToken, _tokenId, _paymentToken, _price, _fee, msg.sender, _listingTime, _expirationTime);
        checkSigner(hash, _rsv, msg.sender);

        return hash;
    }



    function buyHero(uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,address _seller,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) external payable nonReentrant whenNotPaused{

        bytes32 hash = buy(heroAddress, _tokenId, _paymentToken, _price, _fee, _seller, _listingTime, _expirationTime, _rsv);

        emit HeroTrade(hash, _seller, msg.sender, _tokenId, _paymentToken, _price, _fee);
    }


    function cancelSellHero(uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) external whenNotPaused{

        bytes32 hash = cancelSellOrder(heroAddress, _tokenId, _paymentToken, _price, _fee, _listingTime, _expirationTime, _rsv);

        emit CancelHeroOrder(hash, msg.sender, _tokenId);
    }




    function buyWeapon(uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,address _seller,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) external payable nonReentrant whenNotPaused{

        bytes32 hash = buy(weaponAddress, _tokenId, _paymentToken, _price, _fee, _seller, _listingTime, _expirationTime, _rsv);

        emit WeaponTrade(hash, _seller, msg.sender, _tokenId, _paymentToken, _price, _fee);
    }


    function cancelSellWeapon(uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) external whenNotPaused{

        bytes32 hash = cancelSellOrder(weaponAddress, _tokenId, _paymentToken, _price, _fee, _listingTime, _expirationTime, _rsv);

        emit CancelWeaponOrder(hash, msg.sender, _tokenId);
    }
}