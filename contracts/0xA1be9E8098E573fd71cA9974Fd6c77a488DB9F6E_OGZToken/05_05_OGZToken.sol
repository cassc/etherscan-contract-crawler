// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";

contract OGZToken is ERC20{

    address public owner;
    uint256 private poolNumber = 6;
    uint256 public totalTaxRate;
    uint256 public maxTaxRate = 800;
    uint256 private constant initializeSupply = 118_000_000_000 ether;
    uint256 private toggleReferenceFees = 0;
    uint256 public toggleWhitelistAffiliate;
    uint256 public referenceFee;

    struct Pools {
        address poolAddress;
        uint256 taxRate;
    }

    mapping(uint256 => Pools) public pools;
    //For referral system
    mapping(address => address) internal _referrals;
    mapping(address => string) internal _referralNickname;
    mapping(uint256 => uint256) internal _toggledOffPools;
    mapping(address => uint256) internal _whitelist;
    mapping(string => address) internal _nickNames;
    mapping(address => uint256) internal _affiliateWhitelist;


    event RegisteredReferrence(address referrer, string nickname, address referee, uint256 timestamp);
    event CreatedLink(address owner, string nickName, uint256 timestamp);
    event FeesUpdated(uint256 indexed poolId, uint256 newRate);
    event ChangedPoolAddress(uint256 indexed poolId, address newAddress);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event TransferWithTaxFee(string referralNickName, address referralAddress, address from, uint256 amount, uint256 referralEarnedAmount, uint256 timestamp);

    constructor(
        address _multisigOwner,
        string memory _name,
        string memory _symbol,
        Pools[] memory _poolsData)
    ERC20(_name, _symbol) {
        require(_poolsData.length == poolNumber);
        owner = _multisigOwner;
        totalTaxRate = 100;
        referenceFee = 100;
        toggleWhitelistAffiliate = 1;
        _whitelist[owner] = 1;
        for (uint256 i = 0 ; i < _poolsData.length; i++) {
            pools[i] = _poolsData[i];
            totalTaxRate += _poolsData[i].taxRate;
        }
        require(totalTaxRate <= maxTaxRate, "Total tax rate is too high");
        _mint(owner, initializeSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner.");
        _;
    }

    modifier onlyAffiliateCreateNickname() {
        require(toggleWhitelistAffiliate == 0 || _affiliateWhitelist[msg.sender] == 1, "You are not affiliate");
        _;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function addWhitelist(address[] memory account) external onlyOwner returns(bool) {
        for(uint256 i = 0; i < account.length; i++) {
            require(_whitelist[account[i]] == 0, "Address already added");
            _whitelist[account[i]] = 1;
        }
        return true;
    }
    function deleteWhitelist(address[] memory account) external onlyOwner returns(bool) {
        for (uint256 i = 0; i < account.length; i++) {
            delete _whitelist[account[i]];
        }
        return true;
    }


    function changeOwner(address newOwner) external onlyOwner returns(bool) {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        return true;
    }

    function changePoolAddress(uint256 poolId, address newAddress) external onlyOwner {
        require(poolId < poolNumber, "Pool id is not found.");
        pools[poolId].poolAddress = newAddress;
        emit ChangedPoolAddress(poolId, newAddress);
    }


    function toggleOffWhitelistAffiliate() external onlyOwner returns(bool) {
        toggleWhitelistAffiliate = 0;
        return true;
    }

    function addWhitelistAffiliate(address[] memory account) external onlyOwner returns(bool) {
        for(uint256 i = 0; i < account.length; i++) {
            require(_affiliateWhitelist[account[i]] == 0, "Address already added");
            _affiliateWhitelist[account[i]] = 1;
        }

        return true;
    }

    function removeWhitelistAffiliate(address[] memory account) external onlyOwner returns(bool) {
        for(uint256 i = 0; i < account.length; i++) {
            require(_affiliateWhitelist[account[i]] == 1, "Address already deleted");
            delete _affiliateWhitelist[account[i]];
        }
        return true;
    }

    function checkCreateNicknamePermission(address account) external view returns(bool) {
        return toggleWhitelistAffiliate == 0 || _affiliateWhitelist[account] == 1;
    }


    /**
    * @param poolId Specifies the pool to be deleted
    * 0 => FuturePlan
    * 1 => Team1
    * 2 => Team2
    * 3 => Team3
    * 4 => Liquidity Pool
    * 5 => Staking
    * 6 => Future Plan or Referral
    **/
    function toggleOffTaxFee(uint256 poolId) external onlyOwner returns(bool){
        require(_toggledOffPools[poolId] == 0, "The pool is already toggled off");
        require(poolId <= poolNumber, "Pool id not found");
        if (poolId == 6) {
            toggleReferenceFees = 1;
            totalTaxRate = totalTaxRate - 100;
        }
        else {
            _toggledOffPools[poolId] = 1;
            totalTaxRate = totalTaxRate - pools[poolId].taxRate;
            delete pools[poolId];
        }
        emit FeesUpdated(poolId, 0);
        return true;
    }

    function decreaseTaxFee(uint256 poolId, uint256 newFee) external onlyOwner returns(bool){
        require(_toggledOffPools[poolId] == 0, "The pool is already toggled off");
        require(poolId <= poolNumber, "Pool id not found");
        require(newFee > 0, "New fee rate must be greater than 0");
        if (poolId == 6) {
            require(referenceFee > newFee, "New fee rate must be less than current fee rate");
            totalTaxRate = totalTaxRate - (referenceFee - newFee);
            referenceFee = newFee;
        }
        else {
            require(newFee < pools[poolId].taxRate, "New fee rate must be less than current fee rate");
            totalTaxRate = totalTaxRate - (pools[poolId].taxRate - newFee);
            pools[poolId].taxRate = newFee;
        }
        emit FeesUpdated(poolId, newFee);
        return true;
    }


    function computeFee(uint256 amount, uint256 fee) private pure returns(uint256) {
        return amount * fee / 10000;
    }

    /**
    * @dev This function calculates and distributes all applicable fees when a user makes a transfer on any contract.
    * @param amount user's input amount for the transfer.
    */
    function sendFees(address from, uint256 amount) private returns(uint256) {
        uint256 taxFee = computeFee(amount, totalTaxRate);
        uint256 collectedFee;

        for (uint256 i = 0; i < poolNumber; i++) {
            uint256 poolTaxRate = pools[i].taxRate;
            if (poolTaxRate != 0) {
                uint256 fee = computeFee(amount, poolTaxRate);
                collectedFee += fee;
                address poolAddress = pools[i].poolAddress;
            unchecked {
                _balances[poolAddress] += fee;
            }
                emit Transfer(from, poolAddress, fee);
            }
        }

        uint256 remaining = taxFee - collectedFee;
        if (toggleReferenceFees == 0) {
            address referral = _referrals[tx.origin];
            if (referral != address(0)) {
            unchecked {
                _balances[referral] += remaining;
            }
                emit Transfer(from, referral, remaining);
                emit TransferWithTaxFee(_referralNickname[referral], referral, tx.origin, amount, remaining, block.timestamp);
            } else {
                address poolZeroAddress = pools[0].poolAddress;
            unchecked {
                _balances[poolZeroAddress] += remaining;
            }
                emit Transfer(from, poolZeroAddress, remaining);
            }
        }
        return amount - taxFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 lastAmount = !isContract(msg.sender) ||
        _toggledOffPools[6] != 0 ||
        from == owner ||
        _whitelist[tx.origin] == 1 ? amount : sendFees(from, amount);
    unchecked {
        _balances[from] = fromBalance - amount;
        // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
        // decrementing then incrementing.
        _balances[to] += lastAmount;
    }
        emit Transfer(from, to, lastAmount);
    }

    function createNickname(string memory nickName) external onlyAffiliateCreateNickname returns(bool) {
        require(bytes(_referralNickname[msg.sender]).length == 0, "You already have a nickname");
        require(bytes(nickName).length != 0 && bytes(nickName).length <= 64, "Nickname must be between 1 and 64 characters");
        require(_nickNames[nickName] == address(0), "Nickname is already taken");
        _nickNames[nickName] = msg.sender;
        _referralNickname[msg.sender] = nickName;
        emit CreatedLink(msg.sender, nickName, block.timestamp);
        return true;
    }

    function getNickname(address account) external view returns(string memory) {
        return _referralNickname[account];
    }

    function getReferrer(address referee) external view returns(string memory, address) {
        address referrer = _referrals[referee];
        return (_referralNickname[referrer], referrer);
    }

    function getAddressWithNickname(string memory nickname) external view returns(address) {
        return _nickNames[nickname];
    }

    /**
    * @param nickname The return value when the getReferralLink function is executed with the referrer's address as a parameter.
    */

    function addReffer(string memory nickname) external returns(bool) {
        address referrer = _nickNames[nickname];
        bytes32 referrerNicknameHash = keccak256(abi.encodePacked(_referralNickname[referrer]));

        require(
            _referrals[referrer] != msg.sender &&
            _referrals[msg.sender] == address(0) &&
            referrerNicknameHash != keccak256(abi.encodePacked("")) &&
            referrer != address(0) &&
            referrer != msg.sender,
            "Invalid referral"
        );

        _referrals[msg.sender] = referrer;
        emit RegisteredReferrence(referrer, nickname, msg.sender, block.timestamp);
        return true;
    }
}

