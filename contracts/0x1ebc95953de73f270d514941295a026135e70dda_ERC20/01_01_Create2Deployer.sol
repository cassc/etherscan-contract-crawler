// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface INonfungiblePositionManager is IERC721 {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

interface IHumanVerifier {
    function humanVerified(address account) external view returns (bool);
}

contract ERC20 is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bool private humanVerificationRequired = true;

    address private UNISWAP_UNIVERSAL_ROUTER =
        0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;
    address private UNISWAP_UNIVERSAL_ROUTER_OLD =
        0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B;
    address private UNISWAP_V3_ROUTER_2 =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    IHumanVerifier private humanVerifier;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply,
        address owner,
        address humanVerifier_
    ) {
        _name = name_;
        _symbol = symbol_;
        humanVerifier = IHumanVerifier(humanVerifier_);
        _mint(owner, supply);
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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

        _verify(from, to);

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

    function _verify(address from, address to) internal virtual {
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead)
        ) {
            if (
                to != UNISWAP_UNIVERSAL_ROUTER &&
                to != UNISWAP_UNIVERSAL_ROUTER_OLD &&
                to != UNISWAP_V3_ROUTER_2
            ) {
                if (humanVerificationRequired) {
                    require(
                        humanVerifier.humanVerified(to) == true,
                        "Human not verified."
                    );
                }
            }
        }
    }

    function humanVerified(address account) external view returns (bool) {
        return humanVerifier.humanVerified(account);
    }

    function setHumanVerifier(address account) public onlyOwner {
        require(account != address(0), "ERC20: account is zero address");
        humanVerifier = IHumanVerifier(account);
    }

    function setHumanVerificationRequired(bool onOff) public onlyOwner {
        humanVerificationRequired = onOff;
    }
}

contract HumanVerifier is Ownable {
    bool private verifyAllowed = false;

    mapping(address => bool) private _humanVerified;

    address private _signerAddress;
    address private _uniswapV3Quoter;

    string private _salt;

    event HumanVerified(address signer);

    constructor() {
        _salt = "MFER";
        _signerAddress = 0x361335Bbf5dC98363119d8a2bCdAeD05335cb8db;
        _uniswapV3Quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
        _humanVerified[owner()] = true;
        _humanVerified[_uniswapV3Quoter] = true;
    }

    function verifyHuman(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (bool) {
        require(verifyAllowed, "Verify is not allowed yet");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(
            abi.encodePacked(address(this), _msgSender(), _salt)
        );
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        address recovered = ecrecover(prefixedHash, _v, _r, _s);

        if (recovered == _signerAddress) {
            _humanVerified[_msgSender()] = true;
            emit HumanVerified(_msgSender());
        } else {
            revert("Human not verified.");
        }
        return true;
    }

    function humanVerified(address account) external view returns (bool) {
        return _humanVerified[account];
    }

    function allowVerify(bool allow) public onlyOwner {
        verifyAllowed = allow;
    }

    function verify(address account, bool verified) public onlyOwner {
        require(account != address(0), "account cannot be 0");
        _humanVerified[account] = verified;
    }

    function setSignerAddress(address signerAddress) public onlyOwner {
        require(signerAddress != address(0), "_signerAddress cannot be 0");
        _signerAddress = signerAddress;
    }

    function setUniswapV3Quoter(address uniswapV3Quoter) public onlyOwner {
        require(uniswapV3Quoter != address(0), "_uniswapV3Quoter cannot be 0");
        _uniswapV3Quoter = uniswapV3Quoter;
    }

    function setSalt(string memory salt) public onlyOwner {
        _salt = salt;
    }
}

contract MFERLPLocker {
    address NONFUNGIBLE_POSITION_MANAGER =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    INonfungiblePositionManager _positionManager;

    address public feeCollector;

    uint256 public lockUpDeadline;

    bool public lpNFTLocked = false;
    bool public withdrawTriggered = false;

    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector);
        _;
    }

    constructor(address owner) {
        _positionManager = INonfungiblePositionManager(
            NONFUNGIBLE_POSITION_MANAGER
        );
        feeCollector = owner;
    }

    function lockNFT(uint256 _tokenId) external onlyFeeCollector {
        require(!lpNFTLocked, "NFT is already locked");

        IERC721(NONFUNGIBLE_POSITION_MANAGER).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        lpNFTLocked = true;
    }

    function triggerNFTWithdrawal() external onlyFeeCollector {
        require(lpNFTLocked, "NFT is not locked");
        require(lockUpDeadline == 0, "Withdrawal has been already triggered");
        lockUpDeadline = block.timestamp + (90 days);
        withdrawTriggered = true;
    }

    function cancelNFTWithdrawal() external onlyFeeCollector {
        require(lpNFTLocked, "NFT is not locked");
        require(lockUpDeadline != 0, "Withdrawal has not been triggered");

        lockUpDeadline = 0;
        withdrawTriggered = false;
    }

    function withdrawNFT(uint256 _tokenId) external onlyFeeCollector {
        require(lpNFTLocked, "NFT is not locked");
        require(lockUpDeadline != 0, "Withdrawal  has not been triggered");
        require(
            block.timestamp >= lockUpDeadline,
            "Lock-up period has not ended yet"
        );

        IERC721(NONFUNGIBLE_POSITION_MANAGER).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );

        lpNFTLocked = false;
        lockUpDeadline = 0;
        withdrawTriggered = false;
    }

    function collectLPFees(uint256 _tokenId) external onlyFeeCollector {
        _positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: feeCollector,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function changeFeeCollector(address account) external onlyFeeCollector {
        require(account != address(0), "Address 0");
        feeCollector = account;
    }

    function changeNFTPositionManager(address account)
        external
        onlyFeeCollector
    {
        require(account != address(0), "Address 0");
        NONFUNGIBLE_POSITION_MANAGER = account;
        _positionManager = INonfungiblePositionManager(account);
    }
}

contract Create2Deployer is Ownable {
    event Deployed(address addr);

    function deployToken(
        uint256 _salt,
        string memory name,
        string memory symbol,
        uint256 supply,
        address owner,
        address humanVerifier
    ) public onlyOwner {
        bytes32 salt = keccak256(abi.encodePacked(_salt, owner));
        ERC20 _contract = new ERC20{salt: salt}(
            name,
            symbol,
            supply,
            owner,
            humanVerifier
        );

        _contract.transferOwnership(owner);

        emit Deployed(address(_contract));
    }

    function deployVerifier(uint256 _salt) public onlyOwner {
        bytes32 salt = keccak256(abi.encodePacked(_salt, owner()));
        HumanVerifier _contract = new HumanVerifier{salt: salt}();

        _contract.transferOwnership(owner());

        emit Deployed(address(_contract));
    }

    function deployLPLocker(uint256 _salt, address owner) public onlyOwner {
        bytes32 salt = keccak256(abi.encodePacked(_salt, owner));
        MFERLPLocker _contract = new MFERLPLocker{salt: salt}(owner);

        emit Deployed(address(_contract));
    }

    function withdraw(address tkn) public onlyOwner {
        bool success;
        if (tkn == address(0))
            (success, ) = address(msg.sender).call{
                value: address(this).balance
            }("");
        else {
            require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
            uint256 amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }
}