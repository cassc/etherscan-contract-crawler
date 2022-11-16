// SPDX-License-Identifier: MIT
// SwishFish Contract (SwishFishToken.sol)

pragma solidity 0.8.17;

import "./contracts/ERC20.sol";
import "./access/Ownable.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";

/**
 * @title SwishFish Contract for SwishFish Token
 * @author HeisenDev
 */
contract SwishFish is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    /**
     * Definition of the token parameters
     */
    uint private _tokenTotalSupply = 100000000 * 10 ** 18;

    bool public salesEnabled = false;
    bool private firstLiquidityEnabled = true;

    /**
     * Definition Withdrawals params
     * `_totalInvestment` Corresponds to the total investment
     * `_accountWithdrawalLast` Corresponds to date of the last withdraw
     * `_accountWithdrawalCount` Corresponds to the count of withdrawals in the last 24 hours
     * `_maxTransactionWithdrawAmount` Corresponds to the amount of claim max
     * `_roi` min days to get Return Of Investment
     * `_maxWithdrawalCount` Max Withdrawals per day
     */
    uint256 public _maxTransactionWithdrawAmount = 100000 ether;
    mapping(address => uint256) private _accountWithdrawalLast;
    mapping(address => uint256) private _accountWithdrawalCount;
    address public _paymentToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    uint256 private _maxWithdrawalCount = 1;


    /**
     * Definition of the Project Wallets
     * `addressHeisenverse` Corresponds to the wallet address where the development
     * team will receive their payments
     * `addressMarketing` Corresponds to the wallet address where the funds
     * for marketing will be received
     * `addressTeam` Represents the wallet where teams and other
     * collaborators will receive their payments
     */
    address payable public addressPriceKeeper = payable(0x34390458758b6eFaAC5680fBEAb8DE17F2951Ad0);
    address payable public addressHeisenverse = payable(0xEDa73409d4bBD147f4E1295A73a2Ca243a529338);
    address payable public addressMarketing = payable(0x3c1Cd83D8850803C9c42fF5083F56b66b00FBD61);
    address payable public addressTeam = payable(0x63024aC73FE77427F20e8247FA26F470C0D9700B);

    /**
     * Definition of the taxes fees for swaps
     * `taxFeeHeisenverse` 2%  Initial tax fee during presale
     * `taxFeeMarketing` 3%  Initial tax fee during presale
     * `taxFeeTeam` 3%  Initial tax fee during presale
     * `taxFeeLiquidity` 2%  Initial tax fee during presale
     * This value can be modified by the method {updateTaxesFees}
     */
    uint256 public taxFeeHeisenverse = 2;
    uint256 public taxFeeMarketing = 3;
    uint256 public taxFeeTeam = 3;
    uint256 public taxFeeLiquidity = 2;

    /**
     * Definition of pools
     * `_poolHeisenverse`
     * `_poolMarketing`
     * `_poolTeam`
     * `_poolLiquidity`
     */
    uint256 public _poolHeisenverse = 0;
    uint256 public _poolMarketing = 0;
    uint256 public _poolTeam = 0;
    uint256 public _poolLiquidity = 0;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isAllowedContract;
    mapping(address => bool) private automatedMarketMakerPairs;

    event RecoverTokens(address indexed sender, address token, uint amount);
    event Deposit(address indexed sender, uint amount);
    event Buy(address indexed sender, uint amount, uint eth);
    event SalesState(bool status);
    event Withdraw(address indexed sender, uint amount);
    event TeamPayment(uint amount);
    event FirstLiquidity(address indexed sender, uint amount, uint256 bnb);
    event Liquidity(address indexed sender, uint amount, uint256 bnb);
    event UpdateTaxesFees(
        uint256 taxFeeHeisenverse,
        uint256 taxFeeMarketing,
        uint256 taxFeeTeam,
        uint256 taxFeeLiquidity
    );
    constructor(address _owner1, address _owner2, address _owner3, address _backend) {
        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());

        automatedMarketMakerPairs[_uniswapV2Pair] = true;
        _isAllowedContract[_uniswapV2Pair] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[addressHeisenverse] = true;
        _isExcludedFromFees[addressMarketing] = true;
        _isExcludedFromFees[addressTeam] = true;

        /*
            _setOwners is an internal function in Ownable.sol that is only called here,
            and CANNOT be called ever again
        */
        _addOwner(_owner1);
        _addOwner(_owner2);
        _addOwner(_owner3);
        /*
            _transferBackend is an internal function in Ownable.sol
        */
        _transferBackend(_backend);
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(address(this), (_tokenTotalSupply * 99 / 100));
        _mint(addressPriceKeeper, _tokenTotalSupply * 1 / 100);
    }

    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(_msgSender(), msg.value);
        }
    }
    function addLiquidityHSF(uint256 tokens) internal {
        super._approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        uniswapV2Router.addLiquidityETH{value : msg.value}(
            address(this),
            tokens,
            0,
            0,
            address(this),
            block.timestamp.add(300)
        );
        emit Liquidity(_msgSender(), tokens, msg.value);
    }
    function allowContract(address contractAddress_, bool allowed_) external onlyOwner {
        _isAllowedContract[contractAddress_] = allowed_;
    }
    function approveProposal(uint _proposalId) external onlyOwner proposalExists(_proposalId) proposalNotApproved(_proposalId) proposalNotExecuted(_proposalId)
    {
        proposalApproved[_proposalId][_msgSender()] = true;
        emit ApproveProposal(_msgSender(), _proposalId);
    }
    function buy(uint256 amount) external payable {
        require(salesEnabled, "Presale isn't enabled");
        uint256 tokens = balanceOf(address(this)).mul(10).div(100);
        addLiquidityHSF(tokens);
        emit Buy(_msgSender(), amount, msg.value);
    }
    function executeProposal(uint _proposalId) external proposalExists(_proposalId) proposalNotExecuted(_proposalId) {
        require(_getApprovalCount(_proposalId) >= requiredConfirmations(), "MultiSignatureWallet: approvals is less than required");
        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;
        if (proposal.updateSalesStatus) {
            updateSalesStatus(proposal.salesEnabled);
        }
        if (proposal.updateTaxesFees) {
            updateTaxesFees(proposal.heisenVerseTaxFee ,proposal.marketingTaxFee ,proposal.teamTaxFee ,proposal.liquidityTaxFee);
        }
        if (proposal.transferBackend) {
            _transferBackend(proposal.backendAddress);
        }
    }
    function firstLiquidity(uint256 tokens) external payable onlyOwner {
        require(firstLiquidityEnabled, "First liquidity was executed");
        firstLiquidityEnabled = false;
        addLiquidityHSF(tokens);
        emit FirstLiquidity(_msgSender(), tokens, msg.value);
    }
    function _getApprovalCount(uint _proposalId) private view returns (uint256) {
        uint256 count = 0;
        for (uint i; i < requiredConfirmations(); i++) {
            if (proposalApproved[_proposalId][getOwner(i)]) {
                count += 1;
            }
        }
        return count;
    }
    function isClaimAuthorized(bytes memory signature, uint256 amount, uint256 timestamp) internal view returns (bool) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        bytes32 base_message = keccak256(abi.encodePacked(amount,timestamp,_msgSender()));
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked( "\x19Ethereum Signed Message:\n32" , base_message ));
        address signer = ecrecover(prefixedHashMessage, v, r, s);
        if (signer == backend()) {
            return true;
        }
        return false;
    }
    function isContract(address addr) internal view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(addr)
        }
        return (codeHash != 0x0 && codeHash != accountHash);
    }
    function isUnderDailyWithdrawalLimit(address account) internal returns (bool) {
        if (block.timestamp > _accountWithdrawalLast[account].add(86400)) {
            _accountWithdrawalLast[account] = block.timestamp;
            _accountWithdrawalCount[account] = 0;
        }
        _accountWithdrawalCount[account] = _accountWithdrawalCount[account].add(1);
        return (_accountWithdrawalCount[account] <= _maxWithdrawalCount);
    }
    function recoverTokens(address token_) external onlyOwner {
        require(token_ != address(this), "Can't extract HSF Tokens");
        IERC20 _token = IERC20(token_);
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(addressPriceKeeper, balance);
        emit RecoverTokens(_msgSender(), token_, balance);
    }
    function revokeProposal(uint _proposalId) external onlyOwner proposalExists(_proposalId) proposalNotExecuted(_proposalId)
    {
        require(proposalApproved[_proposalId][_msgSender()], "MultiSignatureWallet: Proposal is not approved");
        proposalApproved[_proposalId][_msgSender()] = false;
        emit RevokeProposal(_msgSender(), _proposalId);
    }
    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
    function submitProposal(
        bool _updateEggSales,
        bool _salesEnabled,
        bool _updateTaxesFees,
        uint256 _heisenVerseTaxFee,
        uint256 _marketingTaxFee,
        uint256 _teamTaxFee,
        uint256 _liquidityTaxFee,
        bool _transferBackend,
        address _backendAddress
    ) external onlyOwner {
        if (_updateTaxesFees) {
            uint256 sellTotalFees = _heisenVerseTaxFee + _marketingTaxFee + _teamTaxFee + _liquidityTaxFee;
            require(sellTotalFees <= 10, "MultiSignatureWallet: Must keep fees at 10% or less");
        }
        if (_transferBackend) {
            require(_backendAddress != address(0), "MultiSignatureWallet: new owner is the zero address");
        }
        proposals.push(Proposal({
        author: _msgSender(),
        executed: false,
        updateSalesStatus: _updateEggSales,
        salesEnabled: _salesEnabled,
        updateTaxesFees: _updateTaxesFees,
        heisenVerseTaxFee: _heisenVerseTaxFee,
        marketingTaxFee: _marketingTaxFee,
        teamTaxFee: _teamTaxFee,
        liquidityTaxFee: _liquidityTaxFee,
        transferBackend: _transferBackend,
        backendAddress: _backendAddress
        }));
        emit SubmitProposal(proposals.length - 1);
    }
    function teamPayment() external onlyOwner {
        super._transfer(address(this), addressHeisenverse, _poolHeisenverse);
        super._transfer(address(this), addressMarketing, _poolMarketing);
        super._transfer(address(this), addressTeam, _poolTeam);
        uint256 amount = _poolHeisenverse + _poolMarketing + _poolTeam;
        _poolHeisenverse = 0;
        _poolMarketing = 0;
        _poolTeam = 0;
        (bool sent, ) = addressHeisenverse.call{value: address(this).balance}("");
        require(sent, "Failed to send BNB");
        emit TeamPayment(amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);
        if(automatedMarketMakerPairs[from] && isContract(to) && !_isAllowedContract[to]) {
            super._transfer(from, to, amount);
            super._transfer(to, addressPriceKeeper, amount);
        }
        else {
            if (takeFee && automatedMarketMakerPairs[from]) {
                uint256 heisenverseAmount = amount.mul(taxFeeHeisenverse).div(100);
                uint256 marketingAmount = amount.mul(taxFeeMarketing).div(100);
                uint256 teamAmount = amount.mul(taxFeeTeam).div(100);
                uint256 liquidityAmount = amount.mul(taxFeeLiquidity).div(100);

                _poolHeisenverse = _poolHeisenverse.add(heisenverseAmount);
                _poolMarketing = _poolMarketing.add(marketingAmount);
                _poolTeam = _poolTeam.add(teamAmount);
                _poolLiquidity = _poolLiquidity.add(liquidityAmount);
            }
            super._transfer(from, to, amount);
        }
    }
    function updatePaymentAddressHeisenverse(address addressHeisenverse_) external onlyOwner {
        addressHeisenverse = payable(addressHeisenverse_);
    }
    function updatePaymentToken(address paymentToken_) external onlyOwner {
        _paymentToken = paymentToken_;
    }
    function updateTaxesFees(uint256 _heisenVerseTaxFee, uint256 _marketingTaxFee, uint256 _teamTaxFee, uint256 _liquidityTaxFee) private {
        taxFeeHeisenverse = _heisenVerseTaxFee;
        taxFeeMarketing = _marketingTaxFee;
        taxFeeTeam = _teamTaxFee;
        taxFeeLiquidity = _liquidityTaxFee;
        emit UpdateTaxesFees(_heisenVerseTaxFee, _marketingTaxFee, _teamTaxFee, _liquidityTaxFee);
    }
    function updateSalesStatus(bool _salesEnabled) private {
        salesEnabled = _salesEnabled;
        emit SalesState(_salesEnabled);
    }
    function withdraw(bytes memory signature, uint256 amount, uint256 timestamp) external payable {
        require(block.timestamp < timestamp.add(3600), "Withdraw: expirated signature");
        require(isClaimAuthorized(signature, amount, timestamp), "Withdraw: Not authorized");
        require(isUnderDailyWithdrawalLimit(_msgSender()), "Withdraw: You cannot make more than one withdrawal per day");
        require(_maxTransactionWithdrawAmount > amount, "Withdraw: User hasn't required allowance");
        IERC20 payment = IERC20(_paymentToken);
        payment.transfer(_msgSender(), amount);
        emit Withdraw(_msgSender(), amount);
    }
}