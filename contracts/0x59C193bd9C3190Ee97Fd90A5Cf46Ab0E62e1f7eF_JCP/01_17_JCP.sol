//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./DefaultOperatorFilterer.sol";

error InvalidId();
error SaleInactive();
error PreSaleInactive();
error ClaimInactive();
error SoldOut();
error InvalidPrice();
error WithdrawFailed();
error InvalidQuantity();
error InvalidProof();
error AlreadyClaimed();
error InvalidBatchMint();
error MaxSupplyExceeded();

contract JCP is ERC1155, Ownable, ERC2981, DefaultOperatorFilterer {
        
    string public name;
    string public symbol;

    enum State{CLOSED, OPEN, PRESALE, CLAIM}

    struct Item {
        uint id;
        uint price;
        uint presalePrice;
        uint maxPerWallet;
        uint presaleMaxPerWallet;
        uint maxPerTransaction;
        uint presaleMaxPerTransaction;
        uint supply;
        uint presaleSupply;
        uint mintedSupply;
        State state;
        uint claimedSupply;
        uint claimCost;
        bytes32 merkleRoot;
        mapping(address => bool) whitelistClaimed;
    }


    mapping(uint => Item) public items;
    mapping(uint => string) public tokenURI;
    mapping(address =>  mapping(uint256 => uint256)) private addressMintBalance;
    
    address[] private withdrawAddresses;
    uint256[] private withdrawPercentages;

    uint public numItems = 0;

    constructor(
        string memory _name,
        string memory _symbol,
        uint96 _royaltyAmount,
        address _royaltyAddress
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        _setDefaultRoyalty(_royaltyAddress, _royaltyAmount);
    }

    function createItem(uint _price, uint _presalePrice, uint _maxPerWallet, uint _maxPerTransaction,
        uint _presaleMaxPerWallet, uint _presaleMaxPerTransaction, uint _presaleSupply, uint _supply) 
        external onlyOwner{
        
        Item storage newItem = items[numItems];
        numItems++;

        newItem.id = numItems;
        newItem.price = _price;
        newItem.presalePrice = _presalePrice;
        newItem.maxPerWallet = _maxPerWallet;
        newItem.presaleMaxPerWallet = _presaleMaxPerWallet;
        newItem.maxPerTransaction = _maxPerTransaction;
        newItem.presaleMaxPerTransaction = _presaleMaxPerTransaction;
        require(_presaleSupply <= _supply);
        newItem.presaleSupply = _presaleSupply;
        newItem.supply = _supply;
        newItem.state = State.CLOSED;
    }

    //// minting

    modifier mintCompliance(uint _id, uint _mintAmount) {
        if(_id >= numItems) revert InvalidId();
        if(_mintAmount + (items[_id].mintedSupply + items[_id].claimedSupply)> items[_id].supply) revert MaxSupplyExceeded();
        _;
    }

    function mint(uint _id, uint _amount) external payable mintCompliance(_id, _amount){
        if(items[_id].state != State.OPEN) revert SaleInactive();
        if(_amount < 0 && _amount > items[_id].maxPerTransaction) revert InvalidQuantity();
        if(msg.value < items[_id].price * _amount) revert InvalidPrice();
        if(addressMintBalance[msg.sender][_id] + _amount > items[_id].maxPerWallet) revert InvalidQuantity();
        addressMintBalance[msg.sender][_id] += _amount;
        items[_id].mintedSupply += _amount;
        
        _mint(msg.sender, _id, _amount, "");
    }

    function presaleMint(uint _id, uint256 _amount, bytes32[] calldata merkleProof) external payable mintCompliance(_id, _amount){
        if(items[_id].state != State.PRESALE) revert PreSaleInactive();
        if(_amount < 0 && _amount > items[_id].presaleMaxPerTransaction) revert InvalidQuantity();
        if(msg.value < items[_id].presalePrice * _amount) revert InvalidPrice();
        if(items[_id].whitelistClaimed[msg.sender]) revert AlreadyClaimed();
        if(!MerkleProof.verify(merkleProof, items[_id].merkleRoot, keccak256(abi.encodePacked(msg.sender, _amount)))) revert InvalidProof();
        if(addressMintBalance[msg.sender][_id] + _amount > items[_id].presaleMaxPerWallet) revert InvalidQuantity();
        addressMintBalance[msg.sender][_id] += _amount;
        items[_id].mintedSupply += _amount;
        items[_id].whitelistClaimed[msg.sender] = true;
        
        _mint(msg.sender, _id, _amount, "");
    }

    function teamMint(address _to, uint _id, uint _amount) external onlyOwner {
        _mint(_to, _id, _amount, "");
    }

    function teamMintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");
    }

    //// burning

    function burnToClaim(uint _id, uint _amount) external payable {
        if(items[_id].state != State.CLAIM) revert ClaimInactive();
        if(msg.value < items[_id].claimCost * _amount) revert InvalidPrice();
        addressMintBalance[msg.sender][_id] -= _amount;
        items[_id].mintedSupply -= _amount;
        items[_id].claimedSupply += _amount;
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external onlyOwner {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    //// getters & setters

    function setURI(uint _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint _id) public override view returns (string memory) {
        return tokenURI[_id];
    }

    function setPrice(uint _id, uint _amount) external onlyOwner {
        items[_id].price = _amount;
    }

    function getPrice(uint _id) public view returns(uint) {
        return items[_id].price;
    }

    function setPresalePrice(uint _id, uint _presalePrice) external onlyOwner {
        items[_id].presalePrice = _presalePrice;
    }

    function getPresalePrice(uint _id) public view returns(uint) {
        return items[_id].presalePrice;
    }

    function setMaxPerWallet(uint _id, uint _maxPerWallet) external onlyOwner {
        items[_id].maxPerWallet = _maxPerWallet;
    }

    function getMaxPerWallet(uint _id) public view returns(uint) {
        return items[_id].maxPerWallet;
    }

    function setPresaleMaxPerWallet(uint _id, uint _presaleMaxPerWallet) external onlyOwner {
        items[_id].presaleMaxPerWallet = _presaleMaxPerWallet;
    }

    function getPresaleMaxPerWallet(uint _id) public view returns(uint) {
        return items[_id].presaleMaxPerWallet;
    }

    function setMaxPerTransaction(uint _id, uint _maxPerTransaction) external onlyOwner {
        items[_id].maxPerTransaction = _maxPerTransaction;
    }

    function getMaxPerTransaction(uint _id) public view returns(uint) {
        return items[_id].maxPerTransaction;
    }

    function setPresaleMaxPerTransaction(uint _id, uint _presaleMaxPerTransaction) external onlyOwner {
        items[_id].presaleMaxPerTransaction = _presaleMaxPerTransaction;
    }

    function getPresaleMaxPerTransaction(uint _id) public view returns(uint) {
        return items[_id].presaleMaxPerTransaction;
    }

    function setPresaleSupply(uint _id, uint _presaleSupply) external onlyOwner {
        items[_id].presaleSupply = _presaleSupply;
    }

    function getPresaleSupply(uint _id) public view returns(uint) {
        return items[_id].presaleSupply;
    }

    function setSupply(uint _id, uint _supply) external onlyOwner {
        items[_id].supply = _supply;
    }

    function getSupply(uint _id) public view returns(uint) {
        return items[_id].supply;
    }

    function setState(uint _id, State _state) external onlyOwner {
        items[_id].state = _state;
    }

    function getState(uint _id) public view returns(State) {
        return items[_id].state;
    }

    function getWhitelistClaimed(uint _id, address _adre) public view returns(bool) {
        return items[_id].whitelistClaimed[_adre];
    }

    function getMintedSupply(uint _id) public view returns(uint) {
        return items[_id].mintedSupply;
    }

    function setMerkleRoot(uint _id, bytes32 _merkleRoot) external onlyOwner {
        items[_id].merkleRoot = _merkleRoot;
    }

    function setClaimCost(uint _id, uint _claimCost) external onlyOwner {
        items[_id].claimCost = _claimCost;
    }

    function getClaimCost(uint _id) public view returns(uint) {
        return items[_id].claimCost;
    }

    function getClaimedSupply(uint _id) public view returns(uint) {
        return items[_id].claimedSupply;
    }

    function setWithdrawAddresses(address[] memory _withdrawAddresses, uint256[] memory _withdrawPercentages) external onlyOwner {
        withdrawAddresses = _withdrawAddresses;
        withdrawPercentages = _withdrawPercentages;
    }

    ////withdraw & royalty

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        if (!success) revert WithdrawFailed();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        for (uint256 i; i < withdrawAddresses.length; i++) {
            _withdraw(withdrawAddresses[i], (balance * withdrawPercentages[i]) / 100);
        }
    }

    function setDefaulRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 tokenId, bytes memory data)
        public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, id, tokenId, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public override onlyAllowedOperator {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}