pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "OperaFactory.sol";

contract OperaTeamBuyDeployer {
    address private owner;
    address private factoryContract =
        0x623bf4a5295f2597Fa74f755267227953a46bCEA;
    uint256 private _tokenDecimals = 10 ** 18;
    uint256 private feePerEth = 1 * 10 ** 17;
    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IDEXRouter private router;
    address private WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function setFactory(address factory) external onlyOwner {
        factoryContract = factory;
    }

    function rescueToken(address token) external onlyOwner {
        IERC20 tokenToRescue = IERC20(token);
        tokenToRescue.transfer(owner, tokenToRescue.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}

    function deployContract(
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData,
        uint256 _amountEthToBorrow
    ) external payable {
        OperaFactory factory = OperaFactory(payable(factoryContract));
        uint256 currentId = factory.tokenDeployedCount();
        factory.deployToken{value: _amountEthToBorrow * feePerEth}(
            _stringData,
            _addressData,
            _intData,
            _amountEthToBorrow
        );
        address tokenDeployedAddress = factory.tokenCountToAddress(currentId);
        OperaToken tokenDeployedContract = OperaToken(
            payable(tokenDeployedAddress)
        );
        tokenDeployedContract.authorize(msg.sender);
        router = IDEXRouter(routerAddress);

        address[] memory path = new address[](2);
        path[1] = tokenDeployedAddress;
        path[0] = WETHAddress;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value - (_amountEthToBorrow * feePerEth)
        }(0, path, address(this), block.timestamp);

        tokenDeployedContract.transfer(
            msg.sender,
            tokenDeployedContract.balanceOf(address(this))
        );

        tokenDeployedContract.transferOwnership(payable(msg.sender));
    }
}