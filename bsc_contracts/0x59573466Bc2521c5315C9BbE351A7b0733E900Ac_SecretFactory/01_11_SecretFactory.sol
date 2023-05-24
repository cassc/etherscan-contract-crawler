pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "SecretToken.sol";
import "SecretReward.sol";
import "WBNB.sol";
import "SecretLendingPool.sol";
import "IERC20.sol";
import "Math.sol";

contract SecretFactory {
    uint256 public feePerEth = 1 * 10 ** 6;
    uint256 public _tokenDecimals = 1 * 10 ** 16;
    uint256 public tokenDeployedCount;
    address public owner;
    address public WBNBAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public secretRewardAddress =
        0xC526c7C62DF36AfE1AFc707FDA3e872fF9c77eC4;
    address public secretPoolAddress =
        0x87fb74062AbA40098952F8Faf3F4c040e5f6A962;

    mapping(uint256 => address) public tokenCountToAddress;
    mapping(uint256 => uint256) public initialLiquidityFromTokenCount;
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    IDEXRouter public router;
    event feeChanged(uint256 amount);

    constructor() {
        owner = msg.sender;
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function updateFeePerEth(uint256 amount) external onlyOwner {
        feePerEth = amount;
        emit feeChanged(amount);
    }

    function deployToken(
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData,
        uint256 _amountEthToBorrow
    ) external payable returns (address) {
        uint256 feeEmountEth = _amountEthToBorrow * feePerEth;
        require(feeEmountEth == msg.value, "Send enough to cover the fee");
        TopSecreter deployedToken = new TopSecreter(
            _stringData,
            _addressData,
            _intData
        );
        deployedToken.authorize(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        uint256 tokenAmount = deployedToken.balanceOf(address(this));
        deployedToken.approve(address(router), tokenAmount);
        deployedToken.approve(deployedToken.pair(), tokenAmount);
        // SecretPool lender = SecretPool(payable(secretPoolAddress));
        // // lender.borrowEth(_amountEthToBorrow);
        // router.addLiquidityETH{value: _amountEthToBorrow * _tokenDecimals}(
        //     address(deployedToken),
        //     tokenAmount,
        //     0,
        //     0,
        //     address(this),
        //     block.timestamp + 1
        // );
        // tokenCountToAddress[tokenDeployedCount] = address(deployedToken);
        // initialLiquidityFromTokenCount[tokenDeployedCount] = _amountEthToBorrow;
        // tokenDeployedCount += 1;
        // deployedToken.transferOwnership(payable(msg.sender));
        return address(deployedToken);
    }

    function deployToken2(
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData,
        uint256 _amountEthToBorrow
    ) external payable returns (address) {
        uint256 feeEmountEth = _amountEthToBorrow * feePerEth;
        require(feeEmountEth == msg.value, "Send enough to cover the fee");
        TopSecreter deployedToken = new TopSecreter(
            _stringData,
            _addressData,
            _intData
        );
        deployedToken.authorize(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        uint256 tokenAmount = deployedToken.balanceOf(address(this));
        deployedToken.approve(address(router), tokenAmount);
        deployedToken.approve(deployedToken.pair(), tokenAmount);
        SecretPool lender = SecretPool(payable(secretPoolAddress));
        lender.borrowEth(_amountEthToBorrow);
        // router.addLiquidityETH{value: _amountEthToBorrow * _tokenDecimals}(
        //     address(deployedToken),
        //     tokenAmount,
        //     0,
        //     0,
        //     address(this),
        //     block.timestamp + 1
        // );
        // tokenCountToAddress[tokenDeployedCount] = address(deployedToken);
        // initialLiquidityFromTokenCount[tokenDeployedCount] = _amountEthToBorrow;
        // tokenDeployedCount += 1;
        // deployedToken.transferOwnership(payable(msg.sender));
        return address(deployedToken);
    }

    function deployToken3(
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData,
        uint256 _amountEthToBorrow
    ) external payable returns (address) {
        uint256 feeEmountEth = _amountEthToBorrow * feePerEth;
        require(feeEmountEth == msg.value, "Send enough to cover the fee");
        TopSecreter deployedToken = new TopSecreter(
            _stringData,
            _addressData,
            _intData
        );
        deployedToken.authorize(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        uint256 tokenAmount = deployedToken.balanceOf(address(this));
        deployedToken.approve(address(router), tokenAmount);
        deployedToken.approve(deployedToken.pair(), tokenAmount);
        SecretPool lender = SecretPool(payable(secretPoolAddress));
        lender.borrowEth(_amountEthToBorrow);
        router.addLiquidityETH{value: _amountEthToBorrow * _tokenDecimals}(
            address(deployedToken),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 1
        );
        // tokenCountToAddress[tokenDeployedCount] = address(deployedToken);
        // initialLiquidityFromTokenCount[tokenDeployedCount] = _amountEthToBorrow;
        // tokenDeployedCount += 1;
        // deployedToken.transferOwnership(payable(msg.sender));
        return address(deployedToken);
    }

    function removeLiquidity(uint256 tokenId) external onlyOwner {
        address tokenAddress = tokenCountToAddress[tokenId];
        TopSecreter deployedToken = TopSecreter(payable(tokenAddress));
        IERC20 lpToken = IERC20(deployedToken.pair());
        lpToken.approve(address(router), lpToken.balanceOf(address(this)));
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            tokenAddress,
            WBNBAddress,
            lpToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1
        );
        WBNB wbnbContract = WBNB(payable(WBNBAddress));
        wbnbContract.withdraw(amountA);
        uint256 extraLP;
        if (
            initialLiquidityFromTokenCount[tokenId] * _tokenDecimals >= amountA
        ) {
            SecretPool poolContract = SecretPool(payable(secretPoolAddress));
            poolContract.returnLentEth{value: amountA}();
        } else {
            extraLP =
                amountA -
                (initialLiquidityFromTokenCount[tokenId] * _tokenDecimals);

            SecretRewards rewardContract = SecretRewards(
                payable(secretRewardAddress)
            );
            rewardContract.recieveRewards{value: extraLP}();
            SecretPool poolContract = SecretPool(payable(secretPoolAddress));
            poolContract.returnLentEth{
                value: initialLiquidityFromTokenCount[tokenId] * _tokenDecimals
            }();
        }
    }

    function rescueToken(address token) external onlyOwner {
        IERC20 tokenToRescue = IERC20(token);
        tokenToRescue.transfer(owner, tokenToRescue.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}