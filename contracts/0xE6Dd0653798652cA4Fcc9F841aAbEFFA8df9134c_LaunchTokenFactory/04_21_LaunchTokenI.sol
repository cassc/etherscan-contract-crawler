// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ILaunchSettings.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./IWETH.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract LaunchTokenI is ERC20, ERC721Holder, ERC1155Holder {
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public nft;

    uint256 public nftId;

    uint256 public auctionEnd;
    uint256 public auctionLength;
    uint256 public reserveTotal;
    uint256 public livePrice;
    address payable public winning;
    enum State {
        inactive,
        live,
        ended,
        redeemed
    }
    State public auctionState;

    address public immutable launchSetting;

    address public curator;
    uint256 public fee;
    uint256 public lastClaimed;
    bool public vaultClosed;
    uint256 public votingTokens;
    mapping(address => uint256) public userPrices;

    event PriceUpdate(address indexed user, uint256 price);
    event Start(address indexed buyer, uint256 price);
    event Bid(address indexed buyer, uint256 price);

    event Won(address indexed buyer, uint256 price);
    event Redeem(address indexed redeemer);
    event Cash(address indexed owner, uint256 shares);

    event UpdateAuctionLength(uint256 length);

    event UpdateCuratorFee(uint256 fee);

    event FeeClaimed(uint256 fee);

    constructor(
        address _launchSetting,
        address _curator,
        address _nft,
        uint256 _nftId,
        uint256 _supply,
        uint256 _priceOfNft,
        uint256 _platformFee,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        launchSetting = _launchSetting;
        nft = _nft;
        nftId = _nftId;
        auctionLength = 1 days;
        curator = _curator;
        fee = _platformFee;
        lastClaimed = block.timestamp;
        auctionState = State.inactive;
        userPrices[_curator] = _priceOfNft;

        _mint(_curator, _supply);
    }

    function reservePrice() public view returns (uint256) {
        return votingTokens == 0 ? 0 : reserveTotal / votingTokens;
    }

    function kickCurator(address _curator) external {
        require(msg.sender == Ownable(launchSetting).owner(), "kick:not gov");

        curator = _curator;
    }

    function removeReserve(address _user) external {
        require(msg.sender == Ownable(launchSetting).owner(), "remove:not gov");
        require(
            auctionState == State.inactive,
            "update:auction live cannot update price"
        );

        uint256 old = userPrices[_user];
        require(0 != old, "update:not an update");
        uint256 weight = balanceOf(_user);

        votingTokens -= weight;
        reserveTotal -= weight * old;

        userPrices[_user] = 0;

        emit PriceUpdate(_user, 0);
    }

    function updateCurator(address _curator) external {
        require(msg.sender == curator, "update:not curator");

        curator = _curator;
    }

    function updateAuctionLength(uint256 _length) external {
        require(msg.sender == curator, "update:not curator");
        require(
            _length >= ILaunchSettings(launchSetting).minAuctionLength() &&
                _length <= ILaunchSettings(launchSetting).maxAuctionLength(),
            "update:invalid auction length"
        );

        auctionLength = _length;
        emit UpdateAuctionLength(_length);
    }

    function updateFee(uint256 _fee) external {
        require(msg.sender == curator, "update:not curator");
        require(_fee < fee, "update:can't raise");
        require(
            _fee <= ILaunchSettings(launchSetting).maxCuratorFee(),
            "update:cannot increase fee this high"
        );

        fee = _fee;
        emit UpdateCuratorFee(fee);
    }

    function updateUserPrice(uint256 _new) external {
        require(
            auctionState == State.inactive,
            "update:auction live cannot update price"
        );
        uint256 old = userPrices[msg.sender];
        require(_new != old, "update:not an update");
        uint256 weight = balanceOf(msg.sender);

        if (votingTokens == 0) {
            votingTokens = weight;
            reserveTotal = weight * _new;
        }
        // they are the only one voting
        else if (weight == votingTokens && old != 0) {
            reserveTotal = weight * _new;
        }
        // previously they were not voting
        else if (old == 0) {
            uint256 averageReserve = reserveTotal / votingTokens;

            uint256 reservePriceMin = (averageReserve *
                ILaunchSettings(launchSetting).minReserveFactor()) / 10000;
            require(_new >= reservePriceMin, "update:reserve price too low");
            uint256 reservePriceMax = (averageReserve *
                ILaunchSettings(launchSetting).maxReserveFactor()) / 10000;
            require(_new <= reservePriceMax, "update:reserve price too high");

            votingTokens += weight;
            reserveTotal += weight * _new;
        }
        // they no longer want to vote
        else if (_new == 0) {
            votingTokens -= weight;
            reserveTotal -= weight * old;
        }
        // they are updating their vote
        else {
            uint256 averageReserve = (reserveTotal - (old * weight)) /
                (votingTokens - weight);

            uint256 reservePriceMin = (averageReserve *
                ILaunchSettings(launchSetting).minReserveFactor()) / 10000;
            require(_new >= reservePriceMin, "update:reserve price too low");
            uint256 reservePriceMax = (averageReserve *
                ILaunchSettings(launchSetting).maxReserveFactor()) / 10000;
            require(_new <= reservePriceMax, "update:reserve price too high");

            reserveTotal = reserveTotal + (weight * _new) - (weight * old);
        }

        userPrices[msg.sender] = _new;

        emit PriceUpdate(msg.sender, _new);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        if (auctionState == State.inactive) {
            uint256 fromPrice = userPrices[_from];
            uint256 toPrice = userPrices[_to];

            // only do something if users have different reserve price
            if (toPrice != fromPrice) {
                // new holder is not a voter
                if (toPrice == 0) {
                    // get the average reserve price ignoring the senders amount
                    votingTokens -= _amount;
                    reserveTotal -= _amount * fromPrice;
                }
                // old holder is not a voter
                else if (fromPrice == 0) {
                    votingTokens += _amount;
                    reserveTotal += _amount * toPrice;
                }
                // both holders are voters
                else {
                    reserveTotal =
                        reserveTotal +
                        (_amount * toPrice) -
                        (_amount * fromPrice);
                }
            }
        }
    }

    function start() external payable {
        require(auctionState == State.inactive, "start:no auction starts");
        require(msg.value >= reservePrice(), "start:too low bid");
        require(
            votingTokens * 10000 >=
                ILaunchSettings(launchSetting).minVotePercentage() *
                    totalSupply(),
            "start:not enough voters"
        );

        auctionEnd = block.timestamp + auctionLength;
        auctionState = State.live;

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Start(msg.sender, msg.value);
    }

    function bid() external payable {
        require(auctionState == State.live, "bid:auction is not live");
        uint256 increase = ILaunchSettings(launchSetting).minBidIncrease() +
            10000;
        require(msg.value * 10000 >= livePrice * increase, "bid:too low bid");
        require(block.timestamp < auctionEnd, "bid:auction ended");

        // If bid is within 15 minutes of auction end, extend auction
        if (auctionEnd - block.timestamp <= 15 minutes) {
            auctionEnd += 15 minutes;
        }

        _sendETHOrWETH(winning, livePrice);

        livePrice = msg.value;
        winning = payable(msg.sender);

        emit Bid(msg.sender, msg.value);
    }

    function end() external {
        require(auctionState == State.live, "end:vault has already closed");
        require(block.timestamp >= auctionEnd, "end:auction live");

        if (ILaunchSettings(launchSetting).isERC721(nft)) {
            // transfer erc721 to redeemer
            IERC721(nft).safeTransferFrom(address(this), winning, nftId);
        }
        if (ILaunchSettings(launchSetting).isERC1155(nft)) {
            // transfer erc1155 to redeemer
            IERC1155(nft).safeTransferFrom(
                address(this),
                winning,
                nftId,
                1,
                ""
            );
        }

        auctionState = State.ended;

        emit Won(winning, livePrice);
    }

    function redeem() external {
        require(auctionState == State.inactive, "redeem:no redeeming");
        _burn(msg.sender, totalSupply());

        if (ILaunchSettings(launchSetting).isERC721(nft)) {
            // transfer erc721 to redeemer
            IERC721(nft).safeTransferFrom(address(this), msg.sender, nftId);
        }
        if (ILaunchSettings(launchSetting).isERC1155(nft)) {
            // transfer erc1155 to redeemer
            IERC1155(nft).safeTransferFrom(
                address(this),
                msg.sender,
                nftId,
                1,
                ""
            );
        }

        auctionState = State.redeemed;

        emit Redeem(msg.sender);
    }

    function cash() external {
        require(auctionState == State.ended, "cash:vault not closed yet");
        uint256 bal = balanceOf(msg.sender);
        require(bal > 0, "cash:no tokens to cash out");
        uint256 share = (bal * address(this).balance) / totalSupply();
        _burn(msg.sender, bal);

        _sendETHOrWETH(payable(msg.sender), share);

        emit Cash(msg.sender, share);
    }

    function _sendETHOrWETH(address to, uint256 value) internal {
        // Try to transfer ETH to the given recipient.
        if (!_attemptETHTransfer(to, value)) {
            // If the transfer fails, wrap and send as WETH, so that
            // the auction is not impeded and the recipient still
            // can claim ETH via the WETH contract (similar to escrow).
            IWETH(weth).deposit{value: value}();
            IWETH(weth).transfer(to, value);
            // At this point, the recipient can unwrap WETH.
        }
    }

    function _attemptETHTransfer(address to, uint256 value)
        internal
        returns (bool)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = to.call{value: value, gas: 30000}("");
        return success;
    }
}