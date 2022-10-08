//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

interface IOwnedContract {
    function getOwner() external view returns (address);
}

interface IXUSD {
    function sell(uint256 tokenAmount, address desiredToken) external returns (address, uint256);
}

interface IDUMP {
    function sell(uint256 tokenAmount) external returns (address, uint256);
}

interface IPUMP {
    function burn(uint256 amount) external;
}

contract FeeReceiver {

    // Token
    address public constant PUMP = 0x91Ebe3E0266B70be6AE41b8944170A27A08E3C2e;
    address public constant XUSD = 0x324E8E649A6A3dF817F97CdDBED2b746b62553dD;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public immutable DUMP;

    // Recipients Of Fees
    address public addr0 = 0xED1E4936af3ceCc822358Ab3e96f44b16E358EA5;
    address public addr1 = 0x15F62C92c5a1b3172B071E3391C82bF815c5e4C8;
    address public addr2 = 0xb49844F55c08C0aF57A9FBf71Fb5747aDe7dA8c4;
    address public addr3 = 0xd28D5abC74E58da8c6288fAa1dc9Fdb7b631a2FE;

    // Fee Percentages
    uint private constant denom = 650;

    // Token -> BNB
    address[] private path;

    // bounty percent
    uint256 public bountyPercent = 1;

    // router
    IUniswapV2Router02 public constant router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    modifier onlyOwner(){
        require(
            msg.sender == IOwnedContract(DUMP).getOwner(),
            'Only Token Owner'
        );
        _;
    }

    constructor(address DUMP_) {
        DUMP = DUMP_;
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = PUMP;
    }

    function trigger() external {

        // Bounty Reward For Triggerer
        uint bounty = currentBounty();
        if (bounty > 0) {
            IERC20(DUMP).transfer(msg.sender, bounty);
        }

        // sell dump for BNB
        _dumpToBNB();

        // amount for fee receivers
        uint256 bal = address(this).balance;
        uint p0 = ( bal * 200 ) / denom;
        uint p1 = ( bal * 225 ) / denom;
        uint p2 = ( bal * 25 )  / denom;

        // 2% portions
        _send(addr0, p0);
        _send(addr1, p0);
        
        // 2.25% portion
        _send(addr2, p1);

        // 0.25% portions
        _send(addr3, p2);
    }

    function _dumpToBNB() internal {

        // Sell Dump For Stable
        (address token,) = IDUMP(DUMP).sell(IERC20(DUMP).balanceOf(address(this)));

        // Swap Stable for BNB
        uint stableBal = IERC20(token).balanceOf(address(this));
        address[] memory sPath = new address[](2);
        sPath[0] = token;
        sPath[1] = router.WETH();
        
        // make the swap
        IERC20(token).approve(address(router), stableBal);
        router.swapExactTokensForETH(
            stableBal,
            0,
            sPath,
            address(this),
            block.timestamp + 300
        );
        delete sPath;
    }

    function _buyBurnPump(uint amount) internal {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        IPUMP(PUMP).burn(IERC20(PUMP).balanceOf(address(this)));
    }

    function setBountyPercent(uint256 bountyPercent_) external onlyOwner {
        require(bountyPercent_ < 100);
        bountyPercent = bountyPercent_;
    }

    function withdraw() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }
    
    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    receive() external payable {}
    
    function _send(address recipient, uint amount) internal {
        (bool s,) = payable(recipient).call{value: amount}("");
        require(s);
    }

    function currentBounty() public view returns (uint256) {
        uint balance = IERC20(DUMP).balanceOf(address(this));
        return ((balance * bountyPercent ) / 100);
    }
}