// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library Address {
    error AddressInsufficientBalance(address account);
    error AddressEmptyCode(address target);
    error FailedInnerCall();

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    function _revert(bytes memory returndata) private pure {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

library SafeERC20 {
    using Address for address;

    error SafeERC20FailedOperation(address token);
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }
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
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        if (leavesLen + proofLen != totalHashes + 1) {
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
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
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
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        if (leavesLen + proofLen != totalHashes + 1) {
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
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
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
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


interface IUniswapV2Factory {

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DAOTOKEN is Ownable, IERC20 {

    using SafeERC20 for IERC20;

    event ChangeBuyTax(uint256 prevTax, uint256 newTax);
    event ChangeSellTax(uint256 prevTax, uint256 newTax);

    bool private _swap;

    uint8 private constant _decimals = 18;
    
    uint16 public buyTax = 500;
    uint16 public sellTax = 500;
    uint16 public constant denominator = 10_000;
    
    uint256 public constant maxSupply = 100_000_000 ether; 
    uint256 private _totalSupply = 61_000_000 ether; 
    uint256 public threshold = 0.25 ether; 
    uint256 public swapPct = 10_000; 
    uint256 public immutable genesis;
    uint256 public startLiquidity;
    uint256 public constant firstDate2024 = 1704067200; // 1st Jan 2024 00:00 GMT+0000.
    
    address payable private _multiSig;
    address public immutable pair;

    bytes32 public OGRoot;
    bytes32 public annualRoot;

    string private constant _name = "DAOGAME";
    string private constant _symbol = "DAOG";
    
    IUniswapV2Router02 immutable private uniV2Router;
   
    uint256[] public remainingCommunity = [1_000_000 ether, 1_000_000 ether];
    uint256[] public remainingTeam = [2_500_000 ether, 2_500_000 ether];
    uint256[] public remainingRewards = [12_000_000 ether, 10_000_000 ether, 10_000_000 ether];

    mapping(address => bool) private _isPool;
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public exempted; 
    mapping(address => bytes32[]) public proofs; 

    constructor(address multiSig_, address router_) Ownable(msg.sender){
        require(
            multiSig_ != address(0) &&
            router_ != address(0),
            "zero address"
        );

        genesis = block.timestamp;

        exempted[_msgSender()] = true;
        exempted[multiSig_] = true;
        exempted[address(this)] = true;

        _balances[multiSig_] = 1_000_000 ether;
        _balances[_msgSender()] = 60_000_000 ether;

        uniV2Router = IUniswapV2Router02(router_); // mainnet 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        _multiSig = payable(multiSig_);

        pair = IUniswapV2Factory(uniV2Router.factory()).createPair(uniV2Router.WETH(), address(this));
        _isPool[pair] = true;
    }

    modifier lockSwap {
        _swap = true;
        _;
        _swap = false;
    }

    receive() external payable {}

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isPool(address addr) external view returns (bool){
        return _isPool[addr];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function setProof(bytes32[] memory _proof) external {
        proofs[_msgSender()] = _proof;
    }

    function setBuyTax(uint16 newTax) external onlyOwner {
        require (newTax <= 500, "tax cannot exceed 5%");
        emit ChangeBuyTax(buyTax, newTax);
        buyTax = newTax;
    }

    function setSellTax(uint16 newTax) external onlyOwner {
        require (newTax <= 500, "tax cannot exceed 5%");
        emit ChangeSellTax(sellTax, newTax);
        sellTax = newTax;
    }

    function setExempted(address _address, bool exempt_) external onlyOwner {
       exempted[_address] = exempt_;
    }

    function setPool(address addr, bool isPool_) external onlyOwner {
        require(addr != address(0), "zero address cannot be pool");
        _isPool[addr] = isPool_;
    }

    function safeTokenSwap(uint256 amount) external onlyOwner {
        _tokensToETH(amount);
    }

    function safeETHtransfer() external onlyOwner {
        (bool success,) = _multiSig.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function setOGRoot(bytes32 _OGRoot) external onlyOwner {
        OGRoot = _OGRoot;
    }
    
    function setAnnualRoot(bytes32 _annualRoot) external onlyOwner {
        annualRoot = _annualRoot;
    }

    function setStartLiquidity() external onlyOwner {
        require(startLiquidity == 0, "already set");
        startLiquidity = block.timestamp;
    }

    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    function setSwapPct(uint256 _swapPct) external onlyOwner {
        require(_swapPct <= denominator, "wrong pct");
        swapPct = _swapPct;
    }

    function mintCommunity() external onlyOwner {
        _mint(remainingCommunity);
    }

    function mintTeam() external onlyOwner {
        _mint(remainingTeam);
    }

    function mintRewards() external onlyOwner {
        uint256 available;
        if(block.timestamp >= firstDate2024 + 2 * (365.25 * 1 days)) {
            available += remainingRewards[2];
            delete remainingRewards[2];
        }

        if(block.timestamp >= firstDate2024 +  (365.25 * 1 days)) {
            available += remainingRewards[1];
            delete remainingRewards[1];
        }

        if(block.timestamp >= firstDate2024) {
            available += remainingRewards[0];
            delete remainingRewards[0];
        }

        _mintAvailable(available);

    }

    function setMultiSig(address payable multiSig_) external onlyOwner {
        _multiSig = multiSig_;
    }

    function withdrawLiquidity() external onlyOwner {
        // lock 1 year
        require(
            startLiquidity != 0 &&
            block.timestamp >= startLiquidity + (365.25 * 1 days),
            "not yet"
        );

        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        require(lpBalance != 0, "zero lp balance");
        IERC20(pair).safeTransfer(_multiSig, lpBalance);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(amount != 0, "cannot transfer zero");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(!(_isPool[sender] && _isPool[recipient]), "cannot transfer pool to pool");
        
        require(
            startLiquidity != 0
            || exempted[sender]
            || exempted[recipient],
             "unauthorized transfer"
        );
        
        uint256 taxedAmount = amount;
        
        if(startLiquidity != 0){

            uint256 tax;
            bool buy;
            bool sell;
            
            // if buy
            if(_isPool[sender]) {
                buy = true;
            } else if(_isPool[recipient]) {
                sell = true;
            }

            // whitelist verification
            if(buy && !exempted[recipient]) {

                if(block.timestamp <= startLiquidity + 1 hours / 2) {
                    _verify(recipient, OGRoot);

                } else if(block.timestamp <= startLiquidity + 1 hours) {
                    _verify(recipient, annualRoot);
                }
                
                // apply buy tax
                tax = amount * buyTax / denominator;  
            } else if(sell && !exempted[sender]) {
                // apply sell tax
                tax = amount * sellTax / denominator;
            }

            if(tax != 0){

                unchecked {
                    taxedAmount -= tax;
                    _balances[address(this)] += tax;
                }

                emit Transfer(sender, address(this), tax);
            }

            if(sell && _balances[address(this)] != 0) {
                address[] memory path = _getPath();
                uint256 amountOut = uniV2Router.getAmountsOut(_balances[address(this)], path)[1];
                // DAOG amount
                if (amountOut >= threshold && !_swap && swapPct != 0) {
                    _tokensToETH(_balances[address(this)] * swapPct / denominator);
                }
            }
        }
        
    

        // 0.5% limit 1st 24h
        if(block.timestamp <= startLiquidity + 1 days ){
            _checkLimits(
                recipient, 
                taxedAmount,
                50
            );
        
        // 1% limit next 72h
        } else if(block.timestamp <= startLiquidity + 4 days) {
            _checkLimits(
                recipient, 
                taxedAmount,
                100
            );
        }

        unchecked{
            _balances[recipient] += taxedAmount;
            _balances[sender] -= amount;
        }

        emit Transfer(sender, recipient, taxedAmount);
    }

    function _mint(uint256[] storage remaining) private {
        uint256 available;
        if(block.timestamp >= genesis + (365.25 * 2 days) ) {
            available += remaining[1];
            delete remaining[1];
        }

        if(block.timestamp >= genesis + (365.25 * 1 days)) {
            available += remaining[0];
            delete remaining[0];
        }
        
        _mintAvailable(available);
    }

    function _checkLimits(
        address recipient, 
        uint256 taxedAmount, 
        uint8 pct
    ) private view {
        uint256 limit = maxSupply * pct / denominator;
        string memory pctStr = pct == 50 ? "0.5% supply": "1% supply";
        
        if(!exempted[recipient] && !_isPool[recipient]) {
            require(
                _balances[recipient] + taxedAmount <= limit,
                string.concat("recipient balance ", pctStr)
            );
        }
    }


    function _verify(address _whitelisted, bytes32 _root) private view {
        string memory group = _root == OGRoot ? "OG" : "Annual";
        
        require(
            MerkleProof.verify(
                proofs[_whitelisted], 
                _root, 
                keccak256(abi.encodePacked(_whitelisted))
            ),
            string.concat("not whitelisted ", group)
        );
    }

    function _getPath() private view returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        return path;
    }

    function _tokensToETH(uint256 amount) private lockSwap {
        if(_multiSig != address(0)){
            address[] memory path = _getPath();
            _approve(address(this), address(uniV2Router), amount);
            
            uniV2Router
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                _multiSig,
                block.timestamp
            );
        }
    }

    function _mintAvailable(uint256 available) private {
        require(available != 0, "nothing to withdraw");

        unchecked {
            _balances[_multiSig] += available;
            _totalSupply += available;
        }

        require(_totalSupply <= maxSupply, "wrong supply");

        emit Transfer(address(0), _multiSig, available);
    }
}