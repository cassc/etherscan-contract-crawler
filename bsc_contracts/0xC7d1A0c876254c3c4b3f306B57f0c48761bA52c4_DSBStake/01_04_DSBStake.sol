// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface DSBNFTs {
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface DSBTOKEN {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface PancakeRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract DSBStake is Ownable {
    address public DSBNFT_ADDRESS = address(0);
    address public DSBTOKEN_ADDRESS = address(0);

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    struct StakeInfo {
        bool isStaked;
        address currentOwner;
    }

    struct AccountInfo {
        mapping(uint256 => uint256) tokenId;
        uint256 stakeCount;
        uint256 commitDate;
        uint256 lastClaim;
    }

    uint256 private totalStakedCount = 0;
    uint256 private baseValue = 400000000000000000;

    mapping(uint256 => StakeInfo) public stakeTracker;
    mapping(address => AccountInfo) public accountTracker;

    DSBNFTs dsbNFTInstance =
        DSBNFTs(0x7b6ecc55982aB41156A4D7c88C9F48b8013439bD);
    DSBTOKEN dsbTokenInstance;
    //mainnet 0x10ED43C718714eb63d5aA57B78B54704E256024E
    //testnet 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    PancakeRouter pRouter =
        PancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address[] public path = new address[](2);

    //ALIGNMENT

    function setDSBNFTAddress(address addr) external onlyOwner {
        DSBNFT_ADDRESS = addr;
        dsbNFTInstance = DSBNFTs(addr);
    }

    function setDSBTOKENAddress(address addr) external onlyOwner {
        DSBTOKEN_ADDRESS = addr;
        dsbTokenInstance = DSBTOKEN(addr);
    }

    function setPoolRouter(address addr) external onlyOwner {
        pRouter = PancakeRouter(addr);
    }

    function setTokenPair(address path1, address path2) external onlyOwner {
        path[0] = path1;
        path[1] = path2;
    }

    function setBaseValue(uint256 value) external onlyOwner {
        baseValue = value;
    }

    //STATEFUL

    function stake(uint256[] memory tokenId) public onlyEOA {
        require(tokenId.length > 0, "cannot stake zero value tokenid");
        require(
            dsbNFTInstance.isApprovedForAll(msg.sender, address(this)) == true,
            "need approval from owner"
        );
        AccountInfo storage aInfo = accountTracker[msg.sender];

        for (uint256 i = 0; i < tokenId.length; i++) {
            StakeInfo storage sInfo = stakeTracker[tokenId[i]];

            if (
                dsbNFTInstance.ownerOf(tokenId[i]) != msg.sender &&
                sInfo.isStaked != false
            ) {
                revert("current tokenId need to be unstaked");
            } else {
                dsbNFTInstance.transferFrom(
                    msg.sender,
                    address(this),
                    tokenId[i]
                );

                aInfo.commitDate = block.timestamp;
                sInfo.isStaked = true;
                sInfo.currentOwner = msg.sender;
                aInfo.stakeCount++;
                aInfo.tokenId[aInfo.stakeCount] = tokenId[i];
                totalStakedCount++;
            }
        }
    }

    function unStake(uint256[] memory tokenId) public onlyEOA {
        require(tokenId.length > 0, "argument needed");

        require(
            dsbNFTInstance.isApprovedForAll(msg.sender, address(this)),
            "need approval from owner"
        );
        AccountInfo storage aInfo = accountTracker[msg.sender];

        for (uint256 i = 0; i < tokenId.length; i++) {
            StakeInfo storage sInfo = stakeTracker[tokenId[i]];
            if (sInfo.currentOwner != msg.sender && sInfo.isStaked != true) {
                revert();
            } else {
                for (uint256 s = 1; s <= aInfo.stakeCount; s++) {
                    if (
                        aInfo.tokenId[s] == tokenId[i] && sInfo.isStaked == true
                    ) {
                        sInfo.isStaked = false;
                        aInfo.tokenId[s] = 0;
                        sInfo.currentOwner = address(0);
                        dsbNFTInstance.transferFrom(
                            address(this),
                            msg.sender,
                            tokenId[i]
                        );
                        totalStakedCount--;
                    }
                }
            }
        }
    }

    function claim() public onlyEOA returns (bool) {
        require(
            dsbTokenInstance.balanceOf(address(this)) > 0,
            "nothing to claim yet"
        );
        uint256 claimAble = calculateReward(msg.sender);
        require(claimAble > 0, "null claim");
        accountTracker[msg.sender].lastClaim = block.timestamp;
        require(dsbTokenInstance.transfer(msg.sender, claimAble), "tx failed");
        return true;
    }

    //VIEW

    function viewTVL()
        public
        view
        returns (uint256 dsbAmount, uint256 totalCount)
    {
        uint256[] memory output = pRouter.getAmountsOut(baseValue, path);
        return (output[1] * totalStakedCount, totalStakedCount);
    }

    function isApproved(address addr) public view returns (bool) {
        return dsbNFTInstance.isApprovedForAll(addr, address(this));
    }

    function getStakedNFT(address addr, uint256 stakeCount)
        public
        view
        returns (uint256[] memory outputsd)
    {
        require(stakeCount > 0, "address does not stake a single nft");
        uint256[] memory outputs = new uint256[](stakeCount);
        uint256 currIndex = 0;
        for (uint256 i = 0; i < stakeCount; i++) {
            if (
                stakeTracker[accountTracker[addr].tokenId[i + 1]].isStaked ==
                true &&
                accountTracker[addr].tokenId[i + 1] != 0
            ) {
                outputs[currIndex] = accountTracker[addr].tokenId[i + 1];
                currIndex++;
            }
        }

        return outputs;
    }

    function viewRewardPool() public view returns (uint256) {
        return dsbTokenInstance.balanceOf(address(this));
    }

    function getBaseAmount() public view returns (uint256) {
        uint256[] memory output = pRouter.getAmountsOut(baseValue, path);
        return output[1];
    }

    function calculateReward(address addr) public view returns (uint256) {
        uint256[] memory stakedNft = getStakedNFT(
            addr,
            accountTracker[addr].stakeCount
        );
        require(stakedNft.length > 0, "no items staked");
        uint256[] memory output = pRouter.getAmountsOut(baseValue, path);
        uint256 baseReward = output[1];
        uint256 bp;
        uint256 totalReward;
        uint256 commitDate = accountTracker[addr].commitDate;
        if (block.timestamp - accountTracker[addr].lastClaim >= 30 days) {
            for (uint256 i = 0; i < stakedNft.length; i++) {
                StakeInfo storage sInfo = stakeTracker[stakedNft[i]];
                if (
                    sInfo.isStaked == true &&
                    sInfo.currentOwner == addr &&
                    stakedNft[i] != 0
                ) {
                    if (
                        block.timestamp - commitDate >= 30 days &&
                        block.timestamp - commitDate < 60 days
                    ) {
                        bp = 416; //4.16%
                    } else if (block.timestamp - commitDate < 30 days) {
                        bp = 0;
                    } else {
                        bp = 250; //2.5%
                    }
                    totalReward += (baseReward * (bp * 100)) / 1000000;
                }
            }
        } else {
            totalReward = 0;
        }

        return totalReward;
    }
}