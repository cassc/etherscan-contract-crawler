/*
 SPDX-License-Identifier: MIT
*/
pragma solidity 0.8.17;

import "./Helper.sol";

/// @title The contract for invested to TopCorn Protocol.
contract LayerFacet is Helper {
    event SyncDefi(uint256 reserve);
    event Invest(address indexed account, uint256 getLP, uint256 mintDLP, uint256 investBNB);
    event ConvertCornToLP(uint256 amountCorn, uint256 amountLP);
    event ApproveWithdraw(uint32[] crates, uint256 getLP, uint256 getWBNB);
    event Withdraw(uint32[] crates, uint256[] amounts, uint32 arrivalSeason);
    event ClaimCorn(uint32[] crates, uint256[] amounts, uint32 arrivalSeason);
    event SellCorn(uint32[] crates, uint256 getCorn, uint256 getWBNB);
    event ClaimBNB(uint256 getWBNB);
    event Update(uint256 getCORN);

    /// @notice Invest BNB in the Topcorn Protocol.
    /// @param slippage 0.00-100.00 percent (0-10000)
    /// @param countTokens [BNB, CORN]
    /// @return getLP Amount of invested tokens LP.
    /// @return mintDLP Amount of minted tokens DLP.
    function invest(uint32 slippage, uint256[] memory countTokens) external payable nonReentrant returns (uint256 getLP, uint256 mintDLP) {
        LibDiamond.enforceIsContractOwner(); // Only the owner
        uint256 checkCorn = calcSlippage(slippage, countTokens[1]); // calculation amounts for slippage
        uint256 checkBNB = calcSlippage(slippage, (msg.value - countTokens[0])); // calculation amounts for slippage
        getLP = countLP();
        ITopcornProtocol(s.c.topcornProtocol).addAndDepositLP{value: msg.value}(0, countTokens[1], 0, ITopcornProtocol.AddLiquidity(countTokens[1], checkCorn, checkBNB)); // call TopCorn Protocol (add liquidity)
        getLP = countLP() - getLP; // Total invested of tokens LP
        mintDLP = calcDLP(getLP, IDLP(s.c.dlp).totalSupply(), s.reserveLP); // calc amount DLP for mint
        dlp().mint(msg.sender, mintDLP);
        s.reserveLP = s.reserveLP + getLP; // update reserves
        (, uint256 investBNB) = DLPtoBNB(mintDLP);
        emit Invest(msg.sender, getLP, mintDLP, investBNB);
        emit SyncDefi(s.reserveLP);
    }

    /// @notice Holding tokens LP in the TopCorn Protocol.
    /// @param liquidity Amount tokens DLP for burning.
    /// @param crates Seasons for holding tokens LP.
    /// @param amounts Amount tokens LP for holding.
    function withdraw(
        uint256 liquidity,
        uint32[] calldata crates,
        uint256[] calldata amounts
    ) external nonReentrant returns (uint256 removeLP) {
        LibDiamond.enforceIsContractOwner(); // Only the owner
        (removeLP) = checkLiq(liquidity, amounts); // calc amount DLP for burn
        dlp().burnFrom(msg.sender, liquidity);
        s.reserveLP = s.reserveLP - removeLP; // update reserves
        ITopcornProtocol(s.c.topcornProtocol).withdrawLP(crates, amounts); // call TopCorn Protocol (withdraw LP)
        uint32 arrivalSeason = ITopcornProtocol(s.c.topcornProtocol).season() + ITopcornProtocol(s.c.topcornProtocol).withdrawSeasons();
        emit SyncDefi(s.reserveLP);
        emit Withdraw(crates, amounts, arrivalSeason);
    }

    /// @notice Remove tokens LP from the TopCotn Protocol.
    /// @param crates Seasons for removing tokens LP.
    /// @return getLP The amount of removed tokens LP.
    function approveWithdraw(uint32[] calldata crates) external nonReentrant returns (uint256 getLP) {
        LibDiamond.enforceIsContractOwner(); // Only the owner
        getLP = IERC20(s.c.pair).balanceOf(address(this));
        ITopcornProtocol(s.c.topcornProtocol).claimLP(crates); // // call TopCorn Protocol (claim LP)
        getLP = IERC20(s.c.pair).balanceOf(address(this)) - getLP; // Total removed of tokens LP
        (uint256 topcornAmount, uint256 bnbAmount) = IPancakeRouter02(s.c.router).removeLiquidity(s.c.topcorn, s.c.wbnb, getLP, 1, 1, address(this), block.timestamp);
        (uint256[] memory countTokens, address[] memory path) = getAmounts(s.c.topcorn, s.c.wbnb, topcornAmount); // calculate the amount of sale of tokens CORN
        uint256[] memory amounts = IPancakeRouter02(s.c.router).swapExactTokensForTokens(topcornAmount, countTokens[1], path, address(this), block.timestamp); // Sale tokens CORN
        IWBNB(s.c.wbnb).withdraw(bnbAmount + amounts[1]);
        (bool success, ) = (msg.sender).call{value: bnbAmount + amounts[1]}(""); // send BNB to sender
        require(success, "WBNB: bnb transfer failed");
        emit ApproveWithdraw(crates, getLP, bnbAmount + amounts[1]);
    }

    /// @notice Holding tokens CORN in the TopCorn Protocol.
    /// @param crates Seasons for holding tokens CORN.
    /// @param amounts Amount tokens CORN for holding.
    function claimCorn(uint32[] calldata crates, uint256[] calldata amounts) external nonReentrant {
        LibDiamond.enforceIsContractOwner(); // Only the owner
        ITopcornProtocol(s.c.topcornProtocol).withdrawTopcorns(crates, amounts); // call TopCorn Protocol (withdraw corn)
        uint32 arrivalSeason = ITopcornProtocol(s.c.topcornProtocol).season() + ITopcornProtocol(s.c.topcornProtocol).withdrawSeasons();
        emit ClaimCorn(crates, amounts, arrivalSeason);
    }

    /// @notice Remove tokens CORN from the TopCotn Protocol. Convert CORN to LP. Invest LP in the Topcorn Protocol.
    /// @param crates Seasons for removing tokens CORN.
    /// @param slippage 0.00-100.00 percent (0-10000)
    /// @return getLP Amount of invested tokens LP.
    function updateReserve(uint32[] calldata crates, uint32 slippage, uint256[] memory countTokens) external nonReentrant returns (uint256 getLP) {
        LibDiamond.enforceIsContractOwner(); // Only the ownernonReentrant
        uint256 getCORN = IERC20(s.c.topcorn).balanceOf(address(this));
        ITopcornProtocol(s.c.topcornProtocol).claimTopcorns(crates); // call TopCorn Protocol (claim CORN).
        getCORN = IERC20(s.c.topcorn).balanceOf(address(this)) - getCORN; //  Total removed of tokens CORN
        uint256 checkBNB = calcSlippage(slippage, countTokens[1]); // calculation amounts for slippage
        uint256 checkCorn = calcSlippage(slippage, (getCORN - countTokens[0])); // calculation amounts for slippage
        getLP = countLP();
        ITopcornProtocol(s.c.topcornProtocol).addAndDepositLP(0, 0, countTokens[1], ITopcornProtocol.AddLiquidity(getCORN - countTokens[0], checkCorn, checkBNB)); // call TopCorn Protocol (add liquidity)
        getLP = countLP() - getLP; // Total invested of tokens LP
        s.reserveLP = s.reserveLP + getLP; // update reserves
        emit SyncDefi(s.reserveLP);
        emit ConvertCornToLP(getCORN, getLP);
    }

    /// @notice Convert CORN to LP in TopCorn Protocol. Only for price CORN > 1$.
    /// @param crates Seasons for converting tokens CORN.
    /// @param amounts Amount tokens CORN for converting.
    /// @param slippage 0.00-100.00 percent (0-10000)
    /// @return getLP Amount of invested tokens LP.
    function convertCorn(
        uint32[] calldata crates,
        uint256[] calldata amounts,
        uint32 slippage
    ) external nonReentrant returns (uint256 getLP) {
        LibDiamond.enforceIsContractOwner(); // Only the owner
        uint256 countCorn = 0;
        for (uint256 i; i < crates.length; i++) countCorn = countCorn + amounts[i]; // Sum total amount of tokens CORN
        (uint256[] memory countTokens, uint256 bnbReserve, uint256 cornReserve) = getCountTokenFromCorn(countCorn); // Get the amount of tokens (BNB and CORN) to invest in liquidity. countTokens - [CORN, BNB], bnbReserve, cornReserve - current pool reserve.
        uint256 minLP = Helper.calculateLpRemove(countCorn - countTokens[0], cornReserve, countTokens[1], bnbReserve); // Calc amount LP for CORN
        getLP = countLP();
        ITopcornProtocol(s.c.topcornProtocol).convertDepositedTopcorns(countCorn, calcSlippage(slippage, minLP), crates, amounts); // call TopCorn Protocol (convert CORN)
        getLP = countLP() - getLP; // Total invested of tokens LP
        s.reserveLP = s.reserveLP + getLP; // update reserves
        emit SyncDefi(s.reserveLP);
        emit ConvertCornToLP(countCorn, getLP);
    }

    /// @notice Remove tokens CORN from the TopCotn Protocol. Swap CORN to BNB. .
    /// @param crates Seasons for removing tokens CORN.
    /// @return amounts Amount of get Corn and Amount of get Bnb.
    function sellCorn(uint32[] calldata crates) external nonReentrant returns (uint256[] memory amounts) {
        LibDiamond.enforceIsContractOwner(); // Only the ownernonReentrant
        uint256 getCORN = IERC20(s.c.topcorn).balanceOf(address(this));
        ITopcornProtocol(s.c.topcornProtocol).claimTopcorns(crates); // call TopCorn Protocol (claim CORN).
        getCORN = IERC20(s.c.topcorn).balanceOf(address(this)) - getCORN; //  Total removed of tokens CORN
        (uint256[] memory countTokens, address[] memory path) = getAmounts(s.c.topcorn, s.c.wbnb, getCORN); // calculate the amount of sale of tokens CORN
        amounts = IPancakeRouter02(s.c.router).swapExactTokensForTokens(getCORN, countTokens[1], path, address(this), block.timestamp); // Sale tokens CORN
        IWBNB(s.c.wbnb).withdraw(amounts[1]);
        (bool success, ) = (msg.sender).call{value: amounts[1]}(""); // send BNB to sender
        require(success, "WBNB: bnb transfer failed");
        emit SellCorn(crates, getCORN, amounts[1]);
    }

    /// @notice Claim BNB for Season Of Plenty.
    /// @return getBNB Amount of get BNB.
    function claimBNB() external nonReentrant returns (uint256 getBNB) {
        LibDiamond.enforceIsContractOwner(); // Only the ownernonReentrant
        require(ITopcornProtocol(s.c.topcornProtocol).balanceOfBNB(address(this)) > 0, "Balance SOP must be > 0");
        getBNB = address(this).balance;
        ITopcornProtocol(s.c.topcornProtocol).claimBnb(); // call TopCorn Protocol (claim BNB).
        getBNB = address(this).balance - getBNB; //  Total got BNB
        require(getBNB > 0, "No bnb for transfer");
        (bool success, ) = (msg.sender).call{value: getBNB}(""); // send BNB to sender
        require(success, "WBNB: bnb transfer failed");
        emit ClaimBNB(getBNB);
    }

    /// @notice Update Silo - get CORN
    /// @return getCORN Amount of get CORN.
    function update() external nonReentrant returns (uint256 getCORN) {
        LibDiamond.enforceIsContractOwner(); // Only the ownernonReentrant
        getCORN = ITopcornProtocol(s.c.topcornProtocol).topcornDeposit(address(this), ITopcornProtocol(s.c.topcornProtocol).season());
        ITopcornProtocol(s.c.topcornProtocol).updateSilo(address(this)); // call TopCorn Protocol (updateSilo).
        getCORN = ITopcornProtocol(s.c.topcornProtocol).topcornDeposit(address(this), ITopcornProtocol(s.c.topcornProtocol).season()) - getCORN;
        emit Update(getCORN);
    }
}