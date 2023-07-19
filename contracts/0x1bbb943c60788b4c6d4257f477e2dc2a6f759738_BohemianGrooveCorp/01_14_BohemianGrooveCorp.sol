// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// ██╗    ██╗██╗  ██╗ ██████╗     ██╗███████╗    ▄▄███▄▄· █████╗ ███╗   ███╗ ██████╗ ████████╗    ██████╗
// ██║    ██║██║  ██║██╔═══██╗    ██║██╔════╝    ██╔════╝██╔══██╗████╗ ████║██╔═══██╗╚══██╔══╝    ╚════██╗
// ██║ █╗ ██║███████║██║   ██║    ██║███████╗    ███████╗███████║██╔████╔██║██║   ██║   ██║         ▄███╔╝
// ██║███╗██║██╔══██║██║   ██║    ██║╚════██║    ╚════██║██╔══██║██║╚██╔╝██║██║   ██║   ██║         ▀▀══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝    ██║███████║    ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝   ██║         ██╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝╚══════╝    ╚═▀▀▀══╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝         ╚═╝

/**
 * @title Dillom
 * WhoIsSamot - an 1155 contract for  Bohemian Groove Corp
 */
contract BohemianGrooveCorp is ERC1155Supply, Ownable , ReentrancyGuard{

    using Strings for string;

    struct itemData {
        uint256 maxSupply;
        uint256 maxToMint;
        uint256 maxPerWallet;
        uint256 publicPrice;
        uint256 whitelistPrice;
        uint256 ownerPrice;
        bool saleIdActive;
    }

    uint[] public ogItems;

    mapping(uint256 => itemData) public idStats ; 

    // Whitelist
    bytes32 private merkleRoot;

    string public name;
    string public symbol;
    string public baseURI= "https://samotclub.mypinata.cloud/ipfs/Qmddgn3YUHRyw5tAHd5uibMnAsb2e7Cbd7Tos66kQrRJqh/";

    bool public publicSaleIsActive = false;
    bool public ownerSaleIsActive = false;
    bool public whitelistSaleIsActive = false;

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }

    function uri(uint256 _id) override public view returns (string memory){
        require(exists(_id), "ERC1155: NONEXISTENT_TOKEN");
        return(
            string(abi.encodePacked(baseURI,Strings.toString(_id),".json"))
        );
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }

    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    function addOgItem (uint256 _id) external onlyOwner{
        require(exists(_id),"Id not existent");
        ogItems.push(_id);
    }

    function removeOgItem(uint _index) external onlyOwner {
        require(_index < ogItems.length);
        ogItems[_index] = ogItems[ogItems.length-1];
        ogItems.pop();
    }

    function balanceOgRole(address _address) public view returns (uint256 balance){
        uint256 totalBalance = 0;
        for(uint256 i=0; i<ogItems.length;i++){
            totalBalance += balanceOf(_address,ogItems[i]);
        }
        return totalBalance;
    }

    // Whitelist
    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function verify(
        bytes32[] calldata merkleProof,
        address sender
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function setSaleIdActive(bool _idActive, uint256 _id) external onlyOwner {
        idStats[_id].saleIdActive = _idActive;
    }

    function setMaxToMint(uint256 _maxToMint, uint256 _id) external onlyOwner {
        idStats[_id].maxToMint = _maxToMint;
    }

    function setMaxPerWallet(uint256 _maxPerWallet, uint256 _id) external onlyOwner {
        idStats[_id].maxPerWallet = _maxPerWallet;
    }

    function setMaxSupply(uint256 _maxSupply, uint256 _id) external onlyOwner {
        idStats[_id].maxSupply = _maxSupply;
    }

    function setPublicPrice(uint256 _publicPrice, uint256 _id) external onlyOwner {
        idStats[_id].publicPrice = _publicPrice;
    }
    
    function setWhitelistPrice(uint256 _whitelistPrice, uint256 _id) external onlyOwner {
        idStats[_id].whitelistPrice = _whitelistPrice;
    }

    function setOwnerPrice(uint256 _ownerPrice, uint256 _id) external onlyOwner {
        idStats[_id].ownerPrice = _ownerPrice;
    }

    function flipPublicSaleState() public onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function flipWhitelistSaleState() public onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function flipOwnerSaleState() public onlyOwner {
        ownerSaleIsActive = !ownerSaleIsActive;
    }

    function createItem(uint256 _id, uint256 _maxPerWallet, uint256 _maxToMint,uint256 _maxSupply,uint256 _publicPrice,uint256 _ownerPrice,uint256 _whitelistPrice,bool _saleIdActive ) external onlyOwner{
        idStats[_id].maxPerWallet = _maxPerWallet;
        idStats[_id].maxToMint = _maxToMint;
        idStats[_id].maxSupply = _maxSupply;
        idStats[_id].publicPrice = _publicPrice;
        idStats[_id].ownerPrice = _ownerPrice;
        idStats[_id].whitelistPrice = _whitelistPrice;
        idStats[_id].saleIdActive = _saleIdActive;
    }

    function publicSale(uint256 _quantity,uint256 _id) external payable {
        require(publicSaleIsActive, "Public sale is not active.");
        require(idStats[_id].saleIdActive, "Sale not available for this item now.");
        require(idStats[_id].publicPrice * _quantity <= msg.value,
                "ETH sent is incorrect."
            );
        require(
            totalSupply(_id) + _quantity <= idStats[_id].maxSupply,  
            "Minting limit reached."
        );
        require(
                balanceOf(msg.sender,_id) + _quantity <= idStats[_id].maxPerWallet, 
                "Exceeds wallet limit."
            );
        require(
                _quantity <= idStats[_id].maxToMint,
                "Exceeds NFT per transaction limit."
            );

        _mint(msg.sender,_id,_quantity,"");
    }


    function whitelistSale(uint256 _quantity,uint256 _id, bytes32[] calldata _merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));        
        require(whitelistSaleIsActive, "Whitelist sale is not active.");
        require(idStats[_id].saleIdActive, "Sale not available for this item now.");
        require(idStats[_id].whitelistPrice * _quantity <= msg.value,
                "ETH sent is incorrect."
            );
        require(
            totalSupply(_id) + _quantity <= idStats[_id].maxSupply,  
            "Minting limit reached."
        );
        require(
                balanceOf(msg.sender,_id) + _quantity <= idStats[_id].maxPerWallet, 
                "Exceeds wallet limit."
            );
        require(
                _quantity <= idStats[_id].maxToMint,
                "Exceeds NFT per transaction limit."
            );
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "User is not in the whitelist");
        _mint(msg.sender,_id,_quantity,"");
    }

    function ownerSale(uint256 _quantity,uint256 _id) external payable {
        require(ownerSaleIsActive, "Owner sale is not active.");
        require(idStats[_id].saleIdActive, "Sale not available for this item now.");
        require(balanceOgRole(msg.sender) > 0 , "You are not an Og user");
        require(idStats[_id].ownerPrice * _quantity <= msg.value,
                "ETH sent is incorrect."
            );
        require(
            totalSupply(_id) + _quantity <= idStats[_id].maxSupply,  
            "Minting limit reached."
        );
        require(
                balanceOf(msg.sender,_id) + _quantity <= idStats[_id].maxPerWallet, 
                "Exceeds wallet limit."
            );
        require(
                _quantity <= idStats[_id].maxToMint,
                "Exceeds NFT per transaction limit."
            );
        _mint(msg.sender,_id,_quantity,"");
    }


    function reserveItem(uint256 _quantity,uint256 _id,address _address) external onlyOwner{
        _mint(_address,_id,_quantity,"");
    }    

    function withdraw() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        
        (bool bgc, ) = payable(0x66C8f004Eb65F9361341Ecf7ac71EE6C7c834722).call{value: (80 * contractBalance) / 100}("");
        require(bgc, "Transfer failed");

        (bool sc, ) = msg.sender.call{value: address(this).balance}("");
        require(sc, "Transfer failed.");
    }
}