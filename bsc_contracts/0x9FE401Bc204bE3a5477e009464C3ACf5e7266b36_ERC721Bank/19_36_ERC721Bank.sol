// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./ERC721Wrappers.sol";
import "./BankBase.sol";

contract ERC721Bank is BankBase {
    using Address for address;

    struct PoolInfo {
        address user;
        uint256 liquidity;
        // mapping(address=>mapping(uint=>bool)) userShares;
    }

    address[] nftManagers;
    mapping(address => address) erc721Wrappers;

    mapping(uint256 => PoolInfo) poolInfo;

    constructor(address _positionsManager) BankBase(_positionsManager) {}

    function addManager(address nftManager) external onlyOwner {
        nftManagers.push(nftManager);
    }

    function setWrapper(address nftManager, address wrapper) external onlyOwner {
        erc721Wrappers[nftManager] = wrapper;
    }

    function encodeId(uint256 id, address nftManager) public view returns (uint256) {
        for (uint256 i = 0; i < nftManagers.length; i++) {
            if (nftManagers[i] == nftManager) {
                return (i << 240) | uint240(id);
            }
        }
        revert("NFT manager not supported");
    }

    function decodeId(
        uint256 id
    ) public view override returns (address poolAddress, address nftManager, uint256 pos_id) {
        nftManager = nftManagers[id >> 240];
        pos_id = uint240(id & ((1 << 240) - 1));
        poolAddress = IERC721Wrapper(erc721Wrappers[nftManager]).getPoolAddress(nftManager, pos_id);
    }

    function getLPToken(uint256 id) public view override returns (address managerAddress) {
        (, managerAddress, ) = decodeId(id);
    }

    function getIdFromLpToken(address manager) public view override returns (bool, uint256) {
        for (uint256 i = 0; i < nftManagers.length; i++) {
            if (nftManagers[i] == manager) {
                return (true, uint160(nftManagers[i]));
            }
        }
        return (false, 0);
    }

    function name() public pure override returns (string memory) {
        return "ERC721 Bank";
    }

    function mint(
        uint256 tokenId,
        address userAddress,
        address[] memory suppliedTokens,
        uint256[] memory suppliedAmounts
    ) public override onlyAuthorized returns (uint256) {
        (, , , , , , , uint256 minted, , , , ) = INonfungiblePositionManager(suppliedTokens[0]).positions(
            suppliedAmounts[0]
        );
        poolInfo[tokenId] = PoolInfo(userAddress, minted);
        return minted;
    }

    function mintRecurring(
        uint256 tokenId,
        address userAddress,
        address[] memory suppliedTokens,
        uint256[] memory suppliedAmounts
    ) external override onlyAuthorized returns (uint256) {
        require(poolInfo[tokenId].user == userAddress, "9");
        (, address manager, uint256 id) = decodeId(tokenId);
        address wrapper = erc721Wrappers[manager];

        bytes memory returnData = wrapper.functionDelegateCall(
            abi.encodeWithSelector(IERC721Wrapper.deposit.selector, manager, id, suppliedTokens, suppliedAmounts)
        );
        uint256 minted = abi.decode(returnData, (uint256));
        poolInfo[tokenId].liquidity += minted;
        return minted;
    }

    function burn(
        uint256 tokenId,
        address userAddress,
        uint256 amount,
        address receiver
    ) external override onlyAuthorized returns (address[] memory outTokens, uint256[] memory tokenAmounts) {
        require(poolInfo[tokenId].user == userAddress, "9");
        (, address manager, uint256 id) = decodeId(tokenId);
        address wrapper = erc721Wrappers[manager];
        bytes memory returnData = wrapper.functionDelegateCall(
            abi.encodeWithSelector(IERC721Wrapper.withdraw.selector, manager, id, amount, receiver)
        );
        (outTokens, tokenAmounts) = abi.decode(returnData, (address[], uint256[]));
        // (outTokens, tokenAmounts) = withdraw(manager, id, amount, receiver);
        (, , , , , , , uint256 liquidity, , , , ) = INonfungiblePositionManager(manager).positions(id);
        poolInfo[tokenId].liquidity = liquidity;
    }

    function harvest(
        uint256 tokenId,
        address userAddress,
        address receiver
    ) external override onlyAuthorized returns (address[] memory rewardAddresses, uint256[] memory rewardAmounts) {
        require(poolInfo[tokenId].user == userAddress, "9");
        (, address manager, uint256 id) = decodeId(tokenId);
        address wrapper = erc721Wrappers[manager];
        bytes memory returnData = wrapper.functionDelegateCall(
            abi.encodeWithSelector(IERC721Wrapper.harvest.selector, manager, id, receiver)
        );
        (, , , , , , , uint256 liquidity, , , , ) = INonfungiblePositionManager(manager).positions(id);
        poolInfo[tokenId].liquidity = liquidity;
        (rewardAddresses, rewardAmounts) = abi.decode(returnData, (address[], uint256[]));
        return (rewardAddresses, rewardAmounts);
    }

    function getUnderlyingForFirstDeposit(
        uint256 tokenId
    ) public view override returns (address[] memory underlying, uint256[] memory ratios) {
        (, address manager, ) = decodeId(tokenId);
        underlying = new address[](1);
        underlying[0] = manager;
        ratios = new uint256[](1);
        ratios[0] = 1;
    }

    function getUnderlyingForRecurringDeposit(
        uint256 tokenId
    ) public view override returns (address[] memory, uint256[] memory ratios) {
        (, address manager, uint256 pos_id) = decodeId(tokenId);
        IERC721Wrapper wrapper = IERC721Wrapper(erc721Wrappers[manager]);
        return wrapper.getRatio(manager, pos_id);
        // return wrapper.getERC20Base(pool);
    }

    function getRewards(uint256 tokenId) external view override returns (address[] memory rewardsArray) {
        (rewardsArray, ) = getUnderlyingForRecurringDeposit(tokenId);
    }

    function getPendingRewardsForUser(
        uint256 tokenId,
        address user
    ) external view override returns (address[] memory rewards, uint256[] memory amounts) {
        (, address manager, uint256 pos_id) = decodeId(tokenId);
        IERC721Wrapper wrapper = IERC721Wrapper(erc721Wrappers[manager]);
        return wrapper.getRewardsForPosition(manager, pos_id);
    }

    function getPositionTokens(
        uint256 tokenId,
        address userAddress
    ) external view override returns (address[] memory outTokens, uint256[] memory tokenAmounts) {
        (, address manager, uint256 pos_id) = decodeId(tokenId);
        IERC721Wrapper wrapper = IERC721Wrapper(erc721Wrappers[manager]);
        return wrapper.getPositionUnderlying(manager, pos_id);
    }

    function isUnderlyingERC721() external pure override returns (bool) {
        return true;
    }
}