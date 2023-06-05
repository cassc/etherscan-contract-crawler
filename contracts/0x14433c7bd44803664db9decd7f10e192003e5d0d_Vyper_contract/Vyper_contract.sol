# @version 0.3.7


# Interfaces

interface IERC20:
    def allowance(_owner: address, _spender: address) -> uint256: view
    def balanceOf(_owner: address) -> uint256: view
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable

interface ILendingPoolCore:
    def activeLenders() -> uint256: view
    def fundsAvailable() -> uint256: view
    def fundsInvested() -> uint256: view
    def totalFundsInvested() -> uint256: view
    def totalRewards() -> uint256: view
    def totalSharesBasisPoints() -> uint256: view


# Structs

struct InvestorFunds:
    currentAmountDeposited: uint256
    totalAmountDeposited: uint256
    totalAmountWithdrawn: uint256
    sharesBasisPoints: uint256
    activeForRewards: bool



# Events

event OwnerProposed:
    ownerIndexed: indexed(address)
    proposedOwnerIndexed: indexed(address)
    owner: address
    proposedOwner: address
    erc20TokenContract: address

event OwnershipTransferred:
    ownerIndexed: indexed(address)
    proposedOwnerIndexed: indexed(address)
    owner: address
    proposedOwner: address
    erc20TokenContract: address

event LendingPoolPeripheralAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address


# Global variables

owner: public(address)
proposedOwner: public(address)

lendingPoolPeripheral: public(address)
erc20TokenContract: public(address)

funds: public(HashMap[address, InvestorFunds])
lenders: DynArray[address, 2**50]
knownLenders: public(HashMap[address, bool])
activeLenders: public(uint256)

fundsAvailable: public(uint256)
fundsInvested: public(uint256)
totalFundsInvested: public(uint256)
totalRewards: public(uint256)
totalSharesBasisPoints: public(uint256)

migrationDone: public(bool)

##### INTERNAL METHODS #####

@view
@internal
def _fundsAreAllowed(_owner: address, _spender: address, _amount: uint256) -> bool:
    amountAllowed: uint256 = IERC20(self.erc20TokenContract).allowance(_owner, _spender)
    return _amount <= amountAllowed


@view
@internal
def _computeShares(_amount: uint256) -> uint256:
    if self.totalSharesBasisPoints == 0:
        return _amount
    return self.totalSharesBasisPoints * _amount / (self.fundsAvailable + self.fundsInvested)


@view
@internal
def _computeWithdrawableAmount(_lender: address) -> uint256:
    if self.totalSharesBasisPoints == 0:
        return 0
    return (self.fundsAvailable + self.fundsInvested) * self.funds[_lender].sharesBasisPoints / self.totalSharesBasisPoints


##### EXTERNAL METHODS - VIEW #####

@view
@external
def lendersArray() -> DynArray[address, 2**50]:
  return self.lenders


@view
@external
def computeWithdrawableAmount(_lender: address) -> uint256:
    return self._computeWithdrawableAmount(_lender)


@view
@external
def fundsInPool() -> uint256:
    return self.fundsAvailable + self.fundsInvested


@view
@external
def currentAmountDeposited(_lender: address) -> uint256:
    return self.funds[_lender].currentAmountDeposited


@view
@external
def totalAmountDeposited(_lender: address) -> uint256:
    return self.funds[_lender].totalAmountDeposited


@view
@external
def totalAmountWithdrawn(_lender: address) -> uint256:
    return self.funds[_lender].totalAmountWithdrawn


@view
@external
def sharesBasisPoints(_lender: address) -> uint256:
    return self.funds[_lender].sharesBasisPoints


@view
@external
def activeForRewards(_lender: address) -> bool:
    return self.funds[_lender].activeForRewards


##### EXTERNAL METHODS - NON-VIEW #####

@external
def __init__(_erc20TokenContract: address):
    assert _erc20TokenContract != empty(address), "The address is the zero address"
    self.owner = msg.sender
    self.erc20TokenContract = _erc20TokenContract
    self.migrationDone = False


