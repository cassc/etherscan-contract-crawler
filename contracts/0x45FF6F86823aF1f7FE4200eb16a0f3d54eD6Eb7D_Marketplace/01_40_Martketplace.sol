// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '../pack/PackNft.sol';
import '../utils/MathUtils.sol';
import './MarketplaceSignature.sol';
import '../proxy/PackProxy.sol';
import '../pack/eventListener/IEventListener.sol';

/// @title Marketplace Contract
/// @notice Contract that implements all the functionality of the marketplace

contract Marketplace is AccessControl, ReentrancyGuard, MarketplaceSignature {
    using SafeERC20 for IERC20;
    using Address for address payable;

    event SetBaseUri(string newBaseUri);
    event Purchased(
        address packAddress,
        uint256 tokenId,
        address user,
        uint256 amount,
        address tokenAddress
    );
    event MissionCreated(address creator, uint32 missionId);
    event PackCreated(uint32 missionId, uint256 packId, address packAddress);
    event CelebrityFee(address celebrity, uint256 celebrityFee);
    event TokensUnlocked(address admin, address tokenAddress, uint256 amount);
    event FundsDistributed(
        address packAddress,
        address feeCollector,
        address fundTreasury,
        address celebrity,
        uint256 feeCollectorFee,
        uint256 fundTreasuryFee,
        uint256 celebrityFee,
        address tokenAddress
    );

    bytes32 public constant ADMIN = keccak256('ADMIN');
    bytes32 public constant CREATOR = keccak256('CREATOR');
    bytes32 public constant SIGNER_MARKETPLACE_ROLE = keccak256('SIGNER_MARKETPLACE_ROLE');

    PackNft public immutable packImplementation;
    IEventListener public immutable eventListener;

    struct Mission {
        uint32 id;
        address[] packs;
    }

    mapping(uint32 => Mission) private missions;

    string internal _baseTokenURI;

    uint16 public constant MAX_PACKS_COUNT = 10;

    uint32 public constant HUNDRED_PERCENTS = 100000;

    /// @dev Sets main dependencies
    /// @param _creator creator's address
    /// @param _signer signer's address
    /// @param _name contract name for EIP712
    /// @param _version contract version for EIP712

    constructor(
        address _creator,
        address _signer,
        string memory _name,
        string memory _version,
        address _eventListener
    ) {
        __Signature_init(_name, _version);
        _setupRole(ADMIN, msg.sender);
        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(CREATOR, _creator);
        _setRoleAdmin(CREATOR, ADMIN);
        _setupRole(SIGNER_MARKETPLACE_ROLE, _signer);
        _setRoleAdmin(SIGNER_MARKETPLACE_ROLE, ADMIN);
        packImplementation = new PackNft();
        eventListener = IEventListener(_eventListener);
    }

    /// @dev Set the base URI
    /// @param _baseURI Base path to metadata

    function setBaseUri(string memory _baseURI) external onlyRole(ADMIN) {
        _baseTokenURI = _baseURI;
        emit SetBaseUri(_baseURI);
    }

    /// @dev Get mission information
    /// @param missionId mission id

    function getMission(uint32 missionId) external view returns (Mission memory) {
        return missions[missionId];
    }

    /// @dev Withdraw ERC20 token balance from contract address
    /// @param tokenAddress address of the ERC20 token contract whose tokens will be withdrawn to the recipient

    function unlockTokens(address tokenAddress) external onlyRole(ADMIN) {
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance > 0, 'Balance is zero');
        token.safeTransfer(msg.sender, contractBalance);
        emit TokensUnlocked(msg.sender, tokenAddress, contractBalance);
    }

    /// @dev Create new mission by creating packs. Can only be performed by the creator
    /// @param _missionId new mission id
    /// @param _packIds list of new pack ids
    /// @param _packsNames list of pack names
    /// @param _packsSymbols list of pack symbols
    /// @param _packsUris list of pack uri links

    function createMission(
        uint32 _missionId,
        uint32[] memory _packIds,
        string[] memory _packsNames,
        string[] memory _packsSymbols,
        string[] memory _packsUris
    ) external onlyRole(CREATOR) returns (uint64) {
        require(_missionId != 0, 'Should not be allowed as param from backend.');
        require(_packsNames.length <= MAX_PACKS_COUNT, 'Packs amount limited to 10.');
        require(
            _packIds.length == _packsNames.length &&
                _packIds.length == _packsSymbols.length &&
                _packIds.length == _packsUris.length,
            'Incompatible arrays size.'
        );
        missions[_missionId] = Mission(_missionId, new address[](0));

        _createPacks(_missionId, _packIds, _packsNames, _packsSymbols, _packsUris, msg.sender);

        emit MissionCreated(msg.sender, _missionId);
        return _missionId;
    }

    /// @dev Private function for creation new mission by creating packs
    /// @param missionId new mission id
    /// @param _packIds list of new pack ids
    /// @param _names list of pack names
    /// @param _symbols list of pack symbols
    /// @param _uris list of pack uri links
    /// @param creator list of pack uri links

    function _createPacks(
        uint32 missionId,
        uint32[] memory _packIds,
        string[] memory _names,
        string[] memory _symbols,
        string[] memory _uris,
        address creator
    ) private {
        for (uint8 i = 0; i < _packIds.length; ) {
            PackProxy packProxy = new PackProxy(address(packImplementation));
            missions[missionId].packs.push(address(packProxy));
            PackNft(address(packProxy)).initialize(
                _names[i],
                _symbols[i],
                _baseTokenURI,
                _uris[i],
                creator,
                address(eventListener)
            );
            eventListener.addContract(address(packProxy));
            emit PackCreated(missionId, _packIds[i], address(packProxy));
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Private function for distribute ETH between share addresses
    /// @param _value distribute value
    /// @param shares percentage distribution list
    /// @param shareAddresses list of distribution addresses
    /// @param _packAddress list of pack addresses

    function _distributeEth(
        uint256 _value,
        uint256[] memory shares,
        address[] memory shareAddresses,
        address _packAddress
    ) private {
        uint256 feeCollectorFee;
        uint256 fundTreasuryFee = MathUtils.calculatePart(_value, shares[1]);
        uint256 celebrityFee;
        payable(shareAddresses[1]).sendValue(fundTreasuryFee);
        if (shareAddresses[0] != address(0)) {
            celebrityFee = MathUtils.calculatePart(_value, shares[0]);
            feeCollectorFee = _value - fundTreasuryFee - celebrityFee;
            payable(shareAddresses[0]).sendValue(celebrityFee);
        } else {
            feeCollectorFee = _value - fundTreasuryFee;
        }
        payable(shareAddresses[2]).sendValue(feeCollectorFee);
        emit FundsDistributed(
            _packAddress,
            shareAddresses[2],
            shareAddresses[1],
            shareAddresses[0],
            feeCollectorFee,
            fundTreasuryFee,
            celebrityFee,
            address(0)
        );
    }

    /// @dev Private function for distribute ERC20 between share addresses
    /// @param _value distribute value
    /// @param shares percentage distribution list
    /// @param shareAddresses list of distribution addresses
    /// @param _packAddress list of pack addresses

    function _distributeErc20(
        uint256 _value,
        uint256[] memory shares,
        address[] memory shareAddresses,
        address _packAddress,
        IERC20 _token
    ) private {
        uint256 feeCollectorFee;
        uint256 fundTreasuryFee = MathUtils.calculatePart(_value, shares[1]);
        uint256 celebrityFee;
        _token.safeTransfer(shareAddresses[1], fundTreasuryFee);
        if (shareAddresses[0] != address(0)) {
            celebrityFee = MathUtils.calculatePart(_value, shares[0]);
            feeCollectorFee = _value - fundTreasuryFee - celebrityFee;
            _token.safeTransfer(shareAddresses[0], celebrityFee);
        } else {
            feeCollectorFee = _value - shares[1];
        }
        _token.safeTransfer(shareAddresses[2], feeCollectorFee);
        emit FundsDistributed(
            _packAddress,
            shareAddresses[2],
            shareAddresses[1],
            shareAddresses[0],
            feeCollectorFee,
            fundTreasuryFee,
            celebrityFee,
            address(_token)
        );
    }

    /// @dev External function to purchase a token from a specific pack
    /// @param purchaseData purchase data structure
    /// @param v sign v value
    /// @param r sign r value
    /// @param s sign s value

    function purchase(
        SignData memory purchaseData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant returns (bool) {
        require(
            hasRole(SIGNER_MARKETPLACE_ROLE, _getSigner(msg.sender, purchaseData, v, r, s)),
            'Action is inconsistent.'
        );

        require(purchaseData.shareAddresses[1] != address(0), 'FundTreasury cannot be zero.');
        require(purchaseData.shareAddresses[2] != address(0), 'FeeCollector cannot be zero.');
        require(
            (purchaseData.shares[0] + purchaseData.shares[1] + purchaseData.shares[2]) ==
                HUNDRED_PERCENTS,
            'Shares must be equal 100000 (100%)'
        );
        require(missions[purchaseData.missionId].id > 0, "Mission with this id doesn't exists.");
        require(
            purchaseData.availableIds.length >= purchaseData.quantity,
            'Wrong quantity for minting.'
        );

        if (purchaseData.tokenAddress != address(0)) {
            require(msg.value == 0, 'Purchase should be paid only in ERC-20.');
            IERC20 token = IERC20(purchaseData.tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), purchaseData.price);
            _distributeErc20(
                purchaseData.price,
                purchaseData.shares,
                purchaseData.shareAddresses,
                purchaseData.packAddress,
                IERC20(purchaseData.tokenAddress)
            );
        } else {
            require(msg.value == purchaseData.price, 'Wrong amount of sent funds.');
            _distributeEth(
                purchaseData.price,
                purchaseData.shares,
                purchaseData.shareAddresses,
                purchaseData.packAddress
            );
        }

        PackNft nft = PackNft(purchaseData.packAddress);

        uint256 arrayMaxIndex;

        unchecked {
            arrayMaxIndex = purchaseData.availableIds.length - 1;
        }

        if (arrayMaxIndex == 0) {
            uint256 tokenId = purchaseData.availableIds[0];
            require(!nft.exists(tokenId), 'This token already exists.');
            nft.safeMint(msg.sender, tokenId);
            emit Purchased(
                purchaseData.packAddress,
                tokenId,
                msg.sender,
                msg.value,
                purchaseData.tokenAddress
            );
        } else {
            for (uint32 i = 0; i < purchaseData.quantity; ) {
                uint256 randomIndex = MathUtils.simpleRandom(purchaseData.seed, arrayMaxIndex);
                uint256 tokenId = purchaseData.availableIds[randomIndex];
                for (uint32 j = 1; nft.exists(tokenId); ) {
                    randomIndex = MathUtils.simpleRandom(purchaseData.seed + j, arrayMaxIndex);
                    tokenId = purchaseData.availableIds[randomIndex];
                    unchecked {
                        ++j;
                    }
                }
                nft.safeMint(msg.sender, tokenId);
                unchecked {
                    ++i;
                }

                emit Purchased(
                    purchaseData.packAddress,
                    tokenId,
                    msg.sender,
                    msg.value,
                    purchaseData.tokenAddress
                );
            }
        }

        return true;
    }
}