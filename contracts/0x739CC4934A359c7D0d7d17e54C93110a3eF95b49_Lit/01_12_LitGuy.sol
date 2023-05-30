// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Lit is ERC721("LitGuy", "FLAMES") {
    string public baseURI;
    bool public isSaleActive;
    uint256 public circulatingSupply;
    address public owner = msg.sender;
    uint256 public itemPrice = 0.01 ether;
    uint256 public itemPricePresale = 0.01 ether;
    uint256 public constant totalSupply = 10_000;

    address public lab = 0xBa34F93DBadd48111982a049f6244507C3276ab8;
    address public deployer = 0xADDaF99990b665D8553f08653966fa8995Cc1209;

    bool public isFireListActive;
    uint256 public fireListMaxMint = 20;
    mapping(address => bool) public onFireList;
    mapping(address => uint256) public fireListClaimedBy;

    ////////////////////
    //   FIRELIST    //
    ////////////////////
    function addToFireList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++)
            onFireList[addresses[i]] = true;
    }

    function removeFromFireList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++)
            onFireList[addresses[i]] = false;
    }

    ////////////////////
    //    PRESALE     //
    ////////////////////

    // Mint multiple NFTs at once
    function preLightUp(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(isFireListActive, "Firelist is not active");
        require(onFireList[msg.sender], "You are not on the firelist");
        require(
            fireListClaimedBy[msg.sender] + _howMany <= fireListMaxMint,
            "Exceeds max allowed"
        );
        require(
            msg.value >= _howMany * itemPricePresale,
            "Send more ETH"
        );

        fireListClaimedBy[msg.sender] += _howMany;

        for (uint256 i = 0; i < _howMany; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    ////////////////////
    //  PUBLIC SALE   //
    ////////////////////

    // Mint multiple NFTs at once
    function lightUp(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(
            isSaleActive,
            "Sale is not active"
        );
        require(_howMany > 0 && _howMany <= 20, "Light Up min 1, max 20");
        require(msg.value >= _howMany * itemPrice, "Wrong amount of ETH");

        for (uint256 i = 0; i < _howMany; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    //////////////////////////
    // Only Owner Methods   //
    //////////////////////////

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function stopCypher() external onlyOwner {
        isSaleActive = false;
    }

    function startCypher() external onlyOwner {
        isSaleActive = true;
    }

    function setIsFireListActive(bool _isFireListActive) external onlyOwner {
        isFireListActive = _isFireListActive;
    }

    // Owner can withdraw ETH from here
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 _90_percent = (balance * 0.90 ether) / 1 ether;
        uint256 _10_percent = (balance * 0.10 ether) / 1 ether;

        payable(msg.sender).transfer(_90_percent);
        payable(lab).transfer(_10_percent);
    }

    // set Firelist limit
    function setFireListMaxMint(uint256 _fireListMaxMint) external onlyOwner {
        fireListMaxMint = _fireListMaxMint;
    }

    // Change price in case ETH moons
    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    // Change presale price in case ETH moons
    function setPricePresale(uint256 _itemPricePresale) external onlyOwner {
        itemPricePresale = _itemPricePresale;
    }

    // Update metadata
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    ///////////////////
    // Query Method  //
    ///////////////////

    function tokensRemaining() public view returns (uint256) {
        return totalSupply - circulatingSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    ///////////////////
    //  Helper Code  //
    ///////////////////

    modifier tokensAvailable(uint256 _howMany) {
        require(_howMany <= tokensRemaining(), "Try minting less tokens");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}