@external
def migrateLender(
    _wallet: address,
    _currentAmountDeposited: uint256,
    _totalAmountDeposited: uint256,
    _totalAmountWithdrawn: uint256,
    _sharesBasisPoints: uint256,
    _activeForRewards: bool
):
    assert not self.migrationDone, "migration already done"
    assert msg.sender == self.owner, "msg.sender is not the owner"

    self.lenders.append(_wallet)
    self.knownLenders[_wallet] = True
    self.funds[_wallet] = InvestorFunds({
            currentAmountDeposited: _currentAmountDeposited,
            totalAmountDeposited: _totalAmountDeposited,
            totalAmountWithdrawn: _totalAmountWithdrawn,
            sharesBasisPoints: _sharesBasisPoints,
            activeForRewards: _activeForRewards
            }
    )


@external
def migrate(_from: address):
    assert not self.migrationDone, "migration already done"
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _from != empty(address), "_address is the zero address"
    assert _from.is_contract, "LPCore is not a contract"

    self.activeLenders = ILendingPoolCore(_from).activeLenders()
    self.fundsAvailable = ILendingPoolCore(_from).fundsAvailable()
    self.fundsInvested = ILendingPoolCore(_from).fundsInvested()
    self.totalFundsInvested = ILendingPoolCore(_from).totalFundsInvested()
    self.totalRewards = ILendingPoolCore(_from).totalRewards()
    self.totalSharesBasisPoints = ILendingPoolCore(_from).totalSharesBasisPoints()

    self.migrationDone = True


@external
def proposeOwner(_address: address):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _address != empty(address), "_address it the zero address"
    assert self.owner != _address, "proposed owner addr is the owner"
    assert self.proposedOwner != _address, "proposed owner addr is the same"

    self.proposedOwner = _address

    log OwnerProposed(
        self.owner,
        _address,
        self.owner,
        _address,
        self.erc20TokenContract
    )


@external
def claimOwnership():
    assert msg.sender == self.proposedOwner, "msg.sender is not the proposed"

    log OwnershipTransferred(
        self.owner,
        self.proposedOwner,
        self.owner,
        self.proposedOwner,
        self.erc20TokenContract
    )

    self.owner = self.proposedOwner
    self.proposedOwner = empty(address)


@external
def setLendingPoolPeripheralAddress(_address: address):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _address != empty(address), "address is the zero address"
    assert _address != self.lendingPoolPeripheral, "new value is the same"

    log LendingPoolPeripheralAddressSet(
        self.erc20TokenContract,
        self.lendingPoolPeripheral,
        _address,
        self.erc20TokenContract
    )

    self.lendingPoolPeripheral = _address


@external
def deposit(_lender: address, _payer: address, _amount: uint256) -> bool:
    # _amount should be passed in wei

    assert msg.sender == self.lendingPoolPeripheral, "msg.sender is not LP peripheral"
    assert _lender != empty(address), "The _lender is the zero address"
    assert _payer != empty(address), "The _payer is the zero address"
    assert self._fundsAreAllowed(_payer, self, _amount), "Not enough funds allowed"

    sharesAmount: uint256 = self._computeShares(_amount)

    if self.funds[_lender].currentAmountDeposited > 0:
        self.funds[_lender].totalAmountDeposited += _amount
        self.funds[_lender].currentAmountDeposited += _amount
        self.funds[_lender].sharesBasisPoints += sharesAmount
    elif self.funds[_lender].currentAmountDeposited == 0 and self.knownLenders[_lender]:
        self.funds[_lender].totalAmountDeposited += _amount
        self.funds[_lender].currentAmountDeposited = _amount
        self.funds[_lender].sharesBasisPoints = sharesAmount
        self.funds[_lender].activeForRewards = True

        self.activeLenders += 1
    else:
        self.funds[_lender] = InvestorFunds(
            {
                currentAmountDeposited: _amount,
                totalAmountDeposited: _amount,
                totalAmountWithdrawn: 0,
                sharesBasisPoints: sharesAmount,
                activeForRewards: True
            }
        )
        self.lenders.append(_lender)
        self.knownLenders[_lender] = True
        self.activeLenders += 1
    
    self.fundsAvailable += _amount
    self.totalSharesBasisPoints += sharesAmount

    return IERC20(self.erc20TokenContract).transferFrom(_payer, self, _amount)


