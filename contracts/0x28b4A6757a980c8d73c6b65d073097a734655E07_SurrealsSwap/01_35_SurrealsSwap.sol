// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./sudoswap/LSSVMPairFactory.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ICurve} from "./sudoswap/bonding-curves/ICurve.sol";
import {LSSVMPair} from "./sudoswap/LSSVMPair.sol";
import {LSSVMRouter} from "./sudoswap/LSSVMRouter.sol";

contract SurrealsSwap is Ownable, IERC721Receiver {
    address exponentialCurve = 0x432f962D8209781da23fB37b6B59ee15dE7d9841;
    address pairFactory = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
    address sudoSwapPair;
    uint128 cost = 0.0666 ether;
    address paymentWallet = 0xD2F8818DfB5B9a4C64D0EB1039Ee68c311A4B180;

    address public previousCollectionContract;
    address public surrealsMidnightContract;
    mapping(address => uint256) public sacrifices;

    constructor(address _darkSurreals, address _surreals) {
        previousCollectionContract = _surreals;
        surrealsMidnightContract = _darkSurreals;
    }

    modifier onlyNFTContract() {
        require(msg.sender == surrealsMidnightContract, "Not authorized");
        _;
    }

    function setPaymentWallet(address _wallet) external onlyOwner {
        paymentWallet = _wallet;
    }

    function setPairFactory(address _pairFactory) external onlyOwner {
        pairFactory = _pairFactory;
    }

    function setNFTContracts(
        address _previousContract,
        address _surrealsMidnight
    ) public onlyOwner {
        previousCollectionContract = _previousContract;
        surrealsMidnightContract = _surrealsMidnight;
    }

    function setSudoSwapPair(address _sudoSwap) external onlyOwner {
        sudoSwapPair = _sudoSwap;
    }

    /**
     * @dev redeem sacrifice made for a free mint
     * @param _wallet that made the sacrifice
     * @param _amount of sacrifices to redeem
     */
    function redeemSacrifice(address _wallet, uint256 _amount)
        external
        onlyNFTContract
    {
        if (sacrifices[_wallet] > 0)
            if (_amount >= sacrifices[_wallet]) sacrifices[_wallet] = 0;
            else sacrifices[_wallet] -= _amount;
    }

    /**
     * @dev create ETH pool in sudoswap
     * @param _initialNFTIDs to sned in the pool
     */
    function createPool(uint256[] calldata _initialNFTIDs, address _recipient)
        external
        onlyOwner
    {
        LSSVMPair pair = LSSVMPairFactory(payable(pairFactory)).createPairETH{
            value: 0
        }(
            IERC721(previousCollectionContract), //nft collection
            ICurve(exponentialCurve), //curve
            payable(_recipient), //recipieent
            LSSVMPair.PoolType.NFT, //pooltype
            1004000000000000000, // when an NFT is purchased or sold, how much should it increment or decline by. percentage or fixed
            0,
            cost,
            _initialNFTIDs
        );

        sudoSwapPair = address(pair);
        IERC721(previousCollectionContract).setApprovalForAll(
            pairFactory,
            true
        );
    }

    /**
     * @dev make sacrifice by sending NFT to the pool
     * @param _tokenIds NFTs to send
     */
    function makeSacrifice(uint[] memory _tokenIds) external {
        require(
            sacrifices[msg.sender] + _tokenIds.length <= 3,
            "Max sacrifice is 3"
        );

        // transfer NFTs to the contract
        for (uint i = 0; i < _tokenIds.length; i++)
            IERC721(previousCollectionContract).transferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );

        //deposit NFTs in the pool
        LSSVMPairFactory(payable(pairFactory)).depositNFTs(
            IERC721(previousCollectionContract),
            _tokenIds,
            sudoSwapPair
        );

        sacrifices[msg.sender] += _tokenIds.length;
    }

    // /**
    //  * @dev withdraw deposited NFTs
    //  */
    // function withdrawNFTs(uint[] memory _tokenIds) external onlyOwner {
    //     //deposit NFTs in the pool
    //     LSSVMPair(payable(sudoSwapPair)).withdrawERC721(
    //         IERC721(previousCollectionContract),
    //         _tokenIds
    //     );
    //     for (uint i = 0; i < _tokenIds.length; i++)
    //         IERC721(previousCollectionContract).transferFrom(
    //             address(this),
    //             owner(),
    //             _tokenIds[i]
    //         );
    // }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {}
}