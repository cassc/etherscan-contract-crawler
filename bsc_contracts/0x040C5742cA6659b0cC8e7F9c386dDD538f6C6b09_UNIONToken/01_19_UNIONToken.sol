// SPDX-License-Identifier: MIT
// contracts/UNIONToken.sol

pragma solidity ^0.8.0;

import "./modules/TokenBlack.sol";

contract UNIONToken is TokenBlack {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public WETH;

    address public wallet;

    mapping(address => uint[]) public swapPair;

    event Swap(address indexed from, address indexed token, uint amountIn, uint amountOut);

    function initialize() public initializer {
        __ERC20_init("UNION TOKEN", "UNT");

        uint256 initialSupply = 100000000 * 10**decimals();
        _mint(_msgSender(), initialSupply);

        WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        wallet = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function mint(address to, uint amount) public whenNotPaused {
        require(hasRole(MINTER_ROLE, _msgSender()), "UNIONToken: Must have minter role to mint");

        _mint(to, amount);
    }

    function swapFromETH() public payable whenNotPaused {
        require(msg.value > 0, "UNIONToken: BNB Amount too small");

        uint amountOut = getAmountOut(WETH, msg.value);
        require(amountOut > 0, "UNIONToken: Amount Out Insuffcient");

        (bool success, ) = wallet.call{value: msg.value}("");
        require(success, "UNIONToken: Failed to send Ether");

        _mint(_msgSender(), amountOut);

        emit Swap(_msgSender(), WETH, msg.value, amountOut);
    }

    function swapFromToken(address token, uint amountIn) public whenNotPaused {
        require(amountIn > 0, "UNIONToken: BNB Amount too small");

        uint amountOut = getAmountOut(token, amountIn);
        require(amountOut > 0, "UNIONToken: Amount Out Insuffcient");

        IERC20(token).transferFrom(_msgSender(), wallet, amountIn);
        _mint(_msgSender(), amountOut);

        emit Swap(_msgSender(), token, amountIn, amountOut);
    }

    function getAmountOut(address token, uint amountIn) public view returns (uint) {
        require(swapPair[token].length == 2, "UNIONToken: Swap pair length invalid");

        uint[] memory amounts = swapPair[token];
        return (amountIn * amounts[1]) / amounts[0];
    }

    function setWETH(address addr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "UNIONToken: Must have admin role to set WETH");

        WETH = addr;
    }

    function setWallet(address addr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "UNIONToken: Must have admin role to set wallet");

        wallet = addr;
    }

    function setSwapPair(
        address token,
        uint amountIn,
        uint amountOut
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "UNIONToken: Must have admin role to mint");
        require(token.code.length > 0, "UNIONToken: Token address invalid");
        require(amountIn > 0, "UNIONToken: Amount in too samll");
        require(amountOut > 0, "UNIONToken: Amount out too samll");

        swapPair[token] = [amountIn, amountOut];
    }

    function reamoveSwapPair(address token) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "UNIONToken: Must have admin role to remove");
        require(swapPair[token].length == 2, "UNIONToken: Swap pair length invalid");

        delete swapPair[token];
    }

    uint256[50] private __gap;
}