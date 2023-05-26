// SPDX-License-Identifier: MIT

//                                                                                                                        
//                                                              @@@@@@@@@@@@@@@       @@@@@@@@@@@@      @@@@@@@@@@@@@@@@  
//                              @@@@@@                          @@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@
//                            (@                         @      @@@@@        @@@@@  @@@@@     @@@@@   @@@@@          @@@@@
// @@@@@@@@@@@@@  @@     @@  @@@@@@  @  @@@@@@ @@@@@@  @@@@@@   @@@@@        @@@@@  @@@@@@@@@@@@@@@@  @@@@@          @@@@@
// @     @@    @@  @@   @@    (@     @  @@    ,@/        @      @@@@@       @@@@@@ @@@@@@@@@@@@@@@@@  @@@@@@        @@@@@@
// @     @@    @@   @@ @@     (@     @  @@          @@   @      @@@@@@@@@@@@@@@@   @@@@@        @@@@@  @@@@@@@@@@@@@@@@@@ 
// @     @@    @@    @@@      (@     @  @@     @@@@@@@   @@@@   @@@@@@@@@@@@@     @@@@@         @@@@@     @@@@@@@@@@@@    
//                   @@                                                                                                   
//

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract DAOphin is ERC1155, Ownable, ReentrancyGuard, RevokableDefaultOperatorFilterer  {    

    string public metadata = "ipfs://QmRuiSNTCMqcmGv4LzE4ZAwW7oU7utJKtuhsAGDCHYx8Tz/";
    string public name_;
    string public symbol_;  

    uint256 public pricePerToken = 0.015 ether;

    address public signer = 0x2f2A13462f6d4aF64954ee84641D265932849b64;
    address public burnContract;

    address private paymentAddress = 0xa69B6935B0F38506b81224B4612d7Ea49A4B0aCC;
    uint256 public paymentFee = 0.0006 ether;

    bool public listingsAllowed = false;
    bool public sale = false;
    bool public claim = false;
    bool public refund = false;

    bool private airdropEnabled = true;

    uint256 public totalMinted;
    uint256 public totalRefunded;
    uint256 public totalBurned;

    uint256 id = 1;
    uint256 maxPerTx = 25;

    mapping(address => mapping(uint256 => bool)) public claimed;
    mapping(address => uint256) public minted;

    constructor() ERC1155(metadata)  {
        name_ = "DAOphin";
        symbol_ = "MFD";
    }
    
    function mintTokens(uint256 tokenAmount) public payable nonReentrant {
        require(sale, "Sale is off");
        require(tokenAmount <= maxPerTx, "Too many in One Transaction");

        uint256 fee = paymentFee * tokenAmount;

        uint256 totalCost = (pricePerToken * tokenAmount) + fee;

        require(msg.value >= totalCost,"Price Not Enough");

        totalMinted += tokenAmount;
        minted[msg.sender] += tokenAmount;

        _mint(msg.sender, id, tokenAmount, "");

        (bool payFee, ) = payable(paymentAddress).call{value: fee}(""); require(payFee);
    }

    function claimTokens(bytes calldata _voucher,  uint256 tokenAmount) public payable nonReentrant {        
        require(claim, "Claim is off");
        require(!claimed[msg.sender][id], "Already claimed");
        require(tokenAmount < maxPerTx, "Max per tx hit");
        claimed[msg.sender][id] = true;

        uint256 totalCost = paymentFee * tokenAmount;

        if(tokenAmount > maxPerTx) {
            totalCost = paymentFee * maxPerTx;
        }

        require(msg.value >= totalCost, "Not enough eth");

        totalMinted += tokenAmount;

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, id, tokenAmount));
        require(_verifySignature(signer, hash, _voucher), "Invalid voucher");

        _mint(msg.sender, id, tokenAmount, "");

        (bool payFee, ) = payable(paymentAddress).call{value: totalCost}(""); require(payFee);

    }

    function airdropTokens(address [] calldata _wallets, uint256 amount) public onlyOwner {
        require(airdropEnabled, "Airdrop functionality is permanently disabled");

        totalMinted += amount;

        for(uint i = 0; i < _wallets.length; i++)
            _mint(_wallets[i], id, amount, "");
    }

   function refundTokens(address wallet, uint256 tokenId, uint256 tokenAmount) public nonReentrant  {
        require(refund, "Refund is off");
        require(wallet == msg.sender || isApprovedForAll(wallet, msg.sender), "Not allowed");
        require(minted[msg.sender] >= tokenAmount, "Not enough tokens to refund");

        _burn(wallet, tokenId, tokenAmount);

        (bool refundSender, ) = payable(msg.sender).call{value: tokenAmount * pricePerToken}(""); require(refundSender);

        minted[msg.sender] -= tokenAmount;
        totalRefunded += tokenAmount;
    }

    function burnForAddress(address _address) external {
        require(msg.sender == burnContract, "Invalid burner address");
        _burn(_address, id, 1);
        totalBurned += 1;
    }

    function setBurnContract(address _contract) external onlyOwner {
        burnContract = _contract;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function setListingAllowed() public onlyOwner {
        listingsAllowed = true;
    } 

    function setMetadata(string calldata _uri) public onlyOwner {
        metadata = _uri;
    }

    function setMaxTx(uint256 _amount) public onlyOwner {
        maxPerTx = _amount;
    } 

    function setSale(bool _state) public onlyOwner {
        sale = _state;
    }

    function setPricePerToken(uint256 price) public onlyOwner {
        pricePerToken = price;
    }

    function setRefund(bool _state) public onlyOwner {
        refund = _state;
    } 

    function setClaim(bool _state) public onlyOwner {
        claim = _state;
    }

    function setPaymentAddress(address _paymentAddress) public onlyOwner {
        paymentAddress = _paymentAddress;
    }

    function setPaymentFee(uint256 amount) public onlyOwner {
        paymentFee = amount;
    }

    function permanentlyDisableAirdrops() public onlyOwner {
        airdropEnabled = false;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function totalSupply() public view returns (uint){
        return totalMinted - totalRefunded - totalBurned;
    }

    function withdraw() public payable onlyOwner {
        require(!sale, "Sale is on");
        require(!refund, "Refunds are on");
        (bool success, ) = payable(msg.sender).call {value: address(this).balance}("");
        require(success);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        require(listingsAllowed, "Listings aren't allowed yet");
        
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