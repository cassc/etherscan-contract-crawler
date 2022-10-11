// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) wNFT Launchpad. 
pragma solidity 0.8.11;
import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "IERC721Receiver.sol";
import "IWrapperCollateral.sol";
import "IWLAllocation.sol";


contract LaunchpadWNFTV1 is Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;

    struct Price {
        uint256 value;
        uint256 decimals;
    }

    address public wNFT;
    uint256 public enableAfter;
    address public tradableCollateral;
    address public allocationList;
    mapping(address => Price) public priceForOneCollateralUnit;

    event PriceChanged(address tokenForPay, uint256 value, uint256 decimals, uint256 timestamp);
    event Payed(address tokenForPay, uint256 value, uint256 timestamp, uint256 wNFT);


    constructor(address _wNFT, address _tradableCollateral, uint256 _enableAfter) {
        wNFT = _wNFT;
        tradableCollateral = _tradableCollateral;
        enableAfter = _enableAfter;

    }

    function claimNFT(uint256 tokenId) public {
        require(allocationList != address(0), "White list is NOT active");
        uint256 collateralBalance = _getCollateralBalance(tokenId);
        require(
            IWLAllocation(allocationList).availableAllocation(msg.sender, tradableCollateral) >= collateralBalance,
            "Too low allocation"
        );
        IWrapperCollateral(wNFT).transferFrom(address(this), msg.sender, tokenId);
        IWLAllocation(allocationList).spendAllocation(msg.sender, tradableCollateral, collateralBalance);
        emit Payed(address(0), 0, block.timestamp, tokenId);
    }
    
    function claimNFT(uint256 tokenId, address payWith) public payable {
        require(block.timestamp >= enableAfter, "Please wait for start date");
        require(priceForOneCollateralUnit[payWith].value > 0,"Cant pay with this ERC20");
        uint256 payAmount= getWNFTPrice(tokenId, payWith);
        if (payWith != address(0)){
            require(msg.value == 0, "No need ether");
            IERC20(payWith).safeTransferFrom(msg.sender, address(this), payAmount);
        } else {
            require(msg.value >= payAmount, "Received amount less then price");
            // Return change
            if  ((msg.value - payAmount) > 0) {
                address payable s = payable(msg.sender);
                s.transfer(msg.value - payAmount);
            }
        }
        IWrapperCollateral(wNFT).transferFrom(address(this), msg.sender, tokenId);
        emit Payed(payWith, payAmount, block.timestamp, tokenId);
    }

    function getWNFTPrice(uint256 tokenId, address payWith) public view returns (uint256 payAmount) {
        payAmount  = _getCollateralBalance(tokenId)
                * priceForOneCollateralUnit[payWith].value / priceForOneCollateralUnit[payWith].decimals;
    }

    function getTradableCollateralBalance(uint256 tokenId) public view returns (uint256 bal) {
        bal  = _getCollateralBalance(tokenId);
    }

    function getAvailableAllocation(address _user) external view returns(uint256) {
        require(allocationList != address(0), "White list is NOT active");
        return  IWLAllocation(allocationList).availableAllocation(_user, tradableCollateral);
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    ////////////////////////////////////////////////////////////
    /////////// Admin only           ////////////////////////////
    ////////////////////////////////////////////////////////////
    function withdrawEther() external onlyOwner {
        address payable o = payable(msg.sender);
        o.transfer(address(this).balance);
    }

    function withdrawTokens(address _erc20) external onlyOwner {
        IERC20(_erc20).transfer(msg.sender, IERC20(_erc20).balanceOf(address(this)));
    }

    function setPrice(address _erc20, uint256 _amount, uint256 _decimals) external onlyOwner {
        priceForOneCollateralUnit[_erc20] = Price({
            value:  _amount,
            decimals: _decimals
        });
    }
  
    function setEnableAfterDate(uint256 _enableAfter) external onlyOwner {
        enableAfter = _enableAfter;
    }

    function setAllocationList(address _contract) external onlyOwner {
        allocationList = _contract;
    }
    //////////////////////////////////////////////////////////////
    function _getCollateralBalance(uint256 tokenId) internal view returns (uint256 collateralBalance) {
        if (tradableCollateral == address(0)){
            (collateralBalance,) = IWrapperCollateral(wNFT).getTokenValue(tokenId);
        } else {
            collateralBalance = IWrapperCollateral(wNFT).getERC20CollateralBalance(tokenId, tradableCollateral);    
        }
    }
}