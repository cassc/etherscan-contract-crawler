// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

import "./interfaces/IZirconPylonRouter.sol";
import "@zircon/core/contracts/interfaces/IZirconPair.sol";
import "@zircon/core/contracts/interfaces/IZirconPylonFactory.sol";
import "@zircon/core/contracts/interfaces/IZirconFactory.sol";
import "@zircon/core/contracts/interfaces/IZirconPoolToken.sol";
import "@zircon/core/contracts/interfaces/IZirconPTFactory.sol";
import "./libraries/ZirconPeripheralLibrary.sol";
import "./libraries/UniswapV2Library.sol";
//import "hardhat/console.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract ZirconPylonRouter is IZirconPylonRouter {

    address public immutable override factory;
    address public immutable override pylonFactory;
    address public immutable override ptFactory;
    address public immutable override WETH;
    bytes4 private constant DEPOSIT = bytes4(keccak256(bytes('routerDeposit(uint256)')));

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    // **** Constructor ****
    constructor(address _factory, address _pylonFactory, address _ptFactory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
        pylonFactory = _pylonFactory;
        ptFactory = _ptFactory;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // *** HELPER FUNCTIONS *****
    function _getPylon(address tokenA, address tokenB) internal view returns (address pylon){
        pylon = ZirconPeripheralLibrary.pylonFor(pylonFactory, tokenA, tokenB, UniswapV2Library.pairFor(factory, tokenA, tokenB));
    }

    // Transfers token or utility
    function _transfer(uint amountDesired, address token, address pylon) private {
        if (token == WETH) {
            IWETH(WETH).deposit{value: amountDesired}();
            assert(IWETH(WETH).transfer(pylon, amountDesired));
        }else{
            TransferHelper.safeTransferFrom(token, msg.sender, pylon, amountDesired);
        }
    }



    function _getAmounts(uint amountDesiredToken, uint amountDesiredETH, bool isAnchor, address tokenA, address tokenB) internal view returns (uint amountA, uint amountB){
        uint atA =  !isAnchor ? amountDesiredToken : amountDesiredETH;
        uint atB = !isAnchor ?  amountDesiredETH : amountDesiredToken;
        //        uint aminA = !isAnchor ? amountTokenMin : amountETHMin;
        //        uint aminB = !isAnchor ?  amountETHMin : amountTokenMin;
        (amountA, amountB) = _addAsyncLiquidity(tokenA, tokenB, atA, atB);
    }

    // Transfers both tokens to pylon
    function _transferAsync(address tokenA, address tokenB, uint amountA, uint amountB) internal returns (address pylon){
        pylon = _getPylon(tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pylon, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pylon, amountB);
    }

    // Modifier to check that pylon & pair are initialized
    modifier _addLiquidityChecks(address tokenA, address tokenB) {
        address pair = IZirconFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "ZPR: Pair Not Created");
        require(IZirconPylonFactory(pylonFactory).getPylon(tokenA, tokenB) != address(0), "ZPR: Pylon not created");
        // Checking if pylon is initialized
        require(ZirconPeripheralLibrary.isInitialized(pylonFactory, tokenA, tokenB, pair), "ZPR: Pylon Not Initialized");
        _;
    }
    // function called only to use the modifier to restrict the usage
    function restricted(address tokenA, address tokenB) internal _addLiquidityChecks(tokenA, tokenB){}

    // **** INIT PYLON *****
    function _initializePylon(address tokenA, address tokenB) internal virtual returns (address pair, address pylon) {
        // If Pair is not initialized
        pair = IZirconFactory(factory).getPair(tokenA, tokenB);

        if (pair == address(0)) {
            // Let's create it...
            pair = IZirconFactory(factory).createPair(tokenA, tokenB, pylonFactory);
        }

        //Let's see if pylon is initialized
        pylon = IZirconPylonFactory(pylonFactory).getPylon(tokenA, tokenB);
        if (pylon == address(0)) {
            // adds pylon
            pylon = IZirconPylonFactory(pylonFactory).addPylon(pair, tokenA, tokenB);
        }
    }

    // Init Function with two tokens
    function init(
        address tokenA,
        address tokenB,
        uint amountDesiredA,
        uint amountDesiredB,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB){
        // Initializes the pylon
        (, address pylon) = _initializePylon(tokenA, tokenB);
        // Desired amounts
        amountA = amountDesiredA;
        amountB = amountDesiredB;
        // Let's transfer to pylon
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pylon, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pylon, amountB);
        // init Pylon
        IZirconPylon(pylon).initPylon(to);
    }

    // Init Function with one token and utility token
    function initETH(
        address token,
        uint amountDesiredToken,
        bool isAnchor,
        address to,
        uint deadline
    ) virtual override ensure(deadline)  external payable  returns (uint amountA, uint amountB){

        // Initialize Pylon & Pair
        address tokenA = isAnchor ? WETH : token;
        address tokenB = isAnchor ? token : WETH;
        (, address pylon) = _initializePylon(tokenA, tokenB);


        amountA = isAnchor ? msg.value : amountDesiredToken;
        amountB = isAnchor ? amountDesiredToken : msg.value;

        // Transfering tokens to Pylon
        TransferHelper.safeTransferFrom(token, msg.sender, pylon, amountDesiredToken);
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pylon, msg.value));

        // Calling init Pylon
        IZirconPylon(pylon).initPylon(to);
    }

    // **** ADD SYNC LIQUIDITY ****
    function stake(address farm, uint liquidity) internal {
        (bool success, bytes memory data) = farm.call(abi.encodeWithSelector(DEPOSIT, uint256(liquidity)));
        if (!success) {
            if(data.length > 0){
                assembly {
                    let returndata_size := mload(data)
                    revert(add(32, data), returndata_size)
                }
            }else{
                require(success, 'ZP: FARM_FAILED');
            }
        }
    }

    function addSyncLiquidity(
        address tokenA,
        address tokenB,
        uint amountDesired,
        uint minLiquidity,
        bool isAnchor,
        address to,
        address farm,
        uint deadline
    ) virtual override ensure(deadline)  external returns (uint amount, uint liquidity) {
        // Checking Pylon and pair are initialized
        restricted(tokenA, tokenB);
        amount = amountDesired;
        // Getting pylon address
        address pylon = _getPylon(tokenA, tokenB);
        // Transferring tokens
        TransferHelper.safeTransferFrom(isAnchor ? tokenB : tokenA, msg.sender, pylon, amount);
        liquidity = IZirconPylon(pylon).mintPoolTokens(to, isAnchor);
        require(liquidity >= minLiquidity, "ZPR: Not enough liquidity");
        // Adding liquidity
        if (farm != address(0)) {
            stake(farm, liquidity);
        }
    }

    // @isAnchor indicates if the token should be the anchor or float
    // it mints the ETH token, so the opposite of isAnchor
    // In case where we want to mint the token we should use the classic addSyncLiquidity
    // TODO: removing shouldMintAnchor change on FE
    function addSyncLiquidityETH(
        address token,
        bool isAnchor,
        uint minLiquidity,
        address to,
        address farm,
        uint deadline
    ) virtual override ensure(deadline) external payable returns (uint liquidity) {
        require(msg.value > 0, "ZPR: ZERO-VALUE");
        address tokenA = isAnchor ? WETH : token;
        address tokenB = isAnchor ? token : WETH;
        // Checking Pylon and pair are initialized
        restricted(tokenA, tokenB);
        // Getting Pylon Address
        address pylon = _getPylon(tokenA, tokenB);
        // transferring token or utility token
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pylon, msg.value));
        // minting tokens
        liquidity = IZirconPylon(pylon).mintPoolTokens(to, !isAnchor);
        require(liquidity >= minLiquidity, "ZPR: Not enough liquidity");
        // Adding liquidity
        if (farm != address(0)) {
            stake(farm, liquidity);
        }
    }

    // **** ASYNC-100 LIQUIDITY ******
    //    function addAsyncLiquidity100(
    //        address tokenA,
    //        address tokenB,
    //        uint amountDesired,
    //        bool isAnchor,
    //        address to,
    //        address farm,
    //        uint deadline
    //    ) virtual override ensure(deadline) _addLiquidityChecks(tokenA, tokenB) external returns (uint liquidity){
    //        // Getting Pylon Address
    //        address pylon = _getPylon(tokenA, tokenB);
    //        // sending tokens to pylon
    //        TransferHelper.safeTransferFrom(isAnchor ? tokenB : tokenA, msg.sender, pylon, amountDesired);
    //        // minting async-100
    //        liquidity = IZirconPylon(pylon).mintAsync100(to, isAnchor);
    //        // Adding liquidity
    //        if (farm != address(0)) {
    //            stake(farm, liquidity);
    //        }
    //    }

    // @isAnchor indicates if the token should be the anchor or float
    // This Function mints tokens for WETH in the contrary of @isAnchor
    //    function addAsyncLiquidity100ETH(
    //        address token,
    //        bool isAnchor,
    //        address to,
    //        address farm,
    //        uint deadline
    //    ) virtual override ensure(deadline)  external payable returns (uint liquidity){
    //        require(msg.value > 0, "ZPR: ZERO-VALUE");
    //        address tokenA = isAnchor ? WETH : token;
    //        address tokenB = isAnchor ? token : WETH;
    //
    //        restricted(tokenA, tokenB);
    //        // getting pylon
    //        address pylon = _getPylon(tokenA, tokenB);
    //        // Transfering tokens
    //        IWETH(WETH).deposit{value: msg.value}();
    //        assert(IWETH(WETH).transfer(pylon,  msg.value));
    //
    //        // Miting Async-100
    //        liquidity = IZirconPylon(pylon).mintAsync100(to, !isAnchor);
    //        // Adding liquidity
    //        if (farm != address(0)) {
    //            stake(farm, liquidity);
    //        }
    //    }

    // **** ADD ASYNC LIQUIDITY **** //

    function _addAsyncLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired
    ) internal virtual _addLiquidityChecks(tokenA, tokenB) view returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

    }

    function addAsyncLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint minLiquidity,
        bool isAnchor,
        address to,
        address farm,
        uint deadline
    ) virtual override ensure(deadline)  external returns (uint liquidity){
        (uint amountA, uint amountB) = _addAsyncLiquidity(tokenA, tokenB, amountADesired, amountBDesired);
        address pylon = _transferAsync(tokenA, tokenB, amountA, amountB);
        liquidity = IZirconPylon(pylon).mintAsync(to, isAnchor);

        require(liquidity >= minLiquidity,string(abi.encodePacked("MIN_LIQUIDITY: ", uint2str(liquidity), " ", uint2str(minLiquidity))));
        // Adding liquidity
        if (farm != address(0)) {
            stake(farm, liquidity);
        }
    }


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function addAsyncLiquidityETH(
        address token,
        uint amountDesiredToken,
        uint minLiquidity,
        bool isAnchor,
        bool shouldReceiveAnchor,
        address to,
        address farm,
        uint deadline
    ) virtual override ensure(deadline)  external payable returns (uint amountA, uint amountB, uint liquidity){
        {
            address _token = token;
            bool _isAnchor = isAnchor;
            (amountA, amountB) = _getAmounts(amountDesiredToken, msg.value, _isAnchor, _isAnchor ? WETH : _token, _isAnchor ?  _token : WETH);
        }
        {
            address _token = token;
            bool _isAnchor = isAnchor;

            address pylon = _getPylon(_isAnchor ? WETH : _token, _isAnchor ?  _token : WETH);
            TransferHelper.safeTransferFrom(_token, msg.sender, pylon, _isAnchor ? amountB : amountA);
            IWETH(WETH).deposit{value: _isAnchor ? amountA : amountB}();
            assert(IWETH(WETH).transfer(pylon, _isAnchor ? amountA : amountB));
            liquidity = IZirconPylon(pylon).mintAsync(to, shouldReceiveAnchor);
            require(liquidity >= minLiquidity, uint2str(liquidity));
        }
        // refund dust eth, if any
        if (msg.value > (isAnchor ? amountA : amountB)) TransferHelper.safeTransferETH(msg.sender, msg.value - (isAnchor ? amountA : amountB));
        // Adding liquidity
        if (farm != address(0)) {
            stake(farm, liquidity);
        }
    }

    // *** remove Sync

    function removeLiquiditySync(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountMin,
        bool shouldReceiveAnchor,
        address to,
        uint deadline
    ) virtual override ensure(deadline)  public returns (uint amount){
        address pylon = _getPylon(tokenA, tokenB);
        address poolToken = IZirconPTFactory(ptFactory).getPoolToken(pylon, shouldReceiveAnchor ? tokenB : tokenA);

        IZirconPoolToken(poolToken).transferFrom(msg.sender, pylon, liquidity); // send liquidity to pylon
        (amount) = IZirconPylon(pylon).burn(to, shouldReceiveAnchor);
        require(amount >= amountMin, 'UniswapV2Router: INSUFFICIENT_AMOUNT');
    }

    function removeLiquiditySyncETH(
        address token,
        uint liquidity,
        uint amountMin,
        bool isAnchor,
        bool shouldRemoveAnchor,
        address to,
        uint deadline
    ) virtual override ensure(deadline)  external returns (uint amount){
        address tokenA = isAnchor ? WETH : token;
        address tokenB = isAnchor ? token : WETH;
        (amount) = removeLiquiditySync(
            tokenA,
            tokenB,
            liquidity,
            amountMin,
            shouldRemoveAnchor,
            (isAnchor && shouldRemoveAnchor) || (!shouldRemoveAnchor && !isAnchor) ? to : address(this),
            deadline
        );
        if ((isAnchor && !shouldRemoveAnchor) || (shouldRemoveAnchor && !isAnchor)) {
            IWETH(WETH).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount);
        }
    }
    function removeLiquidityAsync(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        bool isAnchor,
        address to,
        uint deadline
    ) virtual override ensure(deadline)  public returns (uint amountA, uint amountB){
        address pylon = _getPylon(tokenA, tokenB);
        address poolToken = IZirconPTFactory(ptFactory).getPoolToken(pylon, isAnchor ? tokenB : tokenA);

        IZirconPoolToken(poolToken).transferFrom(msg.sender, pylon, liquidity); // send liquidity to pair
        (amountA, amountB) = IZirconPylon(pylon).burnAsync(to, isAnchor);


        require(amountA >= amountAMin, string(abi.encodePacked("A_AMOUNT: ", uint2str(amountA), " ", uint2str(amountAMin))));
        require(amountB >= amountBMin,  string(abi.encodePacked("B_AMOUNT: ", uint2str(amountB), " ", uint2str(amountBMin))));

    }
    function removeLiquidityAsyncETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        bool isAnchor,
        bool shouldBurnAnchor,
        address to,
        uint deadline
    ) virtual override ensure(deadline)  external returns (uint amountToken, uint amountETH){
        {
            (uint amountA, uint amountB) = removeLiquidityAsync(
                !isAnchor ? token : WETH,
                !isAnchor ? WETH : token,
                liquidity,
                !isAnchor ? amountTokenMin : amountETHMin,
                !isAnchor ? amountETHMin : amountTokenMin,
                shouldBurnAnchor,
                address(this),
                deadline
            );
            amountToken = !isAnchor ? amountA : amountB;
            amountETH = !isAnchor ?  amountB : amountA;
        }
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    //    function removeLiquiditySyncWithPermit(
    //        address tokenA,
    //        address tokenB,
    //        uint liquidity,
    //        uint amountMin,
    //        bool isAnchor,
    //        address to,
    //        uint deadline,
    //        bool approveMax, uint8 v, bytes32 r, bytes32 s
    //    ) virtual override ensure(deadline)  external returns (uint amount){
    //        address pylon = _getPylon(tokenA, tokenB);
    //        uint value = approveMax ? uint(-1) : liquidity;
    //        IZirconPoolToken(isAnchor ? IZirconPylon(pylon).anchorPoolTokenAddress() : IZirconPylon(pylon).floatPoolTokenAddress()).permit(msg.sender, address(this), value, deadline, v, r, s);
    //        (amount) = removeLiquiditySync(tokenA, tokenB, liquidity, amountMin, isAnchor, to, deadline);
    //    }
    //
    //    function removeLiquidityETHWithPermit(
    //        address token,
    //        uint liquidity,
    //        uint amountMin,
    //        bool isAnchor,
    //        bool shouldRemoveAnchor,
    //        address to,
    //        uint deadline,
    //        bool approveMax, uint8 v, bytes32 r, bytes32 s
    //    ) virtual override ensure(deadline) external returns (uint amount){
    //        address pylon = UniswapV2Library.pairFor(factory, token, WETH);
    //        uint value = approveMax ? uint(-1) : liquidity;
    //        IZirconPoolToken(shouldRemoveAnchor ? IZirconPylon(pylon).anchorPoolTokenAddress() : IZirconPylon(pylon).floatPoolTokenAddress())
    //        .permit(msg.sender, address(this), value, deadline, v, r, s);
    //        (amount) = removeLiquiditySyncETH(
    //            token,
    //            liquidity,
    //            amountMin,
    //            isAnchor,
    //            shouldRemoveAnchor,
    //            to,
    //            deadline);
    //    }
    //
    //    function removeLiquidityAsyncWithPermit(
    //        address token,
    //        uint liquidity,
    //        uint amountTokenMin,
    //        uint amountETHMin,
    //        bool isAnchor,
    //        bool shouldBurnAnchor,
    //        address to,
    //        uint deadline,
    //        bool approveMax, uint8 v, bytes32 r, bytes32 s
    //    ) virtual override ensure(deadline)  external returns (uint amountA, uint amountB){
    //        address tokenA = !isAnchor ? token : WETH;
    //        address tokenB = !isAnchor ?  WETH : token;
    //
    //        address pylon = _getPylon(tokenA, tokenB);
    //        uint value = approveMax ? uint(-1) : liquidity;
    //        IZirconPoolToken(shouldRemoveAnchor ? IZirconPylon(pylon).anchorPoolTokenAddress() : IZirconPylon(pylon).floatPoolTokenAddress())
    //        .permit(msg.sender, address(this), value, deadline, v, r, s);
    //        (amountA, amountB) = removeLiquidityAsyncETH(token, liquidity, amountAMin, amountBMin, isAnchor, to, deadline);
    //
    //    }

    //    function removeLiquidityAsyncETHWithPermit(
    //        address token,
    //        uint liquidity,
    //        uint amountTokenMin,
    //        uint amountETHMin,
    //    bool isAnchor,
    //        bool shouldBurnAnchor,
    //        address to,
    //        uint deadline,
    //        bool approveMax, uint8 v, bytes32 r, bytes32 s
    //    ) virtual override ensure(deadline) external returns (uint amountA, uint amountB){
    //        address pylon = _getPylon(tokenA, tokenB);
    //        uint value = approveMax ? uint(-1) : liquidity;
    //        IZirconPoolToken(shouldRemoveAnchor ? IZirconPylon(pylon).anchorPoolTokenAddress() : IZirconPylon(pylon).floatPoolToken())
    //        .permit(msg.sender, address(this), value, deadline, v, r, s);
    //        (amountA, amountB) = removeLiquidityAsync(token, liquidity, amountTokenMin, amountETHMin, isAnchor, shouldBurnAnchor, to, deadline);
    //
    //    }
}