@external
def withdraw(_lender: address, _wallet: address, _amount: uint256) -> bool:
    # _amount should be passed in wei

    assert msg.sender == self.lendingPoolPeripheral, "msg.sender is not LP peripheral"
    assert _lender != empty(address), "The _lender is the zero address"
    assert _wallet != empty(address), "The _wallet is the zero address"
    assert self._computeWithdrawableAmount(_lender) >= _amount, "_amount more than withdrawable"
    assert self.fundsAvailable >= _amount, "Available funds less than amount"

    newDepositAmount: uint256 = self._computeWithdrawableAmount(_lender) - _amount
    newLenderSharesAmount: uint256 = self._computeShares(newDepositAmount)
    self.totalSharesBasisPoints -= (self.funds[_lender].sharesBasisPoints - newLenderSharesAmount)

    self.funds[_lender] = InvestorFunds(
        {
            currentAmountDeposited: newDepositAmount,
            totalAmountDeposited: self.funds[_lender].totalAmountDeposited,
            totalAmountWithdrawn: self.funds[_lender].totalAmountWithdrawn + _amount,
            sharesBasisPoints: newLenderSharesAmount,
            activeForRewards: True
        }
    )

    if self.funds[_lender].currentAmountDeposited == 0:
        self.funds[_lender].activeForRewards = False
        self.activeLenders -= 1

    self.fundsAvailable -= _amount

    return IERC20(self.erc20TokenContract).transfer(_wallet, _amount)


@external
def sendFunds(_to: address, _amount: uint256) -> bool:
  # _amount should be passed in wei

    assert msg.sender == self.lendingPoolPeripheral, "msg.sender is not LP peripheral"
    assert _to != empty(address), "_to is the zero address"
    assert _amount > 0, "_amount has to be higher than 0"
    assert IERC20(self.erc20TokenContract).balanceOf(self) >= _amount, "Insufficient balance"

    self.fundsAvailable -= _amount
    self.fundsInvested += _amount
    self.totalFundsInvested += _amount

    return IERC20(self.erc20TokenContract).transfer(_to, _amount)


@external
def receiveFunds(_borrower: address, _amount: uint256, _rewardsAmount: uint256, _investedAmount: uint256) -> bool:
    # _amount,_rewardsAmount and _investedAmount should be passed in wei

    assert msg.sender == self.lendingPoolPeripheral, "msg.sender is not LP peripheral"
    assert _borrower != empty(address), "_borrower is the zero address"
    assert _amount + _rewardsAmount > 0, "Amount has to be higher than 0"
    assert IERC20(self.erc20TokenContract).allowance(_borrower, self) >= _amount, "insufficient value received"

    self.fundsAvailable += _amount + _rewardsAmount
    self.fundsInvested -= _investedAmount
    self.totalRewards += _rewardsAmount

    return IERC20(self.erc20TokenContract).transferFrom(_borrower, self, _amount + _rewardsAmount)


@external
def transferProtocolFees(_borrower: address, _protocolWallet: address, _amount: uint256) -> bool:
    # _amount should be passed in wei

    assert msg.sender == self.lendingPoolPeripheral, "msg.sender is not LP peripheral"
    assert _protocolWallet != empty(address), "_protocolWallet is the zero address"
    assert _borrower != empty(address), "_borrower is the zero address"
    assert _amount > 0, "_amount should be higher than 0"
    assert IERC20(self.erc20TokenContract).allowance(_borrower, self) >= _amount, "insufficient value received"

    return IERC20(self.erc20TokenContract).transferFrom(_borrower, _protocolWallet, _amount)