// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";   
import "@openzeppelin/contracts/security/Pausable.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";


interface ERC1155NFT {
    function safeTransferFrom( address from, address to, uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return (counter._value + 495);
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
} 

interface ERC20 {
    function transferFrom( address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external returns (uint256);
    function decimals() external returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
}    

contract Crypt3dpunks is ERC721, Pausable, ERC721Burnable, AccessControl, ERC2981,DefaultOperatorFilterer {
    using Counters for Counters.Counter;      
    Counters.Counter private _gloablId;       
    uint256 public EtherPrice;                                 
    uint256 public Discount; 
    uint256 public Round;  
    bytes32 public root;        
    uint256 private NFTCount;
    address public constant ExistingERC1155 =0xa50c349912739A4fe4e50BaFD3d8689210642D88;              
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD; 
    bool public PresaleLive;
    bool public SaleLive; 
    bool public AllowSwapExistingUsers;

    address[4] public SupportedCryptos; 


    uint256[][] public priceCardInDollar = [
        [100, 100, 100, 100, 100, 100],

        [140, 133, 126, 119, 112, 98],
        [147, 140, 133, 125, 118, 103],
        [155, 147, 139, 132, 124, 109],
        [163, 154, 145, 138, 130, 114],
        [171, 162, 153, 145, 137, 120],
        [179, 170, 160, 152, 143, 126],
        [188, 179, 169, 160, 151, 132],
        [197, 188, 178, 168, 158, 138],
        [207, 197, 187, 176, 166, 145], 
        [218, 207, 196, 185, 174, 153] 
    ];

    
    uint256[11] public roundCap = 
    [   
        495, 
        845, 
        1345, 
        2095, 
        3136, 
        4280, 
        5424, 
        6568, 
        7712, 
        8856, 
        10000   
    ];

    bool[5] public paymentPermitted = [true, true, true, true, true];
    bool[11] public roundReveal = [  false, false, false, false, false, false, false, false, false, false, false ];                                          

    string public baseURI = "https://www.crypt3dpunksmint.io/api/crypt3dpunks/"; 
    
    mapping(uint256 => bool) public stopTransfer;
    enum CurrentState { 
        round0, 
        round1, 
        round2, 
        round3, 
        round4, 
        round5, 
        round6, 
        round7,
        round8, 
        round9, 
        round10, 
        pause,
        completed
    }

    CurrentState public currentState = CurrentState.round1; 

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");     
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
                    

    constructor() ERC721("Cypt3dpunks", "CRYPT3D"){                       
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);                                
        _grantRole(DEFAULT_ADMIN_ROLE, 0x03717989289c46a101A18b0A3e0Ca8DffB92a5a5);                                
        _grantRole(PAUSER_ROLE, msg.sender);    
        _grantRole(UPDATER_ROLE, msg.sender);  
        _grantRole(UPDATER_ROLE, 0x3943afed89b68060105a51285D548464B115aee0);  
        setRoyaltyInfo(0x7c781885b5fEC8Fe40B3625cA54aA8688E4d6A9c, 500);                         

        SupportedCryptos[0]=0xdAC17F958D2ee523a2206206994597C13D831ec7; //USDT 6 decimals
        SupportedCryptos[1]=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC 6 decimals
        SupportedCryptos[2]=0x6B175474E89094C44Da98b954EedeAC495271d0F; //DAI  18 decimals
        SupportedCryptos[3]=0x4Fabb145d64652a948d72533023f6E7A623C7C53; //BUSD  18 decimals
        EtherPrice= 191000; 
        Discount= 0; 
        Round=1;                                       
    }

    modifier mintable(uint token,uint _quantity,bool preSale) {
        if(preSale){
            require(PresaleLive,"PreSale is not live yet");
        }
        else{
            require(SaleLive,"Sale is not live yet");
        }
        require(token>=0 && token<=4,"Invalid input : token");
        require(paymentPermitted[token], "Payment Stopped for this token");         
        require(_quantity == 1 || _quantity == 2 || _quantity == 3 || _quantity == 4 || _quantity == 5 || _quantity == 10,"Invalid input : quantity");
        require((_gloablId.current() + _quantity) <= roundCap[Round],"quantity exceeded the limit for this round");  
        _;
    }

