// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract GoldByStefaniaPinci is ERC1155, AccessControl, ERC1155Supply {
    
    // =============== //
    //  === Fields === //
    // =============== //

    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 immutable public ticketID = 0;
    IERC1155 public ticketContract;
    string private _contractUri;

    mapping(uint256 => string) private _urls;
    mapping(uint256 => uint256) private _prices;
    mapping(uint256 => uint256) private _maxSupply;
    mapping(uint256 => bool) private _mintable;


    // =========================== //
    // === Modifiers Functions === //
    // =========================== //

    modifier ticketCheck(address account){
        uint256 ticketSupply = ticketContract.balanceOf(account, ticketID);
        require(ticketSupply > 0);
        _;
    }

    modifier supplyCheck(uint256 tokenID, uint256 amount) {
        uint256 maxSupply = getMaxSupply(tokenID);
        uint256 currentSupply = totalSupply(tokenID);
        require(maxSupply > 0 && currentSupply + amount <= maxSupply);
        _;
    }

    modifier supplyCheckBatch(uint256[] memory tokenIDs, uint256[] memory amounts) {
        require(tokenIDs.length == amounts.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            uint256 tokenID = tokenIDs[i];
            uint256 amount = amounts[i];
            uint256 maxSupply = getMaxSupply(tokenID);
            uint256 currentSupply = totalSupply(tokenID);
            require(maxSupply > 0 && currentSupply + amount <= maxSupply);
        }
        _;
    }

    modifier priceCheck(uint256 value, uint256 tokenID, uint256 amount) {
        uint256 price = getPrice(tokenID);
        require(value >= price * amount);
        _;
    }

    modifier priceCheckBatch(uint256 value, uint256[] memory tokenIDs, uint256[] memory amounts) {
        require(tokenIDs.length == amounts.length);
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            uint256 tokenID = tokenIDs[i];
            uint256 amount = amounts[i];
            uint256 price = getPrice(tokenID);
            totalPrice += price * amount;
        }
        require(value >= totalPrice);
        _;
    }

    modifier mintCheck(uint256 tokenID){
        require(_mintable[tokenID]);
        _;
    }

    modifier mintCheckBatch(uint256[] memory tokenIDs){
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(_mintable[i]);
        }
        _;
    }


    // ======================== //
    // === Public Functions === //
    // ======================== //

    function publicMint(uint256 tokenID, uint256 amount) 
        external
        payable 
        ticketCheck(msg.sender) 
        mintCheck(tokenID) 
        supplyCheck(tokenID, amount)
        priceCheck(msg.value, tokenID, amount) {

            _mint(msg.sender, tokenID, amount, "");
    }

    function publicMintBatch(uint256[] memory ids, uint256[] memory amounts) 
        public 
        payable 
        ticketCheck(msg.sender)
        mintCheckBatch(ids) 
        supplyCheckBatch(ids, amounts) 
        priceCheckBatch(msg.value, ids, amounts){

            _mintBatch(msg.sender, ids, amounts, "");
    }

    function getPrice(uint256 tokenID) public view returns(uint256) {
        return _prices[tokenID];
    }

    function getMaxSupply(uint256 tokenID) public view returns(uint256) {
        return _maxSupply[tokenID];
    }

    function getMintState(uint256 tokenID) public view returns(bool) {
        return _mintable[tokenID];
    }

    function contractURI() public view returns (string memory) {
      return _contractUri;
    }


    // ======================= //
    // === Owner Functions === //
    // ======================= //

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function initBatch(
        address to, 
        string memory contractUri,
        address ticketAddress,
        uint256[] memory ids, 
        uint256[] memory prices,
        uint256[] memory maxSupplies, 
        string[] memory uris,
        uint256[] memory amounts 
    ) public onlyRole(MINTER_ROLE) {
        setTicketAddress(ticketAddress);
        setContractURI(contractUri);

        setPriceBatch(ids, prices);
        setMaxSupplyBatch(ids, maxSupplies);
        setUriBatch(ids, uris);
        
        ownerMintBatch(to, ids, amounts);
    }

    function withdraw() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent);
    }

    // === Mint Functions

    function ownerMint(address account, uint256 id, uint256 amount) public supplyCheck(id, amount) onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, "");
    }

    function ownerMintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public supplyCheckBatch(ids, amounts) onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, "");
    }

    // === Set Functions

    function setTicketAddress(address ticketAddress) public onlyRole(SETTER_ROLE) {
        ticketContract = IERC1155(ticketAddress);
    }

    function setUri(uint256 tokenID, string memory newUri) external onlyRole(SETTER_ROLE) {
        _urls[tokenID] = newUri;
    }

    function setUriBatch(uint256[] memory tokenIDs, string[] memory newUris) public onlyRole(SETTER_ROLE) {
        require(tokenIDs.length == newUris.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) _urls[tokenIDs[i]] = newUris[i];
    }

    function setPrice(uint256 tokenID, uint256 price) external onlyRole(SETTER_ROLE) {
        _prices[tokenID] = price;
    }

    function setPriceBatch(uint256[] memory tokenIDs, uint256[] memory prices) public onlyRole(SETTER_ROLE) {
        require(tokenIDs.length == prices.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) _prices[tokenIDs[i]] = prices[i];
    }

    function setMaxSupply(uint256 tokenID, uint256 supply) external onlyRole(SETTER_ROLE) {
        _maxSupply[tokenID] = supply;
    }

    function setMaxSupplyBatch(uint256[] memory tokenIDs, uint256[] memory amounts) public onlyRole(SETTER_ROLE) {
        require(tokenIDs.length == amounts.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) _maxSupply[tokenIDs[i]] = amounts[i];
    }

    function setMintState(uint256 tokenID, bool state) external onlyRole(SETTER_ROLE) {
        _mintable[tokenID] = state;
    }

    function setMaxSupplyBatch(uint256[] memory tokenIDs, bool[] memory states) public onlyRole(SETTER_ROLE) {
        require(tokenIDs.length == states.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) _mintable[tokenIDs[i]] = states[i];
    }

    function setContractURI(string memory newUri) public onlyRole(SETTER_ROLE) {
      _contractUri = newUri;
    }


    // ========================= //
    // === Ovrride Functions === //
    // ========================= //

    function uri(uint256 tokenID) public view virtual override returns (string memory) {
        return _urls[tokenID];
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply){
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}