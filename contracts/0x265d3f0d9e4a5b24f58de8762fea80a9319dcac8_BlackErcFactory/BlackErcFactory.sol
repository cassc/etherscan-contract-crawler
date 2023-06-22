/**
 *Submitted for verification at Etherscan.io on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library MerkleProof {

    error MerkleProofInvalidMultiproof();

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }


    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {

        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proof.length - 1 != totalHashes) {
            revert MerkleProofInvalidMultiproof();
        }

        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }


    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {

        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proof.length - 1 != totalHashes) {
            revert MerkleProofInvalidMultiproof();
        }

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


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

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface BercAirdrop {
    function createAirdrop(address _tokenContract, uint256 _totalSupply, uint256 _startTime, uint256 _endTime, uint256 _minDeposit) external;
}

interface Berc20Store {
    function createTokenInfo(address tokenAddress,string memory name,string memory symbol,uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintPerAddress,
        uint256 mintPrice,
        address creator,
        bytes32 wlRoot,
        uint256[] memory params,
        address[] memory authContracts
        ) external;
}

contract BlackErc20 is ERC20, Ownable {

    uint256 private constant DECIMAL_MULTIPLIER = 1e18;
    address private  blackHole = 0x000000000000000000000000000000000000dEaD;
    address public   burnAddress= 0x000000000000000000000000000000000000dEaD;


    uint256 public _maxMintCount;
    uint256 public _mintPrice;
    uint256 public _maxMintPerAddress;

    mapping(address => uint256) public _mintCounts;
    uint256 public _mintedCounts;

    address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //address public wethAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address public lpContract;
    address public _devAddress;
    address public _deplyAddress;

    uint256 public _maxPro = 0;

    uint256 public deployReserveTokenPro = 0;
    uint256 public donateReserveTokenPro = 0;
    uint256 public airDropTokenPro = 0;

    uint256 public tokenLockDays = 0;
    uint256 public deployTime;
    uint256 public tokenUnlockCounts;
    uint256 public hadTokenUnlockCounts=0;
    uint256 public totalTokensLocked;
    uint public totalTokensClaimed;


    uint256 public deployReserveEthPro = 0;
    uint256 public donateEthPro = 0;

    uint256 public wlMintCounts = 0;
    uint256 public wlMintedCounts = 0;
    uint256 public wlMintedEndTime;


    uint256 public mintStartTime=0;
    uint256 public mintEndTime;

    uint256 public _burnPer=0;

    bytes32 public wlRoot;

    uint256 public validateNftNumber=0;

    bool public deployHadClaimEth;
    bool public devHadClaimEth;
    uint256 public  remainBalance=0;

    mapping(uint256 => bool) public tokenExists;

    enum ContractType {ERC721,ERC20,ERC1155}

    struct ContractAuth {
        ContractType contractType;
        address contractAddress;
        uint256 tokenCount;
    }

    ContractAuth[] public contractAuths;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintPerAddress,
        uint256 mintPrice,
        address factoryContract,
        address devAddress,
        address deplyAddress,
        address airDropAddress,
        uint256[] memory params
    ) ERC20(symbol,name) {
        _maxMintCount = maxMintCount;
        _mintPrice = mintPrice;
        _devAddress = devAddress;
        _deplyAddress = deplyAddress;
        _maxMintPerAddress = maxMintPerAddress;

        deployReserveTokenPro = params[0];
        donateReserveTokenPro = params[2];
        wlMintCounts = params[3];
        validateNftNumber = params[13];

        tokenLockDays = params[7];
        if (tokenLockDays>0){
            require(params[6]>0,"tokenUnlockCounts must over 0");
            tokenUnlockCounts = params[6];
        }
        totalTokensLocked = totalSupply*deployReserveTokenPro*1000/100000;
        deployTime = block.timestamp;


        deployReserveEthPro = params[4];
        donateEthPro = params[5];

        if(params[15]>0){
            _burnPer = params[15];
        }

        if(params[1]>0){
            airDropTokenPro = params[1];
            _mint(airDropAddress, totalSupply*airDropTokenPro/100);
        }

        _maxPro = 100000-(1+params[0]*1000+params[1]*1000+params[2]*1000);
        _mint(factoryContract, totalSupply*1/100000);

        if(params[8]>0){
            mintStartTime = params[8];
        }
        if(params[9]>0){
            mintEndTime = params[9];
        }
        if(params[16]>0){
            wlMintedEndTime = params[16];
        }

        if(donateReserveTokenPro>0){
            _mint(devAddress, totalSupply*donateReserveTokenPro*1000/100000);
        }

        if(deployReserveTokenPro>0&&params[7]==0){
            _mint(deplyAddress, totalSupply*deployReserveTokenPro*1000/100000);
        }
        _mint(address(this), totalSupply*_maxPro/100000);
    }

    function mintProof(uint256 mintCount,address receiveAds,bytes32[] memory proof) public  payable {
        require(!isContract(msg.sender),"not supper contract mint");
        require(mintCount > 0, "Invalid mint count");
        require(mintCount <= _maxMintPerAddress, "Exceeded maximum mint count per address");
        require(msg.value >= mintCount*_mintPrice, "illegal price");
        require(_mintCounts[msg.sender]+mintCount <= _maxMintPerAddress, "over limit");
        receiveAds = msg.sender;

        if(isZero(wlRoot)){
            require(block.timestamp >= mintStartTime, "Minting has not started yet");
            require(block.timestamp <= mintEndTime, "Minting has ended");
        }else {
            if (block.timestamp<wlMintedEndTime){
                require(wlMintedCounts+mintCount<=wlMintCounts,"over limit");
                bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
                require(MerkleProof.verify(proof, wlRoot, leaf),"Not In Wl");
                wlMintedCounts += mintCount;
            }
        }

        if (block.timestamp<wlMintedEndTime){
            require(_mintedCounts-wlMintedCounts+mintCount <= (_maxMintCount - wlMintedCounts), "illegal mintAmount");
        }

        IWETH(wethAddress).deposit{value: msg.value*(100-deployReserveEthPro-donateEthPro)/100}();
        IWETH(wethAddress).approve(lpContract, msg.value*(100-deployReserveEthPro-donateEthPro)/100);
        IWETH(wethAddress).transferFrom(address(this), lpContract, msg.value*(100-deployReserveEthPro-donateEthPro)/100); 

        uint256 mintAmount = (totalSupply() * _maxPro * mintCount) / (_maxMintCount * 200000);

        for (uint256 i = 0; i < contractAuths.length; i++) {
            if (contractAuths[i].contractType == ContractType.ERC721) {
                if(validateNftNumber==1){
                    IERC721Enumerable eRC721Enumerable = IERC721Enumerable(contractAuths[i].contractAddress);
                    uint256 tokenId = eRC721Enumerable.tokenOfOwnerByIndex(msg.sender, 0);
                    require(!tokenExists[tokenId],"had used!");
                    tokenExists[tokenId] = true;
                }
                uint256 tokenCount = getERC721TokenCount(contractAuths[i].contractAddress);
                require(tokenCount >= contractAuths[i].tokenCount, "Insufficient ERC721 tokens");
            } else if (contractAuths[i].contractType == ContractType.ERC20) {
                uint256 tokenCount = getERC20TokenCount(contractAuths[i].contractAddress);
                require(tokenCount >= contractAuths[i].tokenCount, "Insufficient ERC20 tokens");
            } else if (contractAuths[i].contractType == ContractType.ERC1155) {
                uint256 tokenCount = getERC1155TokenCount(contractAuths[i].contractAddress, 0);
                require(tokenCount >= contractAuths[i].tokenCount, "Insufficient ERC1155 tokens");
            }
        }

        // Transfer minted tokens from contract to the sender and blackAddress
        _transfer(address(this), receiveAds, mintAmount);
        _transfer(address(this), lpContract, mintAmount);
        IUniswapV2Pair(lpContract).sync();

        _mintCounts[msg.sender] += mintCount;
        _mintedCounts += mintCount;
    }

    function mint(uint256 mintCount,address receiveAds) external payable {
        bytes32[] memory proof = new bytes32[](0);
        mintProof(mintCount,receiveAds,proof);
    }

    function isContract(address addr) private view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(addr)
        }
        return codeSize > 0;
    }


    function setContractAuth(uint256[] memory params, address[] memory authContracts) external onlyOwner {
        delete contractAuths;
        if (authContracts[0] != address(0)) {
            contractAuths.push(ContractAuth({
                contractType: ContractType.ERC721,
                contractAddress: authContracts[0],
                tokenCount: 1
            }));
        }
        if (authContracts[1] != address(0)) {
            contractAuths.push(ContractAuth({
                contractType: ContractType.ERC20,
                contractAddress: authContracts[1],
                tokenCount: params[14]
            }));
        }

        if (authContracts[2] != address(0)) {
            contractAuths.push(ContractAuth({
                contractType: ContractType.ERC1155,
                contractAddress: authContracts[2],
                tokenCount: 1
            }));
        }
        if (authContracts[3] != address(0)) {
           burnAddress = authContracts[3];
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 feeAmount = amount * _burnPer / 100;
        uint256 transferAmount = amount - feeAmount;
        super._transfer(msg.sender, recipient, transferAmount);
        if(feeAmount>0){
            super._transfer(msg.sender, burnAddress, feeAmount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 feeAmount = amount * _burnPer / 100;
        uint256 transferAmount = amount - feeAmount;
        super._transfer(sender, recipient, transferAmount);
        if(feeAmount>0){
            super._transfer(sender, burnAddress, feeAmount);
        }
        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        super._approve(sender, msg.sender, currentAllowance - amount);
         return true;
    }


    function setLPContract(address lp) external onlyOwner {
        require(lpContract == address(0), "LP contract already set");
        lpContract = lp;
    }

    function setWlRoot(bytes32 root) external onlyOwner {
        wlRoot = root;
    }

    function devAwardEth() external {
        require(_mintedCounts==_maxMintCount,"waiting mint finish");
        require(!devHadClaimEth,"had claimed");
        require(msg.sender==_devAddress,"only dev!");
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance.");
        address payable sender = payable(_devAddress);
        uint256 devAmount = donateEthPro*balance/(deployReserveEthPro+donateEthPro);
        if(remainBalance==0){
            sender.transfer(devAmount);
            remainBalance = balance-devAmount;
        }else{
            sender.transfer(remainBalance);
        }
        devHadClaimEth = true;
    }

    function deployAwardEth() external {
        require(_mintedCounts==_maxMintCount,"waiting mint finish");
        require(!deployHadClaimEth,"had claimed");
        require(msg.sender==_deplyAddress,"only deply!");
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance.");
        address payable sender = payable(_deplyAddress);
        uint256 deplyAmount = deployReserveEthPro*balance/(deployReserveEthPro+donateEthPro);
        if(remainBalance==0){
            sender.transfer(deplyAmount);
            remainBalance = balance-deplyAmount;
        }else{
            sender.transfer(remainBalance);
        }
        deployHadClaimEth = true;
    }

    function deployAwardToken() external {
        require(_mintedCounts==_maxMintCount,"waiting mint finish");
        require(msg.sender==_deplyAddress,"not deplyer");
        require(totalTokensClaimed <= totalTokensLocked, "All tokens have been claimed.");
        uint256 currentTimestamp = block.timestamp;
        uint256 lockEndTime = deployTime + (tokenLockDays * 86400);
        uint256 unlockTimes = (lockEndTime - currentTimestamp) / ((tokenLockDays / tokenUnlockCounts) * 86400) - hadTokenUnlockCounts;
        uint256 claimableTokens;
        IERC20 token2 = IERC20(address(this));
        if (unlockTimes >= tokenUnlockCounts) {
            claimableTokens = token2.balanceOf(address(this));
            hadTokenUnlockCounts = tokenUnlockCounts;
        } else {
            require(unlockTimes>0,"not have unlock times!");
            claimableTokens = unlockTimes * (totalTokensLocked/tokenUnlockCounts);
            hadTokenUnlockCounts += unlockTimes;
        }
        token2.transfer(msg.sender, claimableTokens);
    }


    function getERC721TokenCount(address contractAddress) internal view returns (uint256) {
        IERC721 erc721Contract = IERC721(contractAddress);
        return erc721Contract.balanceOf(msg.sender);
    }

    function getERC20TokenCount(address contractAddress) internal view returns (uint256) {
        IERC20 erc20Contract = IERC20(contractAddress);
        return erc20Contract.balanceOf(msg.sender);
    }

    function getERC1155TokenCount(address contractAddress, uint256 tokenId) internal view returns (uint256) {
        IERC1155 erc1155Contract = IERC1155(contractAddress);
        return erc1155Contract.balanceOf(msg.sender, tokenId);
    }

    function burn(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        _burn(msg.sender, amount);
    }

    function getMintedCounts() external view returns (uint256) {
        return _mintedCounts;
    }

    function getContractAuthsLength() public view returns (uint256) {
        return contractAuths.length;
    }

    function getAllContractAuths() public view returns (ContractAuth[] memory) {
        return contractAuths;
    }

    function isZero(bytes32 value) private  pure returns (bool) {
        return value == 0x0000000000000000000000000000000000000000000000000000000000000000;
    }

    function getAllContractTypes() public view returns (uint256[] memory) {
        uint256[] memory contractTypes = new uint256[](contractAuths.length);
        if (contractAuths.length==0){
            return new uint256[](0);
        }
        for (uint256 i = 0; i < contractAuths.length; i++) {
            contractTypes[i] = uint256(contractAuths[i].contractType);
        }
        return contractTypes;
    }


}

contract BlackErcFactory is Ownable {

    address public uniswapRouter;
    address public blackHole;
    address public devAddress;

    uint256 public reserveTokenMax = 15;
    uint256 public airDropTokenMax = 20;
    uint256 public donateTokenMax = 3;
    uint256 public reserveEthMax = 15;
    uint256 public donateEthMax = 3;
    uint256 public burnPerMax = 5;

    address public AIRDROP_CONTRACT = 0x49062c81848f93Db6E8E71f4E358106798A03e61;
    address public TOKENSTORE_CONTRACT = 0x1aa6F5c3F2e822BD2A3568cC99b7f69950A7839e;
    bool public isOpenCreate;
    uint256 public createFee = 100000000000000; // 0.0001 ETH

    mapping(string => address) public _tokenContracts;

    enum ContractType {ERC721,ERC20,ERC1155}

    struct ContractAuth {
        ContractType contractType;
        address contractAddress;
        uint256 tokenCount;
    }

    ContractAuth[] public contractAuths;

    constructor() {
        uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        blackHole = 0x000000000000000000000000000000000000dEaD;
    }
 
    function createToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintPerAddress,
        uint256 mintPrice,
        bytes32 wlRoot,
        uint256[] memory params,
        address[] memory authContracts
    ) external payable {
        require(isOpenCreate,"Not Open Create");
        require(bytes(symbol).length > 2, "Invalid token symbol length");
        require(bytes(symbol).length < 7, "Invalid token symbol length");
        require(msg.value >= createFee, "Incorrect payment amount");
        require(params[0] <= reserveTokenMax, "Invalid reserveToken percentage");
        require(params[1] <= airDropTokenMax, "Invalid airDropToken percentage");
        require(params[2] <= donateTokenMax, "Invalid donateToken percentage");
        require(params[3] <= maxMintCount, "Invalid wlcounts");
        require(params[4] <= reserveEthMax, "Invalid reserveEth percentage");
        require(params[5] <= donateEthMax, "Invalid DonateEth percentage");
        require(params[6] <= 100, "Invalid unlockCounts");
        require(params[7] <= 2000, "Invalid lodckedDays");
        require(params[15] <= burnPerMax, "Invalid burn percentage");

        // Create an ERC20 token contract
        BlackErc20 token = new BlackErc20(symbol,name, totalSupply,
            maxMintCount, maxMintPerAddress,mintPrice,address(this),devAddress,msg.sender,AIRDROP_CONTRACT,params);

        if (wlRoot.length!= 0) {
            token.setWlRoot(wlRoot);
        }

        Berc20Store berc20Store = Berc20Store(TOKENSTORE_CONTRACT);
        berc20Store.createTokenInfo(address(token),name,symbol,totalSupply,maxMintCount,maxMintPerAddress,mintPrice,msg.sender,wlRoot,params,authContracts);

        
        if(params[1]!=0){
            require(params[10]>0,"Invalid bercLimit percentage");
            require(params[12]>params[11],"Invalid depositeTime");
            require(params[12]>block.timestamp,"Invalid depositeTime");
            require(params[12]<(block.timestamp + 30 days),"Invalid depositeEndTime");
            BercAirdrop bercAirdrop = BercAirdrop(AIRDROP_CONTRACT);
            bercAirdrop.createAirdrop(address(token),totalSupply*params[1]/100,params[11],params[12],params[10]*10**18);
        }

        token.setContractAuth(params,authContracts);

        // Add liquidity and get LP tokens
        uint256 ethAmount = 100000000000000;
        addLiquidity(address(token), ethAmount, totalSupply*1/100000);
        // Put all LP tokens into the black hole
        IUniswapV2Pair pair = IUniswapV2Pair(getPairAddress(address(token)));
        uint256 lpAmount = pair.balanceOf(address(this));
        token.setLPContract(getPairAddress(address(token)));
        pair.transfer(blackHole, lpAmount);
        //give up admin privileges
        token.transferOwnership(blackHole);
    }

    function addLiquidity(
        address tokenAddress,
        uint256 ethAmount,
        uint256 tokenAmount
    ) private {
        IERC20 token = IERC20(tokenAddress);
        token.approve(uniswapRouter, tokenAmount);
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouter);
        router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 1200
        );
    }

    function getERC721TokenCount(address contractAddress) internal view returns (uint256) {
        IERC721 erc721Contract = IERC721(contractAddress);
        return erc721Contract.balanceOf(msg.sender);
    }

    function getERC20TokenCount(address contractAddress) internal view returns (uint256) {
        IERC20 erc20Contract = IERC20(contractAddress);
        return erc20Contract.balanceOf(msg.sender);
    }

    function getERC1155TokenCount(address contractAddress, uint256 tokenId) internal view returns (uint256) {
        IERC1155 erc1155Contract = IERC1155(contractAddress);
        return erc1155Contract.balanceOf(msg.sender, tokenId);
    }


    function setCreateFee(uint256 fee) external onlyOwner{
        require(fee>=100000000000000,"Invalid fee");
        createFee = fee;
    }

    function setIsOpenCreate(bool isOpen) external onlyOwner {
        isOpenCreate = isOpen;
    }


    function getPairAddress(address tokenAddress) private view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory());
        address token0 = IUniswapV2Router02(uniswapRouter).WETH();
        return factory.getPair(token0, tokenAddress);
    }

    function setUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = _uniswapRouter;
    }

    function setBurnPerMax(uint256 _burnPerMax) external onlyOwner {
        burnPerMax = _burnPerMax;
    }
    
    function setDonateEthMax(uint256 _donateEthMax) external onlyOwner {
        donateEthMax = _donateEthMax;
    }

    function setReserveEthMax(uint256 _reserveEthMax) external onlyOwner {
        reserveEthMax = _reserveEthMax;
    }

    function setDonateTokenMax(uint256 _donateTokenMax) external onlyOwner {
        donateTokenMax = _donateTokenMax;
    }

    function setAirDropTokenMax(uint256 _airDropTokenMax) external onlyOwner {
        airDropTokenMax = _airDropTokenMax;
    }

    function setReserveTokenMax(uint256 _reserveTokenMax) external onlyOwner {
        reserveTokenMax = _reserveTokenMax;
    }

    function setDevAddress(address dev) external onlyOwner {
        devAddress = dev;
    }

    function setErc20AirDropAddress(address erc20AirDrop) external onlyOwner {
        AIRDROP_CONTRACT = erc20AirDrop;
    }

    function setErc20StoreAddress(address erc20Store) external onlyOwner {
        TOKENSTORE_CONTRACT = erc20Store;
    }

    function devAward() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance.");
        address payable sender = payable(devAddress);
        sender.transfer(balance);
    }
}