// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./fixedVault.sol";

/// @title Fixed Interest Vault
/// @notice Single collateral lending manager with fixed rate interest.
contract stableQiVault is fixedVault, Ownable {

    /// @dev Used to restrain the fee. Can only be up to 5% of the amount.
    uint256 constant FEE_MAX = 500;
    
    string private oracleType;
    
    constructor(
        address ethPriceSourceAddress,
        uint256 minimumCollateralPercentage,
        string memory name,
        string memory symbol,
        address _mai,
        address _collateral,
        string memory baseURI
    )
        fixedVault(
            ethPriceSourceAddress,
            minimumCollateralPercentage,
            name,
            symbol,
            _mai,
            _collateral,
            baseURI
        )
    {
        createVault();
        addFrontEnd(0);
    }

    event UpdatedClosingFee(uint256 newFee);
    event UpdatedOpeningFee(uint256 newFee);
    event WithdrawInterest(uint256 earned);
    event UpdatedMinDebt(uint256 newMinDebt);
    event UpdatedMaxDebt(uint256 newMaxDebt);
    event UpdatedDebtRatio(uint256 _debtRatio);
    event UpdatedGainRatio(uint256 _gainRatio);
    event UpdatedEthPriceSource(address _ethPriceSourceAddress);
    
    event AddedFrontEnd(uint256 promoter);
    event RemovedFrontEnd(uint256 promoter);
    event UpdatedFrontEnd(uint256 promoter, uint256 newFee);

    event UpdatedFees(uint256 _adminFee, uint256 _refFee);

    event UpdatedMinCollateralRatio(uint256 newMinCollateralRatio);
    event UpdatedStabilityPool(address pool);
    event UpdatedInterestRate(uint256 interestRate);
    event BurnedToken(uint256 amount);
    event UpdatedTokenURI(string uri);

    event UpdatedAdmin(address newAdmin);
    event UpdatedRef(address newRef);
    event UpdatedOracleName(string oracle);

    modifier onlyOperators() {
        require(ref == msg.sender || adm == msg.sender || owner() == msg.sender, "Needs to be called by operators");
        _;
    }

    modifier onlyAdmin() {
        require(adm == msg.sender, "Needs to be called by admin");
        _;
    }

    /// @param _oracle name of the oracle used by the contract
    /// @notice sets the oracle name used by the contract. for visual purposes.
    function updateOracleName(string memory _oracle) external onlyOwner {
        oracleType = _oracle;
        emit UpdatedOracleName(_oracle);
    }

    /// @param _gainRatio sets the bonus earned from a liquidator
    /// @notice implements a setter for the bonus earned by a liquidator
    /// @dev fails if the bonus is less than 1
    function setGainRatio(uint256 _gainRatio) external onlyOwner {
        require(_gainRatio >= 1000, "gainRatio cannot be less than or equal to 1000");
        gainRatio = _gainRatio;
        emit UpdatedGainRatio(gainRatio);
    }

    /// @param _debtRatio sets the ratio of debt paid back by a liquidator
    /// @notice sets the ratio of the debt to be paid back
    /// @dev it divides the debt. 1/debtRatio.
    function setDebtRatio(uint256 _debtRatio) external onlyOwner {
        require(debtRatio != 0, "Debt Ratio cannot be 0");
        debtRatio = _debtRatio;
        emit UpdatedDebtRatio(debtRatio);
    }

        /// @param ethPriceSourceAddress is the address that provides the price of the collateral
    /// @notice sets the address used as oracle
    /// @dev Oracle price feed is used in here. Interface's available in the at /interfaces/IPriceSourceAll.sol
    function changeEthPriceSource(address ethPriceSourceAddress)
        external
        onlyOwner
    {
        require(ethPriceSourceAddress != address(0), "Ethpricesource cannot be zero address" );
        ethPriceSource = IPriceSource(ethPriceSourceAddress);
        emit UpdatedEthPriceSource(ethPriceSourceAddress);
    }

    /// @param _pool is the address that can execute liquidations
    /// @notice sets the address used as stability pool for liquidations
    /// @dev if not set to address(0) then _pool is the only address able to liquidate
    function setStabilityPool(address _pool) external onlyOwner {
        require(_pool != address(0), "StabilityPool cannot be zero address" );
        stabilityPool = _pool;
        emit UpdatedStabilityPool(stabilityPool);
    }

    /// @param _admin is the ratio earned by the address that maintains the market
    /// @param _ref is the ratio earned by the address that provides the borrowable asset
    /// @notice sets the interest rate split between the admin and ref
    /// @dev if not set to address(0) then _pool is the only address able to liquidate
    function setFees(uint256 _admin, uint256 _ref) external onlyOwner {
        require((_admin+_ref)==TEN_THOUSAND, "setFees: must equal 10000.");
        adminFee=_admin;
        refFee=_ref;
        emit UpdatedFees(adminFee, refFee);
    }

    /// @param minimumCollateralPercentage is the CDR that limits the amount borrowed
    /// @notice sets the CDR
    /// @dev only callable by owner of the contract
    function setMinCollateralRatio(uint256 minimumCollateralPercentage)
        external
        onlyOwner
    {
        _minimumCollateralPercentage = minimumCollateralPercentage;
        emit UpdatedMinCollateralRatio(_minimumCollateralPercentage);
    }

    /// @param _minDebt is minimum debt able to be borrowed by a vault.
    /// @notice sets the minimum debt.
    /// @dev dust protection
    function setMinDebt(uint256 _minDebt)
        external
        onlyOwner
    {
        require(_minDebt >=0, "setMinDebt: must be over 0.");
        minDebt = _minDebt;
        emit UpdatedMinDebt(minDebt);
    }

    /// @param _maxDebt is maximum debt able to be borrowed by a vault.
    /// @notice sets the maximum debt.
    /// @dev whale and liquidity protection.
    function setMaxDebt(uint256 _maxDebt)
        external
        onlyOwner
    {
        require(_maxDebt >=0, "setMaxDebt: must be over 0.");
        maxDebt = _maxDebt;
        emit UpdatedMaxDebt(maxDebt);
    }

    /// @param _ref is the address that provides the borrowable asset
    /// @notice sets the address that earns interest for providing a borrowable asset
    /// @dev cannot be address(0)
    function setRef(address _ref) external onlyOwner {
        require(_ref != address(0), "Reference Address cannot be zero");
        ref = _ref;
        emit UpdatedRef(ref);
    }

    /// @param _adm is the ratio earned by the address that maintains the market
    /// @notice sets the address that earns interest for maintaining the market
    /// @dev cannot be address(0)
    function setAdmin(address _adm) external onlyOwner {
        require(_adm != address(0), "Admin Address cannot be zero");
        adm = _adm;
        emit UpdatedAdmin(adm);
    }

    /// @param _openingFee is the fee charged to a vault when borrowing.
    /// @notice sets opening fee.
    /// @dev can only be up to 5% (FEE_MAX) of the amount.
    function setOpeningFee(uint256 _openingFee) external onlyOwner {
        require(_openingFee >= 0 && _openingFee <= FEE_MAX, "setOpeningFee: cannot be more than 5%");
        openingFee = _openingFee;
        // emit event
        emit UpdatedOpeningFee(openingFee);
    }

    /// @param _closingFee is the fee charged to a vault when repaying.
    /// @notice sets closing fee.
    /// @dev can only be up to 5% (FEE_MAX) of the amount.
    function setClosingFee(uint256 _closingFee) external onlyOwner {
        require(_closingFee >= 0 && _closingFee <= FEE_MAX, "setClosingFee: cannot be more than 5%");
        closingFee = _closingFee;
        // emit event
        emit UpdatedClosingFee(closingFee);
    }

    /// @param _promoter is a front end for the contract
    /// @notice adds a front end to earn opening/closing fees from borrowing/repaying.
    /// @dev can only be up to 5% (FEE_MAX) of the amount.
    function addFrontEnd(uint256 _promoter) public onlyOwner {
        require(_exists(_promoter), "addFrontEnd: Vault does not exist");    
        require(promoter[_promoter] == 0, "addFrontEnd: already added");
        promoter[_promoter] = TEN_THOUSAND;
        emit AddedFrontEnd(_promoter);
    }

    /// @param _promoter is a front end for the contract
    /// @param cashback is the amount of fee not taken from a user.
    /// @notice updates the cashback variable for a given front end
    /// @dev can only be updated by the front end vault's owner
    function updateFrontEnd(uint256 _promoter, uint256 cashback) external frontExists(_promoter) onlyVaultOwner(_promoter) {
        require(cashback > 0 && cashback <= TEN_THOUSAND, "updateFrontEnd: cannot be 0");
        promoter[_promoter] = cashback;
        emit UpdatedFrontEnd(_promoter, cashback);
    }

    /// @param _promoter is a front end for the contract
    /// @notice removes the ability for a front end to earn fees
    function removeFrontEnd(uint256 _promoter) external frontExists(_promoter) onlyOwner {
        require(_exists(_promoter), "removeFrontEnd: Vault does not exist");
        require(promoter[_promoter] > 0, "removeFrontEnd: not a front end");
        promoter[_promoter] = 0;
        emit RemovedFrontEnd(_promoter);
    }

    /// @notice withdraws earned interest by vault.
    function withdrawInterest() external onlyOperators nonReentrant {

        uint256 adm_fee = maiDebt*adminFee / TEN_THOUSAND;

        // Transfer
        mai.transfer(ref, (maiDebt-adm_fee) ); // cheaper and equivalent.
        mai.transfer(adm, adm_fee);
        emit WithdrawInterest(maiDebt);
        maiDebt = 0;
    }

    /// @param _iR is the fixed interest charged by a vault
    /// @notice sets the interest charged by a vault.
    function setInterestRate(uint256 _iR) external onlyOwner {
        iR = _iR;
        emit UpdatedInterestRate(iR);
    }

    /// @param amountToken is the amount of borrowable asset that is removed from the debt ceiling.
    /// @notice removes debt ceiling from the vault.
    /// @dev returns the asset to the owner so it can be redeployed at a later time.
    function burn(uint256 amountToken) external onlyAdmin {
        // Burn
        require(amountToken < mai.balanceOf(address(this)), "burn: Balance not enough");
        mai.transfer(ref, amountToken);
        emit BurnedToken(amountToken);
    }

    /// @param _uri is the url for the nft metadata
    /// @notice updates the metadata
    /// @dev it currently uses an ipfs json
    function setTokenURI(string calldata _uri) external onlyOwner {
        uri = _uri;
        emit UpdatedTokenURI(uri);
    }

    function setRouter(address _router) external onlyOwner {
        router=_router;
    }
}