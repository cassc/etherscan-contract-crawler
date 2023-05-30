// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IFancyBears.sol";
import "./interfaces/IHoneyJars.sol";
import "./interfaces/IHoneyToken.sol";
import "./interfaces/IHoneyVesting.sol";
import "./interfaces/IFancyBearTraits.sol";
import "./interfaces/IFancyBearHoneyConsumption.sol";

contract FancyTraitSale is AccessControlEnumerable {

    struct TokenSaleData {
        uint256 price;
        uint256 counter;
        uint256 maxSupply;
        bool saleActive;
    }

    struct PurchaseData {
        uint256[] fancyBear; 
        uint256[] amountToSpendFromBear;
        uint256[] honeyJars;
        uint256[] amountToSpendFromHoneyJars;
        uint256 amountToSpendFromWallet;
        uint256[] traitTokenIds;
        uint256[] amountPerTrait;
    }

    using SafeMath for uint256;
    using SafeERC20 for IHoneyToken;

    bytes32 public constant SALE_MANAGER_ROLE = keccak256("SALE_MANAGER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    mapping(uint256 => TokenSaleData) public tokenSaleData;

    IFancyBears public fancyBearsContract;
    IHoneyJars public honeyJarsContract;
    IHoneyToken public honeyTokenContract;
    IHoneyVesting public honeyVestingContract;
    IFancyBearTraits public fancyBearTraitsContract;
    IFancyBearHoneyConsumption public fancyBearHoneyConsumptionContract;

    event SaleDataUpdated(uint256 indexed _tokenId);
    event PriceUpdated(uint256 indexed _tokenId, uint256 _price);
    event CounterCleared(uint256 indexed _tokenId);
    event MaxSupplyUpdated(uint256 indexed _tokenId, uint256 _maxSupply);
    event SaleToggled(uint256 indexed _tokenId, bool _saleActive);
    event SaleDataDeleted(uint256 indexed _tokenId);
    event Withdraw(address _destination, uint256 _amount);

    constructor(
        IFancyBears _fancyBearsContract,
        IHoneyJars _honeyJarsContract,
        IHoneyToken _honeyTokenContract,
        IHoneyVesting _honeyVestingContract,
        IFancyBearTraits _fancyBearTraitsContract,
        IFancyBearHoneyConsumption _fancyBearHoneyConsumptionContract
    ) 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        fancyBearsContract = _fancyBearsContract;
        honeyJarsContract = _honeyJarsContract;
        honeyTokenContract = _honeyTokenContract;
        honeyVestingContract = _honeyVestingContract;
        fancyBearTraitsContract = _fancyBearTraitsContract;
        fancyBearHoneyConsumptionContract = _fancyBearHoneyConsumptionContract;

    }

    function purchaseTraits(PurchaseData calldata purchaseData) public {

        uint256 totalHoneyRequired;
        uint256 totalHoneySubmitted = purchaseData.amountToSpendFromWallet;

        require(
            purchaseData.fancyBear.length <= 1,
            "purchaseTraits: cannot submit more than one fancy bear"
        );

        require(
            purchaseData.amountToSpendFromBear.length == purchaseData.fancyBear.length,
            "purchaseTraits: fancy bear and amount to spend must match in length"
        );

        if(purchaseData.fancyBear.length == 1){

            require(
                fancyBearsContract.tokenByIndex(purchaseData.fancyBear[0].sub(1)) == purchaseData.fancyBear[0]
            );

            if(purchaseData.amountToSpendFromBear[0] > 0){
                require(
                    fancyBearsContract.ownerOf(purchaseData.fancyBear[0]) == msg.sender,
                    "purchaseTraits: caller must own fancy bear if spending honey in bear"
                );

                totalHoneySubmitted += purchaseData.amountToSpendFromBear[0];
            }
        }
        
        require(
            purchaseData.traitTokenIds.length > 0, "purchaseTraits: must request at least 1 trait"
        );

        require(
            purchaseData.traitTokenIds.length == purchaseData.amountPerTrait.length,
            "purchaseTraits: trait token ids and amounts must match in length"
        );

        for(uint256 i = 0; i < purchaseData.traitTokenIds.length; i++) {
            
            require(
                tokenSaleData[purchaseData.traitTokenIds[i]].saleActive,
                "purchaseTraits: trait is not available for sale"
            );
    
            require(
                tokenSaleData[purchaseData.traitTokenIds[i]].counter.add(purchaseData.amountPerTrait[i]) <= tokenSaleData[purchaseData.traitTokenIds[i]].maxSupply,
                "purchaseTraits: request exceeds supply of trait"
            );

            totalHoneyRequired += (tokenSaleData[purchaseData.traitTokenIds[i]]).price.mul(purchaseData.amountPerTrait[i]);

            tokenSaleData[purchaseData.traitTokenIds[i]].counter += purchaseData.amountPerTrait[i];
        }

        require(
            purchaseData.honeyJars.length == purchaseData.amountToSpendFromHoneyJars.length, 
            "purchaseTraits: honey jar ids and amounts to spend must match in length"
        );
        
        for(uint256 i = 0; i < purchaseData.honeyJars.length; i++) {
            require(
                honeyJarsContract.ownerOf(purchaseData.honeyJars[i]) == msg.sender,
                "purchaseTraits: caller must be owner of all honey jars"
            );

            totalHoneySubmitted += purchaseData.amountToSpendFromHoneyJars[i];
        }

        require(
            totalHoneyRequired == totalHoneySubmitted, 
            "purchaseTraits: caller must submit the required amount of honey"
        );

        if(purchaseData.fancyBear.length == 1 && purchaseData.amountToSpendFromBear[0] > 0) {
           
            honeyVestingContract.spendHoney(
                purchaseData.fancyBear,
                purchaseData.amountToSpendFromBear,
                purchaseData.honeyJars,
                purchaseData.amountToSpendFromHoneyJars
            );

        }
        else {
            honeyVestingContract.spendHoney(
                new uint256[](0),
                new uint256[](0),
                purchaseData.honeyJars,
                purchaseData.amountToSpendFromHoneyJars);
        }

        fancyBearTraitsContract.mintBatch(
            msg.sender,
            purchaseData.traitTokenIds,
            purchaseData.amountPerTrait,
            ""
        );

        if(purchaseData.fancyBear.length == 1){
            fancyBearHoneyConsumptionContract.consumeHoney(purchaseData.fancyBear[0], totalHoneyRequired);
        }

        if(purchaseData.amountToSpendFromWallet > 0){
            honeyTokenContract.safeTransferFrom(msg.sender, address(this), purchaseData.amountToSpendFromWallet);
        }
        
    }

    function updateSaleData(uint256 _tokenId, TokenSaleData calldata _tokenSaleData) public onlyRole(SALE_MANAGER_ROLE) {
        tokenSaleData[_tokenId] = _tokenSaleData;
        emit SaleDataUpdated(_tokenId);
    }

    function updateSaleDataBulk(
        uint256[] calldata _tokenIds, 
        TokenSaleData[] calldata _tokenSaleData
    ) 
        public 
        onlyRole(SALE_MANAGER_ROLE) 
    {
        require(
            _tokenIds.length == _tokenSaleData.length, 
            "updateSaleDataBulk: arrays must match in length"
        );
        for(uint256 i = 0; i < _tokenIds.length; i++){
            tokenSaleData[_tokenIds[i]] = _tokenSaleData[i];
            emit SaleDataUpdated(_tokenIds[i]);
        }
       
    }

    function updatePrice(uint256[] calldata _tokenIds, uint256[] calldata _prices) public onlyRole(SALE_MANAGER_ROLE) {
        require(_tokenIds.length == _prices.length, "updatePrice: token Ids and prices array must match in length");
        for(uint256 i = 0; i < _tokenIds.length; i++){
            tokenSaleData[_tokenIds[i]].price = _prices[i];
            emit PriceUpdated(_tokenIds[i], _prices[i]);
        }
    }

    function clearCounter(uint256[] calldata _tokenIds) public onlyRole(SALE_MANAGER_ROLE) {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            tokenSaleData[_tokenIds[i]].counter = 0;
            emit CounterCleared(_tokenIds[i]);
        }
    }

    function updateMaxSupply(uint256[] calldata _tokenIds, uint256[] calldata _maxSupplies) public onlyRole(SALE_MANAGER_ROLE) {
        require(_tokenIds.length == _maxSupplies.length, "updatePrice: token Ids and max supplies array must match in length");
        for(uint256 i = 0; i < _tokenIds.length; i++){
            require(
                _maxSupplies[i] >= tokenSaleData[_tokenIds[i]].counter, 
                "updateMaxSupply: cannot set max supply below item counter"
            );

            tokenSaleData[_tokenIds[i]].maxSupply = _maxSupplies[i];
            emit MaxSupplyUpdated(_tokenIds[i], _maxSupplies[i]);
        }
    }

    function toggleSale(uint256[] calldata _tokenIds) public onlyRole(SALE_MANAGER_ROLE) {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            tokenSaleData[_tokenIds[i]].saleActive = !tokenSaleData[_tokenIds[i]].saleActive;
            emit SaleToggled(_tokenIds[i], tokenSaleData[_tokenIds[i]].saleActive);
        } 
    }

    function deleteSaleData(uint256[] calldata _tokenIds) public onlyRole(SALE_MANAGER_ROLE) {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            delete(tokenSaleData[_tokenIds[i]]);
            emit SaleDataDeleted(_tokenIds[i]); 
        }
    }

    function withdraw(address _beneficiary, uint256 _amount) public onlyRole(WITHDRAW_ROLE) {
        honeyTokenContract.safeTransfer(_beneficiary, _amount);
        emit Withdraw(_beneficiary, _amount);
    }

}