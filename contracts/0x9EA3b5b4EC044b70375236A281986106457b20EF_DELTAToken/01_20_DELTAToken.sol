// DELTA-BUG-BOUNTY
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;

import "../libs/Context.sol";

import "../../interfaces/IOVLBalanceHandler.sol";
import "../../interfaces/IOVLTransferHandler.sol";
import "../../interfaces/IOVLVestingCalculator.sol";
import "../../interfaces/IRebasingLiquidityToken.sol";
import "../../interfaces/IWETH.sol";

import "./Common/OVLBase.sol";
import "../../common/OVLTokenTypes.sol";

import "./Handlers/post_first_rebasing/OVLTransferHandler.sol";
import "./Handlers/post_first_rebasing/OVLBalanceHandler.sol";
import "./Handlers/pre_first_rebasing/OVLLPRebasingHandler.sol";
import "./Handlers/pre_first_rebasing/OVLLPRebasingBalanceHandler.sol";

// Implementation of the DELTA token responsible
// for the CORE ecosystem options layer
// guarding unlocked liquidity inside of the ecosystem
// This token is time lock guarded by 90% FoT which disappears after 2 weeks to 0%
// balanceOf will return the spendable amount outside of the fee on transfer.

contract DELTAToken is OVLBase, Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    address public governance;
    address public tokenTransferHandler;
    address public rebasingLPAddress;
    address public tokenBalanceHandler;
    address public pendingGovernance;

    // ERC-20 Variables
    string private constant NAME = "DELTA.financial - deep DeFi derivatives";
    string private constant SYMBOL = "DELTA";
    uint8 private constant DECIMALS = 18;
    uint256 private constant TOTAL_SUPPLY = 45_000_000e18;

    // Configuration
    address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant BURNER = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
    address private constant LSW_ADDRESS = 0xdaFCE5670d3F67da9A3A44FE6bc36992e5E2beaB;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Handler for activation after first rebasing
    address private immutable tokenBalanceHandlerMain;
    address private immutable tokenTransferHandlerMain;

    // Lookup for pair
    address immutable public _PAIR_ADDRESS;

    constructor (address rebasingLP,  address multisig, address dfv) {
        require(address(this) < WETH_ADDRESS, "DELTAToken: Invalid Token Address");
        require(multisig != address(0));
        require(dfv != address(0));
        require(rebasingLP != address(0));

        // We get the pair address
        // token0 is the smaller address
        address uniswapPair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, // Mainnet uniswap factory
                keccak256(abi.encodePacked(address(this), WETH_ADDRESS)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
        // We whitelist the pair to have no vesting on reception
        governance = msg.sender; // bypass !gov checks
        _PAIR_ADDRESS = uniswapPair;
        setNoVestingWhitelist(uniswapPair, true);
        setNoVestingWhitelist(BURNER, true);
        setNoVestingWhitelist(rebasingLP, true);
        setNoVestingWhitelist(UNISWAP_V2_ROUTER, true); // We set the router to no vesting so we dont need to check it in the balance handler to return maxbalance.
                                                        // Since we return maxbalance of everyone who has no vesting.

        setWhitelists(multisig, true, true, true);
        // We are not setting dfv here intentionally because we have a check inside the dfv that it has them
        // Since DFV needs to be able to set whitelists itself, so it needs to be a part of the modules

        setFullSenderWhitelist(LSW_ADDRESS, true); // Nessesary for lsw because it doesnt just send to the pair

        governance = multisig;

        rebasingLPAddress = rebasingLP;
        _provideInitialSupply(LSW_ADDRESS, TOTAL_SUPPLY); 

        // Set post first rebasing ones now into private variables
        address transferHandler = address(new OVLTransferHandler(uniswapPair, dfv));
        tokenTransferHandlerMain = transferHandler;
        tokenBalanceHandlerMain = address(new OVLBalanceHandler(IOVLTransferHandler(transferHandler), IERC20(uniswapPair))); 
        
        //Set pre rebasing ones as main ones
        tokenTransferHandler = address(new OVLLPRebasingHandler(uniswapPair));
        tokenBalanceHandler = address(new OVLLPRebasingBalanceHandler()); 

    }

    function activatePostFirstRebasingState() public isGovernance() {
        require(distributor != address(0), "Set the distributor first!");
        tokenTransferHandler = tokenTransferHandlerMain;
        tokenBalanceHandler = tokenBalanceHandlerMain;
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return TOTAL_SUPPLY - balanceOf(BURNER);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function matureAllTokensOf(UserInformation storage ui, address account) internal {
        delete vestingTransactions[account]; // remove all vesting buckets
        ui.maturedBalance = ui.maxBalance;
    }

    function setFullSenderWhitelist(address account, bool canSendToMatureBalances) public isGovernance() {
        UserInformation storage ui = _userInformation[account];
        matureAllTokensOf(ui,account);
        ui.fullSenderWhitelisted = canSendToMatureBalances;
    }

   function setImmatureRecipentWhitelist(address account, bool canRecieveImmatureBalances) public isGovernance() {
        UserInformation storage ui = _userInformation[account];
        matureAllTokensOf(ui,account);
        ui.immatureReceiverWhitelisted = canRecieveImmatureBalances;
    }

    function setNoVestingWhitelist(address account, bool recievesBalancesWithoutVestingProcess) public isGovernance() {
        UserInformation storage ui = _userInformation[account];
        matureAllTokensOf(ui,account);
        ui.noVestingWhitelisted = recievesBalancesWithoutVestingProcess;
    }

    function setWhitelists(address account, bool canSendToMatureBalances, bool canRecieveImmatureBalances, bool recievesBalancesWithoutVestingProcess) public isGovernance() {
        UserInformation storage ui = _userInformation[account];
        matureAllTokensOf(ui,account);
        ui.noVestingWhitelisted = recievesBalancesWithoutVestingProcess;
        ui.immatureReceiverWhitelisted = canRecieveImmatureBalances;
        ui.fullSenderWhitelisted = canSendToMatureBalances;
    }

    // Allows for liquidity rebasing atomically 
    // Does a callback to rlp and closes right after
    function performLiquidityRebasing() public {
        onlyRLP(); // guarantees this call can be only done by the rebasing lp contract
        liquidityRebasingPermitted = true;
        IRebasingLiquidityToken(rebasingLPAddress).tokenCaller();
        liquidityRebasingPermitted = false;
        // Rebasing will adjust the lp tokens balance of the pair. Most likely to 0. This means without setting this here there is an attack vector
        lpTokensInPair = IERC20(_PAIR_ADDRESS).balanceOf(_PAIR_ADDRESS);
    }


    // Allows the rebasing LP to change balance of an account
    // Nessesary for fee efficiency of the rebasing process
    function adjustBalanceOfNoVestingAccount(address account, uint256 amount, bool isAddition) public {
        onlyRLP(); // guarantees this call can be only done by the rebasing lp contract
        UserInformation storage ui = _userInformation[account];
        require(ui.noVestingWhitelisted, "Account is a vesting address");

        if(isAddition) {
            ui.maxBalance = ui.maxBalance.add(amount);
            ui.maturedBalance = ui.maturedBalance.add(amount);
        } else {
            ui.maxBalance = amount;
            ui.maturedBalance = amount;
        }

    }

    // allow only RLP to call functions that call this function
    function onlyRLP() internal view {
        require(msg.sender == rebasingLPAddress, "DELTAToken: Only Rebasing LP contract can call this function");
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        bytes memory callData = abi.encodeWithSelector(IOVLTransferHandler.handleTransfer.selector, sender, recipient, amount);
        (bool success, bytes memory result) = tokenTransferHandler.delegatecall(callData);

        if (!success) {
            revert(_getRevertMsg(result));
        } 
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return IOVLBalanceHandler(tokenBalanceHandler).handleBalanceCalculations(account, msg.sender);
    }

    function _provideInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: supplying zero address");

        UserInformation storage ui = _userInformation[account];
        ui.maturedBalance = ui.maturedBalance.add(amount);
        ui.maxBalance = ui.maxBalance.add(amount);

        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice sets a new distributor potentially with new distribution rules
    function setDistributor(address _newDistributor) public isGovernance() {
        distributor = _newDistributor;
        setWhitelists(_newDistributor, true, true, true);
    }

    /// @notice initializes the change of governance
    function setPendingGovernance(address _newGov) public isGovernance() {
        pendingGovernance = _newGov;
    }

    function acceptGovernance() public {
        require(msg.sender == pendingGovernance);
        governance = msg.sender;
        setWhitelists(msg.sender, true, true, true);
        delete pendingGovernance;
    }

    /// @notice sets the function that calculates returns from balanceOF
    function setBalanceCalculator(address _newBalanceCalculator) public isGovernance() {
        tokenBalanceHandler = _newBalanceCalculator;
    }

    /// @notice sets a contract with new logic for transfer handlers (contract upgrade)
    function setTokenTransferHandler(address _newHandler) public isGovernance() {
        tokenTransferHandler = _newHandler;
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function totalsForWallet(address account) public view returns (WalletTotals memory totals) {
        uint256 mature = _userInformation[account].maturedBalance;
        uint256 immature;

        for(uint256 i = 0; i < QTY_EPOCHS; i++) {
            uint256 amount = vestingTransactions[account][i].amount;
            uint256 matureTxBalance = IOVLVestingCalculator(tokenBalanceHandler).getMatureBalance(vestingTransactions[account][i], block.timestamp);
            mature = mature.add(matureTxBalance);
            immature = immature.add(amount.sub(matureTxBalance));
        }
        totals.mature = mature;
        totals.immature = immature;
        totals.total = mature.add(immature);
    }

    // Optimization for Balance Handler
    function getUserInfo(address user) external view returns (UserInformationLite memory) {
        UserInformation storage info = _userInformation[user];
        return UserInformationLite(info.maturedBalance, info.maxBalance, info.mostMatureTxIndex, info.lastInTxIndex);
    }

    // Optimization for `require` checks
    modifier isGovernance() {
        _isGovernance();
        _;
    }

    function _isGovernance() private view {
        require(msg.sender == governance, "!gov");
    }

    // Remaining for js tests only before refactor
    function getTransactionDetail(VestingTransaction memory _tx) public view returns (VestingTransactionDetailed memory dtx) {
       return IOVLVestingCalculator(tokenBalanceHandler).getTransactionDetails(_tx, block.timestamp);
    }

    function userInformation(address user) external view returns (UserInformation memory) {
        return _userInformation[user];
    }
}