// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/interfaces/IChainlink.sol";
import "contracts/Stage2/StandardTokenGateway.sol";
import "contracts/Rates.sol";

contract BondStorage is AccessControl {
    bytes32 public constant WHITELIST_BOND_STORAGE = keccak256("WHITELIST_BOND_STORAGE");

    // Standard Token data feed
    StandardTokenGateway public tokenGateway;

    // used to convert other token to seuro value (before converting to TST)
    // dec should be default chainlink 8 for default 18 dec tokens (to match sEURO)
    // dec should be 20 when other asset is a 6 dec token
    address public chainlinkEurOther;
    uint8 public eurOtherDec;
    address public seuro;
    address public other;
    bool public isCatastrophe;
    mapping(address => BondRecord) issuedBonds;
    address[] public users;

    event NewBond(address indexed user, uint256 principalSeuro, uint256 principalOther, uint256 rate, uint256 maturityDate, uint256 reward, uint256 profit);

    constructor(address _gatewayAddress, address _chainlinkEurOther, address _seuro, address _other) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WHITELIST_BOND_STORAGE, msg.sender);
        tokenGateway = StandardTokenGateway(_gatewayAddress);
        chainlinkEurOther = _chainlinkEurOther;
        eurOtherDec = IChainlink(_chainlinkEurOther).decimals();
        seuro = _seuro;
        other = _other;
    }

    modifier onlyWhitelisted() { require(hasRole(WHITELIST_BOND_STORAGE, msg.sender), "invalid-storage-operator"); _; }

    modifier notInCatastrophe() { require(!isCatastrophe, "err-catastrophe"); _; }

    modifier inCatastrophe() { require(isCatastrophe, "err-not-catastrophe"); _; }

    modifier sufficientCatastropheBalance() {
        (uint256 seuroRequired, uint256 otherRequired) = catastropheFundsRequired();
        uint256 seuroBalance = ERC20(seuro).balanceOf(address(this));
        uint256 otherBalance = ERC20(other).balanceOf(address(this));
        require(seuroBalance >= seuroRequired && otherBalance >= otherRequired, "err-insuff-bal"); _;
    }

    // PositionMetaData holds meta data received from Uniswap when adding a liquidity position
    // tokenId = NFT handle
    // liquidity = New liquidity (geometric average) at moment of transaction
    struct PositionMetaData { uint256 tokenId; uint128 liquidity; }

    // Bond is a traditional bond: exchanged for a principal with a fixed rate and maturity
    // principalSeuro = amount bonding in sEURO
    // principalOther = amount bonding in other asset
    // rate = interest rate for bond - example: 500 is 0.5 pc per annum (= 0.005)
    // maturity = length of bond in seconds
    // reward = payout in TST at maturity of bond
    // profit = TST profit based on the bond's interest rate
    // tapped = if profit has been squeezed from bond
    // PositionMetaData = liquidity position data
    struct Bond { uint256 principalSeuro; uint256 principalOther; uint256 rate; uint256 maturity; uint256 reward; uint256 profit; bool tapped; PositionMetaData data; }

    // BondRecord holds the main data
    // isInitialised = if the user has bonded before
    // amountBondsActive = amount of bonds in play
    // bonds = all the bonds in play
    struct BondRecord { bool isInitialised; uint256 amountBondsActive; Bond[] bonds; }

    function setBondingEvent(address _address) external onlyWhitelisted { grantRole(WHITELIST_BOND_STORAGE, _address); }

    function setTokenGateway(address _newAddress) external onlyWhitelisted {
        require(_newAddress != address(0), "invalid-gateway-address");
        tokenGateway = StandardTokenGateway(_newAddress);
    }

    function setInitialised(address _user) private { issuedBonds[_user].isInitialised = true; }

    function addBond(address _user, uint256 _principalSeuro, uint256 _principalOther, uint256 _rate, uint256 _maturityDate, uint256 _reward, uint256 _profit, PositionMetaData memory _data) private {
        issuedBonds[_user].bonds.push(Bond(_principalSeuro, _principalOther, _rate, _maturityDate, _reward, _profit, false, _data));

        emit NewBond(_user, _principalSeuro, _principalOther, _rate, _maturityDate, _reward, _profit);
    }

    function tapBond(address _user, uint256 _index) private { issuedBonds[_user].bonds[_index].tapped = true; }

    function claimable(Bond memory _bond) private view returns (bool) {
        return hasExpired(_bond) && !_bond.tapped;
    }

    function tapUntappedBonds(address _user) private {
        Bond[] memory bonds = getUserBonds(_user);
        for (uint256 i = 0; i < bonds.length; i++) {
            if (claimable(bonds[i])) { tapBond(_user, i); decrementActiveBonds(_user); }
        }
    }

    function tapAllBonds(address _user) private {
        Bond[] memory bonds = getUserBonds(_user);
        for (uint256 i = 0; i < bonds.length; i++) {
            if (!bonds[i].tapped) { tapBond(_user, i); decrementActiveBonds(_user); }
        }
    }

    // Returns the total payout and the accrued interest ("profit") component separately.
    // Both the payout and the profit is in sEURO.
    function calculateBondYield(uint256 _principalSeuro, uint256 _principalOther, uint256 _rate) public view returns (uint256 payout, uint256 profit) {
        // rates are stored as 5 dec in operator
        uint256 seuroProfit = Rates.convertDefault(_principalSeuro, _rate, 5);
        uint256 seuroPayout = _principalSeuro + seuroProfit;
        uint256 otherProfit = Rates.convertDefault(_principalOther, _rate, 5);
        uint256 otherPayout = _principalOther + otherProfit;
        payout = seuroToStandardToken(seuroPayout) + otherTokenToStandardToken(otherPayout);
        profit = seuroToStandardToken(seuroProfit) + otherTokenToStandardToken(otherProfit);
    }

    function incrementActiveBonds(address _user) private { issuedBonds[_user].amountBondsActive++ ; }

    function decrementActiveBonds(address _user) private { issuedBonds[_user].amountBondsActive-- ; }

    function hasExpired(Bond memory bond) private view returns (bool) { return block.timestamp >= bond.maturity; }

    function maturityDate(uint256 _maturity) private view returns (uint256) { return block.timestamp + _maturity; }

    function otherTokenToStandardToken(uint256 _amount) private view returns (uint256) {
        (, int256 eurOtherRate, , , ) = IChainlink(chainlinkEurOther).latestRoundData();
        uint8 tokenDiffScale = 18 - ERC20(other).decimals();
        uint256 eur = Rates.convertInverse(_amount, uint256(eurOtherRate), eurOtherDec + tokenDiffScale);
        return seuroToStandardToken(eur);
    }

    function seuroToStandardToken(uint256 _amount) private view returns (uint256) { return Rates.convertInverse(_amount, tokenGateway.priceTstEur(), tokenGateway.priceDec()); }

    function potentialReward(uint256 _principalSeuro, uint256 _principalOther, uint256 _rate) private view returns (uint256 tokenPayout, uint256 tokenProfit) {
        (tokenPayout, tokenProfit) = calculateBondYield(_principalSeuro, _principalOther, _rate);
        // if we are able to payout this bond in TST
        require(tokenPayout < tokenGateway.bondRewardPoolSupply() == true, "err-insuff-tst-supply");
    }

    /// ================ BondStorage public APIs ==============

    function startBond(address _user, uint256 _principalSeuro, uint256 _principalOther, uint256 _rate, uint256 _maturity, uint256 _tokenId, uint128 _liquidity) external onlyWhitelisted notInCatastrophe {
        // reduce the amount of available bonding reward TSTs
        (uint256 reward, uint256 profit) = potentialReward(_principalSeuro, _principalOther, _rate);
        tokenGateway.decreaseRewardSupply(reward);

        if (!issuedBonds[_user].isInitialised) {
            setInitialised(_user);
            users.push(_user);
        }

        // finalise record of bond
        addBond(_user, _principalSeuro, _principalOther, _rate, maturityDate(_maturity), reward, profit, PositionMetaData(_tokenId, _liquidity));
        incrementActiveBonds(_user);
    }

    function getActiveBonds(address _user) external view returns (uint256) { return issuedBonds[_user].amountBondsActive; }

    function getUserBonds(address _user) public view virtual returns (Bond[] memory) { return issuedBonds[_user].bonds; }

    function getBondAt(address _user, uint256 index) external view virtual returns (Bond memory) { return getUserBonds(_user)[index]; }

    function getProfit(address _user) external view virtual returns (uint256 profitAmount) { 
        Bond[] memory bonds = getUserBonds(_user);
        for (uint256 i = 0; i < bonds.length; i++) if (claimable(bonds[i])) profitAmount += bonds[i].profit;
    }

    function getClaimAmount(address _user) public view virtual returns (uint256 claimAmount) {
        Bond[] memory bonds = getUserBonds(_user);
        for (uint256 i = 0; i < bonds.length; i++) if (claimable(bonds[i])) claimAmount += bonds[i].reward;
    }

    // Claims the payout in TST tokens by sending it to the user's wallet and resetting the claim to zero.
    function claimReward(address _user) external notInCatastrophe {
        uint256 reward = getClaimAmount(_user);
        require(reward > 0, "err-no-reward");
        tapUntappedBonds(_user);
        tokenGateway.transferReward(_user, reward);
    }

    //  =============== CATASTROPHE ===============

    function getActiveUserPrincipals(address _user) private view returns (uint256 seuroActive, uint256 otherActive) {
        Bond[] memory bonds = getUserBonds(_user);
        for (uint256 i = 0; i < bonds.length; i++) {
            Bond memory bond = bonds[i];
            if (!bond.tapped) { seuroActive += bond.principalSeuro; otherActive += bond.principalOther; }
        }
    }

    function catastropheFundsRequired() public view returns (uint256 seuroRequired, uint256 otherRequired) {
        for (uint256 i = 0; i < users.length; i++) {
            (uint256 seuroActive, uint256 otherActive) = getActiveUserPrincipals(users[i]);
            seuroRequired += seuroActive; otherRequired += otherActive;
        }
    }

    function enableCatastropheMode() external onlyWhitelisted notInCatastrophe sufficientCatastropheBalance { isCatastrophe = true; }

    function disableCatastropheMode() external onlyWhitelisted inCatastrophe { isCatastrophe = false; }

    function catastropheWithdraw() external inCatastrophe {
        (uint256 seuroActive, uint256 otherActive) = getActiveUserPrincipals(msg.sender);
        tapAllBonds(msg.sender);
        if (seuroActive > 0) ERC20(seuro).transfer(msg.sender, seuroActive);
        if (otherActive > 0) ERC20(other).transfer(msg.sender, otherActive);
    }
}