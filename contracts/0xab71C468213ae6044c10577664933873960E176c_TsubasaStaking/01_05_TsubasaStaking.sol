//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract TsubasaStaking is IERC721Receiver {
    /**
     * admin address
     */
    address public admin;
    /**
     * how many tokens can be rewarded per second per NFT
     */
    uint256 public rewardRate;
    /**
     * can user stake NFTs
     */
    bool public stakeEnabled;
    /**
     * when does the reward start
     */
    uint256 public rewardStartTimestamp;
    /**
     * nft address
     */
    address public nftAddress;
    /**
     * ERC20 token address
     */
    address public tokenAddress;
    /**
     * nft id => owner
     */
    mapping(uint256 => address) public nftOwners;
    /**
     * nft id => reward start time
     */
    mapping(uint256 => uint256) public nftTimestamp;
    /**
     * address => staked nft ids
     */
    mapping(address => uint256[]) public userNftIds;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is NOT admin");
        _;
    }

    constructor(
        uint256 rewardRate_,
        address nftAddress_,
        address tokenAddress_
    ) {
        admin = msg.sender;
        stakeEnabled = false;
        rewardRate = rewardRate_;
        rewardStartTimestamp = block.timestamp;
        nftAddress = nftAddress_;
        tokenAddress = tokenAddress_;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address, /* operator */
        address from,
        uint256 tokenId,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        require(stakeEnabled, "Stake disabled");
        // only specified nft contract can call this api
        require(msg.sender == nftAddress, "Wrong NFT");
        // mint to this contract directly is not allowed
        require(from != address(0), "Wrong sender address");
        // confirm nft received
        require(
            IERC721(nftAddress).ownerOf(tokenId) == address(this),
            "NFT NOT received"
        );
        // check nft stake information is empty
        require(nftOwners[tokenId] == address(0), "NFT already staked");
        _stakeNft(tokenId, from);
        return IERC721Receiver.onERC721Received.selector;
    }

    function _stakeNft(uint256 nftId, address owner) private {
        nftOwners[nftId] = owner;
        nftTimestamp[nftId] = block.timestamp;
        userNftIds[owner].push(nftId);
    }

    function stakeApproved() public view returns (bool) {
        return IERC721(nftAddress).isApprovedForAll(msg.sender, address(this));
    }

    function stakeNfts(uint256[] calldata nftIds) public {
        require(stakeApproved(), "Operation unapproved");
        _checkNftOwners(nftIds, msg.sender);
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            IERC721(nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                nftId
            );
        }
    }

    function getStakedNftIds(address owner)
        public
        view
        returns (uint256[] memory)
    {
        return userNftIds[owner];
    }

    function unstakeNfts(uint256[] calldata nftIds) public {
        _checkNftOriginalOwners(nftIds, msg.sender);
        uint256 token = _calculateRewards(nftIds);
        _transferToken(msg.sender, token);
        _returnNfts(nftIds, msg.sender);
    }

    function claimableToken() public view returns (uint256) {
        uint256[] memory nftIds = userNftIds[msg.sender];
        return _calculateRewards(nftIds);
    }

    function claimToken() public {
        uint256[] memory nftIds = userNftIds[msg.sender];
        uint256 token = _calculateRewards(nftIds);
        _resetRewardStartTime(nftIds);
        _transferToken(msg.sender, token);
    }

    function setAdmin(address admin_) public onlyAdmin {
        admin = admin_;
    }

    function setNftAddress(address nftAddress_) public onlyAdmin {
        nftAddress = nftAddress_;
    }

    function setTokenAddress(address tokenAddress_) public onlyAdmin {
        tokenAddress = tokenAddress_;
    }

    function setStakeEnabled(bool stakeEnabled_) public onlyAdmin {
        stakeEnabled = stakeEnabled_;
    }

    function setRewardRate(uint256 rewardRate_) public onlyAdmin {
        rewardRate = rewardRate_;
    }

    function setRewardStartTimestamp(uint256 rewardStartTimestamp_)
        public
        onlyAdmin
    {
        rewardStartTimestamp = rewardStartTimestamp_;
    }

    function returnNfts(uint256[] calldata nftIds) public onlyAdmin {
        for (uint256 i = 0; i < nftIds.length; i++) {
            returnNft(nftIds[i]);
        }
    }

    function returnNft(uint256 nftId) public onlyAdmin {
        _returnNft(nftId, nftOwners[nftId]);
    }

    function returnNftToAddress(uint256 nftId, address owner) public onlyAdmin {
        _returnNft(nftId, owner);
    }

    function returnSpecifiedNftToAddress(
        address nftContract,
        uint256 nftId,
        address owner
    ) public onlyAdmin {
        _transferNft(nftContract, nftId, owner);
    }

    function withdrawEther() public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(uint256 amount) public onlyAdmin {
        _transferToken(msg.sender, amount);
    }

    function withdrawAllToken() public onlyAdmin {
        withdrawToken(tokenBalance());
    }

    function tokenBalance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function _checkNftOwners(uint256[] memory nftIds, address owner)
        private
        view
    {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            require(
                IERC721(nftAddress).ownerOf(nftId) == owner,
                "Wrong NFT owner"
            );
        }
    }

    function _checkNftOriginalOwners(uint256[] memory nftIds, address owner)
        private
        view
    {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            require(nftOwners[nftId] == owner, "Wrong NFT owner");
        }
    }

    function _calculateRewards(uint256[] memory nftIds)
        private
        view
        returns (uint256)
    {
        uint256 currentTime = block.timestamp;
        if (currentTime <= rewardStartTimestamp) {
            return 0;
        }
        uint256 rewardTime = 0;
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            uint256 startTime = nftTimestamp[nftId];
            if (startTime < rewardStartTimestamp) {
                startTime = rewardStartTimestamp;
            }
            if (startTime >= currentTime) continue;
            rewardTime = rewardTime + (currentTime - startTime);
        }
        return rewardTime * rewardRate;
    }

    function _resetRewardStartTime(uint256[] memory nftIds) private {
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            uint256 time = nftTimestamp[nftId];
            if (time >= currentTime) continue;
            nftTimestamp[nftId] = currentTime;
        }
    }

    function _transferToken(address to, uint256 amount) private {
        require(
            amount <= tokenBalance(),
            "Insufficient token in the pool, contact admin"
        );
        if (amount > 0) {
            IERC20(tokenAddress).transfer(to, amount);
        }
    }

    function _returnNfts(uint256[] memory nftIds, address owner) private {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            _returnNft(nftId, owner);
        }
    }

    function _returnNft(uint256 nftId, address to) private {
        _removeNftIdOfUser(to, nftId);
        delete nftOwners[nftId];
        _transferNft(nftAddress, nftId, to);
    }

    function _transferNft(
        address nftContract,
        uint256 nftId,
        address to
    ) private {
        IERC721(nftContract).safeTransferFrom(address(this), to, nftId);
    }

    function _removeNftIdOfUser(address owner, uint256 nftId) private {
        for (uint256 i = 0; i < userNftIds[owner].length; i++) {
            if (userNftIds[owner][i] == nftId) {
                userNftIds[owner][i] = userNftIds[owner][
                    userNftIds[owner].length - 1
                ];
                userNftIds[owner].pop();
                return;
            }
        }
    }
}