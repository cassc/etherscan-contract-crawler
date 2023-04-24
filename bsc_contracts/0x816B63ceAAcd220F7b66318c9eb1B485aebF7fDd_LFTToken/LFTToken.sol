/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract Context {

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface NewLease{
    function getAllOrderCountByUserAddress(address userAddress) external view returns (uint[5] memory);
}

pragma solidity 0.6.12;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity 0.6.12;


interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

   
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

   
    function balanceOf(address owner) external view returns (uint256 balance);

    function totalSupply() external view returns (uint);

  
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;


    function approve(address to, uint256 tokenId) external;


    function getApproved(uint256 tokenId) external view returns (address operator);

 
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function balanceOfLevel(address owner,uint level) external view returns (uint);

    function  totalSupplyOfLevel(uint level) external view returns (uint);


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
           return address(0);
        }

        assembly {
        r := mload(add(signature, 32))
        s := mload(add(signature, 64))
        v := and(mload(add(signature, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
        v += 27;
        }

        if (v != 27 && v != 28) {
           return address(0);
        }

        /* prefix might be needed for geth only
        * https://github.com/ethereum/go-ethereum/issues/3731
        */
        // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        // hash = sha3(prefix, hash);

        return ecrecover(hash, v, r, s);
    }
    
}

 
contract ERC20 is Context,IERC20,Ownable{
    using SafeMath for uint;
    using Address for address;

    using ECDSA for *;

    mapping (address => uint) public _balances;

    mapping (address => mapping (address => uint)) private _allowances;


    uint private _totalSupply;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public _nftFeeByBuy=10;
    uint256 public _nftFeeBySell=30;
    uint256 public _LPFee=20;


    mapping (address => bool) public _isExcludedFromFee;

    bool public issueNft;

    address public leaseAddress;
    uint public addPriceTokenAmount = 1e14;
    address public usdtAddress=0x55d398326f99059fF775485246999027B3197955;
    address public nftAddress=0x1a62fe088F46561bE92BB5F6e83266289b94C154;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public  uniswapV2Pair;

    uint public period=1800;
    uint public lastSendNFTTime;
    uint public lastSendLPTime;
    
    uint public sendCount=50;
    


    address[] public shareholdersOfNFT;
    mapping (address => uint256) public shareholderIndexesOfNFT;
    mapping(address => bool) public _updatedOfNFT;
    uint256  public currentIndexOfNFT;  
    address[] public shareholdersOfLP;
    mapping (address => uint256) public shareholderIndexesOfLP;
    mapping(address => bool) public _updatedOfLP;
    uint256 public currentIndexOfLP;  

    bool isCreatePair;



    
    constructor (string memory name, string memory symbol, uint8 decimals, uint totalSupply) public {
        require(usdtAddress<address(this));
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), usdtAddress);

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
    }



    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address from,address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        bool isAddLiquidity;
        bool isDelLiquidity;
        ( isAddLiquidity, isDelLiquidity) = _isLiquidity(from,to);
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]||(from!=uniswapV2Pair&&to!=uniswapV2Pair)||isAddLiquidity||isDelLiquidity){
            takeFee=false;
        }


        uint256 NFTFee;
        uint256 LPFee;
        if (takeFee){
            if (to==uniswapV2Pair){
                LPFee=calculateLPFee(amount);
                _takeLPFee(from,LPFee);
                NFTFee=calculateNFTFeeBySell(amount);
                _takeNFTFee(from,NFTFee);

            }else{
                NFTFee=calculateNFTFeeByBuy(amount);
                _takeNFTFee(from,NFTFee);
            }
            
        }
        _balances[from] = _balances[from].sub(amount, "ERC20: transfer amount exceeds balance");
        uint256 trunAmount=amount.sub(LPFee).sub(NFTFee);
        _balances[to] = _balances[to].add(trunAmount);
        emit Transfer(from, to, trunAmount);
        if(!address(from).isContract() && from != address(0) ) setShareOfLP(from);
        if(!address(to).isContract() && to != address(0) )setShareOfLP(to);
        if (issueNft){
            if(!address(from).isContract() && from != address(0) ) setShareOfNFT(from);
            if(!address(to).isContract() && to != address(0) ) setShareOfNFT(to);
         }

        if(lastSendLPTime <block.timestamp&&lastSendLPTime!=0) {
             processOfLP();
             lastSendLPTime = block.timestamp.add(period);
        }else if(lastSendNFTTime <block.timestamp&&lastSendNFTTime!=0&&issueNft) {
             processOfNFT();
             lastSendNFTTime = block.timestamp.add(period).add(600);
        }


        if (to==uniswapV2Pair&&!isCreatePair){
            require(from==owner());
            isCreatePair=true;
            lastSendNFTTime = block.timestamp.add(period);
        }
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function processOfNFT() private {
        
        uint256 shareholderCount = shareholdersOfNFT.length;

        if(shareholderCount == 0)return;
        uint256 nowbalance3 = _balances[address(0x3000000000000000000000000000000000000000)];
        uint256 nowbalance4 = _balances[address(0x4000000000000000000000000000000000000000)];
        uint256 nowbalance5 = _balances[address(0x5000000000000000000000000000000000000000)];

        uint256 iterations = 0;

        while(iterations<sendCount && iterations < shareholderCount) {
            if(currentIndexOfNFT >= shareholderCount){
                currentIndexOfNFT = 0;
            }
            uint[5] memory balanceList=NewLease(leaseAddress).getAllOrderCountByUserAddress(shareholdersOfNFT[currentIndexOfNFT]);
            uint256 amount3=0;
            uint256 amount4=0;
            uint256 amount5=0;
            if (IERC721(nftAddress).totalSupplyOfLevel(3)>=10){
                amount3= nowbalance3.mul(IERC721(nftAddress).balanceOfLevel(shareholdersOfNFT[currentIndexOfNFT],3).add(balanceList[2])).div(IERC721(nftAddress).totalSupplyOfLevel(3));
            }

            if (IERC721(nftAddress).totalSupplyOfLevel(4)>=5){
                amount4 = nowbalance4.mul(IERC721(nftAddress).balanceOfLevel(shareholdersOfNFT[currentIndexOfNFT],4).add(balanceList[3])).div(IERC721(nftAddress).totalSupplyOfLevel(4));

            }
            if (IERC721(nftAddress).totalSupplyOfLevel(5)>=5){
                amount5 = nowbalance5.mul(IERC721(nftAddress).balanceOfLevel(shareholdersOfNFT[currentIndexOfNFT],5).add(balanceList[4])).div(IERC721(nftAddress).totalSupplyOfLevel(5));
            }
            distributeDividendOfNFT(shareholdersOfNFT[currentIndexOfNFT],amount3,amount4,amount5);
            currentIndexOfNFT++;
            iterations++;
            }
    }

    function distributeDividendOfNFT(address shareholder ,uint256 amount3,uint256 amount4,uint256 amount5) internal {
        if (_balances[address(0x3000000000000000000000000000000000000000)]>=amount3&&amount3!=0){
            _balances[address(0x3000000000000000000000000000000000000000)] = _balances[address(0x3000000000000000000000000000000000000000)].sub(amount3);
            _balances[shareholder] = _balances[shareholder].add(amount3);
             emit Transfer(address(0x3000000000000000000000000000000000000000), shareholder, amount3);
        }
        if (_balances[address(0x4000000000000000000000000000000000000000)]>=amount4&&amount4!=0){
            _balances[address(0x4000000000000000000000000000000000000000)] = _balances[address(0x4000000000000000000000000000000000000000)].sub(amount4);
            _balances[shareholder] = _balances[shareholder].add(amount4);
             emit Transfer(address(0x4000000000000000000000000000000000000000), shareholder, amount4);
        }
        if (_balances[address(0x5000000000000000000000000000000000000000)]>=amount5&&amount5!=0){
            _balances[address(0x5000000000000000000000000000000000000000)] = _balances[address(0x5000000000000000000000000000000000000000)].sub(amount5);
            _balances[shareholder] = _balances[shareholder].add(amount5);
             emit Transfer(address(0x5000000000000000000000000000000000000000), shareholder, amount5);
        } 
    }

    function setShareOfNFT(address shareholder) private {
           uint balance3=IERC721(nftAddress).balanceOfLevel(shareholder,3);
           uint balance4=IERC721(nftAddress).balanceOfLevel(shareholder,4);
           uint balance5=IERC721(nftAddress).balanceOfLevel(shareholder,5);
           uint[5] memory balanceList=NewLease(leaseAddress).getAllOrderCountByUserAddress(shareholder);
           if(_updatedOfNFT[shareholder] ){      
                if(balance3== 0&&balance4 == 0&&balance5 == 0&&balanceList[2]==0&&balanceList[3]==0&&balanceList[4]==0) {
                    quitShareOfNFT(shareholder); 
                }           
                return; 
           }
           if(balance3== 0&&balance4 == 0&&balance5 == 0&&balanceList[2]==0&&balanceList[3]==0&&balanceList[4]==0)return;
            addShareholderOfNFT(shareholder);
            _updatedOfNFT[shareholder] = true;
      }
    function addShareholderOfNFT(address shareholder) internal {
        shareholderIndexesOfNFT[shareholder] = shareholdersOfNFT.length;
        shareholdersOfNFT.push(shareholder);
    }
    function quitShareOfNFT(address shareholder) private {
           removeShareholderOfNFT(shareholder);   
           _updatedOfNFT[shareholder] = false; 
      }
    function removeShareholderOfNFT(address shareholder) internal {
        shareholdersOfNFT[shareholderIndexesOfNFT[shareholder]] = shareholdersOfNFT[shareholdersOfNFT.length-1];
        shareholderIndexesOfNFT[shareholdersOfNFT[shareholdersOfNFT.length-1]] = shareholderIndexesOfNFT[shareholder];
        shareholdersOfNFT.pop();
    }

    function processOfLP() private {
        uint256 shareholderCount = shareholdersOfLP.length;

        if(shareholderCount == 0)return;
        uint256 nowbalance = _balances[address(0x8888888888888888888888888888888888888888)];

        uint256 iterations = 0;

        while(iterations<sendCount && iterations < shareholderCount) {
            if(currentIndexOfLP >= shareholderCount){
                currentIndexOfLP = 0;
            }
            uint256 amount = nowbalance.mul(IERC20(uniswapV2Pair).balanceOf(shareholdersOfLP[currentIndexOfLP])).div(IERC20(uniswapV2Pair).totalSupply());

            if(_balances[address(0x8888888888888888888888888888888888888888)] < amount)return;
                distributeDividendOfLP(shareholdersOfLP[currentIndexOfLP],amount);
                currentIndexOfLP++;
                iterations++;
            }
    }

    function distributeDividendOfLP(address shareholder ,uint256 amount) internal {
            _balances[address(0x8888888888888888888888888888888888888888)] = _balances[address(0x8888888888888888888888888888888888888888)].sub(amount);
            _balances[shareholder] = _balances[shareholder].add(amount);
             emit Transfer(address(0x8888888888888888888888888888888888888888), shareholder, amount);
    }

    function setShareOfLP(address shareholder) private {
          uint lpbalance=IERC20(uniswapV2Pair).balanceOf(shareholder);
          uint amount0=consult(uniswapV2Pair, lpbalance);
           if(_updatedOfLP[shareholder] ){      
                if(amount0<1000*10**18) quitShareOfLP(shareholder);              
                return;  
           }
            if(amount0<1000*10**18) return;
            addShareholderOfLP(shareholder);
            _updatedOfLP[shareholder] = true;
      }
    function addShareholderOfLP(address shareholder) internal {
        shareholderIndexesOfLP[shareholder] = shareholdersOfLP.length;
        shareholdersOfLP.push(shareholder);
    }
    function quitShareOfLP(address shareholder) private {
           removeShareholderOfLP(shareholder);   
           _updatedOfLP[shareholder] = false; 
      }
    function removeShareholderOfLP(address shareholder) internal {
        shareholdersOfLP[shareholderIndexesOfLP[shareholder]] = shareholdersOfLP[shareholdersOfLP.length-1];
        shareholderIndexesOfLP[shareholdersOfLP[shareholdersOfLP.length-1]] = shareholderIndexesOfLP[shareholder];
        shareholdersOfLP.pop();
    }

    function consult(address _lpToken, uint256 _amountIn) public view returns (uint256 amountOut) {
        uint tokenBalance = _balances[_lpToken];
        if (tokenBalance==0) return 0;
        uint totalLp =IERC20(_lpToken).totalSupply();
        if (totalLp==0) return 0;
        uint amount0 = _amountIn.mul(tokenBalance).div(totalLp);
        return amount0;
    }
    function setIssueNft(bool _bool)public onlyOwner{
        issueNft=_bool;
    }


    function calculateLPFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_LPFee).div(
            10**3
        );
    }
   

    function setNFTFeePercent(uint256[2] memory NFTFee) external onlyOwner() {
        _nftFeeByBuy = NFTFee[0];
        _nftFeeBySell = NFTFee[1];
    }

    function setleaseAddress(address _leaseAddress) public onlyOwner(){
        leaseAddress=_leaseAddress;
    }


    function setNFTAddress(address _nftAddress) external onlyOwner() {
        nftAddress = _nftAddress;
    }




    function calculateNFTFeeByBuy(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_nftFeeByBuy).div(
            10**3
        );
    }
    function calculateNFTFeeBySell(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_nftFeeBySell).div(
            10**3
        );
    }




    function _takeNFTFee(address from,uint256 NFTFee) private {
        if (NFTFee==0)return;
        _balances[address(0x3000000000000000000000000000000000000000)]= _balances[address(0x3000000000000000000000000000000000000000)].add(NFTFee.mul(2).div(10));
        emit Transfer(from, address(0x3000000000000000000000000000000000000000),NFTFee.mul(2).div(10));
        _balances[address(0x4000000000000000000000000000000000000000)]= _balances[address(0x4000000000000000000000000000000000000000)].add(NFTFee.mul(3).div(10));
        emit Transfer(from, address(0x4000000000000000000000000000000000000000),NFTFee.mul(3).div(10));
        _balances[address(0x5000000000000000000000000000000000000000)]= _balances[address(0x5000000000000000000000000000000000000000)].add(NFTFee.mul(5).div(10));
        emit Transfer(from, address(0x5000000000000000000000000000000000000000),NFTFee.mul(5).div(10));
    }


    function _takeLPFee(address from,uint256 LPFee) private {
        if (LPFee==0)return;
        _balances[address(0x8888888888888888888888888888888888888888)]= _balances[address(0x8888888888888888888888888888888888888888)].add(LPFee);
        emit Transfer(from, address(0x8888888888888888888888888888888888888888),LPFee);
    }


    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setInterset(uint _period,uint _sendCount)external onlyOwner{
        period = _period;
        sendCount = _sendCount;
    }


    function _isLiquidity(address from,address to)internal view returns(bool isAdd,bool isDel){
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        (uint r0,,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));
        if(to==uniswapV2Pair ){
            if( token0 != address(this) && bal0 > r0 ){
                isAdd = bal0 - r0 > addPriceTokenAmount;
            }
        }
        if( from==uniswapV2Pair ){
            if( token0 != address(this) && bal0 < r0 ){
                isDel = r0 - bal0 > 0; 
            }
        }
    }

}


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        return c;
    }
    
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract LFTToken is ERC20 {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;
  constructor () public ERC20("LFT", "LFT", 18,105000000*10**18) {
       _balances[msg.sender] = totalSupply();
        emit Transfer(address(0),msg.sender, totalSupply());
  }
}