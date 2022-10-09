// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interface/ILSSVMRouter.sol";
import "../interface/IERC721.sol";
import "../interface/ISudoPool.sol";

contract Reward is
    Initializable, 
    OwnableUpgradeable,
    UUPSUpgradeable
{
    ILSSVMRouter constant router = ILSSVMRouter(0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329); // sudoswap

    mapping(uint16 => bytes) public trustedRemoteLookup; // PengTogether contract on Optimism
    address public admin;
    address public dao;
    uint public nftSwapped;

    event BuyNFT(address pool, uint NFTPrice);
    event SetTrustedRemoteLookup(uint16 chainId, address trustedRemote);
    event SetAdmin(address _admin);
    event SetDao(address _dao);

    function initialize(address _dao, address pengTogetherVault) external initializer {
        __Ownable_init();

        trustedRemoteLookup[111] = abi.encodePacked(pengTogetherVault);

        dao = _dao;
        admin = msg.sender;
    }

    receive() external payable {}

    function buyNFT(address pool) external {
        require(msg.sender == admin || msg.sender == owner(), "only authorized");

        ILSSVMRouter.PairSwapAny[] memory swapList = new ILSSVMRouter.PairSwapAny[](1);
        swapList[0] = ILSSVMRouter.PairSwapAny(pool, 1);
        uint thisBalance = address(this).balance;
        uint remainingValue = router.swapETHForAnyNFTs{value: thisBalance}(
            swapList, // swapList
            payable(address(this)), // ethRecipient
            dao, // nftRecipient
            block.timestamp // deadline
        );

        nftSwapped += 1;

        emit BuyNFT(pool, thisBalance - remainingValue);
    }

    function setNftSwapped(uint _nftSwapped) external onlyOwner {
        nftSwapped = _nftSwapped;
    }

    function setTrustedRemoteLookup(uint16 chainId, address trustedRemote) external onlyOwner {
        trustedRemoteLookup[chainId] = abi.encodePacked(trustedRemote);

        emit SetTrustedRemoteLookup(chainId, trustedRemote);
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;

        emit SetAdmin(_admin);
    }

    function setDao(address _dao) external onlyOwner {
        dao = _dao;

        emit SetDao(_dao);
    }

    function getPoolWithFloorPrice(address[] calldata pools, address nft) external view returns (uint floorPrice, address poolWithFloorPrice) {
        for (uint i; i < pools.length; i++) {
            ISudoPool pool = ISudoPool(pools[i]);
            if (IERC721(nft).balanceOf(address(pool)) > 0) {
                (,,, uint inputAmount,) = pool.getBuyNFTQuote(1);
                if (floorPrice == 0) {
                    floorPrice = inputAmount;
                    poolWithFloorPrice = address(pool);
                } else {
                    if (inputAmount < floorPrice) {
                        floorPrice = inputAmount;
                        poolWithFloorPrice = address(pool);
                    }
                }
            }
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}