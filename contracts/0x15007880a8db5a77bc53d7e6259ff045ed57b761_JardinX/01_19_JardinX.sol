// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./Administration.sol";

contract JardinX is Initializable, Administration, ERC1155Upgradeable, ReentrancyGuardUpgradeable
{
    // libraries
    using SafeMathUpgradeable for uint256;

    // variables
    uint256 internal _cid;
    uint256 internal _txFee;
    uint256 internal _txRate;
    uint256 internal _pause;  
    uint256 internal TOKEN_VALUE;
    uint256[] internal _collectionList;
    uint256[50] internal __gap;
    

    function initialize() public initializer {
        __ERC1155_init("https://jardinx.platform/api/v1/collection/{id}.json");
        __Ownable_init();
        _txFee = 10**13;
        _txRate = 5;
        _cid = 1;
        TOKEN_VALUE = 10**18;
    }
    
    // structs
    struct Collections {
        uint256 cid;
        string currencyName; // ft name
        uint256 totalStaked; // num of nft in stake
        uint256 totalToken; // num of ft distributed
    }
    struct Stake {
        address owner;
    }

    // mappings
    mapping(ERC721Upgradeable => Collections) internal collections;
    mapping(ERC721Upgradeable => mapping(uint256 => Stake)) internal vault;

    // events
    event NFTStaked(address indexed owner, address indexed nft, uint256[] tokenIds);
    event NFTUnstaked(address indexed owner, address indexed nft, uint256 tokenIds);
    event TokenDeposited(address indexed to, uint256 amount);
    event TokenWithdrawn(address indexed from, uint256 amount);
    event CollectionAdded(address indexed owner, address indexed nft, uint256 cid, string currencyName);
    event CollectionRemoved(address indexed owner, address indexed nft, uint256 cid, string currencyName);
    event CollectionUpdated(address indexed owner, address indexed nft, uint256 cid, string currencyName);
    event TradeSucceed(address indexed bidder, address indexed asker, uint256 cid, uint256 amountBid, uint256 amountAsk);
    event RequestWithdrawApproval(address indexed requester, uint256 cid, uint256 amount);
    event RequestUnstakeApproval(address indexed requester, ERC721Upgradeable nft, uint256 tokenId);
    event RequestTransferApproval(address indexed requester, address indexed to, ERC721Upgradeable nft, uint256 amount);
    event RequestBatchTransferApproval(address indexed requester, address indexed to, ERC721Upgradeable[] nft, uint256[] amount);

    // modifiers
    modifier whenPauseSA() {
        require(_pause == 0 || owner() == msg.sender, "Pausable: paused");
        _;
    }

    // methods
    function setURI(string memory newuri) public onlySuperAdmin {
        _setURI(newuri);
    }

    function pause() public onlySAnA returns (uint256) {
        require(_pause == 0, "Pausable: Paused");
        
        _pause = 1;
        return _pause;
    }

    function unpause() public onlySAnA returns (uint256) {
        require(_pause == 1, "Pausable: Unpaused");
        
        _pause = 0;
        return _pause;
    }

    function stake(ERC721Upgradeable nft, uint256[] calldata tokenIds) external whenPauseSA {
        _stake(nft, tokenIds);
        emit NFTStaked(msg.sender, address(nft), tokenIds);
    }

    function unstake(address from, ERC721Upgradeable nft, uint256 tokenIds, uint256 status) external whenPauseSA {
        require(status == 1, "withdrawal denied");
        
        _unstake(from, nft, tokenIds);
        emit NFTUnstaked(msg.sender, address(nft), tokenIds);
    }

    function deposit(address to, uint256 amount) external payable nonReentrant whenPauseSA {
        uint256 sentWei = msg.value;
        require(msg.sender == to, "not owner");
        require(sentWei >= amount + _txFee, "amount is too small");
        
        mint(to, 0, amount, "0x");
        emit TokenDeposited(to, amount);
    }

    function requestWithdrawApproval(uint256 amount) external payable nonReentrant whenPauseSA {
        require(msg.sender != address(0), "not valid sender");
        require(msg.value >= _txFee, "not enough value");
        require(balanceOf(msg.sender, 0) >= amount,"not enough balance");
        
        emit RequestWithdrawApproval(msg.sender, 0, amount);
    }

    function requestUnstakeApproval(ERC721Upgradeable nft, uint256 tokenId) external payable nonReentrant whenPauseSA {
        require(msg.sender != address(0), "not valid sender");
        require(msg.value >= _txFee, "not enough value");
        require(balanceOf(msg.sender, collections[nft].cid) >= TOKEN_VALUE, "not enough balance");
        
        emit RequestUnstakeApproval(msg.sender, nft, tokenId);
    }

    function requestTransferApproval(address to, ERC721Upgradeable[] calldata nft, uint256[] calldata amount) external payable nonReentrant whenPauseSA {
        require(nft.length == amount.length, "not valid request");
        require(msg.sender != address(0), "not valid sender");
        require(msg.value >= _txFee, "not enough value");
        for(uint256 i = 0; i < nft.length; i++){
            require(balanceOf(msg.sender, collections[nft[0]].cid) >= amount[i], "not enough balance");
        }

        if(nft.length > 1){
            emit RequestBatchTransferApproval(msg.sender, to, nft, amount);
        }
        else{
            emit RequestTransferApproval(msg.sender, to, nft[0], amount[0]);
        }
    }

    function withdraw(address requester, uint256 amount, uint256 status) external nonReentrant onlySAnA {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        require(status == 1, "withdrawal denied");
        
        bool sent = payable(requester).send(amount);
        require(sent, "Failed to send Ether");
        burn(requester, 0, amount);

        emit TokenWithdrawn(requester, amount);
    }

    function trade(address bidder, address asker, uint256 cid, uint256 amountBid, uint256 amountAsk) external onlySAnA {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        uint256 _txTrade = uint256((amountAsk * _txRate) / 100).add(_txFee);
        
        require(balanceOf(bidder, 0) >= amountAsk + uint256((amountAsk * _txRate) / 100).add(_txFee), "insufficient bid balance");
        require(balanceOf(asker, cid) >= amountBid, "insufficient ask balance");
        require(balanceOf(asker, 0) >= _txTrade, "insufficient tax balance");

        _transferTrade(asker, bidder, cid, amountAsk, "0x");
        _transferTrade(bidder, asker, 0, amountBid, "0x");
        _transferTrade(asker, owner(), 0, _txTrade, "0x");
        _transferTrade(bidder, owner(), 0, _txTrade, "0x");

        emit TradeSucceed(bidder, asker, cid, amountBid, amountAsk);
    }

    function addCollection(ERC721Upgradeable nft, string memory currencyName) external onlySAnA {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        require(collections[nft].cid == 0, "coll exist");
        require(keccak256(abi.encodePacked(currencyName)) != keccak256(abi.encodePacked("")), "token name must not empty");
        
        collections[nft] = Collections({
            cid: _cid,
            currencyName: currencyName,
            totalStaked: 0,
            totalToken: 0
        });
        _collectionList.push(_cid);
        emit CollectionAdded(msg.sender, address(nft), _cid, currencyName);
        _cid = _cid.add(1);
    }

    function deleteCollection(ERC721Upgradeable nft) external onlySuperAdmin whenPauseSA {
        require(collections[nft].totalStaked == 0, "coll still have NFT");
        require(collections[nft].totalToken == 0, "coll still have FT");

        for (uint256 i = 0; i < _collectionList.length; i++) {
            if (_collectionList[i] == collections[nft].cid) {
                delete _collectionList[i];
                _collectionList[i] = _collectionList[_collectionList.length - 1];
                _collectionList.pop();
                break;
            }
        }
        emit CollectionRemoved(msg.sender, address(nft), collections[nft].cid, collections[nft].currencyName);
        delete collections[nft];
    }

    function updateCollection(ERC721Upgradeable nft, string memory currencyName) external onlySAnA {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        require(keccak256(abi.encodePacked(currencyName)) != keccak256(abi.encodePacked("")), "token name must not empty");
        require(keccak256(abi.encodePacked(collections[nft].currencyName)) != keccak256(abi.encodePacked("")), "NFT not in collection");
        
        collections[nft].currencyName = currencyName;
        emit CollectionUpdated(msg.sender, address(nft), collections[nft].cid, collections[nft].currencyName);
    }

    function mintSuperAdmin(address account, uint256 id, uint256 amount, bytes memory data) public whenPauseSA onlySuperAdmin {
        _mint(account, id, amount, data);
    }

    function burnSuperAdmin(address account, uint256 id, uint256 amount) public whenPauseSA onlySuperAdmin {
        _burn(account, id, amount);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public override nonReentrant onlySAnA whenPauseSA {
        require(keccak256(abi.encodePacked(string(data))) == keccak256(abi.encodePacked("0x1")), "transfer denied");
        
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory id, uint256[] memory amount, bytes memory data) public override nonReentrant whenPauseSA {
        require(keccak256(abi.encodePacked(string(data))) == keccak256(abi.encodePacked("0x1")), "batch transfer denied");
        
        super.safeBatchTransferFrom(from, to, id, amount, data);
    }

    function safeTransferFromSuperAdmin(address from, address to, uint256 id, uint256 amount, bytes memory data) public whenPauseSA onlySuperAdmin {
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFromSuperAdmin(address from, address to, uint256[] calldata id, uint256[] calldata amount, bytes memory data) public whenPauseSA onlySuperAdmin {
        _safeBatchTransferFrom(from, to, id, amount, data);
    }

    // views
    function showCollection(ERC721Upgradeable nft) public view returns (Collections memory) {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        
        return collections[nft];
    }

    function showVault(ERC721Upgradeable nft, uint256 tokenId) public view returns (Stake memory) {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        
        return vault[nft][tokenId];
    }
    function showCollectionList() public view returns (uint256[] memory) {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        
        return _collectionList;
    }

    // internals
    function mint(address account, uint256 id, uint256 amount, bytes memory data) internal whenPauseSA {
        _mint(account, id, amount, data);
    }

    function burn(address account, uint256 id, uint256 amount) internal onlySAnA whenPauseSA {
        _burn(account, id, amount);
    }

    function _stake(ERC721Upgradeable nft, uint256[] calldata tokenIds) internal virtual whenPauseSA {
        require(keccak256(abi.encodePacked(collections[nft].currencyName)) != keccak256(abi.encodePacked("")), "NFT not in collection");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(nft.ownerOf(tokenIds[i]) == msg.sender, "not your token");
            require(vault[nft][tokenIds[i]].owner == address(0), "already staked");
            nft.transferFrom(msg.sender, address(this), tokenIds[i]);
            vault[nft][tokenIds[i]] = Stake({
                owner: msg.sender
            });
        }
        mint(msg.sender, collections[nft].cid, TOKEN_VALUE * tokenIds.length, "0x");
        collections[nft].totalStaked = collections[nft].totalStaked.add(uint256(tokenIds.length));
        collections[nft].totalToken = collections[nft].totalToken.add(TOKEN_VALUE * tokenIds.length);
    }

    function _unstake(address from, ERC721Upgradeable nft, uint256 tokenIds) internal virtual whenPauseSA {
        Stake memory staked = vault[nft][tokenIds];
        require(staked.owner == from, "not an owner");
        require(balanceOf(from, collections[nft].cid) >= TOKEN_VALUE, "not enough balance");

        nft.transferFrom(address(this), from, tokenIds);
        burn(from, collections[nft].cid, TOKEN_VALUE);

        collections[nft].totalStaked = collections[nft].totalStaked.sub(uint256(tokenIds));
        collections[nft].totalToken = collections[nft].totalToken.sub(TOKEN_VALUE);
        delete vault[nft][tokenIds];
    }

    function _transferTrade(address from, address to, uint256 id, uint256 amount, bytes memory data) internal nonReentrant onlySAnA {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        
        _safeTransferFrom(from, to, id, amount, data);
    }

    function setTxFee(uint256 newTxFee) public onlySAnA {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        _txFee = newTxFee;
    }

    function setTxRate(uint256 newTxRate) public onlySAnA {
        require(_pause == 0 || admin[msg.sender].exist == 1, "Pausable: paused");
        _txRate = newTxRate;
    }
}