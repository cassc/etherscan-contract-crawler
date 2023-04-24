// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Recoverable, IERC20} from "./utils/Recoverable.sol";
import {ISweeper} from "./interfaces/ISweeper.sol";
import {ISweepingFunds} from "./interfaces/ISweepingFunds.sol";
import {SweepingFunds} from "./funds/SweepingFunds.sol";

contract MasterSweeper is Recoverable, ERC721Holder, Multicall {
    using ECDSA for bytes32;
    using Address for address;

    // markets enabled for sweeping
    mapping(address => address) public marketSweeper;

    // wallets holding WBNB dedicated for specific collection
    mapping(address => address) public sweepingFunds;
    mapping(address => bool) public isExecutor;
    mapping(address => bool) public isSigner;

    address public VAULT;
    bool public requireExecutor = true;
    bool public requireSignature = false;
    uint256 public signatureMaxAge = 60;

    event Sweep(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed market,
        address to,
        uint256 askPrice
    );

    event UpdatedSweeperForMarket(
        address indexed market,
        address indexed sweeper
    );

    event CreatedSweepingFunds(
        address indexed collection,
        address indexed funds
    );

    event ClosedSweepingFunds(
        address indexed collection,
        address indexed funds
    );

    event UpdateSettings(
        bool indexed requireExecutor,
        bool indexed requireSignature,
        uint256 signatureMaxAge
    );

    event UpdateSigner(address indexed signer, bool indexed isSigner);

    event UpdateExecutor(address indexed executor, bool indexed isExecutor);

    event UpdateVault(address indexed vault);

    constructor(address _vault) {
        require(_vault != address(0), "Invalid vault");
        VAULT = _vault;
    }

    receive() external payable {}

    /**
     * @notice Sweep `_tokenId` of `_collection` on `_market`, transfering to `_to`.
     * @dev Only available when requireSignature == false and sender is executor.
     */
    function sweep(
        address _market,
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        bytes calldata _data
    ) external {
        require(!requireSignature, "Signature required");
        require(requireExecutor, "Invalid setting");
        require(
            msg.sender == owner() || isExecutor[msg.sender],
            "Only executors can sweep unsigned"
        );

        _sweep(_market, _collection, _tokenId, _price, _data);
    }

    /**
     * @notice Sweep `_tokenId` of `_collection` on `_market`, transfering to `_to`, using signed mesage from `_timestamp`.
     * @dev Only available when requireSignature == false and sender is executor.
     */
    function sweep(
        address _market,
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        bytes calldata _data,
        uint256 _timestamp,
        bytes calldata _signature
    ) external {
        require(
            !requireExecutor || msg.sender == owner() || isExecutor[msg.sender],
            "Only executors can sweep"
        );
        require(
            _timestamp + signatureMaxAge > block.timestamp,
            "Signature expired"
        );
        require(
            isValidSigned(
                _market,
                _collection,
                _tokenId,
                _price,
                _data,
                _timestamp,
                _signature
            ),
            "Invalid signature or signer"
        );

        _sweep(_market, _collection, _tokenId, _price, _data);
    }

    /**
     * @dev Set the sweeper to be used for `market`. Only callable by owner. Needs to implement ISweeper.
     */
    function setMarketSweeper(address _market, address _sweeper)
        external
        onlyOwner
    {
        require(_market != address(0), "Invalid market");
        marketSweeper[_market] = _sweeper;
        emit UpdatedSweeperForMarket(_market, _sweeper);
    }

    /**
     * @dev Create wallet for BNB to be used for sweeping `collection`.
     */
    function createSweepingFunds(address _collection)
        external
        onlyOwner
    {
        require(_collection != address(0), "Invalid collection");
        SweepingFunds funds = new SweepingFunds(address(this), _collection);
        funds.transferOwnership(owner());
        sweepingFunds[_collection] = address(funds);
        emit CreatedSweepingFunds(_collection, address(funds));
    }

    /**
     * @dev Create wallet for BNB to be used for sweeping `collection`.
     */
    function closeSweepingFunds(address _collection, address payable _receiver, bool destruct)
        external
        onlyOwner
    {
        require(_collection != address(0), "Invalid collection");
        require(sweepingFunds[_collection] != address(0), "No funds set");
        emit ClosedSweepingFunds(_collection, sweepingFunds[_collection]);
        ISweepingFunds(sweepingFunds[_collection]).closeFunds(_receiver, destruct);
        sweepingFunds[_collection] = address(0);
    }

    function setSettings(
        bool _requireExecutor,
        bool _requireSignature,
        uint256 _signatureMaxAge
    ) external onlyOwner {
        requireExecutor = _requireExecutor;
        requireSignature = _requireSignature;
        signatureMaxAge = _signatureMaxAge;
        require(requireExecutor || requireSignature, "Invalid settings");
        require(
            signatureMaxAge > 0 && signatureMaxAge <= 600,
            "Invalid settings"
        );
        emit UpdateSettings(
            requireExecutor,
            requireSignature,
            _signatureMaxAge
        );
    }

    function setSigner(address _signer, bool _isSigner) external onlyOwner {
        require(_signer != address(0), "Invalid signer");
        isSigner[_signer] = _isSigner;
        emit UpdateSigner(_signer, _isSigner);
    }

    function setExecutor(address _executor, bool _isExecutor)
        external
        onlyOwner
    {
        require(_executor != address(0), "Invalid executor");
        isExecutor[_executor] = _isExecutor;
        emit UpdateExecutor(_executor, _isExecutor);
    }

    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Invalid vault");
        VAULT = _vault;
        emit UpdateVault(_vault);
    }

    /**
     * @dev View funds available for sweeping `_collection`.
     */
    function availableFunds(address _collection)
        external view returns (uint256)
    {
        require(_collection != address(0), "Invalid collection");
        require(sweepingFunds[_collection] != address(0), "No funds set");
        return address(sweepingFunds[_collection]).balance;
    }

    function isValidSigned(
        address _market,
        address _collection,
        uint256 _tokenId,
        uint256 _price,
        bytes calldata _data,
        uint256 _timestamp,
        bytes calldata _signature
    ) public view returns (bool) {
        bytes32 msgHash = keccak256(
            abi.encodePacked(_market, _collection, _tokenId, _price, _data, _timestamp)
        );
        return _isValidSignature(msgHash, _signature);
    }

    function _isValidSignature(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool isValid)
    {
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address signer = signedHash.recover(signature);
        return signer != address(0) && isSigner[signer];
    }

    function _sweep(
        address _market,
        address _collection,
        uint256 _tokenId,
        uint256 _value,
        bytes calldata _data
    ) internal nonReentrant {
        require(_market != address(0), "Invalid market");
        address sweeper = marketSweeper[_market];
        require(sweeper != address(0), "No sweeper registerd for market");
        require(sweepingFunds[_collection] != address(0), "No wallet set");
        
        ISweepingFunds(sweepingFunds[_collection]).fundSweep(_value);

        sweeper.functionDelegateCall(
            abi.encodeWithSelector(ISweeper.sweep.selector, _collection, _tokenId, _value, _data, VAULT)
        );
        
        emit Sweep(_collection, _tokenId, _market, VAULT, _value);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
}