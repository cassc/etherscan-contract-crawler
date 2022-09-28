// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './RealboxVaultToken.sol';

contract RealboxVault is Ownable, ERC721Holder, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for RealboxVaultToken;

    enum CrowdFundingState {
        Uninitialized,
        Initialized,
        PrivateStarted,
        PublicStarted,
        Ended,
        Finalized,
        Canceled,
        Unfrozen
    }

    enum SalesChannels {DirectOnchain, DirectOffchain, Indirect}

    struct ProfitInfo {
        IERC20 token;
        uint256 amountPerUnit;
    }

    struct UserInfo {
        uint256 amount;
        bool claimed;
    }

    struct TxInfo {
        address sender;
        uint256 amount;
        uint256 unitPrice;
        SalesChannels channel;
        string uid;
    }

    CrowdFundingState public state;
    uint256 public vaultId;
    IERC721 public realx;
    IERC20 public baseToken;
    RealboxVaultToken public vaultToken;
    uint256 public publicUnitPrice;
    uint256 public minSupply;
    uint256 public maxSupply;
    uint256 public privateStartBlock;
    uint256 public publicStartBlock;
    uint256 public endBlock;
    address public treasuryAddress;
    uint256 public treasuryFee;
    uint256 public lastProfitId; // Last profit snapshot id
    uint256 public currentSupply;
    uint256 public totalSupply;

    // Store public and private sale states
    uint256 public txIds;
    mapping(uint256 => TxInfo) private _txInfo;
    uint256 private _processedTxId;
    uint256 private _processedToken;

    mapping(uint256 => ProfitInfo) private _profitInfo;
    mapping(address => mapping(uint256 => UserInfo)) private _userInfo;

    event NewVaultToken(address indexed tokenAddress);
    event BuyVaultToken(address indexed buyer, uint256 amount, uint256 price, string uid, uint256 txId);
    event ReturnVaultToken(uint256 txId, uint256 amount);
    event UnfrozenVaultToken(address indexed tokenAddress);
    event ShareProfit(uint256 indexed profitId, address token, uint256 amount);
    event ClaimProfit(uint256 indexed profitId, address buyer, uint256 amount);
    event AdminWithdraw(address tokenAddress, uint256 amount);
    event AdminWithdrawNft(address tokenAddress, uint256 tokenId);
    event CrowdFundingFinalized(uint256 indexed vaultId);
    event CrowdFundingCanceled(uint256 indexed vaultId);
    event CrowdFundingRefund(address indexed buyer, uint256 amount, uint256 price, string uid, uint256 txId);

    /**
     * @dev Modifier that checks that the current state is `_state`.
     */
    modifier onlyState(CrowdFundingState _state) {
        require(currentState() == _state, 'RealboxVault: invalid state');
        _;
    }

    /**
     * @param _treasuryAddress: address to collect fee
     * @param _treasuryFee: crowdfunding fee (100 = 1%, 500 = 5%, 5 = 0.05%)
     */
    function setTreasury(address _treasuryAddress, uint256 _treasuryFee)
        external
        onlyOwner
        onlyState(CrowdFundingState.Uninitialized)
    {
        treasuryAddress = _treasuryAddress;
        treasuryFee = _treasuryFee;
    }

    /**
     * @notice Initialize the contract
     * @param _vaultId: vault id
     * @param _realx: address of RealboxNFT
     * @param _baseToken: address of base token
     * @param _publicUnitPrice: price per vault token in public sale (in base token)
     * @param _minSupply: the minimum amount of vault token sold for the crowdfunding to be success
     * @param _maxSupply: the maximum amount of vault token in existence
     * @param _privateStartBlock: the start block for the private sale
     * @param _publicStartBlock: the start block for the public sale
     * @param _endBlock: the end block for the crowdfunding
     * @param _ownerAddress: address of vault owner
     * @param _name: vault token name
     */
    function initialize(
        uint256 _vaultId,
        IERC721 _realx,
        IERC20 _baseToken,
        uint256 _publicUnitPrice,
        uint256 _minSupply,
        uint256 _maxSupply,
        uint256 _privateStartBlock,
        uint256 _publicStartBlock,
        uint256 _endBlock,
        address _ownerAddress,
        string memory _name
    ) external onlyOwner onlyState(CrowdFundingState.Uninitialized) {
        state = CrowdFundingState.Initialized;

        vaultId = _vaultId;
        realx = _realx;
        baseToken = _baseToken;
        publicUnitPrice = _publicUnitPrice;
        minSupply = _minSupply;
        maxSupply = _maxSupply;
        privateStartBlock = _privateStartBlock;
        publicStartBlock = _publicStartBlock;
        endBlock = _endBlock;

        vaultToken = new RealboxVaultToken(_name);
        emit NewVaultToken(address(vaultToken));

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_ownerAddress);
    }

    /**
     * @dev Current state of the crowdfunding
     */
    function currentState() public view returns (CrowdFundingState) {
        if (state == CrowdFundingState.Initialized) {
            if (block.number >= endBlock) return CrowdFundingState.Ended;
            if (block.number >= publicStartBlock) return CrowdFundingState.PublicStarted;
            if (block.number >= privateStartBlock) return CrowdFundingState.PrivateStarted;
        }
        return state;
    }

    /**
     * @notice Finalized the crowdfunding, cancel if not raise enough minSupply.
     * @param _totalSupply: amount of vault token success raised, the remain will be refunded
     */
    function finalize(uint256 _totalSupply) external onlyOwner onlyState(CrowdFundingState.Ended) {
        if (currentSupply < minSupply) {
            state = CrowdFundingState.Canceled;
            totalSupply = 0;
            emit CrowdFundingCanceled(vaultId);
        } else {
            require(minSupply <= _totalSupply);
            require(_totalSupply <= currentSupply);
            state = CrowdFundingState.Finalized;
            totalSupply = _totalSupply;
            vaultToken.pause();
            emit CrowdFundingFinalized(vaultId);
        }
    }

    /**
     * @notice Process claim or refund next `_size` transactions
     */
    function claimOrRefund(uint256 _size) external nonReentrant onlyState(CrowdFundingState.Finalized) {
        require(_processedTxId < txIds);
        uint256 collectAmount = 0;
        uint256 txId = _processedTxId;
        uint256 tokenId = _processedToken;
        for (uint256 i = 0; i < _size; i++) {
            if (txId >= txIds) break;
            TxInfo storage txInfo = _txInfo[txId];

            uint256 claimToken = 0;
            uint256 refundToken = 0;
            if (tokenId + txInfo.amount <= totalSupply) {
                claimToken = txInfo.amount;
            } else if (tokenId < totalSupply) {
                claimToken = totalSupply - tokenId;
                refundToken = txInfo.amount - claimToken;
            } else {
                refundToken = txInfo.amount;
            }

            if (refundToken > 0) {
                if (txInfo.channel == SalesChannels.DirectOnchain) {
                    baseToken.safeTransfer(txInfo.sender, refundToken.mul(txInfo.unitPrice));
                }
                emit CrowdFundingRefund(txInfo.sender, refundToken, txInfo.unitPrice, txInfo.uid, txId);
            }
            if (claimToken > 0) {
                if (txInfo.channel == SalesChannels.DirectOnchain) {
                    collectAmount = collectAmount.add(claimToken.mul(txInfo.unitPrice));
                }
                if (txInfo.channel != SalesChannels.Indirect) {
                    vaultToken.mint(txInfo.sender, claimToken);
                }
            }
            tokenId += txInfo.amount;
            txId += 1;
        }
        _processedTxId = txId;
        _processedToken = tokenId;

        if (collectAmount > 0 && treasuryFee > 0) {
            uint256 feeAmount = (collectAmount * treasuryFee) / 10000;
            baseToken.safeTransfer(treasuryAddress, feeAmount);
            collectAmount = collectAmount.sub(feeAmount);
        }
        if (collectAmount > 0) {
            baseToken.safeTransfer(owner(), collectAmount);
            emit AdminWithdraw(address(baseToken), collectAmount);
        }
    }

    /**
     * @notice Allow transfer vault token
     */
    function unfreeze() external onlyOwner onlyState(CrowdFundingState.Finalized) {
        state = CrowdFundingState.Unfrozen;
        vaultToken.unpause();
        emit UnfrozenVaultToken(address(vaultToken));
    }

    /**
     * @notice Buy vault token through agents
     * @param _amount: amount of vault token to buy
     * @param _price: price of vault token
     * @param _channel: sales channel, must be Indirect or DirectOffchain
     * @param _uid: user identity
     * @dev Caller must have trusted agent role.
     */
    function agentBuyToken(
        uint256 _amount,
        uint256 _price,
        SalesChannels _channel,
        string memory _uid
    ) external nonReentrant onlyOwner {
        require(bytes(_uid).length > 0, 'RealboxVault: uid must not empty');
        CrowdFundingState _state = currentState();
        require(
            _state == CrowdFundingState.PrivateStarted || _state == CrowdFundingState.PublicStarted,
            'RealboxVault: invalid state'
        );
        require(
            _channel == SalesChannels.Indirect || _channel == SalesChannels.DirectOffchain,
            'RealboxVault: invalid sales channel'
        );
        _buyToken(_amount, _price, _channel, _uid);
        if (_channel == SalesChannels.Indirect) {
            vaultToken.mint(msg.sender, _amount);
        }
    }

    function agentReturnToken(uint256 _txId, uint256 _amount) external nonReentrant onlyOwner {
        require(_txId < txIds, 'RealboxVault: invalid transaction id');
        CrowdFundingState _state = currentState();
        require(
            _state == CrowdFundingState.PrivateStarted ||
                _state == CrowdFundingState.PublicStarted ||
                _state == CrowdFundingState.Ended,
            'RealboxVault: invalid state'
        );
        TxInfo storage txInfo = _txInfo[_txId];
        require(_amount > 0 && _amount <= txInfo.amount, 'RealboxVault: invalid amount');
        require(
            txInfo.channel == SalesChannels.Indirect || txInfo.channel == SalesChannels.DirectOffchain,
            'RealboxVault: invalid sales channel'
        );
        txInfo.amount = txInfo.amount.sub(_amount);
        currentSupply = currentSupply.sub(_amount);
        if (txInfo.channel == SalesChannels.Indirect) {
            vaultToken.burnFrom(msg.sender, _amount);
        }
        emit ReturnVaultToken(_txId, _amount);
    }

    /**
     * @notice Buy vault token using base token (in public sale)
     * @param _amount: amount of vault token to buy
     * @dev Caller must have allowance for this contract of at least `_amount`.
     */
    function buyPublicToken(uint256 _amount) external nonReentrant onlyState(CrowdFundingState.PublicStarted) {
        uint256 totalPrice = _amount.mul(publicUnitPrice);
        baseToken.safeTransferFrom(address(msg.sender), address(this), totalPrice);
        _buyToken(_amount, publicUnitPrice, SalesChannels.DirectOnchain, '');
    }

    function _buyToken(
        uint256 _amount,
        uint256 _price,
        SalesChannels _channel,
        string memory _uid
    ) internal {
        require(_amount > 0);
        require(_amount <= maxSupply.sub(currentSupply));
        _txInfo[txIds] = TxInfo(msg.sender, _amount, _price, _channel, _uid);
        currentSupply = currentSupply.add(_amount);
        emit BuyVaultToken(msg.sender, _amount, _price, _uid, txIds);
        txIds += 1;
    }

    /**
     * @notice Claim profit
     * @param _profitId: profit id to claim
     */
    function claimProfit(uint256 _profitId) external nonReentrant onlyState(CrowdFundingState.Unfrozen) {
        ProfitInfo storage profitInfo = _profitInfo[_profitId];
        require(profitInfo.amountPerUnit > 0, 'RealboxVault: Invalid profit id');
        UserInfo storage userInfo = _userInfo[msg.sender][_profitId];
        require(!userInfo.claimed, 'RealboxVault: Profit claimed');
        uint256 balance = vaultToken.balanceOfAt(msg.sender, _profitId);
        require(balance > 0, 'RealboxVault: No token at snapshot');
        userInfo.amount = balance.mul(profitInfo.amountPerUnit);
        userInfo.claimed = true;
        profitInfo.token.safeTransfer(address(msg.sender), userInfo.amount);
        emit ClaimProfit(_profitId, msg.sender, userInfo.amount);
    }

    /**
     * @notice Share new profit
     * @param _token: address of shared token
     * @param _amount: amount of shared token
     * @dev Owner must have allowance for this contract of at least `_amount`.
     */
    function shareProfit(IERC20 _token, uint256 _amount) external onlyOwner onlyState(CrowdFundingState.Unfrozen) {
        lastProfitId = vaultToken.snapshot();
        _token.safeTransferFrom(address(msg.sender), address(this), _amount);
        _profitInfo[lastProfitId] = ProfitInfo(_token, _amount.div(vaultToken.totalSupply()));
        emit ShareProfit(lastProfitId, address(_token), _amount);
    }

    /**
     * @notice Withdraw RealboxNFT items from vault
     * @param _tokenId: id of token to withdraw
     */
    function withdrawNft(uint256 _tokenId) external onlyOwner {
        realx.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit AdminWithdrawNft(address(realx), _tokenId);
    }
}