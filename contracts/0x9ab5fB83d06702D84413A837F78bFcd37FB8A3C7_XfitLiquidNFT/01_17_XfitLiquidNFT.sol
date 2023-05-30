// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ERC721.sol";
import "Counters.sol";
import "SafeERC20.sol";

import "IFeeGeneratingContract.sol";
import "IXfaiFlashMintable.sol";
import "IXfitLiquidNFT.sol";

contract XfitLiquidNFT is IXfitLiquidNFT, ERC721 {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    address private token2Stake;
    //address private token2Redeem;
    address public feeGeneratingContract;
    address private owner;
    uint256 public stakedReserve;
    uint256 public totalReserveShare;
    uint256 private vestingPeriod;
    uint256 private vestingPeriodStart;
    string private baseUri;
    mapping(uint256 => NFTData) private tokenData;

    struct NFTData {
        uint256 share;
        uint256 vestingStart;
        uint256 vestingEnd;
    }

    constructor(
        address _owner,
        address _token2Stake, // xfit
        //address _token2Redeem, // xfai
        uint256 _vestingPeriod,
        uint256 _initialReserve
    ) ERC721("Liquid-NFT", "LNFT") {
        owner = _owner;
        token2Stake = _token2Stake;
        //token2Redeem = _token2Redeem;
        vestingPeriod = _vestingPeriod;
        stakedReserve = _initialReserve;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'XfitLiquidNFT: FORBIDDEN');
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 _tokenID) public view override returns (string memory) {
        require(_exists(_tokenID), "XfitLiquidNFT: URI query for nonexistent token");
        return _baseURI();
    }

    function setBaseURI(string memory _newURI) external override onlyOwner {
        baseUri = _newURI;
    }

    function getLatestID() public view override returns (uint256 counter) {
        counter = _tokenIds.current();
    }

    function stake(uint256 _amount) internal returns (uint256 share) {
        require(_amount > 0, "XfitLiquidNFT: Amount too small");
        IERC20 token = IERC20(token2Stake);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        stakedReserve += _amount;
        share = 1e18 * _amount / stakedReserve;
    }

    function getNFTData(uint256 _tokenID) public view override returns (
        uint256 share,
        uint256 vestingStart,
        uint256 vestingEnd) {
            require(_exists(_tokenID), "XfitLiquidNFT: NFT does not exist");
            NFTData memory nft = tokenData[_tokenID];
            share = nft.share;
            vestingStart = nft.vestingStart;
            vestingEnd = nft.vestingEnd;
        }
    
    function share2Amount(uint256 share) internal view returns (uint256 redeemableAmountOfShare) {
        uint256 feeGeneratingContractReserve = IFeeGeneratingContract(feeGeneratingContract).getFeeReserve();
        redeemableAmountOfShare = feeGeneratingContractReserve * share / totalReserveShare;
    }

    // Returns the underlying value of an NFT in terms of token2Stake 
    function getUnderlyingValue(uint256 _tokenID) public view override returns (uint256 underlyingNFTValue) {
        (uint256 share,,) = getNFTData(_tokenID);
        underlyingNFTValue = share2Amount(share);
    }

    function getRedeemableTokenAmount(uint256 _tokenID) public view override returns (uint256 redeemableAmount) {
        (uint256 share, uint256 vestingStart, uint256 vestingEnd) = getNFTData(_tokenID);
        if (vestingStart < vestingPeriodStart) {
            vestingStart = vestingPeriodStart;
            vestingEnd = vestingPeriodStart + vestingPeriod;
        }
        uint256 currentBlock = block.number;
        uint256 upperBoundBlock = currentBlock <= vestingEnd ? currentBlock : vestingEnd;
        uint256 redeemableShare = share * (upperBoundBlock - vestingStart) / vestingPeriod;
        redeemableAmount = share2Amount(redeemableShare);
    }

    function mint(address _to, uint256 _amount) public override returns (bool) {
        uint256 share = stake(_amount);
        totalReserveShare += share;
        _tokenIds.increment();
        uint256 newTokenID = _tokenIds.current();
        uint256 currentBlock = block.number;
        tokenData[newTokenID] = NFTData(share, currentBlock, currentBlock + vestingPeriod);
        _safeMint(_to, newTokenID);
        emit Staked(_to, _amount, share, newTokenID);
        return true;
    }

    function boost(uint256 _amount, uint256 _tokenID) public override returns (bool) {
        require(msg.sender == ownerOf(_tokenID), "XfitLiquidNFT: Not the owner of the NFT");
        uint256 share = stake(_amount);
        totalReserveShare += share;
        uint256 currentBlock = block.number;
        (uint256 NFTShare,,) = getNFTData(_tokenID);
        tokenData[_tokenID] = NFTData(NFTShare + share, currentBlock, currentBlock + vestingPeriod);
        emit Boosted(msg.sender, _amount, share, _tokenID);
        return true;
    }

    function redeem(address _to, uint256 _amount, uint256 _tokenID) public override returns (bool) {
        require(vestingPeriodStart != 0, "XfitLiquidNFT: Redeem phase is not active yet");
        require(_amount > 0, "XfitLiquidNFT: Invalid amount");
        require(msg.sender == ownerOf(_tokenID), "XfitLiquidNFT: Not the owner of the NFT");
        uint256 redeemableAmount = getRedeemableTokenAmount(_tokenID);
        require(_amount <= redeemableAmount, "XfitLiquidNFT: Amount exceeds redeemable amount");

        uint256 currentBlock = block.number;
        uint256 dif2share;
        uint256 underlyingValue;
        (uint256 NFTShare, , ) = getNFTData(_tokenID);
        underlyingValue = getUnderlyingValue(_tokenID);
        bool redeeemed = IFeeGeneratingContract(feeGeneratingContract).redeemFees(_to, _amount);
        require(redeeemed == true, "XfitLiquidNFT: not able to redeem fees");
        dif2share = NFTShare * _amount / underlyingValue;
        tokenData[_tokenID] = NFTData(NFTShare - dif2share, currentBlock, currentBlock + vestingPeriod);
        totalReserveShare -= dif2share;

        emit Redeemed(msg.sender, _amount, _tokenID);
        return true;
    }

    function setOwner(address _owner) external override onlyOwner {
        owner = _owner;
        emit ChangedOwner(_owner);
    }

    function setFeeGeneratingContract(address _feeGeneratingContract) external override onlyOwner {
        feeGeneratingContract = _feeGeneratingContract;
    }

    function setVestingPeriodStart(uint256 _vestingPeriodStart) external override onlyOwner {
        vestingPeriodStart = _vestingPeriodStart;
    }

    function setVestingPeriod(uint256 _vestingPeriod) external override onlyOwner {
        vestingPeriod = _vestingPeriod;
    }

}