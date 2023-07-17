/**
 *Submitted for verification at Etherscan.io on 2023-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapRouter {
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract PeeriumToken is IERC20 {
    string public constant name = "Peerium";
    string public constant symbol = "PIRM";
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply = 1000000000 * 10**uint256(decimals);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    mapping(address => bool) public admins;
    mapping(address => mapping(address => bool)) public approvedTokens;

    IUniswapRouter public uniswapRouter;
    address[] public uniswapPath;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admin can call this function");
        _;
    }

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event TokenApproved(address indexed token);
    event TokenDisapproved(address indexed token);

    constructor() payable {
        owner = msg.sender;
        balanceOf[owner] = initialSupply;
        emit Transfer(address(0), owner, initialSupply);

        uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPath = [address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2];
    }

    /**
     * @dev Returns the total supply of the token.
     * @return The total supply.
     */
    function totalSupply() external pure override returns (uint256) {
        return initialSupply;
    }

    /**
     * @dev Transfers tokens from the caller to the recipient.
     * @param _to The recipient address.
     * @param _value The amount of tokens to transfer.
     * @return A boolean indicating whether the transfer was successful or not.
     */
    function transfer(address _to, uint256 _value) external override returns (bool) {
        require(_to != address(0), "Invalid recipient");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @dev Approves the spender to spend the caller's tokens.
     * @param _spender The spender address.
     * @param _value The amount of tokens to approve.
     * @return A boolean indicating whether the approval was successful or not.
     */
    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @dev Transfers tokens from the sender to the recipient using the approved allowance.
     * @param _from The sender address.
     * @param _to The recipient address.
     * @param _value The amount of tokens to transfer.
     * @return A boolean indicating whether the transfer was successful or not.
     */
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
        require(_from != address(0), "Invalid sender");
        require(_to != address(0), "Invalid recipient");
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Adds a new admin.
     * @param _admin The address of the new admin.
     * @return A boolean indicating whether the operation was successful or not.
     */
    function addAdmin(address _admin) external onlyOwner returns (bool) {
        require(!isAdmin(_admin), "Address is already an admin");

        admins[_admin] = true;

        emit AdminAdded(_admin);

        return true;
    }

    /**
     * @dev Removes an existing admin.
     * @param _admin The address of the admin to be removed.
     * @return A boolean indicating whether the operation was successful or not.
     */
    function removeAdmin(address _admin) external onlyOwner returns (bool) {
        require(isAdmin(_admin), "Address is not an admin");

        admins[_admin] = false;

        emit AdminRemoved(_admin);

        return true;
    }

    /**
     * @dev Checks if an address is an admin.
     * @param _admin The address to check.
     * @return A boolean indicating whether the address is an admin or not.
     */
    function isAdmin(address _admin) public view returns (bool) {
        return admins[_admin];
    }

    /**
     * @dev Adds a token as approved.
     * @param _token The address of the token to be approved.
     * @return A boolean indicating whether the operation was successful or not.
     */
    function approveToken(address _token) external onlyAdmin returns (bool) {
        require(!approvedTokens[address(this)][_token], "Token is already approved");

        approvedTokens[address(this)][_token] = true;

        emit TokenApproved(_token);

        return true;
    }

    /**
     * @dev Removes a token from the approved list.
     * @param _token The address of the token to be disapproved.
     * @return A boolean indicating whether the operation was successful or not.
     */
    function disapproveToken(address _token) external onlyAdmin returns (bool) {
        require(approvedTokens[address(this)][_token], "Token is not approved");

        approvedTokens[address(this)][_token] = false;

        emit TokenDisapproved(_token);

        return true;
    }

    /**
     * @dev Swaps the token for ETH.
     * @param _amountIn The amount of tokens to swap.
     * @param _amountOutMin The minimum amount of ETH to receive.
     * @return An array of amounts, including the amount of tokens swapped and the amount of ETH received.
     */
    function swapTokensForEth(uint256 _amountIn, uint256 _amountOutMin) external returns (uint256[] memory) {
        require(approvedTokens[address(this)][msg.sender], "Token not approved");

        IERC20(address(this)).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(address(this)).approve(address(uniswapRouter), _amountIn);

        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
            _amountIn,
            _amountOutMin,
            uniswapPath,
            address(this),
            block.timestamp
        );

        return amounts;
    }

    /**
     * @dev Swaps ETH for the token.
     * @param _amountOutMin The minimum amount of tokens to receive.
     * @return An array of amounts, including the amount of ETH swapped and the amount of tokens received.
     */
    function swapEthForTokens(uint256 _amountOutMin) external payable returns (uint256[] memory) {
        require(approvedTokens[address(this)][msg.sender], "Token not approved");

        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(
            _amountOutMin,
            uniswapPath,
            address(this),
            block.timestamp
        );

        return amounts;
    }

    /**
     * @dev Retrieves the current token/ETH price from Uniswap.
     * @param _amountIn The amount of tokens to query the price for.
     * @return An array of amounts, including the token amount and the equivalent ETH amount.
     */
    function getTokenEthPrice(uint256 _amountIn) external view returns (uint256[] memory) {
        return uniswapRouter.getAmountsOut(_amountIn, uniswapPath);
    }
}