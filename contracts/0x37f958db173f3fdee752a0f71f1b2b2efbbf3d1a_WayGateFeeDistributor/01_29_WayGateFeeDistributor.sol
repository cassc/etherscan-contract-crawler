// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WayGate721.sol";
import "./interfaces/IWGMarketplace.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract WayGateFeeDistributor is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IERC20 wayGateToken;
    IDEXRouter _dexRouter;

    uint256 airdropPercentage;

    address public dexRouterAddress;
    address wayGataMarketplaceAddress;

    address[] wayGate721Holders;

    mapping(address => bool) public isDistributorAddress;

    modifier onlyDistributor() {
        require(isDistributorAddress[_msgSender()], "Not a Distributor");
        _;
    }
    event AirdropHolderFeeTransferred(
        uint256 erc721Holders,
        uint256 feePerHolder,
        uint256 totalAirdropFee
    );

    function initialize() external initializer {
        __Ownable_init();
        _dexRouter = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // ETH: Uniswap V2 Router
        dexRouterAddress = address(_dexRouter);
    }

    function addTaxDistributor(address _distributorAddress) public onlyOwner {
        isDistributorAddress[_distributorAddress] = true;
    }

    function removeTaxDistributor(
        address _distributorAddress
    ) public onlyOwner {
        isDistributorAddress[_distributorAddress] = false;
    }

    function setMarketplaceContract(
        address _wayGataMarketplaceAddress
    ) external onlyOwner {
        wayGataMarketplaceAddress = _wayGataMarketplaceAddress;
    }

    function feeDistributor() external onlyOwner {
        uint256 airdropFeeAmount = getContractBalance();
        _transferTokensToAirdropholder(airdropFeeAmount);
        if (wayGateToken.balanceOf(address(this)) > 0) {
            convertWayTokens(wayGateToken.balanceOf(address(this)));
            uint256 totalFeeAmount = getContractBalance();
            airdropFeeAmount = (totalFeeAmount * airdropPercentage) / 1000;
            totalFeeAmount = totalFeeAmount - airdropFeeAmount;
            _transferTokensToAirdropholder(airdropFeeAmount);
            _transferAmountToPlatformReceiver(totalFeeAmount);
        }
    }

    function _transferTokensToAirdropholder(
        uint _airdropFeeAmount
    ) internal nonReentrant {
        address[] memory erc721AirdropHolders = getERC721AirdropHolders();
        uint256 erc721AirdropHoldersLength = erc721AirdropHolders.length;
        if (erc721AirdropHoldersLength != 0) {
            uint256 feePerAirdropHolder = _airdropFeeAmount /
                erc721AirdropHoldersLength;
            if (erc721AirdropHoldersLength != 0) {
                for (uint256 i = 0; i < erc721AirdropHoldersLength; i++) {
                    payable(erc721AirdropHolders[i]).transfer(
                        feePerAirdropHolder
                    );
                }
            }
            emit AirdropHolderFeeTransferred(
                erc721AirdropHoldersLength,
                feePerAirdropHolder,
                _airdropFeeAmount
            );
        }
    }

    function _transferAmountToPlatformReceiver(
        uint256 platformFeeAmount
    ) internal onlyOwner {
        address platformFeeReceiver = IWGMarketplace(wayGataMarketplaceAddress)
            .getwayGatePlatformFeeReceiver();
        payable(platformFeeReceiver).transfer(platformFeeAmount);
    }

    function convertWayTokens(uint256 _swapAmount) internal returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(wayGateToken);

        path[1] = _dexRouter.WETH();

        uint256 contractWayBalance = wayGateToken.balanceOf(address(this));

        uint256 initialBalance = address(this).balance;

        wayGateToken.approve(address(_dexRouter), contractWayBalance);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 ethAmount = address(this).balance - initialBalance;

        return ethAmount;
    }

    function getERC721AirdropHolders() internal returns (address[] memory) {
        address nftContract721 = IWGMarketplace(wayGataMarketplaceAddress)
            .getWayGate721ContractAddress();
        uint256[] memory ERC721tokenIds = WayGate721(nftContract721)
            .getWhiteListTokenIds();
        uint256 totalTokenId = ERC721tokenIds.length;
        for (uint256 i = 0; i < totalTokenId; i++) {
            address erc721Holder = WayGate721(nftContract721)
                .getErc721airdropTokenIdOwner(ERC721tokenIds[i]);
            if (erc721Holder != address(0)) {
                wayGate721Holders.push(erc721Holder);
            }
        }
        return wayGate721Holders;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function wayGateTokenAddress(
        address _wayGateAddress
    ) public returns (address) {
        wayGateToken = IERC20(_wayGateAddress);
        return address(wayGateToken);
    }

    fallback() external payable {}

    receive() external payable {}
}