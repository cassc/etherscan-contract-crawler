// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract ChadsToken is ERC20 {
    error EtherNotAccepted();
    error NowAllowedToRecoverThisToken();
    error NotAllowedToTransfer(address from, address to);
    error NotPublicLaunched();
    error OnlyAdmin();
    error MaxBuyLimit();
    error MaxWalletLimit();

    event SetAdmin(address indexed admin, bool status);

    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public admins;

    IUniswapV2Router02 public immutable router;
    address public pair;
    bool public isPublicLaunched = false;

    // max buy limit:
    uint256 public maxBuyLimit = 10_000 ether;

    // max wallet limit:
    uint256 public maxWalletLimit = 10_000 ether;

    constructor(address _admin, address _router, string memory _name, string memory _symbol)
    ERC20(_name, _symbol)
    {
        admins[msg.sender] = true;
        admins[_admin] = true;

        emit SetAdmin(msg.sender, true);
        emit SetAdmin(_admin, true);

        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        // mint initial supply and send to admin for distribution:
        _mint(_admin, 1_000_000 ether);

    }

    function publicLaunch() external onlyAdmin {
        isPublicLaunched = true;
    }

    fallback() external payable {
        revert EtherNotAccepted();
    }
    receive() external payable {
        revert EtherNotAccepted();
    }

    modifier onlyAdmin() {
        if(!admins[msg.sender])
            revert OnlyAdmin();
        _;
    }

    function setAdmin(address _minter, bool _status) external onlyAdmin {
        admins[_minter] = _status;
        emit SetAdmin(_minter, _status);
    }

    function recover(address tokenAddress, address to) external onlyAdmin {
        if (tokenAddress == address(this))
            revert NowAllowedToRecoverThisToken();
        IERC20(tokenAddress).transfer(to, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function setBlacklist(address user, bool status) external onlyAdmin {
        blacklist[user] = status;
    }

    // add batch of users to whitelist:
    function addBatchToWhitelist(address[] calldata users, bool status) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = status;
        }
    }
    function setWhitelist(address user, bool status) external onlyAdmin {
        whitelist[user] = status;
    }

    function setMaxBuyLimit(uint256 _maxBuyLimit) external onlyAdmin {
        maxBuyLimit = _maxBuyLimit;
    }

    function setMaxWalletLimit(uint256 _maxWalletLimit) external onlyAdmin {
        maxWalletLimit = _maxWalletLimit;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {

        // where are minting/burning tokens
        if (from == address(0) || to == address(0))
            return;

        // allow us to add liquidity:
        if( admins[from] || admins[to] )
            return;

        // check on blacklist for rogue users:
        if (blacklist[from] || blacklist[to])
            revert NotAllowedToTransfer(from, to);

        bool is_buy = (!isPublicLaunched && from == pair );
        bool is_sell = (!isPublicLaunched && to == pair );

        // check max buy limit:
        if (from == pair && amount > maxBuyLimit){
            revert MaxBuyLimit();
        }

        // check max wallet limit:
        if (from == pair && balanceOf(to) + amount > maxWalletLimit){
            revert MaxWalletLimit();
        }

        // see if public launch has active to allow users to swap:
        if ((is_buy || is_sell)) {
            // check if public launch has started:

            if (!isPublicLaunched && is_buy && !whitelist[to] ){
                revert NotPublicLaunched();
            }
            if (!isPublicLaunched && is_sell && !whitelist[from] ){
                revert NotPublicLaunched();
            }
        }else{
            // user is privileged
            if (!isPublicLaunched){
                if( !whitelist[from] || !whitelist[to] )
                    revert NotPublicLaunched();
            }
        }

    }

}