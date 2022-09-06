// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IPriceSourceAll.sol";
import "../token/MyVaultV4.sol";

contract fixedVault is ReentrancyGuard, VaultNFTv4 {
    using SafeERC20 for ERC20;

    /// @dev Constants used across the contract.
    uint256 constant TEN_THOUSAND = 10000;
    uint256 constant ONE_YEAR = 31556952;
    uint256 constant THOUSAND = 1000;

    IPriceSource public ethPriceSource;

    uint256 public _minimumCollateralPercentage;

    uint256 public vaultCount;
    
    uint256 public closingFee;
    uint256 public openingFee;

    uint256 public minDebt;
    uint256 public maxDebt;

    uint256 constant public tokenPeg = 1e8; // $1

    uint256 public iR;

    mapping(uint256 => uint256) public vaultCollateral;
    mapping(uint256 => uint256) public accumulatedVaultDebt;

    mapping(uint256 => uint256) public lastInterest;
    mapping(uint256 => uint256) public promoter;

    uint256 public adminFee; // 10% of the earned interest
    uint256 public refFee; // 90% of the earned interest

    uint256 public debtRatio;
    uint256 public gainRatio;

    ERC20 public collateral;
    ERC20 public mai;

    uint256 public decimalDifferenceRaisedToTen;

    uint256 public priceSourceDecimals;
    uint256 public totalBorrowed;

    mapping(address => uint256) public maticDebt;
    uint256 public maiDebt;

    address public stabilityPool;
    address public adm;
    address public ref;
    address public router;
    uint8 public version = 7;

    event CreateVault(uint256 vaultID, address creator);
    event DestroyVault(uint256 vaultID);
    event DepositCollateral(uint256 vaultID, uint256 amount);
    event WithdrawCollateral(uint256 vaultID, uint256 amount);
    event BorrowToken(uint256 vaultID, uint256 amount);
    event PayBackToken(uint256 vaultID, uint256 amount, uint256 closingFee);
    event LiquidateVault(
        uint256 vaultID,
        address owner,
        address buyer,
        uint256 debtRepaid,
        uint256 collateralLiquidated,
        uint256 closingFee
    );
    event BoughtRiskyDebtVault(uint256 riskyVault, uint256 newVault, address riskyVaultBuyer, uint256 amountPaidtoBuy);

    constructor(
        address ethPriceSourceAddress,
        uint256 minimumCollateralPercentage,
        string memory name,
        string memory symbol,
        address _mai,
        address _collateral,
        string memory baseURI
    ) VaultNFTv4(name, symbol, baseURI) {
        
        require(ethPriceSourceAddress != address(0));
        require(minimumCollateralPercentage != 0);

        closingFee = 50; // 0.5%
        openingFee = 0; // 0.0% 

        ethPriceSource = IPriceSource(ethPriceSourceAddress);
        stabilityPool = address(0);
        
        maxDebt = 500000 ether; //Keeping maxDebt at 500K * 10^(18)


        debtRatio = 2; // 1/2, pay back 50%
        gainRatio = 1100; // /10 so 1.1

        _minimumCollateralPercentage = minimumCollateralPercentage;

        collateral = ERC20(_collateral);
        mai = ERC20(_mai);
        priceSourceDecimals = 8;
        
        /*
            This works only for collaterals with decimals < 18
        */
        decimalDifferenceRaisedToTen =
            10**(mai.decimals() - collateral.decimals());
        
        adm = msg.sender;
        ref = msg.sender;
    }

    modifier onlyVaultOwner(uint256 vaultID) {
        require(_exists(vaultID), "Vault does not exist");
        require(ownerOf(vaultID) == msg.sender, "Vault is not owned by you");
        _;
    }

    modifier onlyRouter() {
        require(
            router == address(0) || msg.sender == router,
            "must use router"
        );
        _;
    }

    modifier vaultExists(uint256 vaultID) {
        require(_exists(vaultID), "Vault does not exist");
        _;
    }

    modifier frontExists(uint256 vaultID) {
        require(_exists(vaultID), "front end vault does not exist");
        require(promoter[vaultID] <= TEN_THOUSAND && promoter[vaultID] > 0, "Front end not added");
        _;
    }

    /// @notice Return the current debt available to borrow.
    /// @dev checks the outstanding balance of the borrowable asset within the contract.
    /// @return available balance of borrowable asset.
    function getDebtCeiling() public view returns (uint256) {
        return mai.balanceOf(address(this));
    }

    /// @param vaultID is the token id of the vault being checked.
    /// @notice Returns true if a vault exists
    /// @dev the erc721 spec allows users to burn/destroy their nft
    /// @return boolean if the vault exists
    function exists(uint256 vaultID) external view returns (bool) {
        return _exists(vaultID);
    }

    /// @notice Returns the total value locked in the vault, based on the oracle price.
    /// @return uint256 total value locked in vault
    function getTotalValueLocked() external view returns (uint256) {
        return ( getEthPriceSource() * decimalDifferenceRaisedToTen * collateral.balanceOf(address(this)) ) ; //extra 1e8, to get fraction in ui
                // 1e8 * 1eDelta 
    }

    /// @notice Return the fee charged when repaying a vault.
    /// @return uint256 is the fee charged to a vault when repaying.
    function getClosingFee() external view returns (uint256) {
        return closingFee;
    }

    /// @notice Return the peg maintained by the vault.
    /// @return uint256 is the value with 8 decimals used to calculate borrowable debt.
    function getTokenPriceSource() public view returns (uint256) {
        return tokenPeg;
    }

    /// @notice Return the collateral value
    /// @return uint256 is the value retrieved from the oracle used
    /// to calculate the available borrowable amounts.
    function getEthPriceSource() public view returns (uint256) {
        return ethPriceSource.latestAnswer();
    }

    /// @param vaultID is the token id of the vault being checked.
    /// @notice Returns the debt owned by the vault and the interest accrued over time.
    /// @return uint256 fee earned in the time between updates
    /// @return uint256 debt owed by the vault for further calculation.
    function _vaultDebtAndFee(uint256 vaultID)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 currentTime = block.timestamp;
        uint256 debt = accumulatedVaultDebt[vaultID];
        uint256 fee = 0;
        if (lastInterest[vaultID] != 0 && iR > 0) {
            uint256 timeDelta = currentTime - lastInterest[vaultID];

            uint256 feeAccrued = (((iR * debt) * timeDelta) / ONE_YEAR) / TEN_THOUSAND;
            fee = feeAccrued;
            debt = feeAccrued + debt;
        }
        return (fee, debt);
    }

    /// @param vaultID is the token id of the vault being checked.
    /// @notice Returns the debt owned by the vault without tracking the interest
    /// @return uint256 debt owed by the vault for further calculation.
    function vaultDebt(uint256 vaultID) public view returns (uint256) {
        (, uint256 debt) = _vaultDebtAndFee(vaultID);
        return debt;
    }

    /// @param vaultID is the token id of the vault being checked.
    /// @notice Adds the interest charged to the vault over the previous time called.
    /// @return uint256 latest vault debt
    function updateVaultDebt(uint256 vaultID) public returns (uint256) {
        (uint256 fee, uint256 debt) = _vaultDebtAndFee(vaultID);

        maiDebt = maiDebt + fee;

        totalBorrowed = totalBorrowed + fee;

        if(iR > 0) {
            lastInterest[vaultID] = block.timestamp;
        }

        // we can just update the current vault debt here instead
        accumulatedVaultDebt[vaultID] = debt;

        return debt;
    }

    /// @param _collateral is the amount of collateral tokens to be valued.
    /// @param _debt is the debt owed by the vault.
    /// @notice Returns collateral value and debt based on the oracle prices
    /// @return uint256 coolateral value * 100. used to calculate the CDR
    /// @return uint256 debt value. Uses token price source to derive.
    function calculateCollateralProperties(uint256 _collateral, uint256 _debt)
        private
        view
        returns (uint256, uint256)
    {
        require(getEthPriceSource() != 0);
        require(getTokenPriceSource() != 0);

        uint256 collateralValue = _collateral *
            getEthPriceSource() *
            decimalDifferenceRaisedToTen;

        require(collateralValue >= _collateral);

        uint256 debtValue = _debt * getTokenPriceSource();

        require(debtValue >= _debt);

        uint256 collateralValueTimes100 = collateralValue * 100;
        require(collateralValueTimes100 > collateralValue);

        return (collateralValueTimes100, debtValue);
    }

    
    /// @param _collateral is the amount of collateral tokens held by vault.
    /// @param debt is the debt owed by the vault.
    /// @notice Calculates if the CDR is valid before taking a further action with a user
    /// @return boolean describing if the new CDR is valid.
    function isValidCollateral(uint256 _collateral, uint256 debt)
        public
        view
        returns (bool)
    {
        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(_collateral, debt);

        uint256 collateralPercentage = collateralValueTimes100 / debtValue;
        return collateralPercentage >= _minimumCollateralPercentage;
    }

    

    /// @param fee is the amount of basis points (BP) to charge
    /// @param amount is the total value to calculate the BPs from
    /// @param promoFee is the fee charged by the front end
    /// @notice Returns fee to charge based on the collateral amount
    /// @return uint256 fee to charge the collateral.
    /// @dev fee can be called on web app to compare charges.
    function calculateFee(
        uint256 fee,
        uint256 amount,
        uint256 promoFee
    ) public view returns (uint256) {
        uint256 _fee;
        if (promoFee>0) {
            _fee = ((amount * fee * getTokenPriceSource() * promoFee) /
                (getEthPriceSource() * TEN_THOUSAND * TEN_THOUSAND));
        } else {
            _fee = (amount * fee * getTokenPriceSource()) /
                (getEthPriceSource() * TEN_THOUSAND);
        }
        return _fee / decimalDifferenceRaisedToTen;
    }

    /// @notice Creates a new ERC721 Vault NFT
    /// @return uint256 the token id of the vault created.
    function createVault() public returns (uint256) {
        uint256 id = vaultCount;
        vaultCount = vaultCount + 1;
        require(vaultCount >= id);
        _mint(msg.sender, id);
        emit CreateVault(id, msg.sender);
        return id;
    }

    /// @notice Destroys an ERC721 Vault NFT
    /// @param vaultID the vault ID to destroy
    /// @dev vault must not have any debt owed to be able to be destroyed.
    function destroyVault(uint256 vaultID)
        external
        onlyVaultOwner(vaultID)
        nonReentrant
    {
        require(vaultDebt(vaultID) == 0, "Vault has outstanding debt");

        if (vaultCollateral[vaultID] != 0) {
            // withdraw leftover collateral
            collateral.safeTransfer(ownerOf(vaultID), vaultCollateral[vaultID]);
        }

        _burn(vaultID);

        delete vaultCollateral[vaultID];
        delete accumulatedVaultDebt[vaultID];
        delete lastInterest[vaultID];
        emit DestroyVault(vaultID);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @param amount is the amount of collateral to deposit from msg.sender
    /// @notice Adds collateral to a specific vault by token id
    /// @dev Any address can deposit into a vault
    function depositCollateral(uint256 vaultID, uint256 amount)
        external
        vaultExists(vaultID)
        onlyRouter
    {
        uint256 newCollateral = vaultCollateral[vaultID] + (amount);

        require(newCollateral >= vaultCollateral[vaultID]);

        vaultCollateral[vaultID] = newCollateral;

        collateral.safeTransferFrom(msg.sender, address(this), amount);

        emit DepositCollateral(vaultID, amount);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @param amount is the amount of collateral to withdraw
    /// @notice withdraws collateral to a specific vault by token id
    /// @dev If there is debt, then it can only withdraw up to the min CDR.
    function withdrawCollateral(uint256 vaultID, uint256 amount)
        external
        onlyVaultOwner(vaultID)
        nonReentrant
    {
        require(
            vaultCollateral[vaultID] >= amount,
            "Vault does not have enough collateral"
        );

        uint256 newCollateral = vaultCollateral[vaultID] - amount;
        uint256 debt = updateVaultDebt(vaultID);

        if (debt != 0) {
            require(
                isValidCollateral(newCollateral, debt),
                "Withdrawal would put vault below minimum collateral percentage"
            );
        }

        vaultCollateral[vaultID] = newCollateral;
        collateral.safeTransfer(msg.sender, amount);

        emit WithdrawCollateral(vaultID, amount);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @param amount is the amount of borrowable asset to borrow
    /// @notice borrows asset based on the collateral held and the price of the collateral.
    /// @dev Borrowing is limited by the CDR of the vault
    /// If there's opening fee, it will be charged here.
    function borrowToken(
        uint256 vaultID,
        uint256 amount,
        uint256 _front
    ) external 
    frontExists(_front) 
    onlyVaultOwner(vaultID) 
    nonReentrant
    {

        require(amount > 0, "Must borrow non-zero amount");
        require(
            amount <= getDebtCeiling(),
            "borrowToken: Cannot mint over available supply."
        );

        uint256 newDebt = updateVaultDebt(vaultID) + amount;

        require(newDebt<=maxDebt, "borrowToken: max loan cap reached.");

        require(newDebt > vaultDebt(vaultID));


        require(
            isValidCollateral(vaultCollateral[vaultID], newDebt),
            "Borrow would put vault below minimum collateral percentage"
        );

        require(
            ((vaultDebt(vaultID)) + amount) >= minDebt,
            "Vault debt can't be under minDebt"
        );

        accumulatedVaultDebt[vaultID] = newDebt;

        uint256 _openingFee = calculateFee(openingFee, newDebt, promoter[_front]);

        vaultCollateral[vaultID] = vaultCollateral[vaultID] - (_openingFee);
        vaultCollateral[_front] = vaultCollateral[_front] + (_openingFee);
        
        // mai
        mai.safeTransfer(msg.sender, amount);
        totalBorrowed = totalBorrowed + (amount);

        emit BorrowToken(vaultID, amount);
    }

    function paybackTokenAll(
        uint256 vaultID,
        uint256 deadline,
        uint256 _front
    ) external frontExists(_front) vaultExists(vaultID) onlyRouter {
        require(
            deadline >= block.timestamp,
            "paybackTokenAll: deadline expired."
        );

        uint256 _amount = updateVaultDebt(vaultID);
        payBackToken(vaultID, _amount, _front);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @param amount is the amount of borrowable asset to repay
    /// @param _front is the front end that will get the opening
    /// @notice payback asset to close loan.
    /// @dev If there is debt, then it can only withdraw up to the min CDR.
    function payBackToken(
        uint256 vaultID,
        uint256 amount,
        uint256 _front
    ) public frontExists(_front) vaultExists(vaultID) onlyRouter {
        require(mai.balanceOf(msg.sender) >= amount, "Token balance too low");

        uint256 vaultDebtNow = updateVaultDebt(vaultID);

        require(
            vaultDebtNow >= amount,
            "Vault debt less than amount to pay back"
        );

        require(
            ((vaultDebtNow) - amount) >= minDebt || amount == (vaultDebtNow),
            "Vault debt can't be under minDebt"
        );

        uint256 _closingFee = calculateFee(
            closingFee,
            amount,
            promoter[_front]
        );

        accumulatedVaultDebt[vaultID] = vaultDebtNow - amount;

        vaultCollateral[vaultID] = vaultCollateral[vaultID] - _closingFee;
        vaultCollateral[_front] = vaultCollateral[_front] + _closingFee;

        totalBorrowed = totalBorrowed - amount;

        //mai
        mai.safeTransferFrom(msg.sender, address(this), amount);
        
        emit PayBackToken(vaultID, amount, _closingFee);
    }

    /// @notice withdraws liquidator earnings.
    /// @dev reverts if there's no collateral to withdraw.
    function getPaid() external nonReentrant {
        require(maticDebt[msg.sender] != 0, "Don't have anything for you.");
        uint256 amount = maticDebt[msg.sender];
        maticDebt[msg.sender] = 0;
        collateral.safeTransfer(msg.sender, amount);
    }

    /// @param pay is address of the person to getPaid
    /// @notice withdraws liquidator earnings.
    /// @dev reverts if there's no collateral to withdraw.
    function getPaid(address pay) external nonReentrant {
        require(maticDebt[pay] != 0, "Don't have anything for you.");
        uint256 amount = maticDebt[pay];
        maticDebt[pay] = 0;
        collateral.safeTransfer(pay, amount);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates cost to liquidate a vault
    /// @dev Can be used to calculate balance required to liquidate a vault. 
    function checkCost(uint256 vaultID) public view returns (uint256) {
        uint256 vaultDebtNow = vaultDebt(vaultID);

        if (
            vaultCollateral[vaultID] == 0 ||
            vaultDebtNow == 0 ||
            !checkLiquidation(vaultID)
        ) {
            return 0;
        }

        (,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        if (debtValue == 0) {
            return 0;
        }

        debtValue = debtValue / (10**priceSourceDecimals);

        uint256 halfDebt = debtValue / debtRatio; //debtRatio (2)

        if (halfDebt <= minDebt) {
            halfDebt = debtValue;
        }

        return (halfDebt);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates collateral to extract when liquidating a vault
    /// @dev Can be used to calculate earnings from liquidating a vault. 
    function checkExtract(uint256 vaultID) public view returns (uint256) {
        if (vaultCollateral[vaultID] == 0 || !checkLiquidation(vaultID)) {
            return 0;
        }
        uint256 vaultDebtNow = vaultDebt(vaultID);

        (, uint256 debtValue) = calculateCollateralProperties(
            vaultCollateral[vaultID],
            vaultDebtNow
        );

        uint256 halfDebt = debtValue / debtRatio; //debtRatio (2)

        if (halfDebt == 0) {
            return 0;
        }
        if ((halfDebt) / (10**priceSourceDecimals) <= minDebt) {
            // full liquidation if under the min debt.
            return (debtValue * ( gainRatio)) / (THOUSAND) / (getEthPriceSource()) / decimalDifferenceRaisedToTen;
        } else {
            return (halfDebt * (gainRatio)) / THOUSAND / (getEthPriceSource()) / decimalDifferenceRaisedToTen;
        }
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates the collateral percentage of a vault.
    function checkCollateralPercentage(uint256 vaultID)
        public
        view
        vaultExists(vaultID)
        returns (uint256)
    {
        uint256 vaultDebtNow = vaultDebt(vaultID);

        if (vaultCollateral[vaultID] == 0 || vaultDebtNow == 0) {
            return 0;
        }
        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        return collateralValueTimes100 / (debtValue);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates if a vault is liquidatable.
    /// @return bool if vault is liquidatable or not.
    function checkLiquidation(uint256 vaultID)
        public
        view
        vaultExists(vaultID)
        returns (bool)
    {
        uint256 vaultDebtNow = vaultDebt(vaultID);

        if (vaultCollateral[vaultID] == 0 || vaultDebtNow == 0) {
            return false;
        }

        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        uint256 collateralPercentage = collateralValueTimes100 / (debtValue);
        if (collateralPercentage < _minimumCollateralPercentage) {
            return true;
        } else {
            return false;
        }
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates if a vault is risky and can be bought.
    /// @return bool if vault is risky or not.
    function checkRiskyVault(uint256 vaultID) public view vaultExists(vaultID) returns (bool) {

        uint256 vaultDebtNow = vaultDebt(vaultID);

        if (vaultCollateral[vaultID] == 0 || vaultDebtNow == 0) {
            return false;
        }

        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        uint256 collateralPercentage = collateralValueTimes100 / (debtValue);

        if ((collateralPercentage*10) <= gainRatio) {
            return true;
        } else {
            return false;
        }
    }


    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Pays back the part of the debt owed by the vault and removes a 
    /// comparable amount of collateral plus bonus
    /// @dev if vault CDR is under the bonus ratio,
    /// then it will only be able to be bought through buy risky.
    /// Amount to pay back is based on debtRatio variable.
    function liquidateVault(uint256 vaultID, uint256 _front)
        external
        frontExists(_front)
        vaultExists(vaultID)
    {
        require(
            stabilityPool == address(0) || msg.sender == stabilityPool,
            "liquidation is disabled for public"
        );

        uint256 vaultDebtNow = updateVaultDebt(vaultID);
        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );
        require(vaultDebtNow != 0, "Vault debt is 0");

        uint256 collateralPercentage = collateralValueTimes100 / (debtValue);

        require(
            collateralPercentage < _minimumCollateralPercentage,
            "Vault is not below minimum collateral percentage"
        );

        require(collateralPercentage * 10 > gainRatio , "Vault is not above gain ratio");

        debtValue = debtValue / (10**priceSourceDecimals);

        uint256 halfDebt = debtValue / (debtRatio); //debtRatio (2)

        if (halfDebt <= minDebt) {
            halfDebt = debtValue;
        }

        require(
            mai.balanceOf(msg.sender) >= halfDebt,
            "Token balance too low to pay off outstanding debt"
        );

        totalBorrowed = totalBorrowed - (halfDebt);

        uint256 maticExtract = checkExtract(vaultID);

        accumulatedVaultDebt[vaultID] = vaultDebtNow - (halfDebt); // we paid back half of its debt.

        uint256 _closingFee = calculateFee(closingFee, halfDebt, promoter[_front]);
        vaultCollateral[vaultID] = vaultCollateral[vaultID] - (_closingFee);
        vaultCollateral[_front] = vaultCollateral[_front] + (_closingFee);

        
        // deduct the amount from the vault's collateral
        vaultCollateral[vaultID] = vaultCollateral[vaultID] - (maticExtract);

        // let liquidator take the collateral
        maticDebt[msg.sender] = maticDebt[msg.sender] + (maticExtract);

        //mai
        mai.safeTransferFrom(msg.sender, address(this), halfDebt);

        emit LiquidateVault(
            vaultID,
            ownerOf(vaultID),
            msg.sender,
            halfDebt,
            maticExtract,
            _closingFee
        );
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Pays back the debt owed to bring it back to min CDR. 
    /// And transfers ownership of it to the liquidator with a new vault
    /// @return uint256 new vault created with the debt and collateral.
    /// @dev this function can only be called if vault CDR is under the bonus ratio.
    /// address who calls it will now own the debt and the collateral.
    function buyRiskDebtVault(uint256 vaultID) external vaultExists(vaultID) returns(uint256) {
        require(
            stabilityPool == address(0) || msg.sender == stabilityPool,
            "buy risky is disabled for public"
        );        uint256 vaultDebtNow = updateVaultDebt(vaultID);

        require(vaultDebtNow != 0, "Vault debt is 0");

        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        uint256 collateralPercentage = collateralValueTimes100 / (debtValue);
        require(
            (collateralPercentage*10) <= gainRatio,
            "Vault is not below risky collateral percentage" 
        );

        uint256 maiDebtTobePaid = (debtValue / (10**priceSourceDecimals)) - 
                                    (collateralValueTimes100 / 
                                    ( _minimumCollateralPercentage * (10**priceSourceDecimals)));

        //have enough MAI to bring vault to X CDR (presumably min)
        require(mai.balanceOf(msg.sender) >= maiDebtTobePaid, "Not enough mai to buy the risky vault");
        //mai
        mai.safeTransferFrom(msg.sender, address(this), maiDebtTobePaid);
        totalBorrowed = totalBorrowed - (maiDebtTobePaid);
        // newVault for msg.sender
        uint256 newVault = createVault();
        // updating vault collateral and debt details for the transfer of risky vault
        vaultCollateral[newVault] = vaultCollateral[vaultID];
        accumulatedVaultDebt[newVault] = vaultDebtNow - maiDebtTobePaid;
        lastInterest[newVault] = block.timestamp;
        // resetting the vaultID vault info
        delete vaultCollateral[vaultID];
        delete accumulatedVaultDebt[vaultID];
        // lastInterest of vaultID would be block.timestamp, not reseting its timestamp
        emit BoughtRiskyDebtVault(vaultID, newVault, msg.sender, maiDebtTobePaid);
        return newVault;

    }
}