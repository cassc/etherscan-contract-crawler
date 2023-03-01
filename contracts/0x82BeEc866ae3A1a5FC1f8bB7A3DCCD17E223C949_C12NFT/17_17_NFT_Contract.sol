// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilter.sol";

contract C12NFT is ERC1155, ERC2981, ERC1155Supply, DefaultOperatorFilterer, Ownable  {

    using Strings for uint256;

    string private baseURI;

    uint256 public Max_Community_Mint = 1200;
    // uint256 public communitySupply;
    IERC20 public Carbon12;
    
    uint256 public NativeCost = 0.091 ether; 
    uint256 public TokenCost = 2250 * 10**18;  //2250 C12

    string public suffix = ".json";

    string public constant name = "Carbon 12 Impact Dao NFT";
    string public constant symbol = "C12DAO";

    address relayer;
    bool public paused = true;

    modifier onlyRelayer {
        require(msg.sender == relayer,"Error:Caller Must be Authorized!");
        _;
    }
    
    modifier MintCompliance(uint amount) {
        require(communitySupply() + amount <= Max_Community_Mint,"Error: Max Mint Limit Exceeded!");
        _;
    }

    constructor() ERC1155("") {
        Carbon12 = IERC20(0x65526D2B86fF1aC0a3a789FC6fF9C36d35673F1B);
    }

    // Only for Community Nft
    function publicNativeMint(uint256 amount) public payable MintCompliance(amount){
        require(!paused,"Error: Minting is Paused!");
        require(msg.value >= amount * NativeCost,"Invalid Cost");
        _mint(msg.sender, 2, amount, "");  // 2 represent the community token
    }

    function publicTokenMint(uint256 Nftamount) public MintCompliance(Nftamount){
        require(!paused,"Error: Minting is Paused!");
        uint subtotal = Nftamount * TokenCost;
        Carbon12.transferFrom(msg.sender, address(this), subtotal);
        _mint(msg.sender, 2, Nftamount, "");
    }

    function relayerMint(address account, uint amount) public onlyRelayer MintCompliance(amount){
        require(!paused,"Error: Minting is Paused!");
        _mint(account, 2, amount, "");
    }   

    function mint(address account, uint256 id, uint256 amount)
        public
        onlyOwner
    {   
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, "");
    }

    function airdrop(address[] calldata to, uint256[] memory id, uint256[] memory amount) 
        public
        onlyOwner
    {
        require(to.length == id.length,"Length Mismatch");
        require(to.length == amount.length,"Length Mismatch");
        for(uint i = 0; i < to.length; i++) {
            _mint(to[i], id[i], amount[i], "");
        }
    }

    function uri(
        uint256 _tokenId
    )
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(exists(_tokenId),"ERC1155: Token Id Not Exists!");
        return string(abi.encodePacked(baseURI, _tokenId.toString() , suffix));
    }

    function setUri(
        string memory _URI
    )
        external
        onlyOwner
    {
        baseURI = _URI;
    }

    function communitySupply() public view returns (uint) {
        return totalSupply(2);
    }

    function setPaused(bool _status) external onlyOwner() {
        paused = _status;
    }

    function setCostNative(uint256 _newCost) external onlyOwner() {
        NativeCost = _newCost;
    }

    //Set in Wei
    function setCostToken(uint256 _newCost) external onlyOwner() {
        TokenCost = _newCost;
    }

    function setCommunitySupply(uint _newSupply) external onlyOwner() {
        // require(communitySupply < _newSupply,"Error: Count Must be greater than Already Minted!");
        Max_Community_Mint = _newSupply;
    }

    function setRelayer(address _newWallet) external onlyOwner() {
        relayer = _newWallet;
    }

    function setToken(address _newToken) external onlyOwner() {
        Carbon12 = IERC20(_newToken);
    }

    function withdrawFunds() external onlyOwner() {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawTokens(address token) external onlyOwner() {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender,balance);
    }

    function transferTokens(address from, address to, uint id, uint amount) public onlyOwner() {
        require (id==0 || id==1, "Can only transfer F12 or Advisor tokens");
        _safeTransferFrom(from, to, id, amount, '');
    }

    function batchtransferTokens(address[] calldata from, address to, 
        uint id, uint amount
    ) 
        public 
        onlyOwner() 
    {
        require (id==0 || id==1, "Error: Can only transfer F12 or Advisor tokens!");
        for(uint i = 0; i < from.length; i++) {
            _safeTransferFrom(from[i], to, id, amount, '');
        }
    }

    // ========================= Opensea Filters ============================

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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}