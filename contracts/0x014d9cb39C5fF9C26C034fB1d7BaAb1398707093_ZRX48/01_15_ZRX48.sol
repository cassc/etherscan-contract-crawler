// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
// import './VouchContract.sol';
// import "hardhat/console.sol";

contract ZRX48 is ERC721A, EIP712, ReentrancyGuard, Ownable, DefaultOperatorFilterer {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public mintPrice = 48000000 gwei;
    // 0Whitelist 1Allowlist 2PublicSale 3FreeMint
    uint256 public saleStage = 0;
    // uint256 curTokenID = 1;
    uint256 public cap;
    uint256 public freeMintNum;
    

    PartnerParam[] public partners;
    struct PartnerParam {
        address account;
        uint256 totalAmount;
        uint256 soldAmount;
        bool direct;
        bool onlyPublic;
        bool voucher;
    }


    string ipfsAddr1 = "";
    string ipfsAddr2 = "";
    address payable public vaultAddress1;
    address payable public vaultAddress2;
    bool isBlindBox = true;

    struct AccountParam {
        uint256 claimCnt;
        // uint256 freemint;
        uint256[] tokenList;
    }


    // Whitelist,Allowlist
    mapping(address => AccountParam) mapAccount;
    // PublicSale
    mapping(address => AccountParam) mapAccountPublic;
    // freeMint
    mapping(address => AccountParam) mapAccountFreemint;

    Counters.Counter private _tokenIdCounter;

    struct MintVoucher {
        address signer;
        address minter;
        uint256 expiration;
        uint256 count;
        bytes signature;
    }

    address[] _accounts;
    uint256[] _freemint;

    bytes32 internal constant MINTVOUCHER_HASH = keccak256("MintVoucher(address signer,address minter,uint256 expiration,uint256 count)");
    address[] public signers;

    constructor(uint256 cap_, uint256 freeMintNum_) ERC721A("zero to 48", "ZR48") EIP712("ZR48", "1"){
        vaultAddress1 = payable(msg.sender);
        vaultAddress2 = payable(msg.sender);
        cap = cap_;
        freeMintNum = freeMintNum_;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "tokenURI: URI query for nonexistent token");
        
        string memory _tokenIdStr = Strings.toString(_tokenId);
        if(isBlindBox == true){
            return string(abi.encodePacked(ipfsAddr1, _tokenIdStr, ".json"));
        }
        else{
             return string(abi.encodePacked(ipfsAddr2, _tokenIdStr, ".json"));
        }
    }

    function getCurrentTokenId() public view onlyOwner returns(uint256){
        return _nextTokenId();
    }

    function preSaleAvailableQuantity(address account) public view returns(uint256){
        return 2-mapAccount[account].claimCnt;
    }

    function publicSaleAvailableQuantity(address account) public view returns(uint256){
        return 5-mapAccountPublic[account].claimCnt;
    }

    // function getFreeMint(address account) public view onlyOwner returns(AccountParam memory){
    //     return mapAccountFreemint[account];
    // }

    function updateMintPric(uint256 amount) public onlyOwner {
        mintPrice = amount;
    }

    function mint(uint256 amount, MintVoucher calldata voucher) public nonReentrant payable {
        AccountParam storage _accountParam = mapAccount[msg.sender];
        uint256 curTokenID = _nextTokenId();

        if(saleStage < 2 ){
            // Whitelist Allowlist
            _accountParam = mapAccount[msg.sender];
            require(_accountParam.claimCnt.add(amount.sub(1)) < 2, "claim count > 2");
        } else if (saleStage == 2){
            // PublicSale
            _accountParam = mapAccountPublic[msg.sender];
            require(_accountParam.claimCnt.add(amount.sub(1)) < 5, "claim count > 5");
        }

        if (saleStage < 3){
            // Whitelist,Allowlist,PublicSale
            require(curTokenID.add(amount.sub(1)) < cap.sub(freeMintNum), "All nfts have been minted");
            require(msg.value >= mintPrice.mul(amount),  string(abi.encodePacked("claim ",Strings.toString(amount)," nft require ", Strings.toString(mintPrice.mul(amount)), " wei")));
        }else{
            // FreeMint
            _accountParam = mapAccountFreemint[msg.sender];
            // require(_accountParam.claimCnt.add(amount.sub(1)) < _accountParam.freemint , "The num of freemint is invalid");
            require(_accountParam.claimCnt.add(amount.sub(1)) < voucher.count , "The num of freemint is invalid");
            require(curTokenID.add(amount.sub(1)) < cap , "All freemint nfts have been minted");
        }

        bool _allowMint = false;
        if(saleStage == 2)
            // PublicSale
            _allowMint = true;
        else{
            require(verifyVoucher(voucher, msg.sender) , "The voucher is invalid");
            _allowMint = true;
        }

        require(_allowMint == true, "allowMint = false");
        
        for (uint i = 0; i < amount; i++) {
            curTokenID = _nextTokenId();
            _mint(_msgSender(), 1);
            // if(saleStage < 3 ){
                ++_accountParam.claimCnt;
                _accountParam.tokenList.push(curTokenID);
            // }
            // _tokenIdCounter.increment();
        }
    }

    function partnerMint(address minter, MintVoucher calldata voucher) external nonReentrant  payable {
        bool isExist;
        uint256 index;
        (isExist, index) = _isExistPartner(_msgSender());
        require(isExist , "The Partner is invalid");
        require(partners[index].totalAmount > partners[index].soldAmount , "The partner exceeding the sales quota");
        AccountParam storage _accountParam = mapAccount[minter];
        uint256 curTokenID = _nextTokenId();
        require(curTokenID < cap.sub(freeMintNum), "All nfts have been minted");

        require(saleStage < 3,"invalid sale stage");
        if(partners[index].onlyPublic){
            require(saleStage==2,"invalid sale stage");
        }
        if(!partners[index].direct){
            require(msg.value == mintPrice,  string(abi.encodePacked("claim nft require ", Strings.toString(mintPrice), " wei")));
        }
        
        if(saleStage < 2 ){
            // Whitelist Allowlist
            _accountParam = mapAccount[minter];
            require(_accountParam.claimCnt < 2, "claim count > 2");
        } else if (saleStage == 2){
            // PublicSale
            _accountParam = mapAccountPublic[minter];
            require(_accountParam.claimCnt < 5, "claim count > 5");
        }

        if(partners[index].voucher && saleStage < 2){
            require(verifyVoucher(voucher, minter) , "The voucher is invalid");
        }

        _mint(minter, 1);
        ++partners[index].soldAmount;
        ++_accountParam.claimCnt;
        _accountParam.tokenList.push(curTokenID);
        // _tokenIdCounter.increment();
    }


    function balanceOfContract() public view onlyOwner returns (uint) {
        return  address(this).balance;
    }
    
    function withdraw() public nonReentrant onlyOwner{
        uint256 _amount = address(this).balance;
        uint256 _div = SafeMath.div(_amount, 100);
        uint256 _amount1 =  SafeMath.mul(_div, 15);
        uint256 _amount2 = _amount - _amount1;

        (bool success1, ) = vaultAddress1.call{value: _amount1}("");
        require(success1, "Failed to send Ether to vaultAdrress1");

        (bool success2, ) = vaultAddress2.call{value: _amount2}("");
        require(success2, "Failed to send Ether to vaultAdrress2");
    }
    
    function setSaleStage(uint256 stage) public onlyOwner{
        saleStage = stage;
    }

    function startPublicSale() public onlyOwner{
        setSaleStage(2);
    }

    function setVaultAddress(address _vaultAddr1, address _vaultAddr2) public nonReentrant onlyOwner{
        vaultAddress1 = payable(_vaultAddr1);
        vaultAddress2 = payable(_vaultAddr2);
    }

    function setMintPrice(uint256 _mintPrice) public nonReentrant onlyOwner{
        mintPrice = _mintPrice;
    }

    function toggleDisplayMode() public onlyOwner{
        isBlindBox = !isBlindBox;
    }

    function setMetaAddress(string memory _url1, string memory _url2) public onlyOwner{
        ipfsAddr1 = _url1;
        ipfsAddr2 = _url2;
    }

    function reserve(uint _count) public onlyOwner{
        uint256 curTokenID = _nextTokenId();
        if(_count>cap.sub(curTokenID)){
            _mint(_msgSender(), cap.sub(curTokenID));
        }else{
            _mint(_msgSender(), _count);
        }
        

    }

    function addSigner(address _address) external onlyOwner {
      bool isExist;
      (isExist ,) = _isExistSigner(_address);
      if(!isExist){
          signers.push(_address);
      }
    }

    // function removeSigner(address _address) external onlyOwner {
    //     bool isExist;
    //     uint256 index;
    //     (isExist , index) = _isExistSigner(_address);
    //     if(isExist){
    //         signers[index] = signers[signers.length - 1];
    //         signers.pop();
    //     }
    // }

    function _isExistSigner(address _address) internal view returns(bool , uint256) {
        bool exist;
        uint256 index; 
        for(uint256 i ; i < signers.length ; i++){
            if(signers[i] == _address){
                exist = true;
                index = i;
            }
        }
        return (exist , index);
    }

    function isMintVoucher(MintVoucher calldata voucher) public view returns (bool) {       
        bytes32 _hash = _hashTypedDataV4(keccak256(abi.encode(
                    MINTVOUCHER_HASH,
                    voucher.signer,
                    voucher.minter,
                    voucher.expiration,
                    voucher.count
                )));
        return ECDSA.recover(_hash, voucher.signature) == voucher.signer;
    }

    function verifyVoucher(MintVoucher calldata voucher, address minter) public view returns (bool) {       
        require(isMintVoucher(voucher) , "Failed to verify the signature");
        bool isExist;
        (isExist , ) = _isExistSigner(voucher.signer);
        require(isExist , "The signer is invalid");
        // require(msg.sender == voucher.minter , "Minter is not the current caller");
        require(minter == voucher.minter , "Minter is not right");
        require(voucher.expiration > block.timestamp , "The voucher has expired");
        return true;
    }


    function addPartner(
        address _address,
        uint256 totalAmount,
        bool direct,
        bool onlyPublic,
        bool voucher
    ) external onlyOwner {
        bool isExist;
        (isExist, ) = _isExistPartner(_address);
        if (!isExist) {
            partners.push(PartnerParam(_address,totalAmount,0,direct,onlyPublic,voucher));
        }
    }

    // partner contracts Manager
    function updatePartner(
        address _address,
        uint256 totalAmount,
        bool direct,
        bool onlyPublic,
        bool voucher
    ) external onlyOwner {
        bool isExist;
        uint256 index;
        (isExist, index) = _isExistPartner(_address);
        require(isExist,'partner is not exist.');
        partners[index].totalAmount = totalAmount;
        partners[index].direct = direct;
        partners[index].onlyPublic = onlyPublic;
        partners[index].voucher = voucher;
    }
    
    function getPartner() external view onlyOwner returns(PartnerParam[] memory){
        return partners;
    }

    function _isExistPartner(address _address) internal view returns (bool, uint256) {
        bool exist;
        uint256 index;
        for (uint256 i; i < partners.length; i++) {
            if (partners[i].account == _address) {
                exist = true;
                index = i;
            }
        }
        return (exist, index);
    }
    
}