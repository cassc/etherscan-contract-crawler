// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Metaswap
 * @notice Metaswap contract is NFT Swap Service
 */

contract Metaswap is ReentrancyGuard, Ownable, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;
    /**
     * @dev Swap/Trade Id Counter
     */
    uint64 public tradeIdCounter;
    /**
     * @dev Tip Collection Address
     */
    address payable public tipAddress;
    /**
     * @dev Token Limit
     */
    uint16 public tokenLimit;
    /**
     * @dev Trade/swap deadline duration in epoc time
     */
    uint256 public deadlineDuration;
    /**
     * @dev Mapping Trade Id to Offerer Address
     */
    mapping(uint64 => address payable) public offererAddress;
    /**
     * @dev Mapping Trade Id to Offer Acceptor Address
     */
    mapping(uint64 => address) public acceptorAddress;
    /**
     * @dev Mapping Trade Id to Acceptor Address to trade access status used for withdrawal
     */
    mapping(uint64 => mapping(address => bool)) public tradeStatus;
    /**
     * @dev Mapping Trade Id to offer deadline
     */
    mapping(uint64 => uint256) public tradeDeadline;
    /**
     * @dev Mapping Trade Id to amount paid
     */
    mapping(uint256 => uint256) public tradeAmount;
    /**
     * @dev Mapping Trade Id to trade tokens for trade/swap creator
     */
    mapping(uint64 => uint256[]) public offererTokenIds;
    /**
     * @dev Mapping Trade Id to trade tokens for trade/swap acceptor
     */
    mapping(uint64 => uint256[]) public acceptorTokenIds;
    /**
     * @dev Mapping Trade Id to trade NFT token contract addresses for trade/swap offerer
     */
    mapping(uint64 => address[]) public offererNfts;
    /**
     * @dev Mapping Trade Id to trade NFT token contract addresses for for trade/swap acceptor
     */
    mapping(uint256 => address[]) public acceptorNfts;
    /**
     * @dev Mapping Trade Id to trade tokens quantity in ERC1155 for trade/swap offerer
     */
    mapping(uint64 => uint256[]) public offererTokenAmounts;
    /**
     * @dev Mapping Trade Id to trade tokens quantity in ERC1155 for trade/swap acceptor
     */
    mapping(uint64 => uint256[]) public acceptorTokenAmounts;
    /**
     * @dev Mapping Trade Id to execute Lock
     */
    mapping(uint64 => bool) public executeLock;

    /**
     * @notice event for Trade Details
     * @param _message the function name associated with the transactions
     * @param _tradeId the unique trade Id associated with swap/trade
     * @param _offerer the swap/trade offer creator address
     * @param _acceptor the swap/trade acceptor address
     */
    event Trade(
        string _message,
        uint64 indexed _tradeId,
        address _offerer,
        address _acceptor
    );

    /**
     * @notice event for setting Tip Address
     * @param _tipAddress the new tip Address
     */
    event TipAddressSet(address _tipAddress);
    /**
     * @notice event for setting Token Limit
     * @param tokenLimit the token Limit
     */
    event TokenLimitSet(uint16 tokenLimit);
    /**
     * @notice event for setting deadline duration
     * @param deadlineDuration the duration in epoc time
     */
    event DeadlineSet(uint256 deadlineDuration);

    constructor() {}

    /**
     * @dev To set the tip receiving address of the platform
     */
    function setTipAddress(address payable _tipAddress) external onlyOwner {
        require(_tipAddress != address(0), "Zero Address not allowed");
        tipAddress = _tipAddress;
        emit TipAddressSet(_tipAddress);
    }

    /**
     * @dev To set the token limit of the platform
     */
    function setTokenLimit(uint16 _tokenLimit) external onlyOwner {
        tokenLimit = _tokenLimit;
        emit TokenLimitSet(_tokenLimit);
    }

    /**
     * @dev To set the epoc time deadline duration address
     */
    function setDeadline(uint256 _duration) external onlyOwner {
        deadlineDuration = _duration;
        emit DeadlineSet(_duration);
    }

    /**
     * @dev to withdraw ETH from the contract
     * @param _account the receiver account
     * @param _amount the ETH amount in Wei
     */
    function withdrawEth(
        address payable _account,
        uint256 _amount
    ) external onlyOwner {
        require(_account != address(0), "Zero Address not allowed");
        (bool success, ) = _account.call{value: _amount}(new bytes(0));
        require(success, "Transfer failed");
    }

    /**
     * @dev to withdraw ERC20 tokens from the contract
     * @param _account the receiver account
     * @param _amount the token amount in Wei
     * @param _tokenAddress the ERC20 token address
     */
    function withdrawErc20(
        address _account,
        uint256 _amount,
        address _tokenAddress
    ) external onlyOwner {
        require(_tokenAddress != address(0), "Zero Address not allowed");
        IERC20(_tokenAddress).safeTransferFrom(
            address(this),
            _account,
            _amount
        );
    }

    /**
     * @notice swap offer proposals for NFTs and ETH
     * @dev token amount for ERC721 = 0 , ERC1155 > 0
     * @dev tradeId the unique trade Id associated with the swap/trade, obtained as a return value
     * @param acceptor the swap acceptor,amount reciever address
     * @param amount the amount associated with swap ,  the tip amount ( if no tipping ,tipAmount = 0, tip amount is in Wei)
     * @param offererTokenIdList the token ID list for swap offerer
     * @param acceptorTokenIdList the token ID list for swap acceptor
     * @param offererTokenAmount the offerer token amount for each token ID
     * @param acceptorTokenAmount the acceptor token amount for each token ID
     * @param offererNftList the offerer collection address for each token ID
     * @param acceptorNftList the acceptor collection address for each token ID
     */
    function createOffer(
        address acceptor,
        uint256[2] memory amount,
        uint256[] memory offererTokenIdList,
        uint256[] memory acceptorTokenIdList,
        uint256[] memory offererTokenAmount,
        uint256[] memory acceptorTokenAmount,
        address[] memory offererNftList,
        address[] memory acceptorNftList
    ) external payable nonReentrant returns (uint64, bool) {
        require(acceptor != address(0), "Zero Address not allowed");
        tradeIdCounter += 1;
        uint64 tradeId = tradeIdCounter;
        require(
            offererNftList.length < tokenLimit,
            "NFT limit exceeded by initiator."
        );
        require(
            acceptorNftList.length < tokenLimit,
            "NFT limit exceeded by executor."
        );
        require(
            offererTokenIdList.length == offererNftList.length &&
                offererTokenIdList.length == offererTokenAmount.length,
            "Mismatch in initiator's collection."
        );
        require(
            acceptorTokenIdList.length == acceptorNftList.length &&
                acceptorTokenIdList.length == acceptorTokenAmount.length,
            "Mismatch in acceptor's collection."
        );
        tradeDeadline[tradeId] = block.timestamp + deadlineDuration;
        offererAddress[tradeId] = payable(msg.sender);
        acceptorAddress[tradeId] = acceptor;
        tradeAmount[tradeId] = amount[0];
        offererTokenIds[tradeId] = offererTokenIdList;
        acceptorTokenIds[tradeId] = acceptorTokenIdList;
        offererTokenAmounts[tradeId] = offererTokenAmount;
        acceptorTokenAmounts[tradeId] = acceptorTokenAmount;
        offererNfts[tradeId] = offererNftList;
        acceptorNfts[tradeId] = acceptorNftList;
        tradeStatus[tradeId][acceptor] = true;
        if (amount[1] > 0) {
            (bool success, ) = tipAddress.call{value: amount[1]}(new bytes(0));
            require(success, "Transfer failed");
        }
        emit Trade("createOffer", tradeId, msg.sender, acceptor);
        return (tradeId, true);
    }

    /**
     * @notice Withdraw swap/trade offers proposal
     * @param  _tradeId the unique trade Id associated with swap/trade
     */
    function withdrawOffer(uint64 _tradeId) external returns (bool) {
        require(
            msg.sender == offererAddress[_tradeId] ||
                msg.sender == acceptorAddress[_tradeId],
            "UnAuthorized Withdrawal"
        );
        tradeStatus[_tradeId][acceptorAddress[_tradeId]] = false;
        emit Trade(
            "withdrawOffer",
            _tradeId,
            msg.sender,
            acceptorAddress[_tradeId]
        );
        return true;
    }

    /**
     * @notice Execute Swap, ERC721 and ERC1155 NFTs
     * @dev tipAmount = 0, if no tipping, sent to tip address
     * @param _tradeId the unique trade Id associated with swap
     * @param _tipAmount the tipAmount for the trade
     */
    function executeSwap(
        uint64 _tradeId,
        uint256 _tipAmount
    ) external payable nonReentrant returns (bool) {
        require(executeLock[_tradeId] == false, "Execute Locked");
        require(
            msg.sender == acceptorAddress[_tradeId],
            "Not the set acceptor for this trade."
        );
        require(
            msg.value == (tradeAmount[_tradeId] + _tipAmount),
            "Incorrect Amount"
        );
        require(
            tradeStatus[_tradeId][msg.sender] == true,
            "Trade not authorized or withdrawn"
        );
        require(
            block.timestamp <= tradeDeadline[_tradeId],
            "Trade window expired"
        );
        address payable offerer = offererAddress[_tradeId];
        executeLock[_tradeId] = true;
        trade(
            msg.sender,
            offerer,
            acceptorTokenIds[_tradeId],
            acceptorTokenAmounts[_tradeId],
            acceptorNfts[_tradeId]
        );
        trade(
            offerer,
            msg.sender,
            offererTokenIds[_tradeId],
            offererTokenAmounts[_tradeId],
            offererNfts[_tradeId]
        );
        (bool successTransfer, ) = offerer.call{value: tradeAmount[_tradeId]}(
            new bytes(0)
        );
        require(successTransfer, "Transfer failed to Offerer");
        if (_tipAmount > 0) {
            (bool success, ) = tipAddress.call{value: _tipAmount}(new bytes(0));
            require(success, "Transfer failed");
        }
        emit Trade("executeSwap", _tradeId, offerer, msg.sender);
        return true;
    }

    function trade(
        address user1,
        address user2,
        uint256[] memory tokenId,
        uint256[] memory tokenAmount,
        address[] memory contractAddress
    ) private {
        bytes memory data = bytes("swap");
        uint256 arrayLength = contractAddress.length;
        if (arrayLength > 0) {
            for (uint256 i = 0; i < arrayLength; i++) {
                if (tokenAmount[i] == 0) {
                    IERC721 token = IERC721(contractAddress[i]);
                    token.transferFrom(user1, address(this), tokenId[i]);
                    token.transferFrom(address(this), user2, tokenId[i]);
                } else if (tokenAmount[i] > 0) {
                    IERC1155 token = IERC1155(contractAddress[i]);
                    token.safeTransferFrom(
                        user1,
                        address(this),
                        tokenId[i],
                        tokenAmount[i],
                        data
                    );
                    token.safeTransferFrom(
                        address(this),
                        user2,
                        tokenId[i],
                        tokenAmount[i],
                        data
                    );
                }
            }
        }
    }
}