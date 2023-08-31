// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { OFT, IERC20, ERC20 } from "OFT.sol";
import { IERC3156FlashBorrower } from "IERC3156FlashBorrower.sol";
import "IPrismaCore.sol";

/**
    @title Prisma Debt Token "acUSD"
    @notice CDP minted against collateral deposits within `TroveManager`.
            This contract has a 1:n relationship with multiple deployments of `TroveManager`,
            each of which hold one collateral type which may be used to mint this token.
 */
contract DebtToken is OFT {
    string public constant version = "1";

    // --- ERC 3156 Data ---
    bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 public constant FLASH_LOAN_FEE = 9; // 1 = 0.0001%

    // --- Data for EIP2612 ---

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant permitTypeHash = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;

    mapping(address => uint256) private _nonces;

    // --- Addresses ---
    IPrismaCore private immutable _prismaCore;
    address public immutable stabilityPoolAddress;
    address public immutable borrowerOperationsAddress;
    address public immutable factory;
    address public immutable gasPool;

    mapping(address => bool) public troveManager;

    // Amount of debt to be locked in gas pool on opening troves
    uint256 public immutable DEBT_GAS_COMPENSATION;

    constructor(
        string memory _name,
        string memory _symbol,
        address _stabilityPoolAddress,
        address _borrowerOperationsAddress,
        IPrismaCore prismaCore_,
        address _layerZeroEndpoint,
        address _factory,
        address _gasPool,
        uint256 _gasCompensation
    ) OFT(_name, _symbol, _layerZeroEndpoint) {
        stabilityPoolAddress = _stabilityPoolAddress;
        _prismaCore = prismaCore_;
        borrowerOperationsAddress = _borrowerOperationsAddress;
        factory = _factory;
        gasPool = _gasPool;

        DEBT_GAS_COMPENSATION = _gasCompensation;

        bytes32 hashedName = keccak256(bytes(_name));
        bytes32 hashedVersion = keccak256(bytes(version));

        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, hashedName, hashedVersion);
    }

    function enableTroveManager(address _troveManager) external {
        require(msg.sender == factory, "!Factory");
        troveManager[_troveManager] = true;
    }

    // --- Functions for intra-Prisma calls ---

    function mintWithGasCompensation(address _account, uint256 _amount) external returns (bool) {
        require(msg.sender == borrowerOperationsAddress);
        _mint(_account, _amount);
        _mint(gasPool, DEBT_GAS_COMPENSATION);

        return true;
    }

    function burnWithGasCompensation(address _account, uint256 _amount) external returns (bool) {
        require(msg.sender == borrowerOperationsAddress);
        _burn(_account, _amount);
        _burn(gasPool, DEBT_GAS_COMPENSATION);

        return true;
    }

    function mint(address _account, uint256 _amount) external {
        require(msg.sender == borrowerOperationsAddress || troveManager[msg.sender], "Debt: Caller not BO/TM");
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        require(troveManager[msg.sender], "Debt: Caller not TroveManager");
        _burn(_account, _amount);
    }

    function sendToSP(address _sender, uint256 _amount) external {
        require(msg.sender == stabilityPoolAddress, "Debt: Caller not StabilityPool");
        _transfer(_sender, msg.sender, _amount);
    }

    function returnFromPool(address _poolAddress, address _receiver, uint256 _amount) external {
        require(msg.sender == stabilityPoolAddress || troveManager[msg.sender], "Debt: Caller not TM/SP");
        _transfer(_poolAddress, _receiver, _amount);
    }

    // --- External functions ---

    function transfer(address recipient, uint256 amount) public override(IERC20, ERC20) returns (bool) {
        _requireValidRecipient(recipient);
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(IERC20, ERC20) returns (bool) {
        _requireValidRecipient(recipient);
        return super.transferFrom(sender, recipient, amount);
    }

    // --- ERC 3156 Functions ---

    /**
     * @dev Returns the maximum amount of tokens available for loan.
     * @param token The address of the token that is requested.
     * @return The amount of token that can be loaned.
     */
    function maxFlashLoan(address token) public view returns (uint256) {
        return token == address(this) ? type(uint256).max - totalSupply() : 0;
    }

    /**
     * @dev Returns the fee applied when doing flash loans. This function calls
     * the {_flashFee} function which returns the fee applied when doing flash
     * loans.
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256) {
        return token == address(this) ? _flashFee(amount) : 0;
    }

    /**
     * @dev Returns the fee applied when doing flash loans. By default this
     * implementation has 0 fees. This function can be overloaded to make
     * the flash loan mechanism deflationary.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function _flashFee(uint256 amount) internal pure returns (uint256) {
        return (amount * FLASH_LOAN_FEE) / 10000;
    }

    /**
     * @dev Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower-onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     * @return `true` if the flash loan was successful.
     */
    // This function can reenter, but it doesn't pose a risk because it always preserves the property that the amount
    // minted at the beginning is always recovered and burned at the end, or else the entire function will revert.
    // slither-disable-next-line reentrancy-no-eth
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        require(token == address(this), "ERC20FlashMint: wrong token");
        require(amount <= maxFlashLoan(token), "ERC20FlashMint: amount exceeds maxFlashLoan");
        uint256 fee = _flashFee(amount);
        _mint(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE,
            "ERC20FlashMint: invalid return value"
        );
        _spendAllowance(address(receiver), address(this), amount + fee);
        _burn(address(receiver), amount);
        _transfer(address(receiver), _prismaCore.feeReceiver(), fee);
        return true;
    }

    // --- EIP 2612 Functionality ---

    function domainSeparator() public view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Debt: expired deadline");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator(),
                keccak256(abi.encode(permitTypeHash, owner, spender, amount, _nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == owner, "Debt: invalid signature");
        _approve(owner, spender, amount);
    }

    function nonces(address owner) external view returns (uint256) {
        // FOR EIP 2612
        return _nonces[owner];
    }

    // --- Internal operations ---

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name_, bytes32 version_) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name_, version_, block.chainid, address(this)));
    }

    // --- 'require' functions ---

    function _requireValidRecipient(address _recipient) internal view {
        require(
            _recipient != address(0) && _recipient != address(this),
            "Debt: Cannot transfer tokens directly to the Debt token contract or the zero address"
        );
        require(
            _recipient != stabilityPoolAddress && !troveManager[_recipient] && _recipient != borrowerOperationsAddress,
            "Debt: Cannot transfer tokens directly to the StabilityPool, TroveManager or BorrowerOps"
        );
    }
}