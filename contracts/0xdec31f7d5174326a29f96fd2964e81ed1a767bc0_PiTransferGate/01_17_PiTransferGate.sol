// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./openzeppelin/TokensRecoverable.sol";
import "./openzeppelin/Owned.sol";
import "./interfaces/IPi.sol";

import "./interfaces/IPiTransferGate.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./openzeppelin/ReentrancyGuard.sol";

/* Pi:
A transfer gate (GatedERC20) for use with Pi tokens

It:
    Allows customization of tax and burn rates
    Allows transfer to/from approved Uniswap pools
    Disallows transfer to/from non-approved Uniswap pools
    (doesn't interfere with other crappy AMMs)
    Allows transfer to/from anywhere else
    Allows for free transfers if permission granted
    Allows for unrestricted transfers if permission granted
    Provides a safe and tax-free liquidity adding function
*/

struct PiTransferGateParameters
{
    address dev;
    uint16 stakeRate; // 100000 = 100%
    uint16 burnRate; // 100000 = 100%
    uint16 devRate;  // 100000 = 100%
    address stake;
}

contract PiTransferGate is Owned, TokensRecoverable, IPiTransferGate, ReentrancyGuard
{   
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    PiTransferGateParameters public parameters;
    IPi immutable Pi ;
    mapping (address => AddressState) public addressStates;
    IERC20[] public allowedPoolTokens;
    
    bool public unrestricted;
    mapping (address => bool) public unrestrictedControllers;
    mapping (address => bool) public freeParticipant;

    mapping (address => bool) public allowedFactoryAddress;

    mapping (address => uint256) public liquiditySupply;
    address public mustUpdate;    

    uint256 slippage = 5000; //5000 for 5%
    event SlippageSet(uint slippage);
    event ParametersSet(address dev, address stake, uint16 stakeRate, uint16 burnRate, uint16 devRate);
    event AddressStateSet(AddressState state);

    constructor(address _Pi) {
        Pi=IPi(_Pi);
        allowedFactoryAddress[0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f]=true; // uniswap factory address allowed
        PiTransferGateParameters memory _parameters;
        _parameters.dev = 0x16352774BF9287E0324E362897c1380ABC8B2b35;
        _parameters.stakeRate = 2000;
        _parameters.burnRate = 500;
        _parameters.devRate = 2000;
        _parameters.stake = 0xb0bBfAF6492B70359a001Fd30E673A4fcE875c6C;
        parameters = _parameters;
    }

    function addFactory(address factoryAddress) external ownerOnly{
        allowedFactoryAddress[factoryAddress]=true;
    }

    function removeFactory(address factoryAddress) external ownerOnly{
        allowedFactoryAddress[factoryAddress]=false;
    }

    // 3 decimal =>1000 = 1% => 
    function setSlippage(uint256 _slippage) external ownerOnly{
        require(_slippage<100000,"cannot be more than 100%");
        slippage=_slippage;
        emit SlippageSet(slippage);        
    }

    function allowedPoolTokensCount() public view override returns (uint256) { return allowedPoolTokens.length; }

    function setUnrestrictedController(address unrestrictedController, bool allow) public override ownerOnly(){
        unrestrictedControllers[unrestrictedController] = allow;
    }


    function setFreeParticipant(address participant, bool free) public override ownerOnly()
    {
        freeParticipant[participant] = free;
    }

    function setUnrestricted(bool _unrestricted) public override
    {
        require (unrestrictedControllers[msg.sender], "Not an unrestricted controller");
        unrestricted = _unrestricted;
    }

    function setParameters(address _dev, address _stake, uint16 _stakeRate, uint16 _burnRate, uint16 _devRate) public override ownerOnly()
    {
        require (_stakeRate <= 100000 && _burnRate <= 100000 && _devRate <= 100000 && _stakeRate + _burnRate + _devRate <= 100000, "> 100%");
        require (_dev != address(0) && _stake != address(0));
        // require (_stakeRate <= 500 && _burnRate <= 500 && _devRate <= 10, "Sanity");
        
        PiTransferGateParameters memory _parameters;
        _parameters.dev = _dev;
        _parameters.stakeRate = _stakeRate;
        _parameters.burnRate = _burnRate;
        _parameters.devRate = _devRate;
        _parameters.stake = _stake;
        parameters = _parameters;

        emit ParametersSet(_dev, _stake, _stakeRate, _burnRate, _devRate);
    }

    function allowPool(IUniswapV2Factory _uniswapV2Factory, IERC20 token) public override ownerOnly()
    {
        require(allowedFactoryAddress[address(_uniswapV2Factory)],"This uniswapV2Factory not allowed");
        address pool = _uniswapV2Factory.getPair(address(Pi), address(token));
        if (pool == address(0)) {
            pool = _uniswapV2Factory.createPair(address(Pi), address(token));
        }
        AddressState state = addressStates[pool];
        require (state != AddressState.AllowedPool, "Already allowed");
        addressStates[pool] = AddressState.AllowedPool;
        allowedPoolTokens.push(token);
        liquiditySupply[pool] = IERC20(pool).totalSupply();
    }


    function safeAddLiquidity(IUniswapV2Router02 _uniswapRouter02, IERC20 token, uint256 tokenAmount, uint256 PiAmount) public nonReentrant override
        returns (uint256 PiUsed, uint256 tokenUsed, uint256 liquidity)
    {
        require(allowedFactoryAddress[address(_uniswapRouter02.factory())],"This _uniswapV2Factory not allowed");

        address pool = IUniswapV2Factory(_uniswapRouter02.factory()).getPair(address(Pi), address(token));
        require (pool != address(0) && addressStates[pool] == AddressState.AllowedPool, "Pool not approved");
        unrestricted = true;

        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 PiBalance = Pi.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        Pi.transferFrom(msg.sender, address(this), PiAmount);
        Pi.approve(address(_uniswapRouter02), PiAmount);
        token.safeApprove(address(_uniswapRouter02), tokenAmount);
        // actual received token amount
        
        uint256 tokenAmountReceived= token.balanceOf(address(this)).sub(tokenBalance);
        uint256 PiAmountReceived=Pi.balanceOf(address(this)).sub(PiBalance);

        // uint256 tokenMinAmount = estimateBuy(_uniswapRouter02, token,tokenAmount).mul((100000-slippageBuy)/1000)/100;
        // uint256 PiMinAmount = estimateSell(_uniswapRouter02, token,PiAmount).mul((100000-slippageSell)/1000)/100;

        (PiUsed, tokenUsed ,liquidity ) = 
        _uniswapRouter02.addLiquidity(
            address(Pi), 
            address(token), 
            PiAmountReceived, 
            tokenAmountReceived,
            PiAmountReceived.mul(100000-slippage).div(100000), 
            tokenAmountReceived.mul(100000-slippage).div(100000),
            msg.sender, 
            block.timestamp);

        liquiditySupply[pool] = IERC20(pool).totalSupply();
        if (mustUpdate == pool) {
            mustUpdate = address(0);
        }

        if (PiUsed < PiAmount) {
            Pi.transfer(msg.sender, PiAmount.sub(PiUsed));
        }
        tokenBalance = token.balanceOf(address(this)).sub(tokenBalance); // we do it this way in case there's a burn
        if (tokenBalance > 0) {
            token.safeTransfer(msg.sender, tokenBalance);
        }
        
        unrestricted = false;
    }


    function handleTransfer(address, address from, address to, uint256 amount) external override
        returns (uint256 burn, TransferGateTarget[] memory targets){

        address mustUpdateAddress = mustUpdate;
        if (mustUpdateAddress != address(0)) {
            mustUpdate = address(0);
            liquiditySupply[mustUpdateAddress] = IERC20(mustUpdateAddress).totalSupply();
        }
        AddressState fromState = addressStates[from];
        AddressState toState = addressStates[to];
        if (fromState != AddressState.AllowedPool && toState != AddressState.AllowedPool) {
            if (fromState == AddressState.Unknown) { fromState = detectState(from); }
            if (toState == AddressState.Unknown) { toState = detectState(to); }
            require (unrestricted || (fromState != AddressState.DisallowedPool && toState != AddressState.DisallowedPool), "Pool not approved");
        }
        if (toState == AddressState.AllowedPool) {
            mustUpdate = to;
        }
        if (fromState == AddressState.AllowedPool) {
            if (unrestricted) {
                liquiditySupply[from] = IERC20(from).totalSupply();
            }
            require (IERC20(from).totalSupply() >= liquiditySupply[from], "Cannot remove liquidity");            
        }
        if (unrestricted || freeParticipant[from] || freeParticipant[to]) {
            return (0, new TransferGateTarget[](0));
        }
        PiTransferGateParameters memory params = parameters;
        // "amount" will never be > totalSupply which is capped at 10k, so these multiplications will never overflow
        burn = amount.mul(params.burnRate).div(100000);
        targets = new TransferGateTarget[]((params.devRate > 0 ? 1 : 0) + (params.stakeRate > 0 ? 1 : 0));
        uint256 index = 0;
        if (params.stakeRate > 0) {
            targets[index].destination = params.stake;
            targets[index++].amount = amount.mul(params.stakeRate).div(100000);
        }
        if (params.devRate > 0) {
            targets[index].destination = params.dev;
            targets[index].amount = amount.mul(params.devRate).div(100000);
        }
    }

    function setAddressState(address a, AddressState state) public ownerOnly()
    {
        addressStates[a] = state;
        emit AddressStateSet(state);
    }

    function detectState(address a) public returns (AddressState state) 
    {
        state = AddressState.NotPool;
        if (a.isContract()) {
            try this.throwAddressState(a)
            {
                assert(false);
            }
            catch Error(string memory result) {
                if (bytes(result).length == 1) {
                    state = AddressState.NotPool;
                }
                if (bytes(result).length == 2) {
                    state = AddressState.DisallowedPool;
                }
            }
            catch {
            }
        }
        addressStates[a] = state;
        return state;
    }
    
    // Not intended for external consumption
    // Always throws
    // We want to call functions to probe for things, but don't want to open ourselves up to
    // possible state-changes
    // So we return a value by reverting with a message
    function throwAddressState(address a) external view
    {
        try IUniswapV2Pair(a).factory() returns (address factory)
        {
            // don't care if it's some crappy alt-amm
            if (allowedFactoryAddress[factory]) {
                // these checks for token0/token1 are just for additional
                // certainty that we're interacting with a uniswap pair
                try IUniswapV2Pair(a).token0() returns (address token0)
                {
                    if (token0 == address(Pi)) {
                        revert("22");
                    }
                    try IUniswapV2Pair(a).token1() returns (address token1)
                    {
                        if (token1 == address(Pi)) {
                            revert("22");
                        }                        
                    }
                    catch { 
                    }                    
                }
                catch { 
                }
            }
        }
        catch {             
        }
        revert("1");
    }
}