    function batchMint(uint256 _quantity, address _to) external payable whenNotPaused mintable(4,_quantity,false){ 
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) { 
            uint amount =_acceptEthers(_quantity,1000); 
            require(msg.value >= amount, "Not enough ethers"); 
        }  
        _internalMint(_quantity,_to); 
    }       

    function batchMintWhiteList(uint256 _quantity, bytes32[] memory proof) external payable whenNotPaused mintable(4,_quantity,true){
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        uint amount =_acceptEthers(_quantity,(1000-Discount));
        require(msg.value >= amount, "Not enough ethers");
        _internalMint(_quantity,msg.sender); 
    }

    function batchMintUsingCryptoCurrency(uint8 token, uint256 _quantity, address _to) external whenNotPaused mintable(token,_quantity,false){
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            _acceptEthersCrypto(token,_quantity,1000);
        }   
        _internalMint(_quantity,_to);
    }
    
    function batchMintWhiteListUsingCryptoCurrency(uint8 token, uint256 _quantity, bytes32[] memory proof) external whenNotPaused mintable(token,_quantity,true){
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        _acceptEthersCrypto(token,_quantity,1000-Discount);
        _internalMint(_quantity,msg.sender);
    }

    function _acceptEthers(uint _quantity,uint _discount) internal view returns(uint){
        uint amount;
        if(_quantity!=10){
            uint temp =_quantity-1;
            amount= ((priceCardInDollar[Round][temp]*(10**20)*_discount)*_quantity)/(EtherPrice*1000);  
        }else{             
            amount= ((priceCardInDollar[Round][5]*(10**20)*_discount)*_quantity)/(EtherPrice*1000);
        } 
        return amount;
    } 

    function _acceptEthersCrypto(uint token, uint _quantity,uint _discount) internal {
        uint8 decimal = ERC20(SupportedCryptos[token]).decimals();
        uint amount; 
        if(_quantity!=10){
            uint temp =_quantity-1;
            amount = ((priceCardInDollar[Round][temp] * (10**decimal)) *_discount*_quantity)/1000;
            require(ERC20(SupportedCryptos[token]).balanceOf(msg.sender) >=amount,"Not enough Tokens");
            ERC20(SupportedCryptos[token]).transferFrom(msg.sender,address(this),amount);
        }else{ 
            amount = ((priceCardInDollar[Round][5] * (10**decimal)) *_discount*_quantity)/1000;
            require(ERC20(SupportedCryptos[token]).balanceOf(msg.sender) >=amount,"Not enough Tokens");
            ERC20(SupportedCryptos[token]).transferFrom(msg.sender,address(this),amount);
        }
    }    

    function _internalMint(uint _quantity, address _to) internal {
        for (uint256 i = 0; i < _quantity;) {
            uint256 tokenId = _gloablId.current();
            _gloablId.increment();
            _safeMint(_to, tokenId);
            unchecked {
                i++;
            }
            if (_gloablId.current() == roundCap[Round]) {
                currentState = CurrentState.pause;
                _pause();
            }
        }
        NFTCount+=_quantity;
    }

    function batchSwapExistingUsers(uint256[] memory NFTs) external whenNotPaused{
        require(AllowSwapExistingUsers==true,"Swap function is paused by the owner");
        require((_gloablId.current() + NFTs.length) <= roundCap[Round],"Quantity exceeded the limit for this round");
        for (uint256 i = 0; i < NFTs.length; i++) {
            require(ERC1155NFT(ExistingERC1155).balanceOf(msg.sender, NFTs[i]) >=1,"You don't own this NFT");
            require(NFTs[i]<roundCap[0],"Swap NFT id can not be more that 494");  
            ERC1155NFT(ExistingERC1155).safeTransferFrom(msg.sender,burnAddress, NFTs[i], 1, "0x00");
            _safeMint(msg.sender, NFTs[i]); 
            uint256 tokenId = _gloablId.current(); 
            _gloablId.increment();
            _safeMint(msg.sender, tokenId);
            NFTCount+=2;
        }          
        if (_gloablId.current() == roundCap[Round]) {
            currentState = CurrentState.pause;
            _pause();
        }
    } 

    function batchAirdrop(address[] calldata recipients) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = recipients.length;
        require((_gloablId.current() + length) <= roundCap[Round],"Quantity exceeded the limit for this round");
        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = _gloablId.current(); 
            _gloablId.increment();
            _safeMint(recipients[i], tokenId);
            NFTCount+=1;
            unchecked {
                i++;
            } 
        }   
        if (_gloablId.current() == roundCap[Round]) {
            currentState = CurrentState.pause;
            _pause();
        }
    } 

    function startPresale() external onlyRole(DEFAULT_ADMIN_ROLE){
        require(PresaleLive==false,"Presale is already live");
        PresaleLive=true;
    }

    function startSale() external onlyRole(DEFAULT_ADMIN_ROLE){
        require(SaleLive==false,"Sale is already live");
        SaleLive=true;
    }

    function endPresale() external onlyRole(DEFAULT_ADMIN_ROLE){
        require(PresaleLive==true,"Presale has already ended");
        PresaleLive=false;
    }

    function endSale() external onlyRole(DEFAULT_ADMIN_ROLE){
        require(SaleLive==true,"Sale has already ended");
        SaleLive=false;
    }

    function allowSwap() external onlyRole(DEFAULT_ADMIN_ROLE){
        require(AllowSwapExistingUsers==false,"Swap is already live");
        AllowSwapExistingUsers=true;
    }

    function stopSwap() external onlyRole(DEFAULT_ADMIN_ROLE){
        require(AllowSwapExistingUsers==true,"Swap is already stopped");
        AllowSwapExistingUsers=false;
    }

    function ADD_DEFAULT_ADMIN_ROLE(address account) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    } 

    function LEAVE_DEFAULT_ADMIN_ROLE() external virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function ADD_PAUSER_ROLE(address account) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(PAUSER_ROLE, account);
    } 

    function LEAVE_PAUSER_ROLE() external virtual {
        renounceRole(PAUSER_ROLE, msg.sender);
    }

    function ADD_UPDATER_ROLE(address account) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(UPDATER_ROLE, account);
    } 
 
    function LEAVE_UPDATER_ROLE() external virtual {
        renounceRole(UPDATER_ROLE, msg.sender);
    }
    
    function updateEtherPrice(uint price) external onlyRole(UPDATER_ROLE) {
        EtherPrice=price;
    }

    function setMerkleRoot(bytes32 _newRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        root=_newRoot;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function pauseUnpauseNFTsTransfer(uint256 _round, bool flip) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_round >= 0 && _round <= 10);
        stopTransfer[_round] = flip;
    }

    function updatePriceCard(uint256 round, uint256[] memory updatedValues) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(round >= 1 && round <= 10);
        require(updatedValues.length == 6, "Invalid updatedValues array size");
        for (uint256 i = 0; i < updatedValues.length; i++) {
            priceCardInDollar[round][i] = updatedValues[i];
        }
    }

    // Token value 0 - USDT     
    // Token value 1 - USDC     
    // Token value 2 - DAI      
    // Token value 3 - BUSD      
    // Token value 4 - Ethers       

    function AlterPayment(uint256 token)  external onlyRole(DEFAULT_ADMIN_ROLE){
        paymentPermitted[token] = !paymentPermitted[token];
    }

    function reveal(uint256 _round) external onlyRole(DEFAULT_ADMIN_ROLE) {
        roundReveal[_round] = true;
    }

    function updateDiscountPercentage(uint _discountPercentage) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_discountPercentage<1000,"Discount can not be more than 100%");
        Discount=_discountPercentage;    
    }

    function withdrawEthers(address to,uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = (to).call{value: amount}("");
        require(success, "Failed to send ethers");
    }

    function withdrawTokens(uint token, address to, uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC20(SupportedCryptos[token]).transfer(to,amount);
    }

    function updateBaseUri(string memory _newbaseURI) onlyRole(DEFAULT_ADMIN_ROLE) external {
        baseURI = _newbaseURI;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    } 

    function _checkInRoundCap(uint256 _value) internal view returns (bool) {
        for (uint i = 0; i < roundCap.length; i++) {
            if (_value == roundCap[i]) {
                return true;
            } 
        }
        return false;
    }

    function unpause(uint _etherPrice, uint _discountPercentage, bool _isRoundEnd) external onlyRole(PAUSER_ROLE) {
        require(_discountPercentage<1000,"Discount can not be more than 100%");
        if(_isRoundEnd && _gloablId.current()!=10000){
            require(_checkInRoundCap(_gloablId.current()),"Tier hasn't come to an end yet!");
            uint8 current = uint8(currentState);
            currentState = CurrentState(current + 1);
            Round+=1; 
        }
        EtherPrice =_etherPrice; 
        Discount=_discountPercentage; 
        _unpause();
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
                                                                                                                       

    function getPriceForARound(bool isEther,uint256 decimal,uint256 round, uint256 discount) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            if (isEther) {
                if (i == 5) {
                    uint256 amountinWei = (priceCardInDollar[round][i] *10 *(10**20)*(1000-discount)) / (EtherPrice*1000);
                    prices[i] = amountinWei;
                } else {
                    uint256 amountinWei = (priceCardInDollar[round][i] *(i + 1) *(10**20)*(1000-discount)) / (EtherPrice*1000);
                    prices[i] = amountinWei;
                }
            } else {            
                if (i == 5) {
                    uint256 amount = (priceCardInDollar[round][i] *10 *(10**decimal)*(1000-discount))/1000;
                    prices[i] = amount;
                } else {
                    uint256 amount = (priceCardInDollar[round][i] *(i + 1) *(10**decimal)*(1000-discount))/1000;
                    prices[i] = amount;
                }
            }
        }
        return prices;
    }

    function getNextTokenId() external view returns (uint256) {
        return _gloablId.current();
    }
    
    function totalSupply() external view returns (uint256) {
        return NFTCount;
    }                       

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    } 

    function _beforeTokenTransfer( address from, address to, uint256 tokenId  ) internal override {
        if(from != address(0) && to!= address(0)){
            if (!stopTransfer[0] && (tokenId >= 0 && tokenId <= 494)) {
                revert("Owner has paused the transfer for this round");
            }   
            if (!stopTransfer[1] && (tokenId >= 495 && tokenId <= 844)) {
                revert("Owner has paused the transfer for this round");
            }    
            if (!stopTransfer[2] &&(tokenId >= 845 && tokenId <= 1344)) {
                revert("Owner has paused the transfer for this round");
            }   
            if (!stopTransfer[3] &&(tokenId >= 1345 && tokenId <= 2094)) {
                revert("Owner has paused the transfer for this round");
            }    
            if (!stopTransfer[4] && (tokenId >= 2095 && tokenId <= 3135)){
                revert("Owner has paused the transfer for this round");
            }   
            if (!stopTransfer[5] && (tokenId >= 3136 && tokenId <= 4279)) {
                revert("Owner has paused the transfer for this round");
            }   
            if (!stopTransfer[6] &&(tokenId >= 4280 && tokenId <= 5423)) {
                revert("Owner has paused the transfer for this round");
            }
            if (!stopTransfer[7] &&(tokenId >= 5424 && tokenId <= 6567)) {
                revert("Owner has paused the transfer for this round");
            }
            if (!stopTransfer[8] &&(tokenId >= 6568 && tokenId <= 7711)) {
                revert("Owner has paused the transfer for this round");
            }
            if (!stopTransfer[9] &&(tokenId >= 7712 && tokenId <= 8855)) {
                revert("Owner has paused the transfer for this round");
            }
            if (!stopTransfer[10] &&(tokenId >= 8856 && tokenId <= 9999)) {
                revert("Owner has paused the transfer for this round");
            }
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721,AccessControl,ERC2981) returns (bool){
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }
}