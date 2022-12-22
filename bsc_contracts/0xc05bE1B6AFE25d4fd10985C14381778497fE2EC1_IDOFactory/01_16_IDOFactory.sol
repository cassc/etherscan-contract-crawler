pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./IDOPool.sol";

contract IDOFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Burnable;
    using SafeERC20 for ERC20;

    ERC20Burnable public feeToken;
    address public feeWallet;
    uint256 public feeAmount;
    uint256 public burnPercent;
    uint256 public divider;
    uint256 public withdrawfeePercentage4 = 50;

    uint256 public transferAmount;

    struct  PoolInfoStruct{
        uint256 startTimestamp;
        uint256 finishTimestamp;
        uint256 startClaimTimestamp;
        uint256 lpWithdrawTimestamp;
        uint256 minEthPayment;
        uint256 maxEthPayment;
        uint256 maxDistributedTokenAmount;
    }

    struct  Uniswap{
        address FACTORY;
        address ROUTER;
        address WETH;
    }

    event IDOCreated(address indexed owner, address idoPool,
        address indexed rewardToken,
        string tokenURI
        );

    event TokenFeeUpdated(address newFeeToken);
    event FeeAmountUpdated(uint256 newFeeAmount);
    event BurnPercentUpdated(uint256 newBurnPercent, uint256 divider);
    event FeeWalletUpdated(address newFeeWallet);

    constructor(
        ERC20Burnable _feeToken,
        uint256 _feeAmount,
        uint256 _burnPercent
    ){
        feeToken = _feeToken;
        feeAmount = _feeAmount;
        burnPercent = _burnPercent;
        divider = 100;
    }

    function setWithdrawFee(uint256 _fee4) external onlyOwner {
        withdrawfeePercentage4 = _fee4;
    }

    function setFeeToken(address _newFeeToken) external onlyOwner {
        require(isContract(_newFeeToken), "New address is not a token");
        feeToken = ERC20Burnable(_newFeeToken);

        emit TokenFeeUpdated(_newFeeToken);
    }

    function setFeeAmount(uint256 _newFeeAmount) external onlyOwner {
        feeAmount = _newFeeAmount;

        emit FeeAmountUpdated(_newFeeAmount);
    }

    function setFeeWallet(address _newFeeWallet) external onlyOwner {
        feeWallet = _newFeeWallet;

        emit FeeWalletUpdated(_newFeeWallet);
    }

    function setBurnPercent(uint256 _newBurnPercent, uint256 _newDivider)
        external
        onlyOwner
    {
        require(_newBurnPercent <= _newDivider, "Burn percent must be less than divider");
        burnPercent = _newBurnPercent;
        divider = _newDivider;

        emit BurnPercentUpdated(_newBurnPercent, _newDivider);
    }

    function createIDO(
        ERC20 _rewardToken,
        uint256 _tokenRate,
        uint256 _listingRate,
        IDOPool.Capacity memory _capacity,
        IDOPool.Time memory _time,
        IDOPool.Uniswap memory _uniswap,
        IDOPool.LockInfo memory _lockInfo,
        string memory _tokenURI
    ) external payable returns(address){
        if(feeAmount > 0){
            uint256 burnAmount = feeAmount.mul(burnPercent).div(divider);

            feeToken.safeTransferFrom(
                msg.sender,
                feeWallet,
                feeAmount.sub(burnAmount)
            );
            feeToken.safeTransferFrom(msg.sender, address(this), burnAmount);
            feeToken.burn(burnAmount);
        }

        IDOPool idoPool =
            new IDOPool(
                _rewardToken,
                _tokenRate,
                _listingRate,
                _capacity,
                _time,
                _uniswap,
                _lockInfo,
                _tokenURI
            );
            
        transferAmount = getTokenAmount(_capacity.hardCap, _tokenRate) + getTokenAmount(_capacity.hardCap * _lockInfo.lpPercentage / 100, _listingRate);
        idoPool.transferOwnership(msg.sender);

        _rewardToken.safeTransferFrom(
            msg.sender,
            address(idoPool),
            transferAmount
        );


        emit IDOCreated(msg.sender, 
                        address(idoPool),
                        address(_rewardToken),
                        _tokenURI);

        return address(idoPool);
    }

    function getTokenAmount(uint256 _ethAmount, uint256 _rate)
        internal
        view
        returns (uint256)
    {
        return _ethAmount.mul(_rate).div(10 ** 18);
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function getTokenAmount(uint256 ethAmount, uint8 decimals, uint256 price)
        internal
        view
        returns (uint256)
    {
        return ethAmount.mul(10**decimals).div(price);
    }
}