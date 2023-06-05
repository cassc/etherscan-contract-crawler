// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract KANDI is ERC1155, Ownable, ReentrancyGuard, RevokableDefaultOperatorFilterer {    

    string public metadata = "ipfs://QmPVrQoWbELaXVdEp8YisEV1qtaaZEYVgxvL2BRHgxQhMW/";
    string public name_;
    string public symbol_;  

    uint256 public MAX_SUPPLY = 1500;
    uint256 public PASS_SUPPLY = 1250;
    uint256 public VIP_SUPPLY = 250;

    address private signer = 0x2f2A13462f6d4aF64954ee84641D265932849b64;
    address private crossMint = 0xdAb1a1854214684acE522439684a145E62505233; 
    address public BurnContract;

    uint256 public mintTracker;
    uint256 public passTracker;
    uint256 public vipTracker;

    uint256 public burnTracker;

    bool public burnActive = false;
    bool public publicActive = false;
    bool public allowlistActive = false;
    uint256 maxMintPerWallet = 1;

    enum MintType { PASS_ALLOWLIST, PASS_PUBLIC, VIP_ALLOWLIST, VIP_PUBLIC }

    mapping(MintType => mapping(address => uint256)) public didWalletMintAmount;
    mapping(MintType => uint256) private mintId;
    mapping(MintType => uint256) private mintPrice;
    mapping(MintType => bool) private mintActive;

    constructor() ERC1155(metadata) {
        name_ = "KANDI";
        symbol_ = "KANDI";

        mintId[MintType.PASS_ALLOWLIST] = 0;
        mintId[MintType.PASS_PUBLIC] = 0;
        mintId[MintType.VIP_ALLOWLIST] = 1;
        mintId[MintType.VIP_PUBLIC] = 1;

        mintPrice[MintType.PASS_ALLOWLIST] = 0.039 ether;
        mintPrice[MintType.PASS_PUBLIC] = 0.039 ether;
        mintPrice[MintType.VIP_ALLOWLIST] = 0.16 ether;
        mintPrice[MintType.VIP_PUBLIC] = 0.16 ether;

        mintActive[MintType.PASS_ALLOWLIST] = false;
        mintActive[MintType.PASS_PUBLIC] = false;
        mintActive[MintType.VIP_ALLOWLIST] = false;
        mintActive[MintType.VIP_PUBLIC] = false;
    }

    function airdrop(uint256[] calldata tokenAmount, address[] calldata wallet, uint256 tokenId) public onlyOwner {
        require(tokenId <= 1, "Nonexistent id");
        
        for(uint256 i = 0; i < wallet.length; i++){ 
            require(mintTracker + tokenAmount[i] <= MAX_SUPPLY, "Minted Out");

            mintTracker += tokenAmount[i];
            _mint(wallet[i], tokenId, tokenAmount[i], "");

            if(tokenId == 0) passTracker += tokenAmount[i];
            else vipTracker += tokenAmount[i];
        }
    }

    function mint(address wallet, uint256 tokenAmount, bytes calldata voucher, bool isCrossmint, MintType mintType) public payable nonReentrant {
    
        uint256 checkWallet = didWalletMintAmount[mintType][wallet];
        uint256 tokenId = mintId[mintType];
        uint256 price = mintPrice[mintType];
        bool active = mintActive[mintType];

        require(tokenAmount > 0, "Non zero value");
        require(msg.sender == tx.origin, "EOA only");
        require(active, "This phase is not active");
        require(checkWallet + tokenAmount <= maxMintPerWallet, "Already Minted in this Phase");

        require(mintTracker + tokenAmount <= MAX_SUPPLY, "Sold Out");

        if(isCrossmint) require(msg.sender == crossMint, "Crossmint only");
        else require(msg.sender == wallet, "Not your voucher");

        if(mintType == MintType.PASS_ALLOWLIST || mintType == MintType.VIP_ALLOWLIST) {
            bytes32 hash = keccak256(abi.encodePacked(wallet));
            require(_verifySignature(signer, hash, voucher), "Invalid voucher");
        }
        
        if(mintType == MintType.PASS_ALLOWLIST || mintType == MintType.PASS_PUBLIC) {
            require(passTracker + tokenAmount <= PASS_SUPPLY, "Phase sold out");
            passTracker += tokenAmount;
        }
        else {
            require(vipTracker + tokenAmount <= VIP_SUPPLY, "Phase sold out");
            vipTracker += tokenAmount;
        }

        require(msg.value >= price * tokenAmount, "Ether value sent is not correct");
        
        didWalletMintAmount[mintType][wallet] += tokenAmount;
        mintTracker += tokenAmount;

        _mint(msg.sender, tokenId, tokenAmount, "");
    }

    function burnToken(uint256 _qty, address _addr, uint256 tokenId) external {
        require(burnActive, "Burn is not active");
        require(msg.sender == BurnContract, "Must be from future contract");
        _burn(_addr, tokenId, _qty);
        burnTracker += _qty;
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) internal pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
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

    function setMintActive(MintType mintType, bool state) public onlyOwner {
        mintActive[mintType] = state;
    }

    function setMintId(MintType mintType, uint256 newId) public onlyOwner {
        mintId[mintType] = newId;
    }

    function setPrice(MintType mintType, uint256 newPrice) public onlyOwner {
        mintPrice[mintType] = newPrice;
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

    function getAmountMintedPerType(MintType mintType, address _address) public view returns (uint256) {
        return didWalletMintAmount[mintType][_address];
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