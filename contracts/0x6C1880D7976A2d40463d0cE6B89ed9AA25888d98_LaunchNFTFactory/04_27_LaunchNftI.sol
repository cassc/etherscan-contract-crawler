// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@charged-particles/erc721i/contracts/ERC721i.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./ILaunchSettings.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IWETH.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract LaunchNftI is ERC721i, ERC1155Holder, ERC721Holder, ERC2981{
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdTracker;

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
    uint96 public fee;
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

    constructor(
        string memory _name,
        string memory _symbol,
        address _minter,
        uint256 _maxSupply,
        address _launchSetting,
        address _nft,
        uint256 _nftId,
        uint256 _priceOfNft,
        uint96 _curatorFee
    ) ERC721i(_name, _symbol, _minter, _maxSupply) {
        launchSetting = _launchSetting;
        nft = _nft;
        nftId = _nftId;
        auctionLength = 1 days;
        curator = _minter;
        fee = _curatorFee;
        lastClaimed = block.timestamp;
        auctionState = State.inactive;
        userPrices[_minter] = _priceOfNft;
        _preMint();
        _transferOwnership(_minter);
        _tokenIdTracker._value = _maxSupply + 1;
        votingTokens = _maxSupply;
        reserveTotal = _maxSupply * _priceOfNft;
        _setDefaultRoyalty(_minter, _curatorFee);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, ERC721iEnumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



    function batchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds
  ) external virtual returns (uint256 amountTransferred) {
    amountTransferred = _batchTransfer(from, to, tokenIds);
  }

  function _batchTransfer(
    address from,
    address to,
    uint256[] memory tokenIds
  )
    internal
    virtual
    returns (uint256 amountTransferred)
  {
    uint256 count = tokenIds.length;

    for (uint256 i = 0; i < count; i++) {
      uint256 tokenId = tokenIds[i];

      // Skip invalid tokens; no need to cancel the whole tx for 1 failure
      // These are the exact same "require" checks performed in ERC721.sol for standard transfers.
      if (
        (ownerOf(tokenId) != from) ||
        (!_isApprovedOrOwner(from, tokenId)) ||
        (to == address(0))
      ) { continue; }

      _beforeTokenTransfer(from, to, tokenId);

      // Clear approvals from the previous owner
      _approve(address(0), tokenId);

      amountTransferred += 1;
      _owners[tokenId] = to;

      emit Transfer(from, to, tokenId);

      _afterTokenTransfer(from, to, tokenId);
    }

    // We can save a bit of gas here by updating these state-vars atthe end
    _balances[from] -= amountTransferred;
    _balances[to] += amountTransferred;
  }



    function reservePrice() public view returns (uint256) {
        return votingTokens == 0 ? 0 : reserveTotal / votingTokens;
    }

    function kickCurator(address _curator) external {
        require(msg.sender == Ownable(launchSetting).owner(), "kick:not gov");

        curator = _curator;
        _setDefaultRoyalty(curator, fee);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        if (auctionState == State.inactive) {
            uint256 fromPrice = userPrices[_from];
            uint256 toPrice = userPrices[_to];
            if (toPrice != fromPrice) {
                if (toPrice == 0) {
                    votingTokens -= 1;
                    reserveTotal -= 1 * fromPrice;
                } else if (fromPrice == 0) {
                    votingTokens += 1;
                    reserveTotal += 1 * toPrice;
                } else {
                    reserveTotal = reserveTotal + toPrice - fromPrice;
                }
            }
        }
    }

    function removeReserve(address _user) external {
        require(msg.sender == Ownable(launchSetting).owner(), "remove:not gov");
        require(
            auctionState == State.inactive,
            "update:auction live"
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
        _setDefaultRoyalty(curator,fee);
    }

    function updateAuctionLength(uint256 _length) external {
        require(msg.sender == curator, "update:not curator");
        require(
            _length >=
                ILaunchSettings(launchSetting).minAuctionLengthForNFT() &&
                _length <=
                ILaunchSettings(launchSetting).maxAuctionLengthForNFT(),
            "update:invalid auction length"
        );

        auctionLength = _length;
        emit UpdateAuctionLength(_length);
    }

    function updateFee(uint96 _fee) external {
        require(msg.sender == curator, "update:not curator");
        require(_fee < fee, "update:can't raise");
        require(
            _fee <= ILaunchSettings(launchSetting).maxCuratorFeeForNFT(),
            "update:cannot increase fee this high"
        );
        fee = _fee;
        _setDefaultRoyalty(msg.sender, _fee);
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
                ILaunchSettings(launchSetting).minReserveFactorForNFT()) / 10000;
            require(_new >= reservePriceMin, "update:reserve price too low");
            uint256 reservePriceMax = (averageReserve *
                ILaunchSettings(launchSetting).maxReserveFactorForNFT()) / 10000;
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
                ILaunchSettings(launchSetting).minReserveFactorForNFT()) / 10000;
            require(_new >= reservePriceMin, "update:reserve price too low");
            uint256 reservePriceMax = (averageReserve *
                ILaunchSettings(launchSetting).maxReserveFactorForNFT()) / 10000;
            require(_new <= reservePriceMax, "update:reserve price too high");

            reserveTotal = reserveTotal + (weight * _new) - (weight * old);
        }

        userPrices[msg.sender] = _new;

        emit PriceUpdate(msg.sender, _new);
    }

    function calculateRoyaltyFees(uint256 _salePrice) public view returns (uint256 _amount){
        return (_salePrice / 10000) * fee;
    }

    function start() external payable {
        require(auctionState == State.inactive, "start:no auction starts");
        require(msg.value >= reservePrice(), "start:too low bid");
        require(
            votingTokens * 10000 >=
                ILaunchSettings(launchSetting).minVotePercentageForNFT() *
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
        uint256 increase = ILaunchSettings(launchSetting)
            .minBidIncreaseForNFT() + 10000;
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
        require(auctionState == State.live, "end:vault closed");
        require(block.timestamp >= auctionEnd, "end:auction live");


        if (ILaunchSettings(launchSetting).isERC721(nft)) {
            // transfer erc721 to redeemer
            IERC721(nft).safeTransferFrom(address(this), winning, nftId);
        }
        if (ILaunchSettings(launchSetting).isERC1155(nft)) {
            // transfer erc1155 to redeemer
            IERC1155(nft).safeTransferFrom(address(this), winning, nftId, 1, "");
        }
        auctionState = State.ended;

        emit Won(winning, livePrice);
    }

    function redeem() external {
        require(auctionState == State.inactive, "redeem:no redeeming");

        bool allBurned = burnAllToken();
        require(allBurned, "redeem:not burned");

        if (ILaunchSettings(launchSetting).isERC721(nft)) {
            // transfer erc721 to redeemer
            IERC721(nft).safeTransferFrom(address(this), msg.sender, nftId);
        }
        if (ILaunchSettings(launchSetting).isERC1155(nft)) {
            // transfer erc1155 to redeemer
            IERC1155(nft).safeTransferFrom(address(this), msg.sender, nftId, 1, "");
        }
        auctionState = State.redeemed;

        emit Redeem(msg.sender);
    }

    function cash(uint256[] memory tokenList) external {
        require(auctionState == State.ended, "cash:vault not closed yet");
        uint256 bal = balanceOf(msg.sender);
        require(bal > 0, "cash:no tokens to cash out");
        require(bal == tokenList.length, "cash:invalid tokenList");
        uint256 share = (bal * address(this).balance) / totalSupply();
        // TODO
        for (uint256 i = 0; i < bal; i++) {
            _burn(tokenList[i]);
        }

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

    function burnAllToken() internal returns (bool tokensBurned) {
        for (uint256 i = 0; i < _tokenIdTracker.current(); i++) {
            if (_exists(i)) _burn(i);
        }
        tokensBurned = true;
        _tokenIdTracker.reset();
    }
}