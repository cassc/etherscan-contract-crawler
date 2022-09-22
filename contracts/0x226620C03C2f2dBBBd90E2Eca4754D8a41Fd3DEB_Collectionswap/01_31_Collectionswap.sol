// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICollectionswap} from "./ICollectionswap.sol";
import {ILSSVMPair, ILSSVMPairETH} from "./ILSSVMPair.sol";
import {ILSSVMPairFactory} from "./ILSSVMPairFactory.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";
import {OwnableWithTransferCallback} from "./lib/OwnableWithTransferCallback.sol";

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {FixedPointMathLib} from "./lib/FixedPointMathLib.sol";
import {ReentrancyGuard} from './lib/ReentrancyGuard.sol';
import {ERC1155Receiver, ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Collectionswap is OwnableWithTransferCallback, ERC1155Holder, ERC721, ERC721Enumerable, ERC721URIStorage, ICollectionswap, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    ILSSVMPairFactory public immutable _factory;
    ILSSVMPair.PoolType immutable _poolType;

    mapping(address =>bool) private _mapPoolsToIsLiveForAnyNFT;

    /// @dev mapping of token IDs to pools
    mapping(uint256 => LPTokenParams721ETH) private _mapNFTIDToPool;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint256 private _nextTokenId;

    event NewPair(address poolAddress); // @dev: Used for tests
    event NewTokenId(uint256 tokenId);
    event ERC20Rescued();
    event ERC721Rescued();
    event ERC1155Rescued();

    constructor (
        address payable lssvmPairFactoryAddress
    ) ERC721('Collectionswap','CollectSudo LP') {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        _factory = ILSSVMPairFactory(lssvmPairFactoryAddress);
        _poolType = ILSSVMPair.PoolType.TRADE;
    }

    function transferOwnershipNFTList(
        ILSSVMPairFactory factory,
        address oldOwner,
        address newOwner,
        IERC721 _nft,
        uint256[] memory nftList
    ) private {
        
        for (uint256 i; i<nftList.length; ) {
            _nft.safeTransferFrom(
                oldOwner,
                newOwner,
                nftList[i]
            );
            // only approve if NFT is transferred into contract for pair creation
            // approval will fail otherwise
            if (newOwner == address(this))
                _nft.approve(address(factory), nftList[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getMeasurableContribution(
        uint256 tokenId
        ) external view 
        returns (uint256 contribution) {
            LPTokenParams721ETH memory lpTokenParams = _mapNFTIDToPool[tokenId];
            uint256 initialPoolBalance = lpTokenParams.initialPoolBalance;
            uint256 initialNFTIDsLength = lpTokenParams.initialNFTIDsLength;
            contribution = uint256(initialPoolBalance * initialNFTIDsLength).sqrt();
    }

    function refreshPoolParameters(
        uint256 tokenId
    ) external {
        LPTokenParams721ETH memory lpTokenParams = _mapNFTIDToPool[tokenId];
        address payable poolAddress = lpTokenParams.poolAddress;
        require(isApprovedToOperateOnPool(msg.sender, tokenId),"unapproved caller");
        ILSSVMPairETH mypair = ILSSVMPairETH(poolAddress);
        uint256[] memory currentIds = mypair.getAllHeldIds();
        LPTokenParams721ETH memory lpTokenParams2 = LPTokenParams721ETH(
            lpTokenParams.nftAddress,
            lpTokenParams.bondingCurveAddress,
            lpTokenParams.poolAddress,
            mypair.fee(),
            mypair.delta(),
            mypair.spotPrice(),
            address(mypair).balance,
            currentIds.length
        );
        _mapNFTIDToPool[tokenId] = lpTokenParams2;
    }

    function getAllHeldIds(
        uint256 tokenId
    ) external view returns (uint256[] memory currentIds) {
        address payable poolAddress = _mapNFTIDToPool[tokenId].poolAddress;
        ILSSVMPairETH mypair = ILSSVMPairETH(poolAddress);
        currentIds = mypair.getAllHeldIds();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function issueLPToken(
        address receiver,
        LPTokenParams721ETH memory lpTokenParams
    ) private {
        // prefix increment returns value after increment
        uint256 tokenId = ++_nextTokenId;
        _mapNFTIDToPool[tokenId] = lpTokenParams;
        // string memory uri = string(abi.encodePacked('{"pool":"', Strings.toHexString(lpTokenParams.poolAddress), '"}'));
        _mapPoolsToIsLiveForAnyNFT[lpTokenParams.poolAddress] = true;
        emit NewTokenId(tokenId);
        safeMint(receiver, tokenId);
    }

    function useLPTokenToDestroyDirectPairETH(
        uint256 tokenId
    ) external nonReentrant {
        LPTokenParams721ETH memory lpTokenParams = _mapNFTIDToPool[tokenId];
        ERC721 _nft = ERC721(lpTokenParams.nftAddress);
        destroyDirectPairETH(
            tokenId,
            _nft
        );
        // breaks CEI pattern, but has to be done after destruction to return correct msg
        _mapPoolsToIsLiveForAnyNFT[lpTokenParams.poolAddress] = false;
        burn(tokenId);
    }

    function validatePoolParamsLte(
        uint256 tokenId,
        address nftAddress,
        address bondingCurveAddress,
        uint96 fee,
        uint128 delta
    ) public view returns (bool) {    
        LPTokenParams721ETH memory poolParams = viewPoolParams(tokenId);
        return (
            poolParams.nftAddress == nftAddress &&
            poolParams.bondingCurveAddress == bondingCurveAddress &&
            poolParams.fee <= fee &&
            poolParams.delta <= delta
        );
    }

    function validatePoolParamsEq(
        uint256 tokenId,
        address nftAddress,
        address bondingCurveAddress,
        uint96 fee,
        uint128 delta
    ) public view returns (bool) {    
        LPTokenParams721ETH memory poolParams = viewPoolParams(tokenId);
        return (
            poolParams.nftAddress == nftAddress &&
            poolParams.bondingCurveAddress == bondingCurveAddress &&
            poolParams.fee == fee &&
            poolParams.delta == delta
        );
    }

    function viewPoolParams(
        uint256 tokenId
    ) public view returns (LPTokenParams721ETH memory poolParams) {
        poolParams = _mapNFTIDToPool[tokenId];
        require(isPoolAlive(poolParams.poolAddress), 'pool must be alive');
        return poolParams;
    }

    function createDirectPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable nonReentrant returns (ILSSVMPairETH newPair) {
        ILSSVMPairFactory factory = _factory;
        transferOwnershipNFTList(
            factory,
            msg.sender,
            address(this),
            _nft,
            _initialNFTIDs
            );

        newPair = factory.createPairETH{value:msg.value}(
            _nft,
            _bondingCurve,
            payable(0), // assetRecipient
            _poolType,
            _delta,
            _fee,
            _spotPrice,
            _initialNFTIDs
        );

        LPTokenParams721ETH memory poolParamsStruct = LPTokenParams721ETH(
            address(_nft),
            address(_bondingCurve),
            payable(address(newPair)),
            _fee,
            _delta,
            _spotPrice,
            msg.value,
            _initialNFTIDs.length
        );

        issueLPToken(
            msg.sender,
            poolParamsStruct
        );
    }

    function isApprovedToOperateOnPool(address _owner, uint256 tokenId) public view virtual returns (bool) {
        if (_exists(tokenId)) {
            return ownerOf(tokenId) == _owner;
        } else {
            return false;
        }   
    }    


    function isPoolAlive(address _pool) public view returns (bool) {
        return _mapPoolsToIsLiveForAnyNFT[_pool];
    }

    function destroyDirectPairETH(
        uint256 tokenId,
        IERC721 _nft
    ) private {
        string memory errmsg = "only token owner can destroy pool";
        address payable _pool = _mapNFTIDToPool[tokenId].poolAddress;
        if (!_mapPoolsToIsLiveForAnyNFT[_pool]) {
            errmsg = "pool already destroyed";
        }

        require(isApprovedToOperateOnPool(msg.sender, tokenId), errmsg);

        uint256[] memory currentIds = this.getAllHeldIds(tokenId);

        ILSSVMPairETH mypair = ILSSVMPairETH(_pool);
        mypair.withdrawERC721(_nft,currentIds);
        
        uint256 prevBalance = address(this).balance;
        mypair.withdrawAllETH();
        uint256 currBalance = address(this).balance; // check there's no global state here for getting address balance
        uint256 diffBalance = currBalance - prevBalance;

        transferOwnershipNFTList(
            _factory,
            address(this),
            msg.sender,
            _nft,
            currentIds
            );
        (bool sent,) = payable(msg.sender).call{value: diffBalance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    /////////////////////////////////////////////////
    // Rescue Functions
    /////////////////////////////////////////////////
    /**
        @notice Rescues ERC20 tokens. Only callable by the owner if rescuing from this contract, else can be called by tokenId owner.
        @notice Since pools created cannot be paired with ERC20 tokens, there is no validation on the ERC20 token 
        @param a The token to transfer
        @param amount The amount of tokens to send to the owner
        @param tokenId 0 = rescue from this contract, non-zero = rescue from specified pool
     */
    function rescueERC20(IERC20 a, uint256 amount, uint256 tokenId) external {
        if (tokenId == 0) {
            require(msg.sender == owner(), "not owner");
        } else {
            ILSSVMPairETH _pool = ILSSVMPairETH(_mapNFTIDToPool[tokenId].poolAddress);
            require(isApprovedToOperateOnPool(msg.sender, tokenId), "unapproved caller");
            _pool.withdrawERC20(a, amount); // withdrawn to this contract
        }
        a.safeTransfer(msg.sender, amount);
        emit ERC20Rescued();
    }

    /**
        @notice Rescues ERC721 tokens. Only callable by the owner if rescuing from this contract, else can be called by tokenId owner.
        @param a The NFT to rescue
        @param nftIds NFT IDs to rescue
        @param tokenId 0 = rescue from this contract, non-zero = rescue from specified pool (cannot touch users' NFTs)
     */
    function rescueERC721(
        IERC721 a,
        uint256[] calldata nftIds,
        uint256 tokenId
    ) external {
        // 0 tokenId = pull from this contract directly
        if (tokenId == 0) {
            require(msg.sender == owner(), "not owner");
        } else {
            LPTokenParams721ETH memory lpTokenParams = _mapNFTIDToPool[tokenId];
            ILSSVMPairETH _pool = ILSSVMPairETH(lpTokenParams.poolAddress);
            require(isApprovedToOperateOnPool(msg.sender, tokenId), "unapproved caller");
            require(address(a) != lpTokenParams.nftAddress, "call useLPTokenToDestroyDirectPairETH()");
            _pool.withdrawERC721(a, nftIds); // withdrawn to this contract
        }
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            a.safeTransferFrom(address(this), msg.sender, nftIds[i]);
            unchecked {
                ++i;
            }
        }
        emit ERC721Rescued();
    }

    /**
        @notice Rescues ERC1155 tokens. Only callable by the owner if rescuing from this contract, else can be called by tokenId owner.
        @notice There are some cases where an NFT is both ERC721 and ERC1155, so we have to ensure that the users' NFTs arent touched
        @param a The NFT to transfer
        @param ids The NFT ids to transfer
        @param amounts The amounts of each id to transfer
        @param tokenId 0 = rescue from this contract, non-zero = rescue from specified pool (cannot touch users' NFTs)
     */
    function rescueERC1155(
        IERC1155 a,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256 tokenId
    ) external {
        if (tokenId == 0) {
            require(msg.sender == owner(), "not owner");
        } else {
            LPTokenParams721ETH memory lpTokenParams = _mapNFTIDToPool[tokenId];
            ILSSVMPairETH _pool = ILSSVMPairETH(lpTokenParams.poolAddress);
            require(isApprovedToOperateOnPool(msg.sender, tokenId), "unapproved caller");
            require(address(a) != lpTokenParams.nftAddress, "call useLPTokenToDestroyDirectPairETH()");
            _pool.withdrawERC1155(a, ids, amounts); // withdrawn to this contract
        }
        a.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
        emit ERC1155Rescued();
    }

    /////////////////////////////////////////////////
    // ERC 721
    /////////////////////////////////////////////////

    function safeMint(address to, uint256 tokenId)
        private
    {
        _safeMint(to, tokenId);
        // _setTokenURI(tokenId, '');
    }

    function burn(uint256 tokenId)
        private
        // onlyOwner
    {
        _burn(tokenId);
    }

    // overrides required by Solidiity for ERC721 contract
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, ERC721Enumerable, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}