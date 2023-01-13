// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "IERC20.sol";
import "IERC1271.sol";
import "ERC721Holder.sol";
import "IERC1155.sol";
import "ERC1155Holder.sol";
import "IGamingWallet.sol";
import "IDappGuardRegistry.sol";
import "IDappGuard.sol";
import "IRentalPool.sol";
import "IWalletFactory.sol";
import "ECDSA.sol";

contract GamingWallet is IGamingWallet, IERC1271, ERC721Holder, ERC1155Holder {
    using ECDSA for bytes32;

    bytes4 internal constant VALID_SIGNATURE = 0x1626ba7e;
    bytes4 internal constant INVALID_SIGNATURE = 0xffffffff;

    address public immutable rentalPool;
    address public immutable dappGuardRegistry;
    address public immutable owner;
    address public immutable missionManager;
    address public immutable walletFactory;
    address public immutable revenueManager;

    mapping(address => mapping(uint256 => bool)) public depositedNFTs;

    modifier onlyMissionManager() {
        require(
            msg.sender == missionManager,
            "Only MissionManager is authorized"
        );
        _;
    }

    modifier onlyRevenueManager() {
        require(
            msg.sender == revenueManager,
            "Only RevenueManager is authorized"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner is authorized");
        _;
    }

    constructor(
        address _missionManager,
        address _rentalPool,
        address _dappGuardRegistry,
        address _owner,
        address _walletFactory,
        address _revenueManager
    ) {
        missionManager = _missionManager;
        rentalPool = _rentalPool;
        dappGuardRegistry = _dappGuardRegistry;
        owner = _owner;
        walletFactory = _walletFactory;
        revenueManager = _revenueManager;
    }

    function bulkReturnAsset(
        address returnAddress,
        address[] calldata _collection,
        uint256[][] calldata _tokenID
    ) external override onlyMissionManager {
        for (uint32 j = 0; j < _tokenID.length; j++) {
            for (uint32 k = 0; k < _tokenID[j].length; k++) {
                _returnAsset(returnAddress, _collection[j], _tokenID[j][k]);
            }
        }
    }

    function depositAsset(address collection, uint256 id)
        external
        override
        onlyOwner
    {
        IERC721 nftCollection = IERC721(collection);
        address tokenOwner = nftCollection.ownerOf(id);
        nftCollection.transferFrom(tokenOwner, address(this), id);
        depositedNFTs[collection][id] = true;
        emit NFTDeposited(collection, id);
    }

    function withdrawAsset(address collection, uint256 id)
        external
        override
        onlyOwner
    {
        require(
            depositedNFTs[collection][id],
            "NFT is not owned by the wallet"
        );
        IERC721 nftCollection = IERC721(collection);
        nftCollection.transferFrom(address(this), owner, id);
        depositedNFTs[collection][id] = false;
        emit NFTWithdrawn(collection, id);
    }

    function forwardCall(address gameContract, bytes calldata data_)
        external
        override
        onlyOwner
        returns (bytes memory)
    {
        address dappGuard = IDappGuardRegistry(dappGuardRegistry)
            .getDappGuardForGameContract(gameContract);
        bytes memory validatedData = IDappGuard(dappGuard).validateCall(
            gameContract,
            data_
        );
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = gameContract.call(
            validatedData
        );
        require(success, "call failed");

        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = dappGuard.delegatecall(
            abi.encodeWithSelector(
                IDappGuard.postCallHook.selector,
                gameContract,
                validatedData,
                returnData
            )
        );
        require(success, "post call hool failed");

        return returnData;
    }

    function oasisClaimForward(address gameContract, bytes calldata data_)
        external
        override
        onlyMissionManager
        returns (bytes memory)
    {
        address dappGuard = IDappGuardRegistry(dappGuardRegistry)
            .getDappGuardForGameContract(gameContract);
        bytes memory validatedData = IDappGuard(dappGuard)
            .validateOasisClaimCall(gameContract, data_);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = gameContract.call(
            validatedData
        );
        require(success, "call failed");

        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = dappGuard.delegatecall(
            abi.encodeWithSelector(
                IDappGuard.postCallHook.selector,
                gameContract,
                validatedData,
                returnData
            )
        );
        require(success, "post call hool failed");

        return returnData;
    }

    function oasisDistributeERC20Rewards(
        address _rewardToken,
        address _rewardReceiver,
        uint256 _rewardAmount
    ) external override onlyRevenueManager {
        IERC20(_rewardToken).transfer(_rewardReceiver, _rewardAmount);
    }

    function oasisDistributeERC721Rewards(
        address _receiver,
        address _collection,
        uint256 _tokenId
    ) external override onlyRevenueManager {
        IERC721(_collection).safeTransferFrom(
            address(this),
            _receiver,
            _tokenId
        );
    }

    function oasisDistributeERC1155Rewards(
        address _receiver,
        address _collection,
        uint256 _tokenId,
        uint256 _amount
    ) external override onlyRevenueManager {
        IERC1155(_collection).safeTransferFrom(
            address(this),
            _receiver,
            _tokenId,
            _amount,
            ""
        );
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        override(IERC1271, IGamingWallet)
        returns (bytes4 magicValue)
    {
        address signer = _hash.recover(_signature);
        if (signer == owner) {
            return VALID_SIGNATURE;
        } else {
            return INVALID_SIGNATURE;
        }
    }

    function _returnAsset(
        address returnAddress,
        address _collection,
        uint256 _tokenId
    ) internal {
        IERC721(_collection).transferFrom(
            address(this),
            returnAddress,
            _tokenId
        );
        emit NFTReturned(_collection, _tokenId);
    }
}