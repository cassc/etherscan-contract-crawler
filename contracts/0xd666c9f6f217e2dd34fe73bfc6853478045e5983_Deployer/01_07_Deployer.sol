pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "Token.sol";
import "IERC20.sol";

contract Deployer {
    IDEXRouter public router;
    address public owner;
    address public latestDeploy;
    address private WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event tokenDeployed(
        address user,
        address token,
        uint256 blocktime,
        string[] stringData,
        uint256[] uintData,
        address[] addressData
    );
    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function emitDeployedEvent(
        address token,
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData
    ) internal {
        emit tokenDeployed(
            msg.sender,
            token,
            block.timestamp,
            _stringData,
            _intData,
            _addressData
        );
    }

    function deployToken(
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData,
        uint256 lpAmount
    ) external payable returns (address) {
        require(
            lpAmount >= 10 ** 7,
            "You do not want to start with less than 0.1 eth in LP."
        );
        Token deployedToken = new Token(_stringData, _addressData, _intData);

        uint256 tokenAmount = deployedToken.balanceOf(address(this));
        deployedToken.approve(address(router), tokenAmount);
        router.addLiquidityETH{value: lpAmount}(
            address(deployedToken),
            tokenAmount,
            0,
            0,
            msg.sender,
            block.timestamp + 1
        );
        latestDeploy = address(deployedToken);
        emitDeployedEvent(
            address(deployedToken),
            _stringData,
            _addressData,
            _intData
        );
        address[] memory path = new address[](2);
        path[1] = latestDeploy;
        path[0] = WETHAddress;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value - (lpAmount)
        }(0, path, address(this), block.timestamp);
        deployedToken.transfer(
            msg.sender,
            deployedToken.balanceOf(address(this))
        );
        deployedToken.transferOwnership(payable(msg.sender));
        return address(deployedToken);
    }

    receive() external payable {}

    function rescueToken(address token) external onlyOwner {
        IERC20 tokenToRescue = IERC20(token);
        tokenToRescue.transfer(owner, tokenToRescue.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}