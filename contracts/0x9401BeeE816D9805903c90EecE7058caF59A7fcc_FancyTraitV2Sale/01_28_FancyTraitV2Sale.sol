// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IFancyBears.sol";
import "./interfaces/IHoneyJars.sol";
import "./interfaces/IHoneyVesting.sol";
import "./interfaces/IHive.sol";
import "./interfaces/IHoneyToken.sol";
import "./interfaces/IFancyTraitsV2.sol";
import "./interfaces/IFancyBearStaking.sol";
import "./interfaces/IFancy721.sol";
import "./interfaces/ILevels.sol";
import "./Tag.sol";

contract FancyTraitV2Sale is AccessControlEnumerable, ReentrancyGuard {
    struct PurchaseData {
        uint256[] fancyBear;
        uint256[] amountToSpendFromBear;
        uint256[] honeyJars;
        uint256[] amountToSpendFromHoneyJars;
        address[] collectionsOnHive;
        uint256[] tokenIdsOnHive;
        uint256[] amountToSpendOnHive;
        uint256 amountToSpendFromWallet;
        uint256[] traitTokenIds;
        uint256[] amountPerTrait;
    }

    struct TokenSaleData {
        uint256 ethPrice;
        uint256 counter;
        uint256 maxSupply;
        bool saleActive;
        mapping(address => uint256) tokenPrice;
    }

    struct LevelAttributionArgs {
        address collection;
        uint256 tokenId;
    }

    struct SaleDataUpdateArgs {
        uint256 ethPrice;
        uint256 counter;
        uint256 maxSupply;
        bool saleActive;
        address[] tokenContracts;
        uint256[] tokenPrice;
    }

    using SafeMath for uint256;
    using SafeERC20 for IHoneyToken;
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    mapping(uint256 => TokenSaleData) public tokenSaleData;

    IFancyBears public fancyBearsContract;
    IHoneyToken public honeyTokenContract;
    IHoneyJars public honeyJarsContract;
    IHoneyVesting public honeyVestingContract;
    IFancyTraitsV2 public fancyTraitsV2Contract;
    ILevels public levelsContract;
    IFancyBearStaking public fancyBearStakingContract;
    IHive public hiveContract;

    // Add hive, vesting, staking contracts

    event Purchase(
        address indexed _sender,
        uint256[] _traitIds,
        uint256[] _quantities
    );

    event SaleDataUpdated(uint256 indexed _tokenId);
    event ERC20PriceUpdated(
        uint256 indexed _tokenId,
        address indexed _tokenContract,
        uint256 _price
    );
    event ETHPriceUpdated(uint256 indexed _tokenId, uint256 _price);
    event CounterCleared(uint256 indexed _tokenId);
    event MaxSupplyUpdated(uint256 indexed _tokenId, uint256 _maxSupply);
    event SaleToggled(uint256 indexed _tokenId, bool _saleActive);
    event SaleDataDeleted(uint256 indexed _tokenId);
    event WithdrawERC20(
        address _destination,
        address _tokenContract,
        uint256 _amount
    ); 
    event WithdrawETH(address _destination, uint256 _amount);

    constructor(
        IFancyBears _fancyBearsContract,
        IHoneyJars _honeyJarsContract,
        IHoneyVesting _honeyVestingContract,
        IFancyTraitsV2 _fancyTraitsV2Contract,
        IHoneyToken _honeyTokenContract,
        ILevels _levelsContract,
        IFancyBearStaking _fancyBearStakingContract,
        IHive _hiveContract
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        fancyTraitsV2Contract = _fancyTraitsV2Contract;
        honeyTokenContract = _honeyTokenContract;

        fancyBearsContract = _fancyBearsContract;
        honeyJarsContract = _honeyJarsContract;
        honeyVestingContract = _honeyVestingContract;
        levelsContract = _levelsContract;
        fancyBearStakingContract = _fancyBearStakingContract;
        hiveContract = _hiveContract;
    }

    function purchaseTraitsWithHoney(
        PurchaseData calldata purchaseData,
        LevelAttributionArgs calldata _levelAttributionArgs
    ) public {
        require(
            purchaseData.fancyBear.length <= 1,
            "purchaseTraits: cannot submit more than one fancy bear"
        );

        require(
            purchaseData.amountToSpendFromBear.length ==
                purchaseData.fancyBear.length,
            "purchaseTraits: fancy bear and amount to spend must match in length"
        );

        uint256 totalHoneyRequired;
        uint256 totalHoneySubmitted = purchaseData.amountToSpendFromWallet;

        if (purchaseData.fancyBear.length == 1) {
            require(
                fancyBearsContract.tokenByIndex(
                    purchaseData.fancyBear[0].sub(1)
                ) == purchaseData.fancyBear[0]
            );

            if (purchaseData.amountToSpendFromBear[0] > 0) {
                require(
                    fancyBearsContract.ownerOf(purchaseData.fancyBear[0]) ==
                        msg.sender ||
                        fancyBearStakingContract.getOwnerOf(
                            purchaseData.fancyBear[0]
                        ) ==
                        msg.sender,
                    "purchaseTraits: caller must own fancy bear if spending honey in bear"
                );

                totalHoneySubmitted += purchaseData.amountToSpendFromBear[0];
            }
        }

        require(
            purchaseData.traitTokenIds.length > 0,
            "purchaseTraitsWithHoney: must request at least 1 trait"
        );

        require(
            purchaseData.traitTokenIds.length ==
                purchaseData.amountPerTrait.length,
            "purchaseTraitsWithHoney: trait token ids and amounts must match in length"
        );

        for (uint256 i = 0; i < purchaseData.traitTokenIds.length; ) {

            require(
                tokenSaleData[purchaseData.traitTokenIds[i]].tokenPrice[
                    address(honeyTokenContract)
                ] != 0,
                "purchaseTraitsWithHoney: honey price not set"
            );

            require(
                tokenSaleData[purchaseData.traitTokenIds[i]].saleActive,
                "purchaseTraitsWithHoney: trait is not available for sale"
            );

            require(
                tokenSaleData[purchaseData.traitTokenIds[i]].counter.add(
                    purchaseData.amountPerTrait[i]
                ) <= tokenSaleData[purchaseData.traitTokenIds[i]].maxSupply,
                "purchaseTraitsWithHoney: request exceeds supply of trait"
            );

            totalHoneyRequired += (
                tokenSaleData[purchaseData.traitTokenIds[i]].tokenPrice[
                    address(honeyTokenContract)
                ]
            ).mul(purchaseData.amountPerTrait[i]);

            tokenSaleData[purchaseData.traitTokenIds[i]].counter += purchaseData
                .amountPerTrait[i];

            unchecked {
                i++;
            }
        }

        require(
            purchaseData.honeyJars.length ==
                purchaseData.amountToSpendFromHoneyJars.length,
            "purchaseTraits: honey jar ids and amounts to spend must match in length"
        );

        for (uint256 i = 0; i < purchaseData.honeyJars.length; ) {
            require(
                honeyJarsContract.ownerOf(purchaseData.honeyJars[i]) ==
                    msg.sender,
                "purchaseTraits: caller must be owner of all honey jars"
            );

            totalHoneySubmitted += purchaseData.amountToSpendFromHoneyJars[i];

            unchecked {
                i++;
            }
        }

        uint256 expectedLength = purchaseData.collectionsOnHive.length;

        require(
            purchaseData.tokenIdsOnHive.length == expectedLength,
            "purchaseTraits: tokenIdsOnHive array length mismatch"
        );

        require(
            purchaseData.amountToSpendOnHive.length == expectedLength,
            "purchaseTraits: amountToSpendOnHive array length mismatch"
        );

        for (uint256 i; i < expectedLength; ) {
            require(
                IFancy721(purchaseData.collectionsOnHive[i]).ownerOf(
                    purchaseData.tokenIdsOnHive[i]
                ) == msg.sender,
                "purchaseTraits: caller does not own token on collection"
            );

            totalHoneySubmitted += purchaseData.amountToSpendOnHive[i];

            unchecked {
                i++;
            }
        }

        require(
            totalHoneySubmitted == totalHoneyRequired,
            "purchaseTraits: honey required does not match honey submitted"
        );

        if (purchaseData.amountToSpendFromWallet != 0) {
            honeyTokenContract.safeTransferFrom(
                msg.sender,
                address(this),
                purchaseData.amountToSpendFromWallet
            );
        }

        
        if (
            purchaseData.fancyBear.length > 0 ||
            purchaseData.honeyJars.length > 0
        ) {
            if (
                purchaseData.amountToSpendFromBear.length > 0 &&
                purchaseData.amountToSpendFromBear[0] > 0
            ) {
                honeyVestingContract.spendHoney(
                    purchaseData.fancyBear,
                    purchaseData.amountToSpendFromBear,
                    purchaseData.honeyJars.length > 0
                        ? purchaseData.honeyJars
                        : new uint256[](0),
                    purchaseData.honeyJars.length > 0
                        ? purchaseData.amountToSpendFromHoneyJars
                        : new uint256[](0)
                );
            } else {
                honeyVestingContract.spendHoney(
                    new uint256[](0),
                    new uint256[](0),
                    purchaseData.honeyJars.length > 0
                        ? purchaseData.honeyJars
                        : new uint256[](0),
                    purchaseData.honeyJars.length > 0
                        ? purchaseData.amountToSpendFromHoneyJars
                        : new uint256[](0)
                );
            }
        }

        if (purchaseData.collectionsOnHive.length > 0) {
            hiveContract.spendHoneyFromTokenIdsOfCollections(
                purchaseData.collectionsOnHive,
                purchaseData.tokenIdsOnHive,
                purchaseData.amountToSpendOnHive
            );
        }

        if (purchaseData.fancyBear.length > 0) {
            levelsContract.consumeToken(
                address(fancyBearsContract), // collection address - Fancy Bears
                purchaseData.fancyBear[0], // Fancy Bear Token ID
                address(honeyTokenContract),
                totalHoneyRequired
            );
        } else if (_levelAttributionArgs.collection != address(0)) {

            levelsContract.consumeToken(
                _levelAttributionArgs.collection,
                _levelAttributionArgs.tokenId,
                address(honeyTokenContract),
                totalHoneyRequired
            );
        }

        fancyTraitsV2Contract.mintBatch(
            msg.sender,
            purchaseData.traitTokenIds,
            purchaseData.amountPerTrait,
            ""
        );

        emit Purchase(
            msg.sender,
            purchaseData.traitTokenIds,
            purchaseData.amountPerTrait
        );
    }

    function purchaseTraitsWithETH(
        uint256[] calldata _traitTokenIds,
        uint256[] calldata _amountPerTrait,
        LevelAttributionArgs calldata _levelAttributionArgs
    ) public payable nonReentrant {
        uint256 totalETHRequired;

        require(
            _traitTokenIds.length > 0,
            "purchaseTraitsWithETH: must request at least 1 trait"
        );

        require(
            _traitTokenIds.length == _amountPerTrait.length,
            "purchaseTraitsWithETH: trait token ids and amounts must match in length"
        );

        uint256 i;
        for (; i < _traitTokenIds.length; ) {

            require(
                tokenSaleData[_traitTokenIds[i]].ethPrice != 0,
                "purchaseTraitsWithETH: eth price not set"
            );

            require(
                tokenSaleData[_traitTokenIds[i]].saleActive,
                "purchaseTraitsWithETH: trait is not available for sale"
            );

            require(
                tokenSaleData[_traitTokenIds[i]].counter.add(
                    _amountPerTrait[i]
                ) <= tokenSaleData[_traitTokenIds[i]].maxSupply,
                "purchaseTraitsWithETH: request exceeds supply of trait"
            );

            totalETHRequired += (tokenSaleData[_traitTokenIds[i]]).ethPrice.mul(
                    _amountPerTrait[i]
                );

            tokenSaleData[_traitTokenIds[i]].counter += _amountPerTrait[i];

            unchecked {
                i++;
            }
        }

        require(
            msg.value >= totalETHRequired,
            "purchaseTraitsWithETH: incorrect amount of eth"
        );

        fancyTraitsV2Contract.mintBatch(
            msg.sender,
            _traitTokenIds,
            _amountPerTrait,
            ""
        );

        // add levels attribution

        if (_levelAttributionArgs.collection != address(0)) {
     
            levelsContract.consumeETH(
                _levelAttributionArgs.collection,
                _levelAttributionArgs.tokenId,
                totalETHRequired
            );
        }
    }

    function purchaseTraitsWithERC20(
        address _tokenContract,
        uint256[] calldata _traitTokenIds,
        uint256[] calldata _amountPerTrait,
        LevelAttributionArgs calldata _levelAttributionArgs
    ) public payable {
        uint256 totalTokensRequired;

        require(
            _tokenContract != address(0),
            "purchaseTraitsWithERC20: token contract cannot be the zero address"
        );

        require(
            _traitTokenIds.length > 0,
            "purchaseTraitsWithERC20: must request at least 1 trait"
        );

        require(
            _traitTokenIds.length == _amountPerTrait.length,
            "purchaseTraitsWithERC20: trait token ids and amounts must match in length"
        );

        uint256 i;
        for (; i < _traitTokenIds.length; ) {
            require(
                tokenSaleData[_traitTokenIds[i]].saleActive,
                "purchaseTraitsWithERC20: trait is not available for sale"
            );

            require(
                tokenSaleData[_traitTokenIds[i]].counter.add(
                    _amountPerTrait[i]
                ) <= tokenSaleData[_traitTokenIds[i]].maxSupply,
                "purchaseTraitsWithERC20: request exceeds supply of trait"
            );

            require(
                tokenSaleData[_traitTokenIds[i]].tokenPrice[_tokenContract] !=
                    0,
                "purchaseTraitsWithERC20: token price for trait not set"
            );

            totalTokensRequired += (tokenSaleData[_traitTokenIds[i]])
                .tokenPrice[_tokenContract]
                .mul(_amountPerTrait[i]);

            tokenSaleData[_traitTokenIds[i]].counter += _amountPerTrait[i];

            unchecked {
                i++;
            }
        }

        if (_levelAttributionArgs.collection != address(0)) {
  
            levelsContract.consumeToken(
                address(_levelAttributionArgs.collection),
                _levelAttributionArgs.tokenId,
                _tokenContract,
                totalTokensRequired
            );
        }

        IERC20(_tokenContract).safeTransferFrom(
            msg.sender,
            address(this),
            totalTokensRequired
        );

        fancyTraitsV2Contract.mintBatch(
            msg.sender,
            _traitTokenIds,
            _amountPerTrait,
            ""
        );

        emit Purchase(msg.sender, _traitTokenIds, _amountPerTrait);
    }

    function _updateSaleData(
        uint256 _tokenId,
        SaleDataUpdateArgs calldata _saleDataUpdateArgs
    ) internal onlyRole(MANAGER_ROLE) {
        require(
            _saleDataUpdateArgs.tokenContracts.length ==
                _saleDataUpdateArgs.tokenPrice.length,
            "updateSaleData: token array length mismatch"
        );

        tokenSaleData[_tokenId].ethPrice = _saleDataUpdateArgs.ethPrice;
        tokenSaleData[_tokenId].counter = _saleDataUpdateArgs.counter;
        tokenSaleData[_tokenId].maxSupply = _saleDataUpdateArgs.maxSupply;
        tokenSaleData[_tokenId].saleActive = _saleDataUpdateArgs.saleActive;

        uint256 i;
        for (; i < _saleDataUpdateArgs.tokenContracts.length; ) {
            tokenSaleData[_tokenId].tokenPrice[
                _saleDataUpdateArgs.tokenContracts[i]
            ] = _saleDataUpdateArgs.tokenPrice[i];

            unchecked {
                i++;
            }
        }

        emit SaleDataUpdated(_tokenId);
    }

    function updateSaleDataBulk(
        uint256[] calldata _tokenIds,
        SaleDataUpdateArgs[] calldata _saleDataUpdateArgs
    ) public onlyRole(MANAGER_ROLE) {
        require(
            _tokenIds.length == _saleDataUpdateArgs.length,
            "updateSaleDataBulk: arrays must match in length"
        );
        uint256 i;
        for (; i < _tokenIds.length; ) {
            _updateSaleData(_tokenIds[i], _saleDataUpdateArgs[i]);

            unchecked {
                i++;
            }
        }
    }

    function updateERC20Price(
        uint256[] calldata _traitTokenIds,
        address[][] calldata _tokenContracts,
        uint256[][] calldata _prices
    ) public onlyRole(MANAGER_ROLE) {
        uint256 expectedLength = _traitTokenIds.length;

        require(
            _tokenContracts.length == expectedLength,
            "updateERC20Price: token ids and token contracts do not match in length"
        );

        require(
            _prices.length == expectedLength,
            "updateERC20Price: token ids and prices do not match in length"
        );

        uint256 i;
        for (; i < _traitTokenIds.length; ) {
            require(
                _tokenContracts[i].length == _prices[i].length,
                "updateERC20Price: token contracts and prices do not match in length for token id"
            );

            uint256 j;
            for (; j < _tokenContracts[i].length; ) {
                tokenSaleData[_traitTokenIds[i]].tokenPrice[
                    _tokenContracts[i][j]
                ] = _prices[i][j];

                emit ERC20PriceUpdated(
                    _traitTokenIds[i],
                    _tokenContracts[i][j],
                    _prices[i][j]
                );

                unchecked {
                    j++;
                }
            }

            unchecked {
                i++;
            }
        }
    }

    function updateETHPrice(
        uint256[] calldata _tokenIds,
        uint256[] calldata _prices
    ) public onlyRole(MANAGER_ROLE) {
        require(
            _tokenIds.length == _prices.length,
            "updateETHPrice: token Ids and prices array must match in length"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenSaleData[_tokenIds[i]].ethPrice = _prices[i];
            emit ETHPriceUpdated(_tokenIds[i], _prices[i]);
        }
    }

    function clearCounter(uint256[] calldata _tokenIds)
        public
        onlyRole(MANAGER_ROLE)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenSaleData[_tokenIds[i]].counter = 0;
            emit CounterCleared(_tokenIds[i]);
        }
    }

    function updateMaxSupply(
        uint256[] calldata _tokenIds,
        uint256[] calldata _maxSupplies
    ) public onlyRole(MANAGER_ROLE) {
        require(
            _tokenIds.length == _maxSupplies.length,
            "updatePrice: token Ids and max supplies array must match in length"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _maxSupplies[i] >= tokenSaleData[_tokenIds[i]].counter,
                "updateMaxSupply: cannot set max supply below item counter"
            );

            tokenSaleData[_tokenIds[i]].maxSupply = _maxSupplies[i];
            emit MaxSupplyUpdated(_tokenIds[i], _maxSupplies[i]);
        }
    }

    function toggleSale(uint256[] calldata _tokenIds)
        public
        onlyRole(MANAGER_ROLE)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenSaleData[_tokenIds[i]].saleActive = !tokenSaleData[
                _tokenIds[i]
            ].saleActive;
            emit SaleToggled(
                _tokenIds[i],
                tokenSaleData[_tokenIds[i]].saleActive
            );
        }
    }

    function withdrawERC20(
        address _beneficiary,
        address[] calldata _tokenContracts,
        uint256[] calldata _amounts
    ) public onlyRole(WITHDRAW_ROLE) {
        require(
            _tokenContracts.length == _amounts.length,
            "withdrawERC20: token contracts and amounts array length mismatch"
        );

        uint256 i;
        for (; i < _tokenContracts.length; ) {
            IERC20(_tokenContracts[i]).safeTransfer(_beneficiary, _amounts[i]);
            emit WithdrawERC20(_beneficiary, _tokenContracts[i], _amounts[i]);

            unchecked {
                i++;
            }
        }
    }

    function getTokenPriceForTraitId(uint256 _traitId, address[] calldata _tokenContracts) public view returns (uint256[] memory) {
        uint256 i;
        uint256[] memory prices = new uint256[](_tokenContracts.length);

        for(; i < _tokenContracts.length;){
            prices[i] = tokenSaleData[_traitId].tokenPrice[_tokenContracts[i]];

            unchecked {
                i++;
            }
        }

        return prices;
    }

    function withdrawETH(address _beneficiary, uint256 _amount)
        public
        nonReentrant
        onlyRole(WITHDRAW_ROLE)
    {
        uint256 balance = address(this).balance;
        require(
            _amount <= balance,
            "withdrawETH: cannot withdraw more than the balance"
        );
        require(payable(_beneficiary).send(_amount));
    }
}