// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './libraries/TransferHelper.sol';
import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../node_modules/@openzeppelin/contracts/utils/Counters.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libraries/SafeMath.sol';
import './GhostBaseCollection.sol';
import './GhostNFTMarket.sol';
import './interfaces/IWETH.sol';

/*
 * This contract is used to collect sRADS stacking dividends from fee (like swap, deposit on pools or farms)
 */
contract GhostCollectionFactory is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public constant name = 'Ghost Collection Factory';
    address public admin;
    address payable public nftmarket;
    address public WETH;

    // Details about the collections
    mapping(string => bool) private _isCreateCollection;
    mapping(string => address) private _collections;

    mapping(string => bool) private _isMintedToken;
    mapping(string => uint256) private _tokenIds;

    // Details about the creators
    mapping(address => address) public creators;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;
    mapping(bytes32 => uint256) public nonces;

    /* Event */
    event CreateCollection(
        address collection,
        string name,
        string symbol,
        address creator,
        address loyalityAddress,
        uint256 creatorFee,
        uint256 refererFee
    );

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Order(address creator,address profitRecipient,address loyalityAddress,string collectionName,string collectionSymbol,string collectionUID,string name,string description,string cid,string uuid,uint256 creatorFee,uint256 refererFee,uint256 price)");
    bytes32 public constant ORDER_TYPEHASH = 0x0b16d4f2593be27625f94325263955e3bf571e1ef17c89160225bb8ac975fc81;

    struct Order {
        address creator; /* NFT creator address */
        address profitRecipient; /* Sales profit recipient */
        address loyalityAddress; /* Creator loyality recipient */
        string collectionName;
        string collectionSymbol;
        string collectionUID; /* Unique id of collection (before mint) */
        string name;
        string description;
        string cid;
        string uuid; /* tokenUID and uuid */
        uint256 creatorFee;
        uint256 refererFee;
        uint256 price;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    constructor(
        address _admin,
        address _nftmarket,
        address _wbnb
    ) {
        admin = _admin;
        nftmarket = payable(_nftmarket);
        WETH = _wbnb;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Management: Not admin');
        _;
    }

    function closeCollectionForTradingAndListing(address _collection) external onlyAdmin {
        GhostNFTMarket(nftmarket).closeCollectionForTradingAndListing(_collection);
    }

    function addCollection(
        address _collection,
        address _creator,
        address _whitelistChecker,
        uint256 _creatorFee,
        uint256 _refererFee
    ) external onlyAdmin {
        GhostNFTMarket(nftmarket).addCollection(_collection, _creator, _whitelistChecker, _creatorFee, _refererFee);
    }

    function modifyCollection(
        address _collection,
        address _creator,
        address _whitelistChecker,
        uint256 _creatorFee,
        uint256 _refererFee
    ) external onlyAdmin {
        GhostNFTMarket(nftmarket).modifyCollection(_collection, _creator, _whitelistChecker, _creatorFee, _refererFee);
    }

    function updateMinimumAndMaximumPrices(uint256 _minimumAskPrice, uint256 _maximumAskPrice) external onlyAdmin {
        GhostNFTMarket(nftmarket).updateMinimumAndMaximumPrices(_minimumAskPrice, _maximumAskPrice);
    }

    function _createCollection(
        string memory _collectionUID,
        string memory _name,
        string memory _symbol,
        address _creator,
        address _loyalityAddress,
        uint256 _creatorFee,
        uint256 _refererFee
    ) internal returns (address) {
        require(!_isCreateCollection[_collectionUID], 'Error : Already created collection.');
        _collections[_collectionUID] = address(new GhostBaseCollection(_name, _symbol, _creator, admin));
        GhostNFTMarket(nftmarket).addCollection(
            _collections[_collectionUID],
            _loyalityAddress,
            address(0),
            _creatorFee,
            _refererFee
        );
        _isCreateCollection[_collectionUID] = true;
        creators[_collections[_collectionUID]] = _creator;
        emit CreateCollection(
            _collections[_collectionUID],
            _name,
            _symbol,
            _creator,
            _loyalityAddress,
            _creatorFee,
            _refererFee
        );
        return _collections[_collectionUID];
    }

    function createCollection(
        string memory _collectionUID,
        string memory _name,
        string memory _symbol,
        address _creator,
        address _loyalityAddress,
        uint256 _creatorFee,
        uint256 _refererFee
    ) external {
        _createCollection(_collectionUID, _name, _symbol, _creator, _loyalityAddress, _creatorFee, _refererFee);
    }

    function isCreateCollection(string memory _collectionUID) external view returns (bool) {
        return _isCreateCollection[_collectionUID];
    }

    function getCollectionAddress(string memory _collectionUID) external view returns (address) {
        return _collections[_collectionUID];
    }

    function isMintedToken(string memory _tokenUID) external view returns (bool) {
        return _isMintedToken[_tokenUID];
    }

    function getTokenId(string memory _tokenUID) external view returns (uint256) {
        return _tokenIds[_tokenUID];
    }

    function _mint(
        address _collection,
        string memory _name,
        string memory _description,
        string memory _cid,
        string memory _tokenUID,
        address to
    ) internal returns (uint256) {
        GhostBaseCollection collection = GhostBaseCollection(_collection);
        uint256 tokenId = collection.mint(_name, _description, _cid, to);
        _tokenIds[_tokenUID] = tokenId;
        _isMintedToken[_tokenUID] = true;
        return tokenId;
    }

    function mint(
        string memory _collectionUID,
        string memory _name,
        string memory _description,
        string memory _cid,
        string memory _tokenUID
    ) external {
        require(_isCreateCollection[_collectionUID], 'Error : Not created collections');
        address _collection = _collections[_collectionUID];
        require(msg.sender == creators[_collection] || msg.sender == admin, 'Operations: Only creator can mint');
        _mint(_collection, _name, _description, _cid, _tokenUID, msg.sender);
    }

    // Execute Order with hash
    function _executeOrder(
        Order memory order,
        address _referer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        string memory _tokenUID
    ) internal {
        bytes32 digest = _hashOrder(order);

        require(!cancelledOrFinalized[digest], 'Error : This order is already finished!');
        require(ecrecover(digest, v, r, s) == order.creator, 'Error : Invalid creator.');

        if (!_isCreateCollection[order.collectionUID]) {
            // create collection
            _collections[order.collectionUID] = _createCollection(
                order.collectionUID,
                order.collectionName,
                order.collectionSymbol,
                order.creator,
                order.loyalityAddress,
                order.creatorFee,
                order.refererFee
            );
        }

        _mint(_collections[order.collectionUID], order.name, order.description, order.cid, _tokenUID, msg.sender);

        GhostNFTMarket _nftmarket = GhostNFTMarket(nftmarket);

        (uint256 netPrice, uint256 treasureFee, uint256 creatorFee, uint256 refererFee) = _nftmarket
            .calculatePriceAndFeesForCollection(_collections[order.collectionUID], order.price);

        if (order.creator == order.profitRecipient) {
            IWETH(WETH).withdraw(netPrice);
            TransferHelper.safeTransferETH(order.profitRecipient, netPrice);
        } else {
            IERC20(WETH).safeTransfer(order.profitRecipient, netPrice);
        }
        // Update trading fee
        payReward(_nftmarket.treasuryAddress(), treasureFee);

        // Update pending revenues for treasury/creator (if any!)
        if (creatorFee != 0) {
            payReward(order.loyalityAddress, creatorFee);
        }
        // Update refere fee if not equal to 0
        if (refererFee != 0) {
            payReward(_referer, refererFee);
        }

        cancelledOrFinalized[digest] = true;
    }

    function _hashOrder(Order memory order) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            ORDER_TYPEHASH,
                            order.creator,
                            order.profitRecipient,
                            order.loyalityAddress,
                            keccak256(bytes(order.collectionName)),
                            keccak256(bytes(order.collectionSymbol)),
                            keccak256(bytes(order.collectionUID)),
                            keccak256(bytes(order.name)),
                            keccak256(bytes(order.description)),
                            keccak256(bytes(order.cid)),
                            keccak256(bytes(order.uuid)),
                            order.creatorFee,
                            order.refererFee,
                            order.price
                        )
                    )
                )
            );
    }

    function cancelOrder(
        address[3] memory _addr,
        string[7] memory _strs,
        uint256[3] memory _nums,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = _hashOrder(
            Order(
                _addr[0],
                _addr[1],
                _addr[2],
                _strs[0],
                _strs[1],
                _strs[2],
                _strs[3],
                _strs[4],
                _strs[5],
                _strs[6],
                _nums[0],
                _nums[1],
                _nums[2]
            )
        );
        require(!cancelledOrFinalized[digest], 'Error : This order is already finished!');
        require(ecrecover(digest, v, r, s) == _addr[0], 'Error : Invalid creator.');
        require(msg.sender == _addr[0], 'Error : msg.sender is not creator.');
        cancelledOrFinalized[digest] = true;
    }

    function getCancelledOrFinalized(
        address[3] memory _addr,
        string[7] memory _strs,
        uint256[3] memory _nums
    ) external view returns (bool) {
        bytes32 digest = _hashOrder(
            Order(
                _addr[0],
                _addr[1],
                _addr[2],
                _strs[0],
                _strs[1],
                _strs[2],
                _strs[3],
                _strs[4],
                _strs[5],
                _strs[6],
                _nums[0],
                _nums[1],
                _nums[2]
            )
        );
        return cancelledOrFinalized[digest];
    }

    function executeOrderWithETH(
        address[4] memory _addr,
        string[8] memory _strs,
        uint256[2] memory _nums,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        IWETH(WETH).deposit{value: msg.value}();
        _executeOrder(
            Order(
                _addr[0],
                _addr[1],
                _addr[2],
                _strs[0],
                _strs[1],
                _strs[2],
                _strs[3],
                _strs[4],
                _strs[5],
                _strs[6],
                _nums[0],
                _nums[1],
                msg.value
            ),
            _addr[3],
            v,
            r,
            s,
            _strs[7]
        );
    }

    function executeOrderWithWETH(
        address[4] memory _addr,
        string[8] memory _strs,
        uint256[3] memory _nums,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        IERC20(WETH).safeTransferFrom(address(msg.sender), address(this), _nums[2]);
        _executeOrder(
            Order(
                _addr[0],
                _addr[1],
                _addr[2],
                _strs[0],
                _strs[1],
                _strs[2],
                _strs[3],
                _strs[4],
                _strs[5],
                _strs[6],
                _nums[0],
                _nums[1],
                _nums[2]
            ),
            _addr[3],
            v,
            r,
            s,
            _strs[7]
        );
    }

    function payReward(address _target, uint256 _reward) internal {
        if (payable(_target).send(0)) {
            IWETH(WETH).withdraw(_reward);
            TransferHelper.safeTransferETH(_target, _reward);
        } else {
            IERC20(WETH).safeTransfer(_target, _reward);
        }
    }
}