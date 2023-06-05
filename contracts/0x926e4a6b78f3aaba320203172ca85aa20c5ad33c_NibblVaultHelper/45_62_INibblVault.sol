// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";


interface INibblVault is IERC20Upgradeable {

    event BuyoutInitiated(address indexed bidder, uint256 indexed bid);
    event BuyoutRejected(uint256 indexed rejectionValuation);
    event CuratorFeeUpdated(uint256 indexed fee);
    event Buy(address indexed buyer, uint256 indexed continousTokenAmount, uint256 indexed reserveTokenAmt);
    event Sell(address indexed seller, uint256 indexed continousTokenAmount, uint256 indexed reserveTokenAmt);

    function initialize(string memory _tokenName, string memory _tokenSymbol, address _assetAddress, uint256 _assetID, address _curator, uint256 _initialTokenSupply, uint256 _initialTokenPrice, uint256 _minBuyoutTime) external payable;
    function buy(uint256 _minAmtOut, address _to) external payable returns(uint256 _purchaseReturn);
    function sell(uint256 _amtIn, uint256 _minAmtOut, address payable _to) external returns(uint256 _saleReturn);
    function initiateBuyout() external payable returns(uint256 _buyoutBid);
    function withdrawUnsettledBids(address payable _to) external;
    function redeem(address payable _to) external returns(uint256 _amtOut);
    function redeemCuratorFee(address payable _to) external returns(uint256 _feeAccruedCurator);
    function updateCurator(address _newCurator) external;
    function withdrawERC721(address _assetAddress, uint256 _assetID, address _to) external;
    function withdrawMultipleERC721(address[] memory _assetAddresses, uint256[] memory _assetIDs, address _to) external;
    function withdrawERC20(address _asset, address _to) external;
    function withdrawMultipleERC20(address[] memory _assets, address _to) external;
    function withdrawERC1155(address _asset, uint256 _assetID, address _to) external;
    function withdrawMultipleERC1155(address[] memory _assets, uint256[] memory _assetIDs, address _to) external;

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}