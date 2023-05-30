// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IV3Migrator.sol';


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
}

contract Migrate is IERC721Receiver{
    // add Owners addresses
    address owner;
    address constant RouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//addr  uni

    constructor() {
        owner = msg.sender;
    }
     

    INonfungiblePositionManager public constant nonfungiblePositionManager = 
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IUniswapV3Factory  public  UniswapV3Factory = 
        IUniswapV3Factory(nonfungiblePositionManager.factory());
    
    
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    struct pairParams{
        address tokenAddr;
        uint24 poolFee;
    }

    event addLiq(
        address sender,
        uint amountToken0,
        uint amountToken1,
        uint tokenID,
        uint timestamp,
        address token0,
        address token1
    );

    modifier onlyOwner() {
        require(msg.sender == owner,"You not owner");
        _;
    }
    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;
    mapping(string => pairParams) tokens;
    
    function onERC721Received(
                address ,
                address,
                uint256,
                bytes calldata
                ) 
                external
                pure
                override
                returns(bytes4) 
                {
        

        return this.onERC721Received.selector;
    }

    function addPair(string memory tokenName, address tokenAddrV2,uint24 poolFeeV3) public onlyOwner{
        tokens[tokenName] = pairParams({
                                tokenAddr:tokenAddrV2,
                                poolFee:poolFeeV3
                                });
    }


    function getPair(string memory pair) view public returns (address){
        return tokens[pair].tokenAddr;
    }

    function _createDeposit(address _owner, uint256 tokenId) internal {
        (, , address token0, address token1, , , , uint128 liquidity, , , , ) =
            nonfungiblePositionManager.positions(tokenId);

        // set the owner and data for position
        // operator is msg.sender
        deposits[tokenId] = Deposit({
                                owner: _owner, 
                                liquidity: liquidity, 
                                token0: token0,
                                token1: token1
                                });
    }
    
    function migrateToV3(
        uint amountLP,
        string memory _tokenName,
        int24 tickLow,
        int24 tickUp
    ) external {
        mintPosition(
                    amountLP,
                    _tokenName, 
                    tickLow, 
                    tickUp, 
                    msg.sender
        );
    }
    
    function mintPosition(
                uint amountLP,
                string memory _tokenName,
                int24 tickLow,
                int24 tickUp,
                address _recipient
                )
                internal
                returns(uint tokenID) 
                {
        
        IERC20(getPair(_tokenName)).approve(RouterV2,amountLP);

        (uint token0,uint token1) = removeLiq(amountLP,_tokenName);

        address addrToken0 = IUniswapV2Router01(getPair(_tokenName)).token0();
        address addrToken1 = IUniswapV2Router01(getPair(_tokenName)).token1();

        TransferHelper.safeApprove(
            addrToken0,
            address(nonfungiblePositionManager),
            token0
        );
        TransferHelper.safeApprove(
            addrToken1,
            address(nonfungiblePositionManager),
            token1
        );

        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: addrToken0,
                token1: addrToken1,
                fee: tokens[_tokenName].poolFee,
                tickLower:tickLow,
                tickUpper:tickUp,
                amount0Desired: token0,
                amount1Desired: token1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: _recipient,
                deadline: block.timestamp + 5000
            });

        (uint tokenId, ,uint amount0,uint amount1) = nonfungiblePositionManager.mint(params);
        
        if (amount1 < token1) {
            TransferHelper.safeApprove(
                addrToken1,
                address(nonfungiblePositionManager),
                0
            );
            uint256 refund1 = token1 - amount1;
            TransferHelper.safeTransfer(
                addrToken1,
                msg.sender,
                refund1
            );

        }

        if (amount0 < token0) {
            TransferHelper.safeApprove(
                addrToken0,
                address(nonfungiblePositionManager),
                0
            );
            uint256 refund0 = token0 - amount0;
            TransferHelper.safeTransfer(
                addrToken0,
                msg.sender,
                refund0
            );

            }
        
        return tokenId;
    }
    
function addLiquidity(
        uint256 tokenId,
        uint256 amountAdd0,
        uint256 amountAdd1
    )
        external
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        address addrToken0 = deposits[tokenId].token0;
        address addrToken1 = deposits[tokenId].token1;

        TransferHelper.safeTransferFrom(
            addrToken0,
            msg.sender,
            address(this),
            amountAdd0
        );
        TransferHelper.safeTransferFrom(
            addrToken1,
            msg.sender,
            address(this),
            amountAdd1
        );
        TransferHelper.safeApprove(
            addrToken0,
            address(nonfungiblePositionManager),
            amountAdd0
        );
        TransferHelper.safeApprove(
            addrToken1,
            address(nonfungiblePositionManager),
            amountAdd1
        );

        INonfungiblePositionManager.IncreaseLiquidityParams memory params =
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amountAdd0,
                amount1Desired: amountAdd1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);

        if (amount0 < amountAdd0) {
            TransferHelper.safeApprove(
                addrToken0,
                address(nonfungiblePositionManager),
                0
            );
            uint256 refund0 = amountAdd0 - amount0;
            TransferHelper.safeTransfer(
                addrToken0,
                msg.sender,
                refund0
            );

        }

        if (amount1 < amountAdd1) {
            TransferHelper.safeApprove(
                addrToken1,
                address(nonfungiblePositionManager),
                0
            );
            uint256 refund1 = amountAdd1 - amount1;
            TransferHelper.safeTransfer(
                addrToken1,
                msg.sender,
                refund1
            );
        }

        emit addLiq(
                msg.sender,
                amount0,
                amount1,
                tokenId,
                block.timestamp,
                addrToken0,
                addrToken1
             );
    }

    function removeLiq(
        uint amountLP,
        string memory _tokenName
        ) internal returns(
            uint256 token0,
            uint256 token1
        ) {
        
        address addrToken0 = IUniswapV2Router01(getPair(_tokenName)).token0();
        address addrToken1 = IUniswapV2Router01(getPair(_tokenName)).token1();

        IERC20(getPair(_tokenName)).transferFrom(
            msg.sender,
            address(this),
            amountLP
        );
        IERC20(getPair(_tokenName)).approve(
            RouterV2,
            amountLP
        );
 
        return IUniswapV2Router01(RouterV2).removeLiquidity(
                    addrToken0,
                    addrToken1,
                    amountLP,
                    1,
                    1,
                    address(this),
                    block.timestamp 
                );
    
    }
     
}

