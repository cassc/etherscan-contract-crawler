// SPDX-License-Identifier: MIT

//                                                                                                                       
//                                                                                                                        
//                                                                                                                        
//                                                                                                                        
//                                                                                                                        
//                                                    ((((((((((((((((*                                                   
//                                                    (((((((((((((((((                                                   
//                                                    (((((((((((((((((                                                   
//                                                   ,(((((((((((((((((                                                   
//                                                   ((((((((((((((((((                                                   
//                                                   ((((((((((((((((((,                                                  
//                                                   (((((((((((((((((((                                                  
//                                                                                                                        
//                                                                                                                        
//                                                  /(((((((((((((((((((                                                  
//                                                  ((((((((((((((((((((,                                                 
//                                                  ((((((((((((((((((((/                                                 
//                                                  (((((((((((((((((((((                                                 
//                                                 .(((((((((((((((((((((                                                 
//                                                 *(((((((((((((((((((((                                                 
//                                                 ((((((((((((((((((((((.                                                
//                                                 ((((((((((((((((((((((*                                                
//                                                 (((((((((((((((((((((((                                                
//                                                 (((((((((((((((((((((((                                                
//                                                ,(((((((((((((((((((((((                                                
//                                                ((((((((((((((((((((((((                                                
//                                                ((((((((((((((((((((((((,                                               
//                                                (((((((((((((((((((((((((                                               
//                                                (((((((((((((((((((((((((                                               
//                                               ,(((((((((((((((((((((((((                                               
//                                               /(((((((((((((((((((((((((                                               
//                                               ((((((((((((((((((((((((((.                                              
//                                               ((((((((((((((((((((((((((/                                              
//                                               (((((((((((((((((((((((((((                                              
//                                              .(((((((((((((((((((((((((((                                              
//                                              *(((((((((((((((((((((((((((                                              
//                                              ((((((((((((((((((((((((((((.                                             
//                                              ((((((((((((((((((((((((((((*                                             
//                                              (((((((((((((((((((((((((((((                                             
//                                              (((((((((((((((((((((((((((((                                             
//                                              /(((((((((((((((((((((((((((.                                             
//                                                   ((((((((((((((((((*                                                  
//                                                       ,(((((((((                                                       
//                                                            ,                                                           
//                                                                                                                        
//                                                                                                                        
//                                                                                                                        
//                                                                                                                        

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

interface Delegate {
   function checkDelegateForAll(address delegate, address vault) external view returns (bool);
}

