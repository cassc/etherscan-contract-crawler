//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./migratorMain.sol";

contract migrateDeployer is Ownable {
    using SafeMath for uint256;

    struct pools {
        address _owner;
        uint256 _createdTime;
    }

    mapping(address => pools) public migratePools;

    uint256 public feeAmount = 3 * 10**18;

    address public superAdmin = 0x7D3B89c868F83dE6DC8efb24Ff895313C32Dc6Ba;

    event nePoolCreated(address _poolAddress, address _owner);

    constructor() {}

    receive() external payable {}

    function createNewPool(
        address _v1Toke,
        address _v2Token,
        uint256 ratio,
        uint256 tokensForPool
    ) public payable returns (address) {
        require(
            msg.value >= feeAmount,
            "Please submit the asking price in order to complete the pool creating"
        );
        payable(address(this)).transfer(feeAmount);
        // deploy new pool
        TokenMigrate newPool;

        newPool = new TokenMigrate(
            _v1Toke,
            _v2Token,
            msg.sender,
            ratio,
            superAdmin
        );

        IERC20(_v2Token).transferFrom(
            address(msg.sender),
            address(newPool),
            tokensForPool
        );

        migratePools[address(newPool)]._owner = msg.sender;
        migratePools[address(newPool)]._createdTime = block.timestamp;

        emit nePoolCreated(address(newPool), msg.sender);

        return address(newPool);
    }

    function withdrawBnb() external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB);
    }

    function changeFeeAmount(uint256 _feeAmount) public onlyOwner {
        feeAmount = _feeAmount;
    }

    function changeSuperAdmin(address _admin) public onlyOwner {
        superAdmin = _admin;
    }
}