// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../Interface/ISpaceCows.sol";

import "./Modules/Whitelisted.sol";
import "./Modules/Random.sol";

contract Sale is Ownable, Whitelisted {
    using Random for Random.Manifest;
    Random.Manifest internal _manifest;

    uint256 public whitelistSalePrice;
    uint256 public publicSalePrice;
    uint256 public maxMintsPerTxn;
    uint256 public maxPresaleMintsPerWallet;
    uint256 public maxTokenSupply;
    uint256 public maxSales;
    uint256 public tribeId;
    uint256 private salesCounter;

    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _allowBuys;

    enum SaleState {
        CLOSED,
        PRESALE,
        OPEN
    }
    SaleState public saleState;

    ISpaceCows public spaceCows;

    constructor(
        uint256 _whitelistSalePrice,
        uint256 _publicSalePrice,
        uint256 _maxSupply,
        uint256 _maxMintsPerTxn,
        uint256 _maxPresaleMintsPerWallet,
        uint256 _maxSales,
        uint256 _tribeId
    ) {
        whitelistSalePrice = _whitelistSalePrice;
        publicSalePrice = _publicSalePrice;
        maxTokenSupply = _maxSupply;
        maxMintsPerTxn = _maxMintsPerTxn;
        maxPresaleMintsPerWallet = _maxPresaleMintsPerWallet;
        maxSales = _maxSales;
        salesCounter = 1;
        tribeId = _tribeId;
        _manifest.setup(_maxSupply);

        saleState = SaleState(0);
    }

    /**
    =========================================
    Owner Functions
    @dev these functions can only be called 
        by the owner of contract. some functions
        here are meant only for backup cases.
        separate maxpertxn and maxperwallet for
        max flexibility
    =========================================
    */
    function setWhitelistPrice(uint256 _newPrice) external onlyOwner {
        whitelistSalePrice = _newPrice;
    }

    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        publicSalePrice = _newPrice;
    }

    function setMaxTokenSupply(uint256 _newMaxSupply) external onlyOwner {
        maxTokenSupply = _newMaxSupply;
    }

    function setMaxMintsPerTxn(uint256 _newMaxMintsPerTxn) external onlyOwner {
        maxMintsPerTxn = _newMaxMintsPerTxn;
    }

    function setMaxPresaleMintsPerWallet(uint256 _newLimit) external onlyOwner {
        maxPresaleMintsPerWallet = _newLimit;
    }

    function setTribeId(uint256 _newId) external onlyOwner {
        tribeId = _newId;
    }

    function setMaxSale(uint256 _newLimit) external onlyOwner {
        maxSales = _newLimit;
    }

    function resetSalesCounter() external onlyOwner {
        salesCounter = 1;
    }

    function setSpaceCowsAddress(address _newNftContract) external onlyOwner {
        spaceCows = ISpaceCows(_newNftContract);
    }

    function setSaleState(uint256 _state) external onlyOwner {
        saleState = SaleState(_state);
    }

    function setWhitelistRoot(bytes32 _newWhitelistRoot) external onlyOwner {
        _setWhitelistRoot(_newWhitelistRoot);
    }

    function givewayReserved(address _user, uint256 _amount) external onlyOwner {
        uint256 totalSupply = spaceCows.totalSupply();
        require(totalSupply + _amount < maxTokenSupply + 1, "Not enough tokens!");
        
        uint256 index = 0;
        uint256[] memory tmpTokenIds = new uint256[](_amount);
        while (index < _amount) {
            uint256 tokenId = _manifest.draw();
            bool doExists = spaceCows.exists(tokenId);

            if (!doExists) {
                tmpTokenIds[index] = tokenId;
                index++;
            }
        }

        spaceCows.cowMint(_user, tmpTokenIds);
        salesCounter += _amount;
    }

    function withdraw() external onlyOwner {
        uint256 marketingPayment = address(this).balance / 4;
        require(marketingPayment > 0, "Empty balance");
        sendToMarketing(marketingPayment);

        uint256 teamPayment = address(this).balance / 4;
        require(teamPayment > 0, "Empty balance");
        sendToOwners(teamPayment);
    }
    
    /**
    =========================================
    Mint Functions
    @dev these functions are relevant  
        for minting purposes only
    =========================================
    */
    function whitelistPurchase(uint256 numberOfTokens, bytes32[] calldata proof)
    external
    payable
    onlyWhitelisted(msg.sender, address(this), proof) {
        address user = msg.sender;
        uint256 buyAmount = whitelistSalePrice * numberOfTokens;

        require(saleState == SaleState.PRESALE, "Allow list is not active");
        require(numberOfTokens + _allowBuys[user][tribeId][1] < maxPresaleMintsPerWallet + 1, "Exceeded max available to purchase");
        require(getSalesCounter() + numberOfTokens < maxSales + 1, "Purchase would exceed max tokens");
        require(msg.value > buyAmount - 1, "Ether value sent is not correct");

        uint256 index = 0;
        uint256[] memory tmpTokenIds = new uint256[](numberOfTokens);
        while (index < numberOfTokens) {
            uint256 tokenId = _manifest.draw();
            bool doExists = spaceCows.exists(tokenId);

            if (!doExists) {
                tmpTokenIds[index] = tokenId;
                index++;
            }
        }

        spaceCows.cowMint(user, tmpTokenIds);
        _allowBuys[user][tribeId][1] += numberOfTokens;
        salesCounter += numberOfTokens;
    }

    function publicPurchase(uint256 numberOfTokens)
    external
    payable {
        address user = msg.sender;
        uint256 buyAmount = publicSalePrice * numberOfTokens;

        require(saleState == SaleState.OPEN, "Sale must be active to mint tokens");
        require(numberOfTokens + _allowBuys[user][tribeId][2] < maxMintsPerTxn + 1, "Exceeded max available to purchase");
        require(getSalesCounter() + numberOfTokens < maxSales + 1, "Purchase would exceed max tokens");
        require(msg.value > buyAmount - 1, "Ether value sent is not correct");

        uint256 index = 0;
        uint256[] memory tmpTokenIds = new uint256[](numberOfTokens);
        while (index < numberOfTokens) {
            uint256 tokenId = _manifest.draw();
            bool doExists = spaceCows.exists(tokenId);

            if (!doExists) {
                tmpTokenIds[index] = tokenId;
                index++;
            }
        }

        spaceCows.cowMint(user, tmpTokenIds);
        _allowBuys[user][tribeId][2] += numberOfTokens;
        salesCounter += numberOfTokens;
    }

    /**
    ============================================
    Public & External Functions
    @dev functions that can be called by anyone
    ============================================
    */
    function remaining() public view returns (uint256) {
        return _manifest.remaining();
    }

    function getSaleState() public view returns (uint256) {
        return uint256(saleState);
    }

    function getSalesCounter() public view returns (uint256) {
        return salesCounter - 1;
    }

    function getAllowPublicPurchase(address _user) public view returns (uint256) {
        return maxMintsPerTxn - _allowBuys[_user][tribeId][2];
    }

    function getAllowWhitelistPurchase(address _user) public view returns (uint256) {
        return maxPresaleMintsPerWallet - _allowBuys[_user][tribeId][1];
    }

    /**
    ============================================
    Internal Functions
    @dev functions that can be use inside the contract
    ============================================
    */
    function sendToMarketing(uint256 payment) internal {
        sendValue(payable(0x12691AEd0668A44411066C518B4DAE6fd3E8F274), payment);
    } 

    function sendToOwners(uint256 payment) internal {
        sendValue(payable(0xced6ACCbEbF5cb8BD23e2B2E8B49C78471FaAe20), payment);
        sendValue(payable(0x4386103c101ce063C668B304AD06621d6DEF59c9), payment);
        sendValue(payable(0x19Bb04164f17FF2136A1768aA4ed22cb7f1dAa00), payment);
        sendValue(payable(0x910040fA04518c7D166e783DB427Af74BE320Ac7), payment);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}