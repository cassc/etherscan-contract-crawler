pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./StakingDataV2.sol";
import "./../iTrustVaultFactory.sol";
import { ITrustVaultLib as VaultLib } from "./../libraries/ItrustVaultLib.sol"; 
contract VaultV2b is  
    ERC20Upgradeable 
{
    using SafeMathUpgradeable for uint;

    uint8 internal constant FALSE = 0;
    uint8 internal constant TRUE = 1;
    uint8 internal _Locked;

    uint internal _RewardCommission;
    uint internal _AdminFee;    
    address internal _NXMAddress;
    address internal _WNXMAddress;
    address payable internal _VaultWalletAddress;
    address payable internal _TreasuryAddress;
    address internal _StakingDataAddress;
    address internal _BurnDataAddress;
    address internal _iTrustFactoryAddress;
    mapping (address => uint256) internal _ReentrantCheck;
    mapping(address => mapping(string => bool)) internal _UsedNonces;

    event Stake(address indexed account, address indexed tokenAddress, uint amount, uint balance, uint totalStaked);
    event UnstakedRequest(address indexed  account, uint amount, uint balance, uint totalStaked);
    event UnstakedApproved(address indexed  account, uint amount, uint balance, uint totalStaked);
    event TransferITV(
        address indexed  fromAccount, 
        address indexed toAccount, 
        uint amount, 
        uint fromBalance, 
        uint fromTotalStaked,
        uint toBalance, 
        uint toTotalStaked);
    
    function initialize(
        address nxmAddress,
        address wnxmAddress,
        address vaultWalletAddress,
        address stakingDataAddress,
        address burnDataAddress,
        string memory tokenName,
        string memory tokenSymbol,
        uint adminFee,
        uint commission,
        address treasuryAddress
    ) 
        initializer 
        external 
    {
        __ERC20_init(tokenName, tokenSymbol); 
        _Locked = FALSE;
        _NXMAddress = nxmAddress;
        _WNXMAddress = wnxmAddress;
        _VaultWalletAddress = payable(vaultWalletAddress);
        _StakingDataAddress = stakingDataAddress;
        _BurnDataAddress = burnDataAddress;
        _AdminFee = adminFee;
        _iTrustFactoryAddress = _msgSender();
        _RewardCommission = commission;
        _TreasuryAddress = payable(treasuryAddress);
    }

    /**
     * Public functions
     */

    function getAdminFee() external view returns (uint) {
        return _AdminFee;
    }

    function SetAdminFee(uint newFee) external {
        _onlyAdmin();
        _AdminFee = newFee;
    }

    function setCommission(uint newCommission) external {
        _onlyAdmin();
        _RewardCommission = newCommission;
    }

    function setTreasury(address newTreasury) external {
        _onlyAdmin();
        _TreasuryAddress = payable(newTreasury);
    }

    function depositNXM(uint256 value) external  {
        _valueCheck(value);
        _nonReentrant();
        _Locked = TRUE;
        IERC20Upgradeable nxmToken = IERC20Upgradeable(_NXMAddress);        

        _mint(
            _msgSender(),
            value
        );
        
        require(_getStakingDataContract().createStake(value, _msgSender()));
        require(nxmToken.transferFrom(_msgSender(), _VaultWalletAddress, value));        
        emit Stake(
            _msgSender(), 
            _NXMAddress, 
            value,
            balanceOf(_msgSender()),
            _getStakingDataContract().getAccountStakingTotal(_msgSender()));

        _Locked = FALSE;
    }

    function _depositRewardToken(address token, uint amount) internal {        
        require(token != address(0));   
        uint commission = 0;
        uint remain = amount;
        if (_RewardCommission != 0) {
            commission = amount.mul(_RewardCommission).div(10000);
            remain = amount.sub(commission);            
        }       

        IERC20Upgradeable tokenContract = IERC20Upgradeable(token);
        if (commission != 0) {
            require(tokenContract.transferFrom(msg.sender, _TreasuryAddress, commission));  
        }
        require(tokenContract.transferFrom(msg.sender, address(this), remain));  
    }

    function endRound(address[] calldata tokens, uint[] calldata tokenAmounts, bool[] calldata ignoreUnstakes) external {
        _onlyAdmin();
        require(tokens.length == tokenAmounts.length);
        
        require(_getStakingDataContract().endRound(tokens, tokenAmounts, ignoreUnstakes, _RewardCommission));
        for(uint i = 0; i < tokens.length; i++) {
            _depositRewardToken(tokens[i], tokenAmounts[i]);
        }
    }

    function getCurrentRoundData() external view returns(uint roundNumber, uint startBlock, uint endBlock) {
        _onlyAdmin();
       
        return _getStakingDataContract().getCurrentRoundData();
    }

    function getRoundData(uint roundNumberIn) external view returns(uint roundNumber, uint startBlock, uint endBlock) {
        _onlyAdmin();
        
        return _getStakingDataContract().getRoundData(roundNumberIn);
    }

    function getRoundRewards(uint roundNumber) external view 
    returns(
        address[] memory rewardTokens,
        uint[] memory rewardAmounts ,
        uint[] memory commissionAmounts,
        uint[] memory tokenPerDay,
        uint[] memory totalSupply              
    ) {
        _onlyAdmin();
        
        return _getStakingDataContract().getRoundRewards(roundNumber);
    }

    function depositWNXM(uint256 value) external {
        _valueCheck(value);
        _nonReentrant();
        _Locked = TRUE;
        IERC20Upgradeable wnxmToken = IERC20Upgradeable(_WNXMAddress);
        
        _mint(
            _msgSender(),
            value
        );

        require(_getStakingDataContract().createStake(value, _msgSender()));
        require(wnxmToken.transferFrom(_msgSender(), _VaultWalletAddress, value));        
        emit Stake(
            _msgSender(), 
            _WNXMAddress, 
            value,
            balanceOf(_msgSender()),
            _getStakingDataContract().getAccountStakingTotal(_msgSender()));
        _Locked = FALSE;
    }

    function startUnstake(uint256 value) external payable  {
        _nonReentrant();
        _Locked = TRUE;
        uint adminFee = _AdminFee;
        if(adminFee != 0) {
            require(msg.value == _AdminFee);
        }
        
        require(_getStakingDataContract().startUnstake(_msgSender(), value));
        if(adminFee != 0) {
            (bool sent, ) = _VaultWalletAddress.call{value: adminFee}("");
            require(sent);
        }
        emit UnstakedRequest(
            _msgSender(), 
            value,
            balanceOf(_msgSender()),
            _getStakingDataContract().getAccountStakingTotal(_msgSender()));

        _Locked = FALSE;
    }

    function getAccountStakes() external  view 
    returns(
        uint stakingTotal,
        uint unStakingTotal,
        uint[] memory unStakingAmounts,
        uint[] memory unStakingStarts            
    ) {       
        return _getStakingDataContract().getAccountStakes(_msgSender());
    }

    function getAllAcountUnstakes() external view returns (address[] memory accounts, uint[] memory startTimes, uint[] memory values) {
        _onlyAdmin();
        return _getStakingDataContract().getAllAcountUnstakes();
    }

    function getAccountUnstakedTotal() external view  returns (uint) {
        return _getStakingDataContract().getAccountUnstakedTotal(_msgSender());
    }

    function getUnstakedwNXMTotal() external view returns (uint) {
        return _getStakingDataContract().getUnstakedWxnmTotal();
    }


    function authoriseUnstakes(address[] memory account, uint[] memory timestamp, uint[] memory amounts) external {
        _onlyAdmin();        
        //require(_getStakingDataContract().authoriseUnstakes(account, timestamp));  
        //for each unstake burn
        for(uint i = 0; i < account.length; i++) {
            amounts[i] = (balanceOf(account[i]) >= amounts[i] ? amounts[i] : balanceOf(account[i]) );
            _getStakingDataContract().authoriseUnstake(account[i], timestamp[i], amounts[i]);  
            
            _burn(account[i],amounts[i]);
            emit UnstakedApproved(
                account[i], 
                amounts[i], 
                balanceOf(account[i]),
                _getStakingDataContract().getAccountStakingTotal(account[i]));
        }             
    }

    function withdrawUnstakedwNXM(uint amount) external {
        _nonReentrant();
        _Locked = TRUE;
        IERC20Upgradeable wnxm = IERC20Upgradeable(_WNXMAddress);
       
        uint balance = wnxm.balanceOf(address(this));
        
        require(amount <= balance);
        require(_getStakingDataContract().withdrawUnstakedToken(_msgSender(), amount));

        require(wnxm.transfer(msg.sender, amount));
       
      //  emit ClaimUnstaked(msg.sender, amount);
        _Locked = FALSE;
    }

    function isAdmin() external view returns (bool) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.isAddressAdmin(_msgSender());
    }
    function calculateRewards() external view returns (address[] memory rewardTokens, uint[] memory rewards) {        
        return _getStakingDataContract().calculateRewards(_msgSender());
    }

    function calculateRewardsForAccount(address account) external view returns (address[] memory rewardTokens, uint[] memory rewards) {
        _isTrustedSigner(_msgSender());
       
        return _getStakingDataContract().calculateRewards(account);
    }

    function withdrawRewards(address[] memory tokens, uint[] memory rewards, string memory nonce, bytes memory sig) external returns (bool) {
        require(!_UsedNonces[_msgSender()][nonce]);
        _nonReentrant();
        _Locked = TRUE;
        bool toClaim = false;
        for(uint x = 0; x < tokens.length; x++){
            if(rewards[x] != 0) {
                toClaim = true;
            }
        }
        require(toClaim == true);
        bytes32 abiBytes = keccak256(abi.encodePacked(_msgSender(), tokens, rewards, nonce, address(this)));
        bytes32 message = VaultLib.prefixed(abiBytes);

        address signer = VaultLib.recoverSigner(message, sig);
        _isTrustedSigner(signer);

       
        require(_getStakingDataContract().withdrawRewards(_msgSender(), tokens, rewards));
        _UsedNonces[_msgSender()][nonce] = true;

        for(uint x = 0; x < tokens.length; x++){
            if(rewards[x] != 0) {
                IERC20Upgradeable token = IERC20Upgradeable(tokens[x]); 
                require(token.balanceOf(address(this)) >= rewards[x]);
                require(token.transfer(_msgSender() ,rewards[x]));
            }
        }
        _Locked = FALSE;
        return true;
    }

    function burnTokensForAccount(address account, uint tokensToBurn) external returns(bool) {
        _nonReentrant();
        require(
            _BurnDataAddress == _msgSender()
        );
        require(tokensToBurn > 0);
        _Locked = TRUE;
         _burn(account, tokensToBurn);
        require(_getStakingDataContract().removeStake(tokensToBurn, account));
        _Locked = FALSE;
        return true;
    }

    /**
     * @dev See {IERC20Upgradeable-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) { 
        _transfer(_msgSender(), recipient, amount);
                
        return true;
    }

    /**
     * @dev See {IERC20Upgradeable-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);   
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount));     
        return true;    
    }

    /**
     * @dev required to be allow for receiving ETH claim payouts
     */
    receive() external payable {}

    /**
     * Private functions
     */

     /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
        _updateTotalSupplyForBlock();
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        _updateTotalSupplyForBlock();
    }

    function _getStakingDataContract() internal view returns (StakingDataV2){
        return StakingDataV2(_StakingDataAddress);
    }
    function _updateTotalSupplyForBlock() internal {
        require(_getStakingDataContract().updateTotalSupplyForDayAndBlock(totalSupply()));
    }


     /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {

        require(_getStakingDataContract().removeStake(amount, sender));
        require(_getStakingDataContract().createStake(amount, recipient));
        
        super._transfer(sender, recipient, amount);
        emit TransferITV(
            sender,
            recipient,
            amount,            
            balanceOf(sender),
            _getStakingDataContract().getAccountStakingTotal(sender),
            balanceOf(recipient),
            _getStakingDataContract().getAccountStakingTotal(recipient));            
        _updateTotalSupplyForBlock();
    }

     /**
     * Private validation functions
     */

    function _valueCheck(uint value) internal pure {
        require(value != 0, "!");
    }

    function _onlyAdmin() internal view {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(
            vaultFactory.isAddressAdmin(_msgSender())
        );
    }

    function _isTrustedSigner(address signer) internal view {
       // ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(
            ITrustVaultFactory(_iTrustFactoryAddress).isTrustedSignerAddress(signer)
        );
    }

    function _nonReentrant() internal view {
        require(_Locked == FALSE);
    }  
}