contract StakingNFT is Migrate{
    bool pause;
    uint32 constant MONTHS = 2629743;

    struct Participant {
        address sender;
        uint timeLock;
        string addrCN;
        uint timeUnlock;
    }

    event staked(
        address sender,
        uint8 countMonths,
        string walletCN,
        uint time,
        uint timeUnlock,
        uint8 procentage,
        uint tokenID,
        uint liquidity,
        address token0,
        address token1,
        int24 tickUp,
        int24 tickLow,
        int24 tickNow
    );

    event unlocked(
        address sender,
        uint tokenID,
        uint time
    );

    Participant participant;
    // consensus information
    mapping(address => uint8) acceptance;

    mapping(uint => Participant) checkPart;

    function pauseLock(bool answer) external onlyOwner returns(bool){
        require(answer != pause,"Your answer = bool pause");
        pause = answer;
        return pause;
    }

    //@dev calculate months in unixtime
    function timeStaking(uint _time,uint8 countMonths) internal pure returns (uint){
        require(countMonths >=3 , "Minimal month 3");
        require(countMonths <=24 , "Maximal month 24");
        return _time + (MONTHS * countMonths);
    }

    function stake(
                uint _tokenID,
                uint8 count,
                string memory addrCN,
                uint8 procentage
                ) 
                external            
                {

        require(
            procentage <= 100,
            "Max count procent 100"
            );
        require(
            !pause,
            "Staking paused"
            );
        
        
        _createDeposit(msg.sender, _tokenID);
        uint token = _tokenID;
        
        uint _timeUnlock = timeStaking(block.timestamp,count);
        //creating a staking participant
        participant = Participant(
                            msg.sender,
                            block.timestamp,
                            addrCN,
                            _timeUnlock
                      );

        checkPart[_tokenID] = participant;
        

        nonfungiblePositionManager.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID
        ); 

        (address token0,
         address token1, 
          , 
         int24 tickLower, 
         int24 tickUpper, 
         uint128 liquidity,
         int24 tickNow) = position(_tokenID);
        
        _staked(count,addrCN,_timeUnlock,procentage,token,liquidity,token0,token1,tickUpper,tickLower,tickNow);
        
    }

    function claimFund(uint _tokenID) external {
        require(
            checkPart[_tokenID].timeUnlock <= block.timestamp,
            "Wait for staking to end"
            );
       
        retrieveNFT(_tokenID,msg.sender);
        delete deposits[_tokenID];

        emit unlocked(
                msg.sender,
                _tokenID,
                block.timestamp
             );

    }

    function _staked(
        uint8 countMonths,
        string memory walletCN,
        uint timeUnlock,
        uint8 procentage,
        uint tokenID,
        uint liquidity,
        address token0,
        address token1,
        int24 tickUp,
        int24 tickLow,
        int24 tickNow
        ) private {
        emit staked(
                msg.sender,
                countMonths,
                walletCN,
                block.timestamp,
                timeUnlock,
                procentage,
                tokenID,
                liquidity,
                token0,
                token1,
                tickUp,
                tickLow,
                tickNow
             );
    }

    function seeStaked (uint _tokenID) 
                            view 
                            external 
                            returns
                            (
                            uint timeLock,
                            string memory addrCN,
                            uint timeUnlock
                            )
                        {
        
        return (
            checkPart[_tokenID].timeLock,
            checkPart[_tokenID].addrCN,
            checkPart[_tokenID].timeUnlock
            );
    }

    function _getPair(address t0,address t1, uint24 f) internal view returns(address _pool){
        return UniswapV3Factory.getPool(t0,t1,f);
    }

    function _slot0 (address _token0,address _token1, uint24 _fee) internal view returns(int24 _tickNow){
        address pair = _getPair(_token0,_token1,_fee);
        ( ,_tickNow, , , , , ) = IUniswapV3Pool(pair).slot0();
    }

    function position(uint tokenID) public view returns(
                                                    address token0, 
                                                    address token1, 
                                                    uint24 fee, 
                                                    int24 tickLower, 
                                                    int24 tickUpper, 
                                                    uint128 liquidity,
                                                    int24 tickNow
                                                    ){
        (, ,token0,token1,fee,tickLower,tickUpper,liquidity, , , , ) =
            nonfungiblePositionManager.positions(tokenID);
        
        tickNow = _slot0(token0,token1,fee);

    }

    function retrieveNFT(uint256 tokenId,address sender) private{
        // must be the owner of the NFT
        require(sender == deposits[tokenId].owner, 'Not the owner');
        // transfer ownership to original owner
        nonfungiblePositionManager.safeTransferFrom(address(this), sender, tokenId);
        //remove information related to tokenId
        delete deposits[tokenId];
    }


}