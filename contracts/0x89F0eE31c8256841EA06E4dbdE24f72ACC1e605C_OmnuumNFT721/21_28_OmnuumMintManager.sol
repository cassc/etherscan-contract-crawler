// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '../utils/OwnableUpgradeable.sol';
import './OmnuumNFT721.sol';
import './OmnuumCAManager.sol';
import './OmnuumWallet.sol';

/// @title OmnuumMintManager - Manage mint data and logics except ticket minting
/// @author Omnuum Dev Team - <[email protected]>
/// @notice Use only purpose for Omnuum
contract OmnuumMintManager is OwnableUpgradeable {
    uint8 public constant rateDecimal = 5;

    /// @notice minting fee rate
    uint256 public feeRate;

    /// @notice minimum fee (ether)
    uint256 public minFee;

    /// @notice special fee rates for exceptional contracts
    mapping(address => uint256) public specialFeeRates;

    /// @notice nft => groupId => PublicMintSchedule
    mapping(address => mapping(uint256 => PublicMintSchedule)) public publicMintSchedules;

    /// @notice omnuum ca manager address
    address public caManager;

    event ChangeFeeRate(uint256 feeRate);
    event SetSpecialFeeRate(address indexed nftContract, uint256 discountFeeRate);
    event SetMinFee(uint256 minFee);
    event Airdrop(address indexed nftContract, address indexed receiver, uint256 quantity);
    event MintFeePaid(address indexed nftContract, address indexed payer, uint256 profit, uint256 mintFee);
    event SetPublicSchedule(
        address indexed nftContract,
        uint256 indexed groupId,
        uint256 endDate,
        uint256 basePrice,
        uint32 supply,
        uint32 maxMintAtAddress
    );
    event PublicMint(
        address indexed nftContract,
        address indexed minter,
        uint256 indexed groupId,
        uint32 quantity,
        uint32 maxQuantity,
        uint256 price
    );

    struct PublicMintSchedule {
        uint32 supply; // max possible minting amount
        uint32 mintedTotal; // total minted amount
        uint32 maxMintAtAddress; // max possible minting amount per address
        mapping(address => uint32) minted; // minting count per address
        uint256 endDate; // minting schedule end date timestamp
        uint256 basePrice; // minting price
    }

    function initialize(uint256 _feeRate, address _caManager) public initializer {
        __Ownable_init();
        feeRate = _feeRate;
        caManager = _caManager;
        minFee = 0.0005 ether;
    }

    /// @notice get fee rate of given nft contract
    /// @param _nftContract address of nft contract
    function getFeeRate(address _nftContract) public view returns (uint256) {
        return specialFeeRates[_nftContract] == 0 ? feeRate : specialFeeRates[_nftContract];
    }

    /// @notice change fee rate
    /// @param _newFeeRate new fee rate
    function changeFeeRate(uint256 _newFeeRate) external onlyOwner {
        /// @custom:error (NE1) - Fee rate should be lower than 100%
        require(_newFeeRate <= 100000, 'NE1');
        feeRate = _newFeeRate;
        emit ChangeFeeRate(_newFeeRate);
    }

    /// @notice set special fee rate for exceptional case
    /// @param _nftContract address of nft
    /// @param _feeRate fee rate only for nft contract
    function setSpecialFeeRate(address _nftContract, uint256 _feeRate) external onlyOwner {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_nftContract != address(0), 'AE1');

        /// @custom:error (NE1) - Fee rate should be lower than 100%
        require(_feeRate <= 100000, 'NE1');
        specialFeeRates[_nftContract] = _feeRate;
        emit SetSpecialFeeRate(_nftContract, _feeRate);
    }

    function setMinFee(uint256 _minFee) external onlyOwner {
        minFee = _minFee;
        emit SetMinFee(_minFee);
    }

    /// @notice add public mint schedule
    /// @dev only nft contract owner can add mint schedule
    /// @param _nft nft contract address
    /// @param _groupId id of mint schedule
    /// @param _endDate end date of schedule
    /// @param _basePrice mint price of schedule
    /// @param _supply max possible minting amount
    /// @param _maxMintAtAddress max possible minting amount per address
    function setPublicMintSchedule(
        address _nft,
        uint256 _groupId,
        uint256 _endDate,
        uint256 _basePrice,
        uint32 _supply,
        uint32 _maxMintAtAddress
    ) external {
        /// @custom:error (OO1) - Ownable: Caller is not the collection owner
        require(OwnableUpgradeable(_nft).owner() == msg.sender, 'OO1');

        PublicMintSchedule storage schedule = publicMintSchedules[_nft][_groupId];

        schedule.supply = _supply;
        schedule.endDate = _endDate;
        schedule.basePrice = _basePrice;
        schedule.maxMintAtAddress = _maxMintAtAddress;

        emit SetPublicSchedule(_nft, _groupId, _endDate, _basePrice, _supply, _maxMintAtAddress);
    }

    /// @notice before nft mint, check whether mint is possible and count new mint at mint schedule
    /// @dev only nft contract itself can access and use its mint schedule
    /// @param _groupId id of schedule
    /// @param _quantity quantity to mint
    /// @param _value value sent to mint at NFT contract, used for checking whether value is enough or not to mint
    /// @param _minter msg.sender at NFT contract who are trying to mint
    function preparePublicMint(
        uint256 _groupId,
        uint32 _quantity,
        uint256 _value,
        address _minter
    ) external {
        PublicMintSchedule storage schedule = publicMintSchedules[msg.sender][_groupId];

        /// @custom:error (MT8) - Minting period is ended
        require(block.timestamp <= schedule.endDate, 'MT8');

        /// @custom:error (MT5) - Not enough money
        require(schedule.basePrice * _quantity <= _value, 'MT5');

        /// @custom:error (MT2) - Cannot mint more than possible amount per address
        require(schedule.minted[_minter] + _quantity <= schedule.maxMintAtAddress, 'MT2');

        /// @custom:error (MT3) - Remaining token count is not enough
        require(schedule.mintedTotal + _quantity <= schedule.supply, 'MT3');

        schedule.minted[_minter] += _quantity;
        schedule.mintedTotal += _quantity;

        emit PublicMint(msg.sender, _minter, _groupId, _quantity, schedule.supply, schedule.basePrice);
    }

    /// @notice minting multiple nfts, can be used for airdrop
    /// @dev only nft owner can use this function
    /// @param _nftContract address of nft contract
    /// @param _tos list of minting target address
    /// @param _quantitys list of minting quantity which is paired with _tos
    function mintMultiple(
        address payable _nftContract,
        address[] calldata _tos,
        uint256[] calldata _quantitys
    ) external payable {
        OmnuumNFT721 targetContract = OmnuumNFT721(_nftContract);
        uint256 len = _tos.length;

        /// @custom:error (OO1) - Ownable: Caller is not the collection owner
        require(targetContract.owner() == msg.sender, 'OO1');

        /// @custom:error (ARG1) - Arguments length should be same
        require(len == _quantitys.length, 'ARG1');

        uint256 totalQuantity;
        for (uint256 i = 0; i < len; i++) {
            address to = _tos[i];
            uint256 quantity = _quantitys[i];
            totalQuantity += quantity;
            targetContract.mintDirect(to, quantity);
            emit Airdrop(_nftContract, to, quantity);
        }

        /// @custom:error (ARG3) - Not enough ether sent
        require(msg.value >= totalQuantity * minFee, 'ARG3');
        OmnuumWallet(payable(OmnuumCAManager(caManager).getContract('WALLET'))).mintFeePayment{ value: msg.value }(_nftContract);

        emit MintFeePaid(_nftContract, msg.sender, 0, msg.value);
    }

    /// @notice set ca manager
    /// @dev only owner can use this function
    /// @param _caManager address of CA manager
    function setCaManager(address _caManager) external onlyOwner {
        caManager = _caManager;
    }
}