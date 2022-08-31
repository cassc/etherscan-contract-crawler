//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract dohdohcandyshop is ERC1155Supply, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public name;
    string public symbol;

    uint256 public maxSupply;
    uint256 public maxPaidPerAddr;
    uint256 public price;

    bool public claimOpen;
    bool public saleOpen;
    bytes32 private merkleRoot;

    mapping(address => uint256) public claimedCounter;
    mapping(address => uint256) public paidCounter;

    constructor(string memory _name, string memory _symbol) ERC1155("ipfs://") {
        name = _name;
        symbol = _symbol;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //paid accessors
    function setCandyPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setSaleStatus() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function setMaxPaidPerAddr(uint256 _maxPaidPerAddr) external onlyOwner {
        maxPaidPerAddr = _maxPaidPerAddr;
    }

    function setMaxSupplyCandy(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    //claim accessors
    function setClaimStatus() external onlyOwner {
        claimOpen = !claimOpen;
    }

    //merkleroot
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // metadata
    function setTokenURI(string calldata _uri) external onlyOwner {
        _setURI(_uri);
    }

    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    super.uri(_tokenId),
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    //dev mint
    function ownerMint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner {
        _mint(_to, _id, _amount, "");
    }

    //doh doh holder claim
    function claimCandy(
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint256 _maxAmount
    ) public callerIsUser nonReentrant {
        address sender = _msgSender();

        require(claimOpen, "Claim is closed");
        require(
            _amount <= _maxAmount - claimedCounter[sender],
            "You have insufficient candy to claim"
        );
        require(_amount > 0, "Must claim more than 0 tokens");
        require(_verify(_merkleProof, sender, _maxAmount), "Invalid proof");

        claimedCounter[sender] += _amount;
        _mint(sender, 0, _amount, "");
    }

    function _verify(
        bytes32[] calldata _merkleProof,
        address _sender,
        uint256 _maxAmount
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(_sender, _maxAmount.toString())
        );
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    //buy candy
    function buyCandy(uint256 _amount)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(_amount > 0, "Must mint more than 0 tokens");
        require(saleOpen, "Paid public mint is closed");
        require(
            paidCounter[msg.sender] + _amount <= maxPaidPerAddr,
            "Exceeds max per address"
        );
        require(price * _amount == msg.value, "Incorrect funds");
        require(totalSupply(0) + _amount <= maxSupply, "Reached max supply");

        paidCounter[msg.sender] = paidCounter[msg.sender] + _amount;
        _mint(msg.sender, 0, _amount, "");
    }

    //burn candy
    function burnCandy(uint256[] calldata _ids, uint256[] calldata _amounts)
        external
        onlyOwner
    {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    //create and edit shop items
    mapping(uint256 => ShopItem) public ShopItems;

    struct ShopItem {
        uint256 currentSupply;
        uint256 maxSupply;
        uint256 maxPerAddr;
        uint256 candyPrice;
        bool saleActive;
    }

    /**
     * @notice Create a ShopItem.
     * @param _id The token id to set this item to. IDs start at 1 to avoid metadata conflicts with candy.
     * @param _shopItem ["currentSupply", "maxSupply", "maxPerAddr", "candyPrice", "saleActive"]
     */

    function createShopItem(uint256 _id, ShopItem calldata _shopItem)
        external
        onlyOwner
    {
        require(_id != 0, "ID of 0 is reserved for candy");
        require(
            ShopItems[_id].maxSupply == 0,
            "Shop item with that id already exists"
        );
        ShopItems[_id] = _shopItem;
    }

    //update max supply of item
    function updateMaxSupplyItem(uint256 _id, uint256 _maxSupply)
        external
        onlyOwner
    {
        require(ShopItems[_id].maxSupply > 0, "Shop item does not exist");
        ShopItems[_id].maxSupply = _maxSupply;
    }

    //update price (in candy) of item
    function updatePriceItem(uint256 _id, uint256 _newPrice)
        external
        onlyOwner
    {
        require(ShopItems[_id].maxSupply > 0, "Shop item does not exist");
        ShopItems[_id].candyPrice = _newPrice;
    }

    //update max per address
    function updateMaxPerAddrItem(uint256 _id, uint256 _newMaxPerAddr)
        external
        onlyOwner
    {
        require(ShopItems[_id].maxSupply > 0, "Shop item does not exist");
        ShopItems[_id].maxPerAddr = _newMaxPerAddr;
    }

    //toggle item sale status
    function updateSaleStatusItem(uint256 _id) external onlyOwner {
        require(ShopItems[_id].maxSupply > 0, "Shop item does not exist");
        ShopItems[_id].saleActive = !ShopItems[_id].saleActive;
    }

    //address=>id=>amount address has bought
    mapping(address => mapping(uint256 => uint256)) public numAlreadyBought;

    //buy shop items with candy
    function buyShopItems(
        uint256 _candyTotal,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external nonReentrant {
        require(
            _ids.length == _amounts.length,
            "The length of ids and amounts is not the same"
        );

        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                ShopItems[_ids[i]].maxSupply > 0,
                "This item doesn't exist"
            );
            require(
                numAlreadyBought[msg.sender][_ids[i]] + _amounts[i] <=
                    ShopItems[_ids[i]].maxPerAddr,
                "Exceeds max per address for this item"
            );
            require(
                ShopItems[_ids[i]].saleActive == true,
                "This item is not currently for sale"
            );
            require(
                totalSupply(_ids[i]) + _amounts[i] <=
                    ShopItems[_ids[i]].maxSupply,
                "Exceeds max supply for this item"
            );
            //calculate total price here
            totalPrice += ShopItems[_ids[i]].candyPrice * _amounts[i];
        }
        require(totalPrice == _candyTotal, "Wrong amount of candy sent");

        //transfer candy to owner wallet and mint shop items
        safeTransferFrom(msg.sender, owner(), 0, _candyTotal, "");
        _mintBatch(msg.sender, _ids, _amounts, "");

        //update number address has bought and update supply of item
        for (uint256 j = 0; j < _ids.length; j++) {
            numAlreadyBought[msg.sender][_ids[j]] += _amounts[j];
            ShopItems[_ids[j]].currentSupply = totalSupply(_ids[j]);
        }
    }

    //admin
    function withdrawAll(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }
}