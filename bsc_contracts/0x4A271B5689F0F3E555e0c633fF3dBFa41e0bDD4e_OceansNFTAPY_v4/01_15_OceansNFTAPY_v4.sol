// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Cast(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface Pool {
    function stake(
        address _user,
        uint256 _apy,
        uint256 _token
    ) external;
}

//stake -> user , APY, oceans value

error InvalidBusdPrice();
error NftNotFound();
error TransactionFailed();

contract OceansNFTAPY_v4 is Initializable, ERC721Upgradeable, OwnableUpgradeable {

    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter _tokenIds;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public uniswapV2Factor;
    IERC20 public WBNB;
    IERC20 public BUSD;
    IERC20 public OCEANS;
    address public WBNB_BUSD;
    address public WBNB_OCEANS;
    address developer;
    Pool public stakingPool;

    string baseUri;
    string uriSuffix;

    mapping(uint256 => string) _tokenURIs;

    struct database {
        uint256 _nftid;
        uint256 _apy; //percentage
        uint256 _price; //wei
    }
    mapping(uint256 => database) public _NftData;

    address public SaleReciever;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("OCEANSV2NFT", "OOCEANFT");

        //Pancake Mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        //Pancake Testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3

        uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Factor = IUniswapV2Factory(uniswapV2Router.factory());
        WBNB = IERC20(uniswapV2Router.WETH());
        BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //mainnet BUSD
        OCEANS = IERC20(0x2A54F9710ddeD0eBdde0300BB9ac7e21cF0E8DA5); //mainnet Oceans
        WBNB_BUSD = uniswapV2Factor.getPair(address(WBNB), address(BUSD));
        WBNB_OCEANS = uniswapV2Factor.getPair(address(WBNB), address(OCEANS));
        developer = address(0x4a6615b5FcBc9e710318282dbFA489D6699eB421);
        uriSuffix = ".json";
    }

    function mint(
        address recipents,
        uint256 _id,
        uint256 _amount
    ) public {
        require(SaleReciever != address(0),"Error: Address Not Set Yet!");
        if (_NftData[_id]._nftid == 0) revert NftNotFound();
        if (_amount < _NftData[_id]._price) revert InvalidBusdPrice();

        BUSD.transferFrom(msg.sender, address(this), _amount);

        uint nftprice = _NftData[_id]._price;
        uint extra = _amount - nftprice;

        uint TenPercent;

        uint256 Tper = (nftprice * 10) / 100;
        uint256 remaining = (nftprice * 90) / 100;

        TenPercent += Tper;

        if(extra != 0) {
            TenPercent += extra;
        }

        string memory _uri = _id.toString();

        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _mint(recipents, newId);
        _setTokenURI(newId, _uri);

        uint256 RecievedBalance = getPrice(TenPercent);

        // uint256 initialBalance = OCEANS.balanceOf(address(this));
        // swaptobuy(TenPercent);
        // uint256 RecievedBalance = OCEANS.balanceOf(address(this)) -
        //     initialBalance;

        //staking contract function
        BUSD.transfer(SaleReciever, remaining);
        BUSD.transfer(developer, TenPercent);
        // OCEANS.transfer(address(stakingPool), RecievedBalance);

        stakingPool.stake(msg.sender, _NftData[_id]._apy, RecievedBalance);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI not exist on that ID");
        string memory _RUri = _tokenURIs[tokenId];
        return string(abi.encodePacked(baseUri,_RUri,uriSuffix));
    }

    function setBaseUri(string calldata _cid) public onlyOwner {
        baseUri = _cid;
    }

    function setData(
        uint256 _id,
        uint256 _roi,
        uint256 _rate
    ) public onlyOwner {
        _NftData[_id] = database(_id, _roi, _rate);
    }

    function setSaleReciever(address _adr) public onlyOwner {
        SaleReciever = _adr;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 runningSupply = _tokenIds.current();
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= runningSupply) {
            address latestOwnerAddress = ownerOf(currentTokenId);
                 
            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getPrice(uint256 _value) public view returns (uint256) {
        (uint256 res0, uint256 res1, uint256 time) = IUniswapV2Pair(WBNB_BUSD)
            .getReserves();
        (uint256 res2, uint256 res3, uint256 time1) = IUniswapV2Pair(
            WBNB_OCEANS
        ).getReserves();
        if (time + time1 == 0) {}
        uint256 BNBout = uniswapV2Router.getAmountIn(_value, res0, res1);
        uint256 Oceansout = uniswapV2Router.getAmountIn(BNBout, res2, res3);

        return Oceansout;
    }

    function swaptobuy(uint256 amountToSwap) private {
        if (amountToSwap == 0) {
            return;
        }
        BUSD.approve(address(uniswapV2Router), amountToSwap);

        address[] memory path = new address[](2);
        path[0] = address(BUSD);
        path[1] = uniswapV2Router.WETH();

        uint256 balanceBefore = address(this).balance;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 recAmount = address(this).balance - (balanceBefore);
        purchaseOcean(recAmount);
    }

    function purchaseOcean(uint256 _value) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(OCEANS);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _value
        }(0, path, address(this), block.timestamp);
    }

    function setDeveloper(address _newDev) public onlyOwner {
        developer = _newDev;
    }

    function setStaking(address _newPool) public onlyOwner {
        stakingPool = Pool(_newPool);
    }

    function rescueFunds() public onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        if (!os) revert TransactionFailed();
    }

    function rescueToken(
        address _token,
        address recipient,
        uint256 _value
    ) public onlyOwner {
        IERC20(_token).transfer(recipient, _value);
    }

    receive() external payable {}
}