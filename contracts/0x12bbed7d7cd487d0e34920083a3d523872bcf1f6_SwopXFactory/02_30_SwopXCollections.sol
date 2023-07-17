// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


interface iSwopXFactory {
    
    function notifySaleLog(address minter, uint256 tokenID, uint256 price) external;
    function notifyCryptoLog(bool isSupported, address payment, uint256 price) external;
    function notifyActiveLog(bool isActive) external;
    function notifyRootLog(bytes32 root) external;
    function notifyMintLog(address admain, uint256 tokenId) external;
    function notifyStartCollectionLog(address admain, uint256 time, uint256 maxMinPerAddress, bool saleIsActive) external;
    function notifyCurrencySaleLog(address account, uint256 numTokens, address paymentContract, uint256 cost) external;

}


contract SwopXCollections is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl, ERC2981{

    using SafeERC20 for IERC20;

    using Strings for uint256;
    // max minting per a transaction
    uint256 private constant maxMint = 20 ;
    // public price
    uint256 private publicPriceWei_ ;
    // private price
    uint256 private privatePriceWei_ ;
    // the admain is the collector
    address private collector ;
    // max sypply
    uint256 private maxSypplyCollection;
    // active the sale
    bool private saleIsActive;
    
    address private constant fees = payable(0x8E657Af24D96231d8b861E47fC43Dde87B179179);
    // root of the waiting list, the tree has to be balanced.
    // you could add the admin in the tree if the tree is not balanced.
    bytes32 private root;
    // max mintting per address
    uint256 private maxMintPerAddress;
 
    // SalesConf time stamp of the witing list and public sale
    struct SalesConf {
        uint256 whiteListStartTime;
        uint256 publicStartTime;
    }


    SalesConf private salesconf;
    //the factory contract
    address private factory;
    // payment contract address has to be added by the admin/owner of the contract
    // WETH, WBTC, USDT, USDC
    mapping(IERC20=> bool) private erc20Addrs;
    mapping(IERC20=> uint256) private erc20Price;

    bytes32 public constant ADMAIN_ROLE = keccak256("ADMAIN_ROLE");

    /*
    * A cryptocurrency address has to be supported
    */
    modifier supportInterface(address _contract) {
        require(erc20Addrs[IERC20(_contract)] == true,"Contract address is not Supported ");
        _;
    }

    /*
    * No zero address is allowed
    */
    modifier zeroAddress(address _contract) {
        require( _contract != address(0) , "Zero Address");
        _;
    }

    // StartCollectionLog event is called if there is a new collection
    event StartCollectionLog(address indexed collection, address owner, uint256 time, bool status);
    // SaleLog event is called if there is a sale
    event SaleLog(address minter, address contracts, uint256 numberOfTokens, uint256 cost);
    // CryptoLog  event is called in the add erc20 token
    event CryptoLog(address contracts, bool isSupported, uint256 price);
    // CollectorLog event is the reciver address of the payment
    event CollectorLog(address admain);
    // MintLog event, minting
    event MintLog(address admain, uint256 tokenId);
    // is sale active
    event ActiveLog(bool isActive);
    // if the root is updated
    event RootLog(bytes32 root);

    /*
    * @notice: this function runs once the contract deployed
    * @param  name_symbol_ string is an array of name and symbol of the collection
    * @param  _admain address is the owner of the collection
    * @param  maxSypplyCollection_ uint256 is max sypply of the collection
    * @param  _privatePriceWei_startTime_ uint256 is an arry of the private price in Wei and private start time stamp
    * @param  _publicPriceWei_publicstartTime_ uint256 is an arry of the public pricd in Wei and the public start time stamp
    * @param maxMintPerAddress_ uint256 is how many a wallet address can mint
    * @param baseURI string of the URI
    * @param merkleroot bytes32 is the root of the waiting list of the private sale.
    */
    function initialize(string [2] calldata name_symbol_, address _admain, address _factory,
    uint256 maxSypplyCollection_, uint256 [2] calldata _privatePriceWei_startTime_, uint256 [2] calldata _publicPriceWei_publicstartTime_,
    uint256 maxMintPerAddress_, string calldata baseURI, bytes32 merkleroot) external virtual initializer  {
            require(timestamp() <= _publicPriceWei_publicstartTime_[1],"public time sale is not correct " );
            require(_publicPriceWei_publicstartTime_[1] >= _privatePriceWei_startTime_[1],"public time smaller than end time" );
            require(_admain != address(0));
            __ERC721_init(name_symbol_[0], name_symbol_[1]);
            maxSypplyCollection = maxSypplyCollection_;
            _setBaseURI(string(abi.encodePacked(baseURI, Strings.toHexString(address(this)),"/")));
            _grantRole(DEFAULT_ADMIN_ROLE,_admain);
            _grantRole(ADMAIN_ROLE, _admain);
            collector = _admain;
            publicPriceWei_ = _publicPriceWei_publicstartTime_[0];
            privatePriceWei_ = _privatePriceWei_startTime_[0];
            salesconf.whiteListStartTime = _privatePriceWei_startTime_[1];
            salesconf.publicStartTime = _publicPriceWei_publicstartTime_[1];
            saleIsActive = true;
            maxMintPerAddress = maxMintPerAddress_;
            root = merkleroot;
            factory = _factory;
            emit StartCollectionLog(address(this), msg.sender, _publicPriceWei_publicstartTime_[1], saleIsActive);
    }

    /*
    * @notice: addToken function for adding cryptocurancy contract address
    * @param _contract address is a contract address
    * @param _mode bool true/ false
    */
    function addToken(address _contract, bool _mode, uint256 _price) external
    zeroAddress(_contract) onlyRole(ADMAIN_ROLE) {
        erc20Addrs[IERC20(_contract)] = _mode;
        erc20Price[IERC20(_contract)] = _price;
        iSwopXFactory(factory).notifyCryptoLog(_mode,_contract, _price);
        
        emit CryptoLog(_contract, _mode, _price) ;
    }

    /*
    * @notice: update root function for replacing the old root
    * @param merkleroot bytes32 is the root of the 
    */
    function resetRoot(bytes32 merkleroot) external
    onlyRole(ADMAIN_ROLE) {
        root = merkleroot;
        iSwopXFactory(factory).notifyRootLog(root);
        emit RootLog(root) ;
    }

    /*
    * @notice: to set ERC20 token receiver
    * @param _admain address is a wallet address of the collection owner.
    */
    function setCollector(address _admain) external
        zeroAddress(_admain) onlyRole(ADMAIN_ROLE) {
        collector = _admain;
        emit CollectorLog(_admain) ;
    }

    /*
    * @notice: check if a cryptocurrency address is supported, and the price of the curruncy 
    * @param _contract address is the erc20 contract address.
    */
    function currencyTokens(address _contract) external
    zeroAddress(_contract) view returns(bool, uint256){
        return (erc20Addrs[IERC20(_contract)], erc20Price[IERC20(_contract)]);
    }

    /*
    * @notice: this function runs if the owner would like to change the timestamp of the public sale timestamp
    * @param  publicstartTime_ uint256 is the public pricd in Wei and the public start time stamp
    * @param maxMintPerAddress_ uint256 is how many a wallet address can mint
    */
    function setPublicTimeSale(uint256 publicstartTime_, uint256 maxMintPerAddress_) external onlyRole(ADMAIN_ROLE) {
        uint256 whiteListTime_ = salesconf.whiteListStartTime;
        require(publicstartTime_> whiteListTime_,"List Time" );
        require(timestamp() < publicstartTime_,"public time" );
        salesconf.publicStartTime = publicstartTime_;
        maxMintPerAddress = maxMintPerAddress_;
        saleIsActive = true;
        iSwopXFactory(factory).notifyStartCollectionLog(msg.sender, publicstartTime_, maxMintPerAddress, saleIsActive);
        emit StartCollectionLog(address(this),  msg.sender, publicstartTime_, saleIsActive);
    }


        /*
    * @notice: public sale. ETH
    * @param _numTokens uint256 is the number of tokens to be minited.
    */

    function publicSaleMint(uint256 numTokens)  external payable {
        SalesConf memory conf = salesconf;
        uint256 tokenId = totalSupply();
        require(numTokens + tokenId <= maxSypplyCollection, "Exceed max supply");
        uint256 timestamp_ = conf.publicStartTime;
        uint256 price_ = publicPriceWei_;
        require(timestamp() >= timestamp_,"Sales have not started yet");
        uint256 cost = price_ * numTokens;
        uint _fee = calculateFees(cost);
        require(cost + _fee <= msg.value, "No Enogh Ether value");
        payable(fees).transfer(_fee);
        safeMint(numTokens);
        iSwopXFactory(factory).notifySaleLog(msg.sender, numTokens, cost + _fee);
        emit SaleLog(msg.sender, address(0), numTokens, cost + _fee);
    }


    /*
    * @notice: safeMint function called in whitelistSaleMint, publicSaleMint, publicSaleMintCurrency
    @param numTokens uint256 is the number of tokens to be minited.
    */
    function safeMint( uint256 numTokens) private {
        uint256 tokenId = totalSupply();
        require(numTokens + tokenId <= maxSypplyCollection, "Exceed max supply");
        require(numTokens <= maxMint, "Only 20 tokens at a time");
        require(saleIsActive, "Sale is not active");
        require(maxMintPerAddress >= numTokens + balanceOf(msg.sender), "can't mint more than requires");
        for(uint i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, tokenId + i);
            _setTokenURI(tokenId + i,  string(abi.encodePacked(Strings.toString(tokenId + i),'.json')));
            iSwopXFactory(factory).notifyMintLog(msg.sender, tokenId + i);
            emit MintLog(msg.sender, tokenId + i);
        }

    }

    /*
    * @notice: only the collection admain can mint
    * @param numTokens uint256 is the number of tokens to be minited.
    */
    function mint(uint256 numTokens) external onlyRole(ADMAIN_ROLE) {
        uint256 tokenId = totalSupply();
        require(numTokens + tokenId <= maxSypplyCollection, "Exceed max supply");
        for(uint i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, tokenId + i);
            _setTokenURI(tokenId + i,  string(abi.encodePacked(Strings.toString(tokenId + i),'.json')));
            iSwopXFactory(factory).notifyMintLog(msg.sender, tokenId + i);
            emit MintLog(msg.sender, tokenId + i);
        }
    }

    function timestamp() private view returns (uint256) {
        return block.timestamp ;
    }


    /*
    * @notice: waiting list addresses can mint nft if theose addresses are belong to the root and the proof.
    * @param  account address is the wallet address in the array of the root.
    * @param _numTokens uint256 is the number of tokens to be minited.
    * @param proof bytes32 is proof of this account.
    */
    function whitelistSaleMint( address account, uint numTokens, bytes32 [] calldata proof)
    zeroAddress(account) external payable {
        require(account== msg.sender,"must be an owner" );
        require(_verify(_leaf(account), proof), "Invalid merkle proof");
        SalesConf memory conf = salesconf;
        uint256 tokenId = totalSupply();
        require(numTokens + tokenId <= maxSypplyCollection, "Exceed max supply");
        uint256 startTimestamp_ = conf.whiteListStartTime;
        require (timestamp() >= startTimestamp_ , "Time" );
        uint256 price_ = privatePriceWei_;
        uint256 cost = price_ * numTokens;
        uint256 _fee = calculateFees(cost);
        require(cost + _fee <= msg.value, "No Enogh Ether value");
      
        payable(fees).transfer(_fee);
        safeMint( numTokens);
        iSwopXFactory(factory).notifySaleLog(account, numTokens, cost + _fee);
        emit SaleLog(account, address(0), numTokens, cost + _fee);
    }


    /*
    * @notice: public sale. token
    * @param _numTokens uint256 is the number of tokens to be minited.
    */
    function publicSaleMintCurrency( address paymentContract, uint256 numTokens, uint256 amount)
    zeroAddress(paymentContract) supportInterface(paymentContract)  external {
        SalesConf memory conf = salesconf;
        uint256 tokenId = totalSupply();
        require(numTokens + tokenId <= maxSypplyCollection, "Exceed max supply");
        uint256 timestamp_ = conf.publicStartTime;
        uint256 price_ = erc20Price[IERC20(paymentContract)];
        require(timestamp() >= timestamp_,"Sales have not started yet");
        uint256 cost = price_ * numTokens;
        uint _fee = calculateFees(cost);
        require(amount >=  cost + _fee, "amount is lower");
        IERC20(paymentContract).safeTransferFrom(msg.sender, factory, _fee);
        IERC20(paymentContract).safeTransferFrom(msg.sender, collector, cost);
        safeMint( numTokens);
        iSwopXFactory(factory).notifyCurrencySaleLog(msg.sender, numTokens, paymentContract, cost + _fee);
        emit SaleLog(msg.sender, paymentContract, numTokens, cost + _fee);
    }

    /*
    * @notice: only the admin can withdraw.
    */
    function withdraw() external onlyRole(ADMAIN_ROLE) {
        uint256 contract_balance = address(this).balance;
        // require(contract_balance > 0, "No funds available for withdrawal");
        payable(msg.sender).transfer(contract_balance);
    }




    function calculateFees(uint256 _amount) public pure returns(uint fee) {
        uint256 callItFee = _amount * 150;
        fee = callItFee / 1e4;
    }


    /*
    * @notice: to stop/run the sale
    * it is flipping the sale action.  
    */
    function flipSaleState() external onlyRole(ADMAIN_ROLE) {
        saleIsActive = !saleIsActive;
        iSwopXFactory(factory).notifyActiveLog(saleIsActive);
        emit ActiveLog(saleIsActive);
    }

    /*
    * @notice: read the balance of this contract
    */
    function balance() external view returns(uint256 _balance) {
        _balance = address(this).balance;
    }

    /*
    * @notice: only the collection admain change the base uri
    * @param baseURI string is the uri in sting
    */
    function setURI(string calldata baseURI) onlyRole(ADMAIN_ROLE) external {
        _setBaseURI(baseURI);
    }


    /*
    * @notice: status of this collection
    whiteListStartTime is timestamp of the private sale
    privatePriceWei is the price of the private sale
    publicStartTime is timestamp of the public sale
    publicPriceWei is the price of the public sale
    maxSypply is the max supply of the collection
    */
    function saleStatus() view external returns(
        bool status,
        uint256 whiteListStartTime,
        uint256 privatePriceWei,
        uint256 publicStartTime,
        uint256 publicPriceWei,
        uint256 maxSypply ) {
        status = saleIsActive ;
        whiteListStartTime = salesconf.whiteListStartTime;
        privatePriceWei = privatePriceWei_ ;
        publicStartTime = salesconf.publicStartTime;
        publicPriceWei = publicPriceWei_;
        maxSypply = maxSypplyCollection;

    }

    function owner() view external returns(address sc_owner){
        sc_owner = collector;
    }


    /*
    * @notice: _leaf function is called in makePayment, makePerPayment function to verify each Merkle 
    * @param account address is in an array of addresses  
    */
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    /*
    * @notice: Verifies a Merkle proof proving the existence of a leaf in a Merkle tree
    * @param leaf Leaf of Merkle tree
    * @param proof Merkle proof 
    */
    function _verify(bytes32 leaf, bytes32[] memory proof) private view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }



        // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}