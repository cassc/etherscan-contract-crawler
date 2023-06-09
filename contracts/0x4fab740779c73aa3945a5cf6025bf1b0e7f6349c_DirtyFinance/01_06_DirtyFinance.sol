/*////////////////////////////////////////////////////////////////////////////////////////////////////////////
     
                                                                ╓╥[email protected]▓▒▒╓
                 $$\ $$\             $$\                     ╓g╬╜░g╣Ñ▒▒░▒▒@
                 $$ |\__|            $$ |                   ╣▒▒▄Ñ╜`    ╙▒▒▒▒▒╕
            $$$$$$$ |$$\  $$$$$$\  $$$$$$\   $$\   $$\     ▐▓▒╙░   ╓Ç,  ╙▒╓▒╫N,
            $$  __$$ |$$ |$$  __$$\ \_$$  _|  $$ |  $$ | ,╥▓▒╖▓@g▄ '╙▀   ░░▒``,╥
            $$ /  $$ |$$ |$$ |  \__|  $$ |    $$ |  $$ | ▓╣▓▓▓▓▓▓`) . =.  ▐▓@]▒
            $$ |  $$ |$$ |$$ |        $$ |$$\ $$ |  $$ | ╙▓▓▓▓@╠▓╖▒▓²,╜  ` ╢▒╣╛
            \$$$$$$$ |$$ |$$ |        \$$$$  |\$$$$$$$ |  "▓▓╢▓╫▓▓▓▒░,╓`  ▒▒H╓
             \_______|\__|\__|         \____/  \____$$ |    ╙▓▒╨╫▀▀▀▒,r║▒░,  ░╖
                                              $$\   $$ |      ▒ ,▒╓p▒░░░░░░░░░░▒
                                              \$$$$$$  |    ,m░░░░░░░   ░░░░░░░▒▓
                                               \______/   g╣░░ (,,,,    ░░  ░░░▒▒
                                           ╓∩∩╥∩∩∩╓       ▓╖,▓█▓▓▓H░░░▒╖  [   ░░▒▌
                                         ╓` ╓░      ▒╓    ▓▓▓▓▓▓▓▓@▒▒╠▄░▓,░   ░▒▒
                                        Æ  ╓░         ▒╓   `▀▓▓▓▓▓▓▓▓▓▓▓▓▓    ░▒▓
                                       ╣  ╒       ,     ▒┐   ▓▓▓▓▓▓▀░░░░▓╣   ░▒╢
                                      ▒   ▒       ▒       ▒  ▓▓▓▓▓@╦~░▒▒▒║   ░▒
                                    ,▒   ▒░      ░▒▌        \▐▓▓▓╢▒▒▒▒░░▒║░  ░╢
                                    ▒   ╣       ,▒▓▓          ▓▓▓╣╢▒▒▒▒▒▒▌▒  ▒╢
                                   ╣░  ╢       ╓╢▓▓╣░          ╙╣▒▒▒▒▒▒▒▒▓░  ░║
                                  ╣░  ╢░     ,▒╫▓▓▓╣▒░           ▓▒╖░░░▒╢▓╢  ░▒
                                 ║░  ╔▒    ,╓╩  ▓╢▓▓╣▒░           ╙▓Ñ▒@╢╢▌╘▒  ▒
                                ╔░  ╓░    ╓╝    ╘╣╣╢▓╣▒░            ╣╖╙▓╣▓ ▒  ]
                               ╣░  ║░   ,╜       ╙╣╣▓▓╣╣▒░           ▓▒╟╢▓ ║░░▒
                             ,▒──,╜░   ╓`         ╙╣╣╣▓╣╣▒░          ╢▒▒╢▓  ▒░▒
                            ╓░  ╓▒%─ `╨            ╙▓╣╬▓╣╣▒░░        ▓╢╫▓`  ▒░▒
                           ╗   ╢░▒  ╓▓               ▀╣▓▓█╣▒░░      ▐▓▓▓╜   ▒▓▓▓
                          ╢░  ╣▒   ░╜` ┐ $$$$$$\  $$\  ▀███╣▒▒░░░  á▓▓▀     ▓▒▒▒'░░░▒▒▒∩,
                         /╜'░╟▒░    ░ ╓,$$  __$$\ \__|        ╚╩╩╩╩▀▀              ""    ``
                        ╔²  )╜`'`*╚▀    $$ /  \__|$$\ $$$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$\  $$$$$$\ 
                      ╢▒▒═,N    ▒▓ 4╫   $$$$\     $$ |$$  __$$\  \____$$\ $$  __$$\ $$  _____|$$  __$$\
                      Γ"╙M4▒▒b æ  ╙╙╨   $$  _|    $$ |$$ |  $$ | $$$$$$$ |$$ |  $$ |$$ /      $$$$$$$$ |
                                        $$ |      $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |      $$   ____|
                                    $$\ $$ |      $$ |$$ |  $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$\ \$$$$$$$\ 
                                    \__|\__|      \__|\__|  \__| \_______|\__|  \__| \_______| \_______|
 
*////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DirtyFinance is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private constant NAME = "dirty.finance";
    string private constant SYMBOL = "DIRTY";
    uint8 private constant DECIMALS = 18;

    mapping(address => uint256) private rewards;
    mapping(address => uint256) private actual;
    mapping(address => mapping(address => uint256)) private allowances;

    mapping(address => bool) private excludedFromFees;
    mapping(address => bool) private excludedFromRewards;
    address[] private rewardExcluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant ACTUAL_TOTAL = 1000000 * 10**6 * 10**18;  //1 Trillion
    uint256 private rewardsTotal = (MAX - (MAX % ACTUAL_TOTAL));
    uint256 private holderFeeTotal;
    uint256 private regenFeeTotal;
    uint256 private burnFeeTotal;

    //dev reward wallets
    //1% admin, 2% holders and 2% burn
    uint256 public taxPercentage = 5;     
    uint256 public holderTaxAlloc = 20;   
    uint256 public regenTaxAlloc = 10;  
    uint256 public burnTaxAlloc = 20;      
    uint256 public totalTaxAlloc = regenTaxAlloc.add(holderTaxAlloc).add(burnTaxAlloc);

    address public regenAddress;
    address public burnAddress;

    constructor(address _regenAddress) {
        rewards[_regenAddress] = rewardsTotal;
        emit Transfer(address(0), _regenAddress, ACTUAL_TOTAL);

        regenAddress = _regenAddress;

        excludeFromRewards(_msgSender());
        excludeFromFees(_regenAddress);

        if (_regenAddress != _msgSender()) {
            excludeFromRewards(_regenAddress);
            excludeFromFees(_msgSender());
        }

        excludeFromFees(address(0x000000000000000000000000000000000000dEaD));
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() external pure override returns (uint256) {
        return ACTUAL_TOTAL;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        if (excludedFromRewards[_account]) {
            return actual[_account];
        }
        return tokenWithRewards(rewards[_account]);
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);

        _approve(
        _sender,
            _msgSender(),
            allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance")
        );

        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(_msgSender(), _spender, allowances[_msgSender()][_spender].add(_addedValue));
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            _spender,
            allowances[_msgSender()][_spender].sub(_subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function isExcludedFromRewards(address _account) external view returns (bool) {
        return excludedFromRewards[_account];
    }

    function isExcludedFromFees(address _account) external view returns (bool) {
        return excludedFromFees[_account];
    }

    function totalFees() external view returns (uint256) {
        return holderFeeTotal.add(regenFeeTotal).add(burnFeeTotal);
    }

    function totalHolderFees() external view returns (uint256) {
        return holderFeeTotal;
    }

    function totalRegenFees() external view returns (uint256) {
        return regenFeeTotal;
    }

    function totalBurnFees() external view returns (uint256) {
        return burnFeeTotal;
    }


    function distribute(uint256 _actualAmount) public {
        address sender = _msgSender();
        require(!excludedFromRewards[sender], "Excluded addresses cannot call this function");

        (uint256 rewardAmount, , , , ) = _getValues(_actualAmount);
        rewards[sender] = rewards[sender].sub(rewardAmount);
        rewardsTotal = rewardsTotal.sub(rewardAmount);
        holderFeeTotal = holderFeeTotal.add(_actualAmount);
    }

    function excludeFromFees(address _account) public onlyOwner() {
        require(!excludedFromFees[_account], "Account is already excluded from fee");
        excludedFromFees[_account] = true;
    }

    function includeInFees(address _account) public onlyOwner() {
        require(excludedFromFees[_account], "Account is already included in fee");
        excludedFromFees[_account] = false;
    }

    function excludeFromRewards(address _account) public onlyOwner() {
        require(!excludedFromRewards[_account], "Account is already excluded from reward");

        if (rewards[_account] > 0) {
            actual[_account] = tokenWithRewards(rewards[_account]);
        }

        excludedFromRewards[_account] = true;
        rewardExcluded.push(_account);
    }

    function includeInRewards(address _account) public onlyOwner() {
        require(excludedFromRewards[_account], "Account is already included in rewards");

        for (uint256 i = 0; i < rewardExcluded.length; i++) {
            if (rewardExcluded[i] == _account) {
                rewardExcluded[i] = rewardExcluded[rewardExcluded.length - 1];
                actual[_account] = 0;
                excludedFromRewards[_account] = false;
                rewardExcluded.pop();
                break;
            }
        }
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");

        uint256 currentTaxPercentage = taxPercentage;
        if (excludedFromFees[_sender] || excludedFromFees[_recipient]) {
            taxPercentage = 0;
        } else {
            uint256 fee = _getFee(_amount);
            uint256 regenFee = _getRegenFee(fee);
            uint256 burnFee = _getBurnFee(fee);

            _updateRegenFee(regenFee);
            _updateBurnFee(burnFee);
            
        }

        if (excludedFromRewards[_sender] && !excludedFromRewards[_recipient]) {
            _transferWithoutSenderRewards(_sender, _recipient, _amount);
        } else if (!excludedFromRewards[_sender] && excludedFromRewards[_recipient]) {
            _transferWithRecipientRewards(_sender, _recipient, _amount);
        } else if (!excludedFromRewards[_sender] && !excludedFromRewards[_recipient]) {
            _transferWithRewards(_sender, _recipient, _amount);
        } else if (excludedFromRewards[_sender] && excludedFromRewards[_recipient]) {
            _transferWithoutRewards(_sender, _recipient, _amount);
        } else {
            _transferWithRewards(_sender, _recipient, _amount);
        }

        if (currentTaxPercentage != taxPercentage) {
            taxPercentage = currentTaxPercentage;
        }
    }

    function _transferWithRewards(
        address _sender,
        address _recipient,
        uint256 _actualAmount
    ) private {
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee,
            uint256 actualTransferAmount,
            uint256 actualFee
        ) = _getValues(_actualAmount);

        rewards[_sender] = rewards[_sender].sub(rewardAmount);
        rewards[_recipient] = rewards[_recipient].add(rewardTransferAmount);
        _updateHolderFee(rewardFee, actualFee);
        emit Transfer(_sender, _recipient, actualTransferAmount);
    }

    function _transferWithRecipientRewards(
        address _sender,
        address _recipient,
        uint256 _actualAmount
    ) private {
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee,
            uint256 actualTransferAmount,
            uint256 actualFee
        ) = _getValues(_actualAmount);

        rewards[_sender] = rewards[_sender].sub(rewardAmount);
        actual[_recipient] = actual[_recipient].add(actualTransferAmount);
        rewards[_recipient] = rewards[_recipient].add(rewardTransferAmount);
        _updateHolderFee(rewardFee, actualFee);
        emit Transfer(_sender, _recipient, actualTransferAmount);
    }

    function _transferWithoutSenderRewards(
        address _sender,
        address _recipient,
        uint256 _actualAmount
    ) private {
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee,
            uint256 actualTransferAmount,
            uint256 actualFee
        ) = _getValues(_actualAmount);

        actual[_sender] = actual[_sender].sub(_actualAmount);
        rewards[_sender] = rewards[_sender].sub(rewardAmount);
        rewards[_recipient] = rewards[_recipient].add(rewardTransferAmount);
        _updateHolderFee(rewardFee, actualFee);
        emit Transfer(_sender, _recipient, actualTransferAmount);
    }

    function _transferWithoutRewards(
        address _sender,
        address _recipient,
        uint256 _actualAmount
    ) private {
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee,
            uint256 actualTransferAmount,
            uint256 actualFee
        ) = _getValues(_actualAmount);

        actual[_sender] = actual[_sender].sub(_actualAmount);
        rewards[_sender] = rewards[_sender].sub(rewardAmount);
        actual[_recipient] = actual[_recipient].add(actualTransferAmount);
        rewards[_recipient] = rewards[_recipient].add(rewardTransferAmount);
        _updateHolderFee(rewardFee, actualFee);
        emit Transfer(_sender, _recipient, actualTransferAmount);
    }

    function _updateHolderFee(uint256 _rewardFee, uint256 _actualFee) private {
        rewardsTotal = rewardsTotal.sub(_rewardFee);
        holderFeeTotal = holderFeeTotal.add(_actualFee);
    }

    function _updateRegenFee(uint256 _regenFee) private {
        if (regenAddress == address(0)) {
            return;
        }

        uint256 rewardsRate = _getRewardsRate();
        uint256 rewardRegenFee = _regenFee.mul(rewardsRate);
        regenFeeTotal = regenFeeTotal.add(_regenFee);

        rewards[regenAddress] = rewards[regenAddress].add(rewardRegenFee);
        if (excludedFromRewards[regenAddress]) {
            actual[regenAddress] = actual[regenAddress].add(_regenFee);
        }
    }

    function _updateBurnFee(uint256 _burnFee) private {
        if (burnAddress == address(0)) {
            return;
        }

        uint256 rewardsRate = _getRewardsRate();
        uint256 rewardBurnFee = _burnFee.mul(rewardsRate);
        burnFeeTotal = burnFeeTotal.add(_burnFee);

        rewards[burnAddress] = rewards[burnAddress].add(rewardBurnFee);
        if (excludedFromRewards[burnAddress]) {
            actual[burnAddress] = actual[burnAddress].add(_burnFee);
        }
    }


    function rewardsFromToken(uint256 _actualAmount, bool _deductTransferFee) public view returns (uint256) {
        require(_actualAmount <= ACTUAL_TOTAL, "Amount must be less than supply");
        if (!_deductTransferFee) {
            (uint256 rewardAmount, , , , ) = _getValues(_actualAmount);
            return rewardAmount;
        } else {
            (, uint256 rewardTransferAmount, , , ) = _getValues(_actualAmount);
            return rewardTransferAmount;
        }
    }

    function tokenWithRewards(uint256 _rewardAmount) public view returns (uint256) {
        require(_rewardAmount <= rewardsTotal, "Amount must be less than total rewards");
        uint256 rewardsRate = _getRewardsRate();
        return _rewardAmount.div(rewardsRate);
    }

    function _getValues(uint256 _actualAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 actualTransferAmount, uint256 actualFee) = _getActualValues(_actualAmount);
        uint256 rewardsRate = _getRewardsRate();
        (
            uint256 rewardAmount,
            uint256 rewardTransferAmount,
            uint256 rewardFee
        ) = _getRewardValues(_actualAmount, actualFee, rewardsRate);

        return (rewardAmount, rewardTransferAmount, rewardFee, actualTransferAmount, actualFee);
    }

    function _getActualValues(uint256 _actualAmount) private view returns (uint256, uint256) {
        uint256 actualFee = _getFee(_actualAmount);
        uint256 actualHolderFee = _getHolderFee(actualFee);
        uint256 actualTransferAmount = _actualAmount.sub(actualFee);
        return (actualTransferAmount, actualHolderFee);
    }

    function _getRewardValues(
        uint256 _actualAmount,
        uint256 _actualHolderFee,
        uint256 _rewardsRate
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 actualFee = _getFee(_actualAmount).mul(_rewardsRate);
        uint256 rewardAmount = _actualAmount.mul(_rewardsRate);
        uint256 rewardTransferAmount = rewardAmount.sub(actualFee);
        uint256 rewardFee = _actualHolderFee.mul(_rewardsRate);
        return (rewardAmount, rewardTransferAmount, rewardFee);
    }

    function _getRewardsRate() private view returns (uint256) {
        (uint256 rewardsSupply, uint256 actualSupply) = _getCurrentSupply();
        return rewardsSupply.div(actualSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rewardsSupply = rewardsTotal;
        uint256 actualSupply = ACTUAL_TOTAL;

        for (uint256 i = 0; i < rewardExcluded.length; i++) {
            if (rewards[rewardExcluded[i]] > rewardsSupply || actual[rewardExcluded[i]] > actualSupply) {
                return (rewardsTotal, ACTUAL_TOTAL);
            }

            rewardsSupply = rewardsSupply.sub(rewards[rewardExcluded[i]]);
            actualSupply = actualSupply.sub(actual[rewardExcluded[i]]);
        }

        if (rewardsSupply < rewardsTotal.div(ACTUAL_TOTAL)) {
            return (rewardsTotal, ACTUAL_TOTAL);
        }

        return (rewardsSupply, actualSupply);
    }

    function _getFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxPercentage).div(100);
    }

    function _getHolderFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(holderTaxAlloc).div(totalTaxAlloc);
    }

    function _getRegenFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(regenTaxAlloc).div(totalTaxAlloc);
    }

    function _getBurnFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(burnTaxAlloc).div(totalTaxAlloc);
    }


    function setTaxPercentage(uint256 _taxPercentage) external onlyOwner {
        require(_taxPercentage >= 1 && _taxPercentage <= 10, "Value is outside of range 1-10");
        taxPercentage = _taxPercentage;
    }

    function setTaxAllocations(
        uint256 _holderTaxAlloc,
        uint256 _regenTaxAlloc,
        uint256 _burnTaxAlloc
        
    ) external onlyOwner {
        totalTaxAlloc = _holderTaxAlloc.add(_regenTaxAlloc).add(_burnTaxAlloc);

        require(_holderTaxAlloc >= 5 && _holderTaxAlloc <= 20, "_holderTaxAlloc is outside of range 5-20");
        require(_burnTaxAlloc >= 5 && _burnTaxAlloc <= 20, "_burnTaxAlloc is outside of range 5-20");
        require(_regenTaxAlloc <= 10, "_regenTaxAlloc is greater than 10");
        

        holderTaxAlloc = _holderTaxAlloc;
        regenTaxAlloc = _regenTaxAlloc;
        burnTaxAlloc = _burnTaxAlloc;
        
    }

    function setRegenAddress(address _regenAddress) external onlyOwner {
        regenAddress = _regenAddress;
    }

    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
    }


}