contract AcceptanceLtr is ERC1155, Ownable, ReentrancyGuard, RevokableDefaultOperatorFilterer {    

    string public metadata = "ipfs://QmUqgHjreKbwmD6SYHg1sby1ciGVWBVKdAt93Q17EyBpUY/";
    string public name_;
    string public symbol_;  

    uint256 public MAX_SUPPLY = 15001;
    uint256 ethPrice = 0.096 ether;
    uint256 pepePrice = 50000000;

    address private tokenContract = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;
    address private signer = 0x2f2A13462f6d4aF64954ee84641D265932849b64;
    address private adminAddress = 0x62ac2DbBD306610fF8652B9e0D1A310B6C6AFa0f;
    address public BurnContract;

    uint256 public mintTracker;
    uint256 public burnTracker;

    bool public burnActive = false;
    bool public publicActive = false;
    uint256 publicTokenId = 0;
    uint256 maxMintPerWallet = 10;

    enum MintType { TRUTH, BELIEVER }

    mapping(MintType => uint256) private mintId;
    mapping(MintType => bool) private mintActive;
    mapping(MintType => mapping(address => bool)) public didWalletMint;

    mapping(address => uint256) public publicMintedPerWallet;

    event MintApplication(address minter, uint256 qty, uint256 applicationId);

    constructor() ERC1155(metadata) {
        name_ = "AcceptanceLtr";
        symbol_ = "BIMNT";

        mintActive[MintType.TRUTH] = false;
        mintActive[MintType.BELIEVER] = false;

        mintId[MintType.TRUTH] = 0;
        mintId[MintType.BELIEVER] = 1;
    }

    function airdrop(uint256[] calldata tokenAmount, address[] calldata wallet, uint256 tokenId) public onlyOwner {
        for(uint256 i = 0; i < wallet.length; i++){ 
            require(mintTracker + tokenAmount[i] <= MAX_SUPPLY, "Minted Out");
            _mint(wallet[i], tokenId, tokenAmount[i], "");
            mintTracker += tokenAmount[i];
        }
    }

    function mintAllowlist(address wallet, uint256 tokenAmount, bytes calldata voucher, MintType mintType, bool delegate) external nonReentrant {

        if(delegate)
            require(Delegate(0x00000000000076A84feF008CDAbe6409d2FE638B).checkDelegateForAll(msg.sender, wallet), "Not delegate");
        else 
            require(msg.sender == wallet, "Not wallet");

        uint256 tokenId = mintId[mintType];
        bool checkWallet = didWalletMint[mintType][wallet];

        require(mintActive[mintType], "Mint type not active");
        require(!checkWallet, "Already Minted in this Phase");
        require(mintTracker + tokenAmount <= MAX_SUPPLY, "Minted out");
        require(tokenAmount > 0, "Non zero value");
        
        require(msg.sender == tx.origin, "EOA only");

        bytes32 hash = keccak256(abi.encodePacked(wallet, tokenId, tokenAmount));
        require(_verifySignature(signer, hash, voucher), "Invalid voucher");
        
        didWalletMint[mintType][wallet] = true;
        mintTracker += tokenAmount;

        _mint(msg.sender, tokenId, tokenAmount, "");
        emit MintApplication(msg.sender, tokenAmount, tokenId);
    }

    function mintPEPE(uint256 tokenAmount) external payable nonReentrant {

        require(msg.sender == tx.origin, "EOA only");
        require(mintTracker + tokenAmount <= MAX_SUPPLY, "Minted out");

        require(publicActive, "Mint type not active");
        require(publicMintedPerWallet[msg.sender] <= maxMintPerWallet, "Already Minted Max Per Wallet");
        require(tokenAmount > 0, "Non zero value");
        publicMintedPerWallet[msg.sender] += tokenAmount;

        uint256 price = pepePrice * tokenAmount * (10**18); // Convert pepePrice to token amount

        IERC20(tokenContract).transferFrom(
            msg.sender,
            adminAddress,
            price
        );
        
         mintTracker += tokenAmount;

        _mint(msg.sender, publicTokenId, tokenAmount, "");
        emit MintApplication(msg.sender, tokenAmount, publicTokenId);
    }

    function mintETH(uint256 tokenAmount) external payable nonReentrant {

        require(msg.sender == tx.origin, "EOA only");
        require(mintTracker + tokenAmount <= MAX_SUPPLY, "Minted out");

        require(tokenAmount > 0, "Non zero value");
        require(publicActive, "Mint type not active");
        require(publicMintedPerWallet[msg.sender] <= maxMintPerWallet, "Already Minted Max Per Wallet");
        publicMintedPerWallet[msg.sender] += tokenAmount;

        require(msg.value >= ethPrice * tokenAmount, "Ether value sent is not correct");
        
        mintTracker += tokenAmount;

        _mint(msg.sender, publicTokenId, tokenAmount, "");
        emit MintApplication(msg.sender, tokenAmount, publicTokenId);

    }

    function burnForCharacter(uint256 _qty, address _addr, uint256 tokenId) external {
        require(burnActive, "Burn is not active");
        require(msg.sender == BurnContract, "Must be from future contract");
        _burn(_addr, tokenId, _qty);
        burnTracker += _qty;
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) internal pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function setMintActive(MintType mintType, bool state) public onlyOwner {
        mintActive[mintType] = state;
    }

    function setMintId(MintType mintType, uint256 newId) public onlyOwner {
        mintId[mintType] = newId;
    }

    function setTokenContract(address _tokenContract) public onlyOwner {
        tokenContract = _tokenContract;
    }

    function setAdminAddress(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    function setPEPEPrice(uint256 _price) public onlyOwner {
        pepePrice = _price;
    }

    function setETHPrice(uint256 _ethprice) public onlyOwner {
        ethPrice = _ethprice;
    }

    function setPublicTokenId(uint256 _id) public onlyOwner {
        publicTokenId = _id;
    }

    function setMaxMintPerWallet(uint256 _amount) public onlyOwner {
        maxMintPerWallet = _amount;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setBurnContract(address _contract) public onlyOwner {
        BurnContract = _contract;
    }

    function setBurn(bool _state) public onlyOwner {
        burnActive = _state;
    }

    function setPublic(bool _state) public onlyOwner {
        publicActive = _state;
    }

    function setMetadata(string calldata _uri) public onlyOwner {
        metadata = _uri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(metadata, Strings.toString(tokenId)));
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function totalSupply() public view returns (uint){
        return mintTracker - burnTracker;
    }

    function getAmountMintedPerType(MintType mintType, address _address) public view returns (bool) {
        return didWalletMint[mintType][_address];
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call {value: address(this).balance}("");
        require(success);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

}