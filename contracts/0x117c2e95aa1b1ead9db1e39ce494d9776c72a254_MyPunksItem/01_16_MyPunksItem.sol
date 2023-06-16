// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MyPunksFace.sol";

/**

  __  ____   _____ _   _ _  _ _  _____ 
 |  \/  \ \ / / _ \ | | | \| | |/ / __|
 | |\/| |\ V /|  _/ |_| | .` | ' <\__ \
 |_|  |_| |_| |_|  \___/|_|\_|_|\_\___/
                                       
        Customize Your Own Punks                                        

 */

contract MyPunksItem is ERC721A, AccessControl, ReentrancyGuard {
    // AccessControl
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public immutable collectionSize;
    uint256 public immutable amountReserved;
    uint256 public reserveMinted;

    bool public stakingPaused;
    bool public mintingPaused;

    // Contract Configs
    string private _currentBaseURI;

    address public faceContract;
    address private owner;

    struct ItemSale {
        uint32 saleStartTime;
        uint64 price;
        uint256 amountSale;
        uint256 amountMinted;
        bool isPublicSale;
    }

    mapping(uint256 => ItemSale) public itemSales;
    uint256 public currentSaleRound;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountReserved_,
        bool stakingPaused_,
        bool mintingPaused_
    ) ERC721A("MyPunks Item", "MPITEM", maxBatchSize_) {
        collectionSize = collectionSize_;
        amountReserved = amountReserved_;
        stakingPaused = stakingPaused_;
        mintingPaused = mintingPaused_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        owner = msg.sender;
    }

    modifier mintable() {
        require(mintingPaused == false, "Mint is disabled");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * ======================================================================================
     *
     *  Token Minting
     *
     * ======================================================================================
     */

    function mintItem(uint256 _amount) external payable mintable callerIsUser {
        ItemSale memory currentSale = itemSales[currentSaleRound];
        require(
            (currentSale.amountMinted + _amount <= currentSale.amountSale) &&
                (totalSupply() < collectionSize),
            "Items are all minted"
        );
        require(
            currentSale.saleStartTime != 0 &&
                currentSale.saleStartTime <= block.timestamp,
            "Time Locked"
        );
        if (!currentSale.isPublicSale) {
            MyPunksFace Face = MyPunksFace(faceContract);
            require(
                Face.balanceOf(msg.sender) > 0,
                "You must own at least one face to mint"
            );
        }
        _safeMint(msg.sender, _amount);
        refundIfOver(currentSale.price * _amount);
        itemSales[currentSaleRound].amountMinted += _amount;
    }

    /**
        @dev Reserved Token Minting
    */
    function mintReserved(address _to, uint256 _amount)
        external
        mintable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(totalSupply() < collectionSize, "All Items are minted");
        require(
            reserveMinted + _amount < amountReserved + 1,
            "Reserved are all minted"
        );
        _safeMint(_to, _amount);
        reserveMinted += _amount;
    }

    /**
        @dev This is used to plugin other contract to mint the item, eg. staking contract
    */
    function mintByMinter(address _to, uint256 _amount)
        external
        mintable
        onlyRole(MINTER_ROLE)
    {
        require(totalSupply() < collectionSize, "All Items are minted");
        _safeMint(_to, _amount);
    }

    function refundIfOver(uint256 _price) private {
        require(msg.value >= _price, "Need to send more ETH.");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    function getCurrentSale() external view returns (ItemSale memory) {
        return itemSales[currentSaleRound];
    }

    /**
     * ======================================================================================
     *
     *  Item Equippment (Staking)
     *
     * ======================================================================================
     */

    function getOwnedTokens(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_address);
        uint256[] memory result = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            result[i] = tokenOfOwnerByIndex(_address, i);
        }
        return result;
    }

    function stakeItem(uint256[] memory _tokenIds, uint256 _faceId) external {
        require(stakingPaused == false, "Contract Paused");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            bytes memory data = abi.encodePacked(_faceId);
            safeTransferFrom(msg.sender, faceContract, _tokenIds[i], data);
        }
    }

    function unstakeItem(address _to, uint256 _tokenId) external {
        require(stakingPaused == false, "Contract Paused");
        require(
            msg.sender == faceContract,
            "This method can only be called by Face Contract."
        );
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    /**
     * ======================================================================================
     *
     *  Contract Configurations & Overrides
     *
     * ======================================================================================
     */

    function setItemSale(
        uint256 _index,
        uint256 _amountSale,
        uint256 _amountMinted,
        uint64 _price,
        uint32 _saleStartTime,
        bool _isPublicSale
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        itemSales[_index].amountSale = _amountSale;
        itemSales[_index].amountMinted = _amountMinted;
        itemSales[_index].price = _price;
        itemSales[_index].saleStartTime = _saleStartTime;
        itemSales[_index].isPublicSale = _isPublicSale;
    }

    function pauseMint(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintingPaused = _paused;
    }

    function pauseStaking(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingPaused = _paused;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string calldata _URI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _currentBaseURI = _URI;
    }

    function setFaceContract(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        faceContract = _address;
    }

    function setMinter(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, _address);
    }

    function numberMinted(address _owner) external view returns (uint256) {
        return _numberMinted(_owner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawMoney()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}