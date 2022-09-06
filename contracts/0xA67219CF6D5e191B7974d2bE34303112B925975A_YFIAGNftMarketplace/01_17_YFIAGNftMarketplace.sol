//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC721.sol";
import "./interfaces/IERC20.sol";
import "./extensions/IERC721Pausable.sol";
import "./utils/Address.sol";
import "./utils/SafeMath.sol";
import "./interfaces/IYFIAGNftMarketplace.sol";
import "./interfaces/IYFIAGNftPool.sol";

contract YFIAGNftMarketplace is IYFIAGNftMarketplace, ERC721, IERC721Pausable{
    using Address for address;
    using SafeMath for uint256;

    uint256 public maxRoyalties = 2000;

    uint256 public minRoyalties = 0;

    address public platformFeeAddress;

    mapping(uint256 => bool) public tokenStatus; 

    mapping(uint256 => uint256) public prices;  

    mapping(uint256 => address) public tokenAddress;

    mapping(uint256 => uint256) public royalties; // in decimals (min 0.1%, max 100%)
    
    mapping(uint256 => address) public tokenCreators;

    mapping(address => uint256[]) public creatorsTokens;

    mapping(address => mapping(address => uint256)) public amountEarn;

    mapping(uint256 => bool) public inProcess;

    uint256 public tokenId;

    uint256 public platformFee = 200;

    address public yfiagPool;

    constructor() ERC721("YFIAG Marketplace", "YFIAGMarket") {
        tokenId = 1;
        platformFeeAddress = msg.sender;
    }

    modifier onlyEOA(){
        require(tx.origin == msg.sender, "Only EOA");
        _;
    }

    function getPlatformFee() public view returns(uint256) {
        return platformFee;
    }

    function getAddressLaunchPad() public view returns(address){
        return _launchPad;
    }

    function getBalance() public view override returns(uint256){
        address _self = address(this);
        uint256 _balance = _self.balance;
        return _balance;
    }

    function balanceOf(address _user, uint256 _tokenId) public view returns(uint256) {
        return IERC20(tokenAddress[_tokenId]).balanceOf(_user);
    }

    function getPriceInTokens(uint256 _tokenId) public view tokenNotFound(_tokenId) returns(uint256, address){
        return (prices[_tokenId], tokenAddress[_tokenId]);
    }

    function getRoyalty(uint256 _tokenId) public view returns(uint256) {
        return royalties[_tokenId];
    }

    function getMaxFragment() public view returns(uint256) {
        return MAX_FRAGMENT;
    }
    
    function getAllTokensByPage(uint256 _from, uint256 _to) public view returns(Token[] memory) {
        require(_from < _to, "From > to");

        uint256 _last = (_to > _allTokens.length) ? _allTokens.length : _to;

        Token[] memory _tokens = new Token[](_last + 1);

        uint256 _j = 0;

        for(uint256 i=_from; i<=_last; i++) {
            Token memory _token = Token({
                id:    i,
                rootId: _rootIdOf[i],
                price: prices[i],
                token: tokenAddress[i],
                owner: _owners[i],
                creator: tokenCreators[i],
                uri:   _tokenURIs[i],
                status: isForSale(i),
                isRoot: _rootTokens[i],
                isFragment: _fragmentTokens[i]
            });

            _tokens[_j++] = _token;
        }

        return _tokens;
    }

    function getTokensByUserObjs(address _user) public view returns(Token[] memory) {
        Token[] memory _tokens = new Token[](_balances[_user]);

        for(uint256 i=0; i<_tokens.length; i++) {
            if(_ownedTokens[_user][i] != 0) {
                uint256 _tokenId = _ownedTokens[_user][i];
                Token memory _token = Token({
                    id:    _tokenId,
                    rootId: _rootIdOf[_tokenId],
                    price: prices[_tokenId],
                    token: tokenAddress[_tokenId],
                    owner: _user,
                    creator: tokenCreators[_tokenId],
                    uri:   _tokenURIs[_tokenId],
                    status: isForSale(_tokenId),
                    isRoot: _rootTokens[_tokenId],
                    isFragment: _fragmentTokens[_tokenId]
                });

                _tokens[i] = _token;
            }
        }

        return _tokens;
    }

    function getTokenInfo(uint256 _tokenId) public view returns(Token memory) {
        Token memory _token = Token({
            id: _tokenId,
            rootId: _rootIdOf[_tokenId],
            price: prices[_tokenId],
            token: tokenAddress[_tokenId],
            owner: _owners[_tokenId],
            creator: tokenCreators[_tokenId],
            uri: _tokenURIs[_tokenId],
            status: isForSale(_tokenId),
            isRoot: _rootTokens[_tokenId],
            isFragment: _fragmentTokens[_tokenId]
        });

        return _token;
    }

    function getCreatorsTokens(address _creator) public view returns(uint256[] memory) {
        return creatorsTokens[_creator];
    }

    function getCreatorsTokensObj(address _creator) public view returns(Token[] memory) {
        Token[] memory _tokens = new Token[](creatorsTokens[_creator].length);

        for(uint256 i=0; i<_tokens.length; i++) {
            uint256 _tokenId = creatorsTokens[_creator][i];
            Token memory _token = Token({
                id: _tokenId,
                rootId: _rootIdOf[_tokenId],
                price: prices[_tokenId],
                token: tokenAddress[_tokenId],
                owner: _owners[_tokenId],
                creator: _creator,
                uri: _tokenURIs[_tokenId],
                status: isForSale(_tokenId),
                isRoot: _rootTokens[_tokenId],
                isFragment: _fragmentTokens[_tokenId]
            });

            _tokens[i] = _token;
        }
        
        return _tokens;
    }

    function allFragmentOf(uint256 _tokenId) public view returns(uint256[] memory){
        return _fragments[_tokenId];
    }

    function subOwners(uint256 _tokenId) public view returns(address[] memory){
        return _subOwners[_tokenId];
    }

    function getAmountEarn(address _user, address _tokenAddress) public view override returns(uint256){
        return amountEarn[_user][_tokenAddress];
    }
    
    function withdraw() external override onlyOwner() {
        payable(owner()).transfer(getBalance());
    }

    function withdraw(address _user, uint256 _amount) external override onlyOwner() {
        uint256 _balance = getBalance();
        require(_balance > 0, "Balance is null");
        require(_balance >= _amount, "Balance < amount");
        require(_user != address(0),"Bad _user");
        payable(_user).transfer(_amount);
    }

    function withdraw(address _tokenErc20, address _user) external override onlyOwner() {
        
        uint256 _totalBalance = IERC20(_tokenErc20).balanceOf(address(this));

        require(_totalBalance > 0, "balance < 0");
        require(_user != address(0),"Bad _user");
        IERC20(_tokenErc20).transfer(_user, _totalBalance);
    }

    function setPlatformFee(uint256 _newFee) public override onlyOwner() {
        require(_newFee <= 1000, "Royalty > 10%");
        platformFee = _newFee;
        emit SetNewPlatformFee(_newFee);
    }

    function setDefaultRoyalties(uint256 _min, uint256 _max) public onlyOwner(){
        minRoyalties = _min;
        maxRoyalties = _max;
        emit SetNewDefaultRoyalties(_min,_max);
    }

    function setMaxFragment(uint256 _max) public onlyOwner(){
        require(_max != MAX_FRAGMENT && _max > 0,"Bad max");
        MAX_FRAGMENT = _max;
    }
    function setPool(address pool) public onlyOwner(){
        require(pool != address(0),"Bad pool");
        require(pool.isContract(),"Not contract");
        // transfer all fund to new pool 
        if(yfiagPool != address(0)){
            IYFIAGNftPool(yfiagPool).migratePool(pool, address(0));
        }
        yfiagPool = pool;
        emit SetNewPool(pool);
    }

    function setLaunchPad(address launchPad) public onlyOwner(){
        require(launchPad != address(0),"Bad launchPad");
        require(launchPad.isContract(),"Not contract");
        _launchPad = launchPad;
        setAdmin(launchPad, true);
        emit SetNewLaunchPad(launchPad);
    }

    // Launchpad can also be an admin
    function burnByLaunchpad(address account,uint256 _tokenId) external override tokenNotFound(_tokenId) onlyLaunchpad(){
        require(_rootTokens[_tokenId], "isn`t root");
        _burn(account,_tokenId);
    }

    function burn(uint256 _tokenId) external override tokenNotFound(_tokenId) isNotRootToken(_tokenId) isNotFragments(_tokenId)  {
        require(ownerOf(_tokenId) == msg.sender, "isn`t owner of token");
        _burn(msg.sender, _tokenId);
    }

    function setDefaultAmountEarn(address _user, address _tokenAddress) external override{
        require(msg.sender == yfiagPool, "Isn`t Pool");
        amountEarn[_user][_tokenAddress] = 0;
    }

    function setPlatformFeeAddress(address newPlatformFeeAddess) external override onlyAdmin(){
        require(newPlatformFeeAddess != address(0),"Bad newPlatformFeeAddess");
        platformFeeAddress = newPlatformFeeAddess;
        emit SetNewPlatformFeeAddress(newPlatformFeeAddess);
    }

    function mint(address _to,address _token, string memory _uri, uint256 _royalty, bool _isRoot) public override onlyEOA {
        require(_token == address(0) || _token.isContract(), "Token isn`t a contract address");
        require(_royalty <= maxRoyalties && _royalty >= minRoyalties, "Royalty wrong");
        
        if(!isAdmin(msg.sender)){
            _isRoot = false;
        }
        _safeMint(_to, tokenId, 0, _uri);

        tokenAddress[tokenId] = _token;
        royalties[tokenId] = _royalty;
        tokenCreators[tokenId] = _to;
        creatorsTokens[_to].push(tokenId);
        _rootTokens[tokenId] = _isRoot;
        emit Mint(tokenId, _to, _to, _royalty, _isRoot);
        tokenId++;

        
    }

    function mintFragment(address _to,uint256 _rootTokenId) public override onlyLaunchpad(){
        require(tokenAddress[_rootTokenId] == address(0) || tokenAddress[_rootTokenId].isContract(), "Token isn`t a contract address");
        require(_rootTokens[_rootTokenId], "isn`t root");
        
            _safeMint(_to, tokenId, _rootTokenId, _tokenURIs[_rootTokenId]);

            tokenAddress[tokenId] = tokenAddress[_rootTokenId];
            royalties[tokenId] = royalties[_rootTokenId];
            tokenCreators[tokenId] = tokenCreators[_rootTokenId];
            creatorsTokens[tokenCreators[_rootTokenId]].push(tokenId);
            emit Mint(tokenId, tokenCreators[_rootTokenId], _to, royalties[_rootTokenId], false);
            tokenId++;
    }

    function setPriceAndSell(uint256 _tokenId, uint256 _price) public override tokenNotFound(_tokenId) isNotRootToken(_tokenId) {
        require(!tokenStatus[_tokenId], "token not locked");
        require(ownerOf(_tokenId) == msg.sender, "isn`t owner of token");
        prices[_tokenId] = _price;
        _resume(_tokenId);        

        emit PriceChanged(_tokenId, _price, tokenAddress[_tokenId], msg.sender);
    }

    function buy(uint256 _tokenId) public payable override tokenNotFound(_tokenId) isNotRootToken(_tokenId) onlyEOA { 
        require(tokenStatus[_tokenId], "Token not for sale");
        require(ownerOf(_tokenId) != msg.sender, "already owner of token");
        require(tokenAddress[_tokenId] == address(0), "Not native token");
       
        address _prevOwner = ownerOf(_tokenId);
        uint256 _rootId = _rootIdOf[_tokenId];
        uint256 _prevLenght = _subOwners[_rootId].length;
        uint256 _price = prices[_tokenId];
        uint256 _creatorRoyalty = 0;
        uint256 _platformFee = (_price.mul(platformFee)).div(10000);
        uint256 _subOwnerFee = 0;
        if(_fragmentTokens[_tokenId] && _fragments[_rootId].length > 1){
            _subOwnerFee = (_price.mul(royalties[_tokenId])).div(10000);
        }
        if(!_fragmentTokens[_tokenId]){
            _creatorRoyalty = (_price.mul(royalties[_tokenId])).div(10000);
        }

        // buy native
        require(prices[_tokenId] == msg.value, "Value != price!");
        bool flag;
        payable(ownerOf(_tokenId)).transfer(_price.sub(_creatorRoyalty + _platformFee + _subOwnerFee));
        if(_creatorRoyalty > 0){
            payable(tokenCreators[_tokenId]).transfer(_creatorRoyalty);
        }
        payable(platformFeeAddress).transfer(_platformFee);
        _pause(_tokenId);
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
        if(_fragmentTokens[_tokenId]){
            address _owner = ownerOf(_tokenId);
            uint256 _countBalanceOwner = balanceOfToken(_rootId, _owner);
            uint256 _countBalancePrevOwner = balanceOfToken(_rootId, _prevOwner);
            uint256 _countPerson =  0;
            if(_subOwners[_rootId].length >= _prevLenght){
                _countPerson = _subOwners[_rootId].length-1 > 0 ? _subOwners[_rootId].length-1 : 1;
            }
            if(_subOwners[_rootId].length < _prevLenght){
                if(_countBalanceOwner > 1 && _countBalancePrevOwner == 0){
                    _countPerson = _subOwners[_rootId].length-1 > 0 ? _subOwners[_rootId].length-1 : 1;
                }else{
                    _countPerson = _subOwners[_rootId].length > 0 ? _subOwners[_rootId].length : 1;
                }
            }
            uint256 _amountEarn = _subOwnerFee.div(_countPerson);
            for(uint256 i=0; i< _subOwners[_rootId].length; ++i){
                if(_subOwners[_rootId][i] != _owner){
                    address _subOwner = _subOwners[_rootId][i];
                    amountEarn[_subOwner][tokenAddress[tokenId]] += _amountEarn;
                    flag= true;
                }                                                   
            }
        }
        if(_subOwnerFee > 0 && flag){
            IYFIAGNftPool(yfiagPool).subOwnerFeeBalance{value: _subOwnerFee}();
        }
        if(_subOwnerFee > 0 && !flag){
            payable(_prevOwner).transfer(_subOwnerFee);
        } 
    }

    function pause(uint256 _tokenId) external override tokenNotFound(_tokenId){
        require(ownerOf(_tokenId) == msg.sender, "isn`t owner of token!");

        _pause(_tokenId);
    }

    function _pause(uint256 _tokenId) internal {
        tokenStatus[_tokenId] = false;

        emit Paused(_tokenId);
    }

    function resume(uint256 _tokenId) external override tokenNotFound(_tokenId){
        require(ownerOf(_tokenId) == msg.sender, "isn`t owner of token!");

        _resume(_tokenId);
    }

    function _resume(uint256 _tokenId) internal {
        tokenStatus[_tokenId] = true;

        emit Resumed(_tokenId);
    }

    function isForSale(uint256 _tokenId) public view override returns(bool) {
        return tokenStatus[_tokenId];
    }
    function isOwnerOfRoot(uint256 _tokenId,address owner) public view override returns(bool) {
        return isRootTokenOwner(_tokenId,owner);
    }
}